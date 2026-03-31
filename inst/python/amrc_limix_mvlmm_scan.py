#!/usr/bin/env python3
"""Generic LIMIX mixed-model scan runner for amrcartography.

This script accepts response, marker, optional covariate, and optional kinship
CSV files produced by the R package and runs either:

1. a multivariate mixed-model scan across all response columns, or
2. a univariate mixed-model scan across each response column separately.

It is intentionally generic: the inputs can represent phenotype-map axes,
MIC columns, gene presence/absence markers, aligned allele tables, or other
numeric features, as long as the R side has already prepared the CSV files.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import pandas as pd


def _read_labeled_frame(path: str) -> pd.DataFrame:
    frame = pd.read_csv(path)
    if "isolate_id" not in frame.columns:
        raise ValueError(f"{path} must contain an 'isolate_id' column.")
    frame["isolate_id"] = frame["isolate_id"].astype(str)
    return frame


def _read_kinship(path: str) -> tuple[pd.Index | None, np.ndarray]:
    frame = pd.read_csv(path)

    if "isolate_id" in frame.columns:
        ids = pd.Index(frame["isolate_id"].astype(str), name="isolate_id")
        matrix = frame.drop(columns=["isolate_id"]).to_numpy(dtype=float)
        return ids, matrix

    return None, frame.to_numpy(dtype=float)


def _read_component_manifest(path: str) -> pd.DataFrame:
    frame = pd.read_csv(path)
    required = {"label", "path"}
    if not required.issubset(frame.columns):
        raise ValueError(f"{path} must contain columns: label, path")
    return frame


def _align_inputs(
    responses: pd.DataFrame,
    markers: pd.DataFrame,
    covariates: pd.DataFrame | None = None,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame | None]:
    response_idx = responses.set_index("isolate_id")
    marker_idx = markers.set_index("isolate_id")
    shared_ids = response_idx.index.intersection(marker_idx.index)

    covariate_idx = None
    if covariates is not None:
        covariate_idx = covariates.set_index("isolate_id")
        shared_ids = shared_ids.intersection(covariate_idx.index)

    if len(shared_ids) == 0:
        raise ValueError("No shared isolate IDs were found across the input files.")

    response_idx = response_idx.loc[shared_ids]
    marker_idx = marker_idx.loc[shared_ids]
    if covariate_idx is not None:
        covariate_idx = covariate_idx.loc[shared_ids]

    return response_idx, marker_idx, covariate_idx


def _align_kinship(
    kinship_ids: pd.Index | None,
    kinship_matrix: np.ndarray | None,
    isolate_ids: pd.Index,
) -> np.ndarray | None:
    if kinship_matrix is None:
        return None

    if kinship_ids is None:
        if kinship_matrix.shape[0] != len(isolate_ids) or kinship_matrix.shape[1] != len(isolate_ids):
            raise ValueError("Kinship matrix must align to the retained isolate count.")
        return kinship_matrix

    kinship_frame = pd.DataFrame(kinship_matrix, index=kinship_ids, columns=kinship_ids)
    missing = isolate_ids.difference(kinship_frame.index)
    if len(missing) > 0:
        raise ValueError(
            "Kinship matrix is missing retained isolate IDs: "
            + ", ".join(map(str, missing[:10]))
        )
    kinship_frame = kinship_frame.loc[isolate_ids, isolate_ids]
    return kinship_frame.to_numpy(dtype=float)


def _trait_covariance(y: pd.DataFrame, mode: str) -> np.ndarray:
    p = y.shape[1]
    if mode == "identity":
        return np.eye(p)

    cov = np.cov(y.to_numpy(dtype=float), rowvar=False)
    cov = np.asarray(cov, dtype=float)
    if cov.ndim == 0:
        cov = np.array([[float(cov)]], dtype=float)
    elif cov.ndim == 1:
        cov = np.diag(cov)
    return cov


def _na_stats_row(columns: list[str], marker_name: str, trait_name: str | None, error_text: str) -> pd.DataFrame:
    row = {col: np.nan for col in columns}
    row["marker"] = marker_name
    if trait_name is not None:
        row["trait_name"] = trait_name
    row["error"] = error_text
    return pd.DataFrame([row])


def _ensure_effect_frame(frame: pd.DataFrame, marker_name: str, trait_name: str | None) -> pd.DataFrame:
    frame = frame.copy()
    frame["marker"] = marker_name
    if trait_name is not None:
        frame["trait_name"] = trait_name
    return frame


def run_heritability(
    responses: pd.DataFrame,
    kinship_matrix: np.ndarray,
) -> pd.DataFrame:
    try:
        from limix.her import estimate
    except ImportError as exc:
        raise RuntimeError(
            "Running the LIMIX heritability analysis requires Python package 'limix'."
        ) from exc

    rows = []
    for response_name in responses.columns:
        try:
            result = estimate(responses[response_name], "normal", kinship_matrix, verbose=False)
            row = {"response": response_name, "error": np.nan}

            if np.isscalar(result):
                row["heritability"] = float(result)
            elif isinstance(result, dict):
                row.update(result)
            elif hasattr(result, "items"):
                row.update(dict(result.items()))
            elif hasattr(result, "h2"):
                row["heritability"] = float(result.h2)
            else:
                row["result"] = str(result)

            rows.append(row)
        except Exception as exc:  # pragma: no cover
            rows.append({"response": response_name, "heritability": np.nan, "error": str(exc)})

    return pd.DataFrame(rows)


def run_variance_decomposition(
    responses: pd.DataFrame,
    component_manifest: pd.DataFrame,
    isolate_ids: pd.Index,
) -> pd.DataFrame:
    try:
        from limix.vardec import VarDec
    except ImportError as exc:
        raise RuntimeError(
            "Running the LIMIX variance-decomposition analysis requires Python package 'limix'."
        ) from exc

    components = []
    for _, row in component_manifest.iterrows():
        comp_ids, comp_matrix = _read_kinship(row["path"])
        comp_matrix = _align_kinship(comp_ids, comp_matrix, isolate_ids)
        components.append((str(row["label"]), comp_matrix))

    rows = []
    for response_name in responses.columns:
        y = responses[response_name]
        try:
            vd = VarDec(y, "normal")
            for label, comp_matrix in components:
                vd.append(comp_matrix, label)
            vd.append_iid("noise")
            vd.fit(verbose=False)

            scales = [float(c.scale) for c in vd._covariance]
            labels = [label for label, _ in components] + ["noise"]
            total = float(np.sum(scales))

            for label, scale in zip(labels, scales):
                rows.append(
                    {
                        "response": response_name,
                        "component": label,
                        "variance": scale,
                        "proportion": (scale / total) if total > 0 else np.nan,
                        "error": np.nan,
                    }
                )
        except Exception as exc:  # pragma: no cover
            rows.append(
                {
                    "response": response_name,
                    "component": np.nan,
                    "variance": np.nan,
                    "proportion": np.nan,
                    "error": str(exc),
                }
            )

    return pd.DataFrame(rows)


def run_multivariate_scan(
    responses: pd.DataFrame,
    markers: pd.DataFrame,
    covariates: pd.DataFrame | None,
    kinship_matrix: np.ndarray | None,
    trait_covariance: str,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    try:
        import limix
        from limix.qtl import scan
        from limix.stats import linear_kinship
    except ImportError as exc:
        raise RuntimeError(
            "Running the LIMIX multivariate mixed-model scan requires Python "
            "packages 'limix', 'numpy', and 'pandas'."
        ) from exc

    y = responses.copy()
    g_all = markers.copy()
    m = None if covariates is None else covariates.to_numpy(dtype=float)
    a = _trait_covariance(y, trait_covariance)
    a0 = np.ones((y.shape[1], 1))
    a1 = np.eye(y.shape[1])

    stats_rows = []
    effect_rows = []

    for marker_name in g_all.columns:
        test_marker = g_all[[marker_name]]
        try:
            if kinship_matrix is None:
                remainder = g_all.drop(columns=[marker_name])
                if remainder.shape[1] == 0:
                    remainder = test_marker
                k = linear_kinship(remainder.to_numpy(dtype=float))
            else:
                k = kinship_matrix

            result = scan(
                G=test_marker,
                Y=y,
                K=k,
                M=m,
                A=a,
                A0=a0,
                A1=a1,
                verbose=False,
            )

            stats_row = result.stats.copy()
            stats_row["marker"] = marker_name
            stats_row["error"] = np.nan
            stats_rows.append(stats_row)

            if "h2" in result.effsizes:
                effect_rows.append(_ensure_effect_frame(result.effsizes["h2"], marker_name, None))
        except Exception as exc:  # pragma: no cover - execution depends on local Python/LIMIX env
            if stats_rows:
                columns = list(stats_rows[0].columns)
            else:
                columns = ["lml0", "lml2", "dof20", "scale2", "pv20", "marker", "error"]
            stats_rows.append(_na_stats_row(columns, marker_name, None, str(exc)))

    stats_frame = pd.concat(stats_rows, ignore_index=True) if stats_rows else pd.DataFrame()
    effects_frame = pd.concat(effect_rows, ignore_index=True) if effect_rows else pd.DataFrame()
    return stats_frame, effects_frame


def run_univariate_scan(
    responses: pd.DataFrame,
    markers: pd.DataFrame,
    covariates: pd.DataFrame | None,
    kinship_matrix: np.ndarray | None,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    try:
        import limix
        from limix.qtl import scan
        from limix.stats import linear_kinship
    except ImportError as exc:
        raise RuntimeError(
            "Running the LIMIX univariate mixed-model scan requires Python "
            "packages 'limix', 'numpy', and 'pandas'."
        ) from exc

    g_all = markers.copy()
    m = None if covariates is None else covariates.to_numpy(dtype=float)

    stats_rows = []
    effect_rows = []

    for trait_name in responses.columns:
        y_trait = responses[[trait_name]]

        for marker_name in g_all.columns:
            test_marker = g_all[[marker_name]]
            try:
                if kinship_matrix is None:
                    remainder = g_all.drop(columns=[marker_name])
                    if remainder.shape[1] == 0:
                        remainder = test_marker
                    k = linear_kinship(remainder.to_numpy(dtype=float))
                else:
                    k = kinship_matrix

                result = scan(
                    test_marker,
                    y_trait,
                    "normal",
                    K=k,
                    M=m,
                    verbose=False,
                )

                stats_row = result.stats.copy()
                stats_row["marker"] = marker_name
                stats_row["trait_name"] = trait_name
                stats_row["error"] = np.nan
                stats_rows.append(stats_row)

                if "h2" in result.effsizes:
                    effect_rows.append(_ensure_effect_frame(result.effsizes["h2"], marker_name, trait_name))
            except Exception as exc:  # pragma: no cover - execution depends on local Python/LIMIX env
                if stats_rows:
                    columns = list(stats_rows[0].columns)
                else:
                    columns = ["lml0", "lml2", "dof20", "scale2", "pv20", "marker", "trait_name", "error"]
                stats_rows.append(_na_stats_row(columns, marker_name, trait_name, str(exc)))

    stats_frame = pd.concat(stats_rows, ignore_index=True) if stats_rows else pd.DataFrame()
    effects_frame = pd.concat(effect_rows, ignore_index=True) if effect_rows else pd.DataFrame()
    return stats_frame, effects_frame


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a generic LIMIX mixed-model scan.")
    parser.add_argument(
        "--mode",
        choices=("multivariate", "univariate", "heritability", "variance-decomposition"),
        required=True,
    )
    parser.add_argument("--trait-covariance", choices=("empirical", "identity"), default="empirical")
    parser.add_argument("--responses", required=True, help="CSV file of response variables with isolate_id column.")
    parser.add_argument("--markers", help="CSV file of markers/features with isolate_id column.")
    parser.add_argument("--covariates", help="Optional CSV file of covariates with isolate_id column.")
    parser.add_argument("--kinship", help="Optional kinship CSV aligned to isolate order or isolate_id labels.")
    parser.add_argument("--component-manifest", help="Optional manifest CSV with label/path columns for variance components.")
    parser.add_argument("--out-stats", required=True, help="Output CSV path for statistics.")
    parser.add_argument("--out-effects", help="Optional output CSV path for effect sizes.")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    responses = _read_labeled_frame(args.responses)
    covariates = _read_labeled_frame(args.covariates) if args.covariates else None

    kinship_ids = None
    kinship_matrix = None
    if args.kinship:
        kinship_ids, kinship_matrix = _read_kinship(args.kinship)

    if args.mode in ("multivariate", "univariate"):
        if not args.markers:
            raise ValueError("--markers is required for multivariate and univariate scan modes.")
        markers = _read_labeled_frame(args.markers)
        responses, markers, covariates = _align_inputs(responses, markers, covariates)
        isolate_ids = responses.index
        kinship_matrix = _align_kinship(kinship_ids, kinship_matrix, isolate_ids) if args.kinship else None

    if args.mode == "multivariate":
        stats_frame, effects_frame = run_multivariate_scan(
            responses=responses,
            markers=markers,
            covariates=covariates,
            kinship_matrix=kinship_matrix,
            trait_covariance=args.trait_covariance,
        )
    elif args.mode == "univariate":
        stats_frame, effects_frame = run_univariate_scan(
            responses=responses,
            markers=markers,
            covariates=covariates,
            kinship_matrix=kinship_matrix,
        )
    else:
        isolate_ids = responses.set_index("isolate_id").index
        responses = responses.set_index("isolate_id")
        kinship_matrix = _align_kinship(kinship_ids, kinship_matrix, isolate_ids) if args.kinship else None
        if args.mode == "heritability":
            if kinship_matrix is None:
                raise ValueError("--kinship is required for heritability mode.")
            stats_frame = run_heritability(
                responses=responses,
                kinship_matrix=kinship_matrix,
            )
            effects_frame = pd.DataFrame()
        elif args.mode == "variance-decomposition":
            if not args.component_manifest:
                raise ValueError("--component-manifest is required for variance-decomposition mode.")
            manifest = _read_component_manifest(args.component_manifest)
            stats_frame = run_variance_decomposition(
                responses=responses,
                component_manifest=manifest,
                isolate_ids=isolate_ids,
            )
            effects_frame = pd.DataFrame()
        else:
            raise ValueError(f"Unsupported mode: {args.mode}")

    if args.out_effects:
        Path(args.out_effects).parent.mkdir(parents=True, exist_ok=True)
        effects_frame.to_csv(args.out_effects, index=False)

    Path(args.out_stats).parent.mkdir(parents=True, exist_ok=True)
    stats_frame.to_csv(args.out_stats, index=False)
    return 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
