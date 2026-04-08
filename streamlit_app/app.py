from __future__ import annotations

import io
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pandas as pd
import streamlit as st


REPO_ROOT = Path(__file__).resolve().parents[1]
BACKEND = REPO_ROOT / "streamlit_app" / "amrc_streamlit_backend.R"
GENERIC_EXAMPLE_ROOT = REPO_ROOT / "inst" / "extdata" / "examples" / "generic"
SPNEUMONIAE_08_ROOT = REPO_ROOT / "inst" / "extdata" / "examples" / "spneumoniae-08"
PACKAGED_SUIS_ROOT = REPO_ROOT / "inst" / "extdata" / "examples" / "suis-demo"
LOCAL_SUIS_ROOT = Path("/Users/ab69/AMR_cartography_suis")


def existing_path(path: Path) -> Path | None:
    return path if path.exists() else None


def demo_specs() -> dict[str, dict]:
    specs: dict[str, dict] = {
        "generic_mic_only": {
            "label": "Generic MIC only",
            "scope": "Bundled package demo",
            "note": "Small generic MIC teaching fixture for fast QA and smoke runs.",
            "phenotype_path": GENERIC_EXAMPLE_ROOT / "mic_raw.csv",
            "phenotype_id_col": "isolate_id",
            "mic_cols": ["drug_a", "drug_b", "drug_c"],
            "metadata_cols": ["lineage", "source"],
            "transform": "log2",
            "less_than": "numeric",
            "greater_than": "numeric",
            "fill_col": "lineage",
            "group_col": "lineage",
            "cluster_distinct_col": "isolate_id",
            "n_clusters": 3,
            "cluster_max_k": 6,
            "phenotype_rotation_degrees": 0.0,
            "external_rotation_degrees": 0.0,
            "external_path": None,
            "external_mode": None,
            "reference_enabled": False,
        },
        "generic_numeric_external": {
            "label": "Generic MIC + numeric features",
            "scope": "Bundled package demo",
            "note": "Small generic fixture with aligned numeric external features.",
            "phenotype_path": GENERIC_EXAMPLE_ROOT / "mic_raw.csv",
            "phenotype_id_col": "isolate_id",
            "mic_cols": ["drug_a", "drug_b", "drug_c"],
            "metadata_cols": ["lineage", "source"],
            "transform": "log2",
            "less_than": "numeric",
            "greater_than": "numeric",
            "fill_col": "lineage",
            "group_col": "lineage",
            "cluster_distinct_col": "isolate_id",
            "n_clusters": 3,
            "cluster_max_k": 6,
            "phenotype_rotation_degrees": 0.0,
            "external_rotation_degrees": 0.0,
            "external_path": GENERIC_EXAMPLE_ROOT / "external_numeric.csv",
            "external_mode": "numeric_features",
            "external_id_col": "isolate_id",
            "external_feature_cols": ["axis1", "axis2"],
            "reference_enabled": True,
            "reference_col": "lineage",
        },
        "generic_character_external": {
            "label": "Generic MIC + character features",
            "scope": "Bundled package demo",
            "note": "Small generic fixture with aligned character-state external data.",
            "phenotype_path": GENERIC_EXAMPLE_ROOT / "mic_raw.csv",
            "phenotype_id_col": "isolate_id",
            "mic_cols": ["drug_a", "drug_b", "drug_c"],
            "metadata_cols": ["lineage", "source"],
            "transform": "log2",
            "less_than": "numeric",
            "greater_than": "numeric",
            "fill_col": "lineage",
            "group_col": "lineage",
            "cluster_distinct_col": "isolate_id",
            "n_clusters": 3,
            "cluster_max_k": 6,
            "phenotype_rotation_degrees": 0.0,
            "external_rotation_degrees": 0.0,
            "external_path": GENERIC_EXAMPLE_ROOT / "external_character.csv",
            "external_mode": "character_features",
            "external_id_col": "isolate_id",
            "reference_enabled": True,
            "reference_col": "lineage",
        },
    }

    spn_phenotype = existing_path(SPNEUMONIAE_08_ROOT / "meta_data_Spneumoniae.csv")
    spn_external = existing_path(SPNEUMONIAE_08_ROOT / "genotype_map_calibrated.csv")
    if spn_phenotype is not None:
        specs["spneumoniae_case_study"] = {
            "label": "S. pneumoniae case study",
            "scope": "Bundled large case study",
            "note": "3628-isolate packaged pneumococcal MIC case study with optional genotype-map coordinates for external comparison.",
            "phenotype_path": spn_phenotype,
            "phenotype_id_col": "LABID",
            "mic_cols": [
                "Penicillin",
                "Amoxicillin",
                "Meropenem",
                "Cefotaxime",
                "Ceftriaxone",
                "Cefuroxime",
            ],
            "metadata_cols": ["PT"],
            "transform": "log2",
            "less_than": "numeric",
            "greater_than": "numeric",
            "fill_col": "PT",
            "group_col": "PT",
            "cluster_distinct_col": "LABID",
            "n_clusters": 6,
            "cluster_max_k": 10,
            "phenotype_rotation_degrees": 326.0,
            "external_rotation_degrees": 0.0,
            "external_path": spn_external,
            "external_mode": "numeric_features" if spn_external is not None else None,
            "external_id_col": "LABID",
            "external_feature_cols": ["G1", "G2"],
            "reference_enabled": spn_external is not None,
            "reference_col": "PT",
        }

    packaged_suis_required = {
        "phenotype_path": PACKAGED_SUIS_ROOT / "phenotype_map_input_non_divergent_log2.csv",
        "phenotype_metadata_path": PACKAGED_SUIS_ROOT / "mic_metadata_non_divergent.csv",
        "external_path": PACKAGED_SUIS_ROOT / "pbp_distance_matrix_non_divergent.csv",
    }
    local_suis_required = {
        "phenotype_path": LOCAL_SUIS_ROOT / "results" / "02_prepare_phenotypes" / "phenotype_map_input_non_divergent_log2.csv",
        "phenotype_metadata_path": LOCAL_SUIS_ROOT / "results" / "02_prepare_phenotypes" / "mic_metadata_non_divergent.csv",
        "external_path": LOCAL_SUIS_ROOT / "results" / "04_process_genotypes_and_pbps" / "pbp_distance_matrix_non_divergent.csv",
    }

    if all(path.exists() for path in packaged_suis_required.values()):
        suis_required = packaged_suis_required
        suis_scope = "Bundled large case study"
        suis_note = (
            "633-isolate packaged S. suis phenotype panel with a bundled "
            "precomputed PBP distance matrix for website/demo exploration."
        )
    elif all(path.exists() for path in local_suis_required.values()):
        suis_required = local_suis_required
        suis_scope = "Local large case study"
        suis_note = (
            "633-isolate phenotype panel with local S. suis genotype distance "
            "matrix from the sibling AMR_cartography_suis checkout."
        )
    else:
        suis_required = None

    if suis_required is not None:
        specs["suis_case_study"] = {
            "label": "S. suis case study",
            "scope": suis_scope,
            "note": suis_note,
            "phenotype_path": suis_required["phenotype_path"],
            "phenotype_metadata_path": suis_required["phenotype_metadata_path"],
            "phenotype_id_col": "LABID",
            "mic_cols": ["Amoxicillin", "Cefquinome", "Ceftiofur", "Penicillin"],
            "metadata_cols": ["BAPS2_1092", "Genome.Set", "Pathogen", "Source", "Year"],
            "transform": "none",
            "less_than": "numeric",
            "greater_than": "numeric",
            "fill_col": "BAPS2_1092",
            "group_col": "BAPS2_1092",
            "cluster_distinct_col": "LABID",
            "n_clusters": 5,
            "cluster_max_k": 10,
            "phenotype_rotation_degrees": 230.0,
            "external_rotation_degrees": 0.0,
            "external_path": suis_required["external_path"],
            "external_mode": "precomputed_distance",
            "external_id_col": "LABID",
            "reference_enabled": True,
            "reference_col": "BAPS2_1092",
        }

    return specs


DEMO_SPECS = demo_specs()


def read_uploaded_csv(uploaded_file) -> pd.DataFrame | None:
    if uploaded_file is None:
        return None
    return pd.read_csv(io.BytesIO(uploaded_file.getvalue()))


def read_local_csv(path: Path | None) -> pd.DataFrame | None:
    if path is None:
        return None
    if not path.exists():
        raise FileNotFoundError(f"Bundled example file is missing: {path}")
    return pd.read_csv(path)


def none_option(label: str = "(none)") -> str:
    return label


def maybe_none(value: str | None) -> str | None:
    if value in (None, "", "(none)"):
        return None
    return value


def maybe_positive_number(value):
    if value in (None, ""):
        return None
    try:
        numeric = float(value)
    except (TypeError, ValueError):
        return None
    if numeric <= 0:
        return None
    return numeric


def maybe_number(value):
    if value in (None, ""):
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


def save_uploaded_file(uploaded_file, target: Path) -> None:
    target.write_bytes(uploaded_file.getvalue())


def save_dataframe(df: pd.DataFrame, target: Path) -> None:
    df.to_csv(target, index=False)


def clear_demo_selection() -> None:
    for key in ("demo_key", "demo_label"):
        st.session_state.pop(key, None)


def load_demo_phenotype_dataframe(spec: dict) -> pd.DataFrame:
    phenotype_df = read_local_csv(spec["phenotype_path"])
    metadata_path = spec.get("phenotype_metadata_path")
    if metadata_path is None:
        return phenotype_df

    metadata_df = read_local_csv(metadata_path)
    id_col = spec["phenotype_id_col"]
    overlap_cols = [
        col for col in metadata_df.columns
        if col != id_col and col in phenotype_df.columns
    ]
    if overlap_cols:
        metadata_df = metadata_df.drop(columns=overlap_cols)
    return phenotype_df.merge(metadata_df, on=id_col, how="left")


def load_demo_external_dataframe(spec: dict) -> pd.DataFrame | None:
    external_path = spec.get("external_path")
    if external_path is None:
        return None
    return read_local_csv(external_path)


def demo_catalog_frame() -> pd.DataFrame:
    rows = []
    for key, spec in DEMO_SPECS.items():
        rows.append(
            {
                "Key": key,
                "Dataset": spec["label"],
                "Scope": spec.get("scope", "Demo"),
                "External": "yes" if spec.get("external_path") is not None else "no",
                "Note": spec.get("note", ""),
            }
        )
    return pd.DataFrame(rows)


def apply_demo_selection(demo_key: str) -> None:
    spec = DEMO_SPECS[demo_key]
    phenotype_df = load_demo_phenotype_dataframe(spec)
    phenotype_columns = phenotype_df.columns.tolist()
    metadata_cols = [col for col in spec.get("metadata_cols", []) if col in phenotype_columns]
    mic_cols = [col for col in spec.get("mic_cols", []) if col in phenotype_columns]

    st.session_state["demo_key"] = demo_key
    st.session_state["demo_label"] = spec["label"]
    st.session_state["phenotype_id_col"] = spec["phenotype_id_col"]
    st.session_state["mic_cols"] = mic_cols
    st.session_state["metadata_cols"] = metadata_cols
    st.session_state["transform"] = spec.get("transform", "log2")
    st.session_state["less_than"] = spec.get("less_than", "numeric")
    st.session_state["greater_than"] = spec.get("greater_than", "numeric")
    st.session_state["fill_col"] = spec.get("fill_col", none_option()) if spec.get("fill_col") in metadata_cols else none_option()
    st.session_state["facet_by"] = none_option()
    st.session_state["group_col"] = spec.get("group_col", none_option()) if spec.get("group_col") in metadata_cols else none_option()
    st.session_state["grid_spacing_one"] = True
    st.session_state["density"] = False
    st.session_state["use_clustering"] = True
    st.session_state["n_clusters"] = spec.get("n_clusters", 3)
    st.session_state["cluster_max_k"] = spec.get("cluster_max_k", 6)
    st.session_state["cluster_distinct_col"] = spec.get("cluster_distinct_col", spec["phenotype_id_col"])
    st.session_state["phenotype_rotation_degrees"] = spec.get("phenotype_rotation_degrees", 0.0)
    st.session_state["external_rotation_degrees"] = spec.get("external_rotation_degrees", 0.0)
    st.session_state["reference_cluster_mode"] = "auto"
    st.session_state["reference_filter_col"] = none_option()
    st.session_state["reference_filter_values"] = []
    st.session_state["reference_x_max"] = 0.0
    st.session_state["reference_y_max"] = 0.0
    st.session_state["reference_x_break_step"] = 0.0
    st.session_state["reference_y_break_step"] = 0.0
    st.session_state["reference_annotation_text"] = ""
    st.session_state["reference_annotation_x"] = 0.0
    st.session_state["reference_annotation_y"] = 0.0
    st.session_state["report_pdf"] = False

    if spec.get("external_path") is None:
        st.session_state["use_external"] = False
        st.session_state["use_reference_summary"] = False
    else:
        external_df = load_demo_external_dataframe(spec)
        external_columns = external_df.columns.tolist()
        st.session_state["use_external"] = True
        st.session_state["external_mode"] = spec["external_mode"]
        st.session_state["external_id_col"] = spec.get("external_id_col", spec["phenotype_id_col"])
        st.session_state["external_feature_cols"] = [
            col for col in spec.get("external_feature_cols", external_columns)
            if col in external_columns and col != st.session_state["external_id_col"]
        ]
        st.session_state["use_reference_summary"] = bool(spec.get("reference_enabled", True))
        reference_default = spec.get("reference_col", metadata_cols[0] if metadata_cols else spec["phenotype_id_col"])
        st.session_state["reference_col"] = reference_default if reference_default in phenotype_columns else spec["phenotype_id_col"]
        ref_values = phenotype_df[st.session_state["reference_col"]].dropna().astype(str).tolist()
        st.session_state["reference_value"] = str(spec.get("reference_value", ref_values[0] if ref_values else ""))


def active_demo_key() -> str | None:
    value = st.session_state.get("demo_key")
    return value if value in DEMO_SPECS else None


def active_demo_label() -> str | None:
    return st.session_state.get("demo_label")


def apply_rotation_preset(key: str, value: float) -> None:
    st.session_state[key] = float(value)


def copy_input_source(uploaded_file, local_path: Path | None, target: Path, fallback_df: pd.DataFrame | None = None) -> None:
    if uploaded_file is not None:
        save_uploaded_file(uploaded_file, target)
        return
    if local_path is not None:
        target.write_bytes(local_path.read_bytes())
        return
    if fallback_df is not None:
        save_dataframe(fallback_df, target)
        return
    raise ValueError("No input source was provided.")


def build_config(
    phenotype_upload,
    phenotype_df: pd.DataFrame,
    external_upload,
    external_df: pd.DataFrame | None,
    work_dir: Path,
    phenotype_local_path: Path | None = None,
    external_local_path: Path | None = None,
) -> dict:
    phenotype_path = work_dir / "phenotype.csv"
    copy_input_source(
        uploaded_file=phenotype_upload,
        local_path=phenotype_local_path,
        target=phenotype_path,
        fallback_df=phenotype_df,
    )

    phenotype_id_col = st.session_state["phenotype_id_col"]
    mic_cols = st.session_state["mic_cols"]
    metadata_cols = st.session_state["metadata_cols"]

    config = {
        "repo_root": str(REPO_ROOT),
        "output_dir": str(work_dir / "output"),
        "phenotype": {
            "path": str(phenotype_path),
            "id_col": phenotype_id_col,
            "mic_cols": mic_cols,
            "metadata_cols": metadata_cols,
            "transform": st.session_state["transform"],
            "less_than": st.session_state["less_than"],
            "greater_than": st.session_state["greater_than"],
            "drop_incomplete": True,
        },
        "plot": {
            "fill_col": maybe_none(st.session_state.get("fill_col")),
            "facet_by": maybe_none(st.session_state.get("facet_by")),
            "grid_spacing_one": st.session_state["grid_spacing_one"],
            "density": st.session_state["density"],
            "phenotype_rotation_degrees": maybe_number(st.session_state.get("phenotype_rotation_degrees")),
            "external_rotation_degrees": maybe_number(st.session_state.get("external_rotation_degrees")),
        },
        "comparison": {
            "group_col": maybe_none(st.session_state.get("group_col")),
        },
        "report": {
            "zip_bundle": True,
            "pdf_export": bool(st.session_state.get("report_pdf")),
        },
        "clustering": {
            "enabled": bool(st.session_state.get("use_clustering")),
            "n_clusters": int(st.session_state.get("n_clusters", 4)),
            "max_k": max(
                int(st.session_state.get("n_clusters", 4)),
                int(st.session_state.get("cluster_max_k", 10)),
            ),
            "distinct_col": maybe_none(st.session_state.get("cluster_distinct_col")),
        },
        "reference": {
            "enabled": bool(st.session_state.get("use_reference_summary")),
            "reference_col": maybe_none(st.session_state.get("reference_col")),
            "reference_value": maybe_none(st.session_state.get("reference_value")),
            "cluster_mode": st.session_state.get("reference_cluster_mode", "auto"),
            "filter_col": maybe_none(st.session_state.get("reference_filter_col")),
            "filter_values": st.session_state.get("reference_filter_values", []),
            "x_max": maybe_positive_number(st.session_state.get("reference_x_max")),
            "y_max": maybe_positive_number(st.session_state.get("reference_y_max")),
            "x_break_step": maybe_positive_number(st.session_state.get("reference_x_break_step")),
            "y_break_step": maybe_positive_number(st.session_state.get("reference_y_break_step")),
            "annotation_text": maybe_none(st.session_state.get("reference_annotation_text")),
            "annotation_x": maybe_number(st.session_state.get("reference_annotation_x")),
            "annotation_y": maybe_number(st.session_state.get("reference_annotation_y")),
        },
        "external": {
            "enabled": bool(st.session_state["use_external"]),
        },
    }

    if st.session_state["use_external"]:
        external_path = work_dir / "external.csv"
        copy_input_source(
            uploaded_file=external_upload,
            local_path=external_local_path,
            target=external_path,
            fallback_df=external_df,
        )
        external_mode = st.session_state["external_mode"]
        external_id_col = st.session_state["external_id_col"]
        external_feature_cols = st.session_state.get("external_feature_cols", [])

        config["external"] = {
            "enabled": True,
            "path": str(external_path),
            "mode": external_mode,
            "id_col": external_id_col,
            "feature_cols": external_feature_cols,
        }

    return config


def run_backend(config: dict) -> dict:
    work_dir = Path(config["output_dir"])
    work_dir.mkdir(parents=True, exist_ok=True)

    config_path = work_dir.parent / "config.json"
    config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")

    package_load_mode = os.environ.get("AMRC_PACKAGE_LOAD_MODE", "source")

    completed = subprocess.run(
        ["Rscript", str(BACKEND), str(config_path)],
        capture_output=True,
        text=True,
        cwd=str(REPO_ROOT),
        env={**os.environ, "AMRC_PACKAGE_LOAD_MODE": package_load_mode},
    )

    if completed.returncode != 0:
        raise RuntimeError(
            "Backend run failed.\n\n"
            f"STDOUT:\n{completed.stdout}\n\n"
            f"STDERR:\n{completed.stderr}"
        )

    summary = json.loads((work_dir / "summary.json").read_text(encoding="utf-8"))

    result = {
        "summary": summary,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
        "files": {},
        "tables": {},
    }

    for name in (
        "phenotype_map.png",
        "external_map.png",
        "side_by_side_maps.png",
        "phenotype_cluster_map.png",
        "phenotype_cluster_elbow.png",
        "external_cluster_map.png",
        "external_cluster_elbow.png",
        "reference_distance_relationship.png",
        "summary.json",
        "amrc_report.md",
        "amrc_report.html",
        "amrc_report.pdf",
        "amrc_result_bundle.rds",
        "amrc_output_bundle.zip",
    ):
        path = work_dir / name
        if path.exists():
            result["files"][name] = path.read_bytes()

    for name in (
        "phenotype_map_data.csv",
        "phenotype_cluster_data.csv",
        "phenotype_cluster_scree.csv",
        "phenotype_fit_metrics.csv",
        "phenotype_residual_summary.csv",
        "phenotype_stress_summary.csv",
        "phenotype_fit_distances.csv",
        "comparison_data.csv",
        "external_cluster_data.csv",
        "external_cluster_scree.csv",
        "external_fit_metrics.csv",
        "external_residual_summary.csv",
        "external_stress_summary.csv",
        "external_fit_distances.csv",
        "reference_distance_table.csv",
        "reference_distance_summary.csv",
    ):
        path = work_dir / name
        if path.exists():
            result["tables"][name] = pd.read_csv(path)
            result["files"][name] = path.read_bytes()

    return result


st.set_page_config(page_title="amrcartography", layout="wide")
st.markdown(
    """
    <style>
    .stApp {
        background-color: #ffffff;
        color: #202020;
    }
    .stApp,
    .stApp p,
    .stApp li,
    .stApp label,
    .stApp span,
    .stApp div,
    .stMarkdown,
    .stCaption,
    .stText,
    [data-testid="stSidebar"],
    [data-testid="stSidebar"] *,
    [data-testid="stMetric"],
    [data-testid="stMetric"] *,
    [data-baseweb="select"] *,
    [data-baseweb="radio"] *,
    [data-baseweb="checkbox"] *,
    .stMultiSelect [data-baseweb="tag"] {
        color: #202020;
    }
    [data-testid="stSidebar"] {
        background-color: #fafafa;
        border-right: 1px solid #dddddd;
    }
    [data-testid="stSidebar"] .stCaption {
        color: #4d4d4d;
    }
    h1, h2, h3 {
        letter-spacing: 0.01em;
        color: #202020;
    }
    h2, h3 {
        color: #202020;
    }
    code, pre {
        color: #202020;
    }
    [data-testid="stMetric"] {
        background: #fbfbfb;
        border: 1px solid #d9d9d9;
        padding: 0.75rem 0.9rem;
        border-radius: 8px;
    }
    .stTabs [data-baseweb="tab-list"] {
        gap: 0.5rem;
    }
    .stTabs [data-baseweb="tab"] {
        border-radius: 6px 6px 0 0;
        border: 1px solid #d9d9d9;
        background: #fafafa;
    }
    .stTabs [data-baseweb="tab"][aria-selected="true"] {
        background: #111111;
        border-color: #111111;
    }
    .stTabs [data-baseweb="tab"][aria-selected="true"],
    .stTabs [data-baseweb="tab"][aria-selected="true"] *,
    .stTabs [data-baseweb="tab"][aria-selected="true"] p,
    .stTabs [data-baseweb="tab"][aria-selected="true"] span,
    .stTabs [data-baseweb="tab"][aria-selected="true"] div,
    .stTabs button[role="tab"][aria-selected="true"],
    .stTabs button[role="tab"][aria-selected="true"] *,
    .stTabs button[role="tab"][aria-selected="true"] p,
    .stTabs button[role="tab"][aria-selected="true"] span,
    .stTabs button[role="tab"][aria-selected="true"] div {
        color: #ffffff !important;
        -webkit-text-fill-color: #ffffff !important;
    }
    .stTabs [data-baseweb="tab"][aria-selected="false"],
    .stTabs [data-baseweb="tab"][aria-selected="false"] *,
    .stTabs [data-baseweb="tab"][aria-selected="false"] p,
    .stTabs [data-baseweb="tab"][aria-selected="false"] span,
    .stTabs [data-baseweb="tab"][aria-selected="false"] div,
    .stTabs button[role="tab"][aria-selected="false"],
    .stTabs button[role="tab"][aria-selected="false"] *,
    .stTabs button[role="tab"][aria-selected="false"] p,
    .stTabs button[role="tab"][aria-selected="false"] span,
    .stTabs button[role="tab"][aria-selected="false"] div {
        color: #202020 !important;
        -webkit-text-fill-color: #202020 !important;
    }
    div.stButton > button[kind="primary"] {
        background-color: #E41A1C;
        color: white;
        border: 1px solid black;
    }
    div.stButton > button[kind="secondary"] {
        color: #202020;
        border: 1px solid #bdbdbd;
    }
    div.stButton > button[kind="primary"]:hover {
        background-color: #C91A14;
        color: white;
    }
    div.stButton > button[kind="secondary"]:hover {
        color: #202020;
        border-color: #7f7f7f;
    }
    .stDownloadButton > button {
        color: #202020;
        border: 1px solid #bdbdbd;
    }
    .amrc-style-note {
        border-left: 4px solid #377EB8;
        background: #f7fbff;
        padding: 0.75rem 1rem;
        margin-bottom: 1rem;
    }
    </style>
    """,
    unsafe_allow_html=True,
)
st.title("amrcartography")
st.caption(
    "Experimental Streamlit front end for the generic phenotype/external workflow, "
    "using manuscript-aligned plotting defaults from the R package."
)
st.markdown(
    (
        '<div class="amrc-style-note">'
        "Maps, cluster overlays, and reference plots are rendered through the package plotting "
        "helpers so the app keeps the manuscript cartography theme, palette, and point styling "
        "rather than using a separate visual system. MIC-scale spacing comes from the package "
        "calibration model: use calibration plus a 1-unit grid if you want one doubling dilution "
        "per major grid step, rather than trying to dilate the map by hand."
        "</div>"
    ),
    unsafe_allow_html=True,
)

with st.sidebar:
    st.header("Quick demo")
    st.caption("Use the bundled package fixtures for fast QA and demo runs.")
    demo_button_cols = st.columns(3)
    if demo_button_cols[0].button("MIC only", use_container_width=True):
        apply_demo_selection("generic_mic_only")
    if demo_button_cols[1].button("Numeric ext.", use_container_width=True):
        apply_demo_selection("generic_numeric_external")
    if demo_button_cols[2].button("Character ext.", use_container_width=True):
        apply_demo_selection("generic_character_external")
    if active_demo_key() is not None:
        st.caption(f"Active exploration dataset: {active_demo_label()}")
        if st.button("Clear demo selection", use_container_width=True):
            clear_demo_selection()

    st.header("Exploration datasets")
    st.caption("Larger case studies and reproducible exploration inputs available in this checkout.")
    case_button_cols = st.columns(2)
    if "spneumoniae_case_study" in DEMO_SPECS and case_button_cols[0].button("S. pneumoniae", use_container_width=True):
        apply_demo_selection("spneumoniae_case_study")
    if "suis_case_study" in DEMO_SPECS and case_button_cols[1].button("S. suis", use_container_width=True):
        apply_demo_selection("suis_case_study")
    with st.expander("Available datasets", expanded=False):
        st.dataframe(
            demo_catalog_frame()[["Dataset", "Scope", "External"]],
            use_container_width=True,
            hide_index=True,
        )
        active_key = active_demo_key()
        if active_key is not None:
            st.caption(DEMO_SPECS[active_key].get("note", ""))

    st.header("Phenotype Input")
    phenotype_upload = st.file_uploader("Phenotype MIC CSV", type=["csv"])
active_spec = DEMO_SPECS.get(active_demo_key()) if active_demo_key() is not None else None

phenotype_df = read_uploaded_csv(phenotype_upload)
if phenotype_df is None and active_spec is not None:
    phenotype_df = load_demo_phenotype_dataframe(active_spec)

if phenotype_df is not None:
    columns = phenotype_df.columns.tolist()

    with st.sidebar:
        st.selectbox("Phenotype ID column", options=columns, key="phenotype_id_col")

        default_mic = columns[1:min(len(columns), 4)]
        st.multiselect(
            "MIC columns",
            options=[col for col in columns if col != st.session_state["phenotype_id_col"]],
            default=default_mic,
            key="mic_cols",
        )

        st.multiselect(
            "Metadata columns",
            options=[
                col for col in columns
                if col != st.session_state["phenotype_id_col"]
            ],
            default=[],
            key="metadata_cols",
        )

        st.selectbox(
            "Transform",
            options=["log2", "none"],
            index=0,
            key="transform",
        )
        st.selectbox(
            "Less-than handling",
            options=["numeric", "half"],
            index=0,
            key="less_than",
        )
        st.selectbox(
            "Greater-than handling",
            options=["numeric", "double"],
            index=0,
            key="greater_than",
        )

        st.header("Plotting")
        metadata_options = [none_option()] + st.session_state["metadata_cols"]
        st.selectbox("Colour by", options=metadata_options, key="fill_col")
        st.selectbox("Facet by", options=metadata_options, key="facet_by")
        st.selectbox("Group column", options=metadata_options, key="group_col")
        st.checkbox(
            "Use 1-unit grid spacing",
            value=False,
            key="grid_spacing_one",
            help="Use this after calibration if you want one doubling dilution per grid interval.",
        )
        st.checkbox("Add density contours", value=False, key="density")
        preset_cols = st.columns(4)
        if preset_cols[0].button("0°", key="phen-rot-0", use_container_width=True):
            apply_rotation_preset("phenotype_rotation_degrees", 0)
        if preset_cols[1].button("+15°", key="phen-rot-15", use_container_width=True):
            apply_rotation_preset("phenotype_rotation_degrees", 15)
        if preset_cols[2].button("-15°", key="phen-rot-neg15", use_container_width=True):
            apply_rotation_preset("phenotype_rotation_degrees", -15)
        if preset_cols[3].button("326°", key="phen-rot-spn", use_container_width=True):
            apply_rotation_preset("phenotype_rotation_degrees", 326)
        st.number_input(
            "Phenotype rotation (degrees)",
            min_value=-360.0,
            max_value=360.0,
            value=0.0,
            step=1.0,
            key="phenotype_rotation_degrees",
            help="Optional post-calibration rotation. The map dilation still comes from the calibration model.",
        )

        st.header("Clustering")
        cluster_distinct_options = [st.session_state["phenotype_id_col"]] + st.session_state["metadata_cols"]
        st.checkbox("Overlay clusters", value=False, key="use_clustering")
        st.number_input("Number of clusters", min_value=2, max_value=20, value=4, step=1, key="n_clusters")
        st.number_input("Max scree k", min_value=2, max_value=30, value=10, step=1, key="cluster_max_k")
        st.selectbox(
            "Cluster distinct units by",
            options=cluster_distinct_options,
            key="cluster_distinct_col",
        )

        st.header("External Structure")
        st.checkbox("Include external/genotype structure", value=False, key="use_external")

    if st.session_state["use_external"]:
        with st.sidebar:
            external_upload = st.file_uploader("External CSV", type=["csv"])
        external_df = read_uploaded_csv(external_upload)
        if external_df is None and active_spec is not None:
            external_df = load_demo_external_dataframe(active_spec)

        if external_df is not None:
            external_columns = external_df.columns.tolist()
            with st.sidebar:
                st.selectbox(
                    "External mode",
                    options=[
                        "precomputed_distance",
                        "numeric_features",
                        "character_features",
                        "sequence_alleles",
                    ],
                    key="external_mode",
                )
                st.selectbox(
                    "External ID column",
                    options=external_columns,
                    key="external_id_col",
                )

                if st.session_state["external_mode"] != "precomputed_distance":
                    st.multiselect(
                        "External feature columns",
                        options=[
                            col for col in external_columns
                            if col != st.session_state["external_id_col"]
                        ],
                        default=[
                            col for col in external_columns
                            if col != st.session_state["external_id_col"]
                        ][: min(6, max(1, len(external_columns) - 1))],
                        key="external_feature_cols",
                    )

                external_rot_cols = st.columns(4)
                if external_rot_cols[0].button("0°", key="ext-rot-0", use_container_width=True):
                    apply_rotation_preset("external_rotation_degrees", 0)
                if external_rot_cols[1].button("+15°", key="ext-rot-15", use_container_width=True):
                    apply_rotation_preset("external_rotation_degrees", 15)
                if external_rot_cols[2].button("-15°", key="ext-rot-neg15", use_container_width=True):
                    apply_rotation_preset("external_rotation_degrees", -15)
                if external_rot_cols[3].button("326°", key="ext-rot-spn", use_container_width=True):
                    apply_rotation_preset("external_rotation_degrees", 326)
                st.number_input(
                    "External rotation (degrees)",
                    min_value=-360.0,
                    max_value=360.0,
                    value=0.0,
                    step=1.0,
                    key="external_rotation_degrees",
                    help="Optional post-calibration rotation for the external/genotype map.",
                )

                st.header("Reference Summary")
                reference_options = [st.session_state["phenotype_id_col"]] + st.session_state["metadata_cols"]
                st.checkbox("Compute reference-distance summary", value=False, key="use_reference_summary")
                st.selectbox("Reference column", options=reference_options, key="reference_col")
                st.selectbox(
                    "Reference summary mode",
                    options=["auto", "overall", "clustered"],
                    format_func=lambda x: {
                        "auto": "Auto",
                        "overall": "Overall only",
                        "clustered": "By cluster",
                    }[x],
                    key="reference_cluster_mode",
                )

                reference_values = (
                    phenotype_df[st.session_state["reference_col"]]
                    .dropna()
                    .astype(str)
                    .unique()
                    .tolist()
                )
                st.selectbox(
                    "Reference value",
                    options=sorted(reference_values),
                    key="reference_value",
                )
                reference_filter_options = [none_option()] + reference_options
                st.selectbox(
                    "Filter reference rows by",
                    options=reference_filter_options,
                    key="reference_filter_col",
                )
                selected_filter_col = maybe_none(st.session_state.get("reference_filter_col"))
                if selected_filter_col is not None and selected_filter_col in phenotype_df.columns:
                    filter_values = (
                        phenotype_df[selected_filter_col]
                        .dropna()
                        .astype(str)
                        .unique()
                        .tolist()
                    )
                    st.multiselect(
                        "Reference filter values",
                        options=sorted(filter_values),
                        default=[],
                        key="reference_filter_values",
                    )
                else:
                    st.session_state["reference_filter_values"] = []
                st.number_input(
                    "Reference plot x max (0 = auto)",
                    min_value=0.0,
                    value=0.0,
                    step=0.5,
                    key="reference_x_max",
                )
                st.number_input(
                    "Reference plot x break step (0 = auto)",
                    min_value=0.0,
                    value=0.0,
                    step=0.5,
                    key="reference_x_break_step",
                )
                st.number_input(
                    "Reference plot y max (0 = auto)",
                    min_value=0.0,
                    value=0.0,
                    step=0.5,
                    key="reference_y_max",
                )
                st.number_input(
                    "Reference plot y break step (0 = auto)",
                    min_value=0.0,
                    value=0.0,
                    step=0.5,
                    key="reference_y_break_step",
                )
                st.text_input(
                    "Reference annotation text",
                    value="",
                    key="reference_annotation_text",
                )
                annotation_cols = st.columns(2)
                annotation_cols[0].number_input(
                    "Annotation x",
                    value=0.0,
                    step=0.5,
                    key="reference_annotation_x",
                )
                annotation_cols[1].number_input(
                    "Annotation y",
                    value=0.0,
                    step=0.5,
                    key="reference_annotation_y",
                )
        else:
            external_upload = None
    else:
        external_upload = None
        external_df = None

    left, right = st.columns((1.1, 1))

    with left:
        st.subheader("Input Preview")
        if active_demo_key() is not None and phenotype_upload is None:
            st.caption(f"Previewing exploration dataset: {active_demo_label()}")
        st.dataframe(phenotype_df.head(10), use_container_width=True)
        if external_df is not None:
            st.subheader("External Preview")
            st.dataframe(external_df.head(10), use_container_width=True)

    with right:
        st.subheader("Run")
        st.markdown(
            "- Requires `Rscript` plus the package dependencies available in the local environment.\n"
            "- This v1 app covers phenotype-only and phenotype-plus-external/genotype map workflows, not the full mixed-model layer.\n"
            "- Map scaling to 1-MIC-style units comes from the package calibration model; the app exposes rotation controls but not a free-form dilation slider.\n"
            "- The generic demo buttons are for fast QA; the larger case-study buttons are slower because they recompute maps, diagnostics, clustering, and reports on real datasets."
        )
        st.checkbox(
            "Export PDF report",
            value=bool(st.session_state.get("report_pdf", False)),
            key="report_pdf",
        )

        can_run = bool(st.session_state.get("mic_cols"))
        if st.session_state["use_external"]:
            can_run = can_run and (
                external_upload is not None or (active_spec is not None and active_spec.get("external_path") is not None)
            )

        if st.button("Run analysis", disabled=not can_run, type="primary"):
            with st.spinner("Running R backend..."):
                try:
                    work_dir = Path(tempfile.mkdtemp(prefix="amrc-streamlit-"))
                    config = build_config(
                        phenotype_upload=phenotype_upload,
                        phenotype_df=phenotype_df,
                        external_upload=external_upload,
                        external_df=external_df,
                        work_dir=work_dir,
                        phenotype_local_path=None,
                        external_local_path=None,
                    )
                    st.session_state["amrc_app_result"] = run_backend(config)
                except Exception as exc:  # noqa: BLE001
                    st.session_state["amrc_app_error"] = str(exc)
                else:
                    st.session_state["amrc_app_error"] = None

result = st.session_state.get("amrc_app_result")
error = st.session_state.get("amrc_app_error")

if error:
    st.error(error)

if result:
    st.subheader("Summary")
    metric_cols = st.columns(4)
    phenotype_summary = result["summary"].get("phenotype", {})
    external_summary = result["summary"].get("external") or {}
    metric_cols[0].metric("Phenotype isolates", phenotype_summary.get("n_isolates", "NA"))
    metric_cols[1].metric("MIC variables", phenotype_summary.get("n_drugs", "NA"))
    metric_cols[2].metric("Phenotype stress", f"{phenotype_summary.get('stress', float('nan')):.3f}" if phenotype_summary.get("stress") is not None else "NA")
    if external_summary:
        metric_cols[3].metric("External stress", f"{external_summary.get('stress', float('nan')):.3f}" if external_summary.get("stress") is not None else "NA")
    else:
        metric_cols[3].metric("External workflow", "off")

    phenotype_calibration = phenotype_summary.get("calibration") or {}
    if phenotype_calibration:
        st.caption(
            "Phenotype map calibration: "
            f"dilation={phenotype_calibration.get('dilation', 'NA')}, "
            f"rotation={phenotype_calibration.get('rotation_degrees', 0)} degrees. "
            "Follow this calibration if you want one-unit grid spacing to mean one doubling dilution."
        )
    external_calibration = external_summary.get("calibration") or {}
    if external_calibration:
        st.caption(
            "External map calibration: "
            f"dilation={external_calibration.get('dilation', 'NA')}, "
            f"rotation={external_calibration.get('rotation_degrees', 0)} degrees."
        )

    extra_downloads = []
    if "summary.json" in result["files"]:
        extra_downloads.append(("Download summary.json", "summary.json", "application/json"))
    if "amrc_result_bundle.rds" in result["files"]:
        extra_downloads.append(("Download result bundle (.rds)", "amrc_result_bundle.rds", "application/octet-stream"))
    if "amrc_report.md" in result["files"]:
        extra_downloads.append(("Download report (.md)", "amrc_report.md", "text/markdown"))
    if "amrc_report.html" in result["files"]:
        extra_downloads.append(("Download report (.html)", "amrc_report.html", "text/html"))
    if "amrc_report.pdf" in result["files"]:
        extra_downloads.append(("Download report (.pdf)", "amrc_report.pdf", "application/pdf"))
    if "amrc_output_bundle.zip" in result["files"]:
        extra_downloads.append(("Download output bundle (.zip)", "amrc_output_bundle.zip", "application/zip"))

    result_tabs = st.tabs(["Maps", "Diagnostics", "Tables", "Reports", "Raw summary"])

    with result_tabs[0]:
        image_cols = st.columns(2)
        if "phenotype_map.png" in result["files"]:
            image_cols[0].image(result["files"]["phenotype_map.png"], caption="Phenotype map")
        if "external_map.png" in result["files"]:
            image_cols[1].image(result["files"]["external_map.png"], caption="External map")

        if "side_by_side_maps.png" in result["files"]:
            st.image(result["files"]["side_by_side_maps.png"], caption="Side-by-side phenotype vs external maps")

        cluster_images = []
        if "phenotype_cluster_map.png" in result["files"]:
            cluster_images.append(("Phenotype clusters", result["files"]["phenotype_cluster_map.png"]))
        if "external_cluster_map.png" in result["files"]:
            cluster_images.append(("External clusters", result["files"]["external_cluster_map.png"]))
        if cluster_images:
            st.subheader("Cluster overlays")
            cluster_cols = st.columns(len(cluster_images))
            for col, (caption, image_bytes) in zip(cluster_cols, cluster_images):
                col.image(image_bytes, caption=caption)

        if "reference_distance_relationship.png" in result["files"]:
            st.subheader("Reference-distance relationship")
            st.image(
                result["files"]["reference_distance_relationship.png"],
                caption="Phenotype vs external distance from the selected reference",
            )

    with result_tabs[1]:
        fit_sections = []
        if "phenotype_fit_metrics.csv" in result["tables"]:
            fit_sections.append(
                ("Phenotype fit", "phenotype_fit_metrics.csv", "phenotype_residual_summary.csv", "phenotype_stress_summary.csv")
            )
        if "external_fit_metrics.csv" in result["tables"]:
            fit_sections.append(
                ("External fit", "external_fit_metrics.csv", "external_residual_summary.csv", "external_stress_summary.csv")
            )
        if fit_sections:
            st.subheader("Goodness-of-fit summaries")
            fit_tabs = st.tabs([label for label, *_ in fit_sections])
            for tab, (label, metrics_name, residual_name, stress_name) in zip(fit_tabs, fit_sections):
                with tab:
                    st.markdown(f"**{label} metrics**")
                    st.dataframe(result["tables"][metrics_name], use_container_width=True)
                    if residual_name in result["tables"]:
                        st.markdown("**Residual summary**")
                        st.dataframe(result["tables"][residual_name], use_container_width=True)
                    if stress_name in result["tables"]:
                        st.markdown("**Stress-per-point summary**")
                        st.dataframe(result["tables"][stress_name], use_container_width=True)
                    download_cols = st.columns(4)
                    for col, name in zip(
                        download_cols,
                        [metrics_name, residual_name, stress_name, metrics_name.replace("_metrics.csv", "_distances.csv")],
                    ):
                        if name in result["files"]:
                            col.download_button(
                                label=f"Download {name}",
                                data=result["files"][name],
                                file_name=name,
                                mime="text/csv",
                                key=f"download-{name}",
                            )

        scree_images = []
        if "phenotype_cluster_elbow.png" in result["files"]:
            scree_images.append(("Phenotype cluster scree", result["files"]["phenotype_cluster_elbow.png"]))
        if "external_cluster_elbow.png" in result["files"]:
            scree_images.append(("External cluster scree", result["files"]["external_cluster_elbow.png"]))
        if scree_images:
            st.subheader("Cluster scree diagnostics")
            scree_cols = st.columns(len(scree_images))
            for col, (caption, image_bytes) in zip(scree_cols, scree_images):
                col.image(image_bytes, caption=caption)
            scree_tables = []
            if "phenotype_cluster_scree.csv" in result["tables"]:
                scree_tables.append(("Phenotype scree table", "phenotype_cluster_scree.csv"))
            if "external_cluster_scree.csv" in result["tables"]:
                scree_tables.append(("External scree table", "external_cluster_scree.csv"))
            if scree_tables:
                scree_table_cols = st.columns(len(scree_tables))
                for col, (caption, name) in zip(scree_table_cols, scree_tables):
                    col.markdown(f"**{caption}**")
                    col.dataframe(result["tables"][name], use_container_width=True, height=220)
                    col.download_button(
                        label=f"Download {name}",
                        data=result["files"][name],
                        file_name=name,
                        mime="text/csv",
                        key=f"download-{name}",
                    )

    with result_tabs[2]:
        if result["tables"]:
            st.subheader("Output tables")
            for name, table in result["tables"].items():
                st.markdown(f"**{name}**")
                st.dataframe(table.head(50), use_container_width=True)
                st.download_button(
                    label=f"Download {name}",
                    data=result["files"][name],
                    file_name=name,
                    mime="text/csv",
                    key=f"table-{name}",
                )

    with result_tabs[3]:
        if "amrc_report.md" in result["files"] or "amrc_report.html" in result["files"]:
            st.subheader("Report export")
            report_tabs = st.tabs(["Preview", "Downloads"])
            with report_tabs[0]:
                if "amrc_report.html" in result["files"]:
                    st.components.v1.html(
                        result["files"]["amrc_report.html"].decode("utf-8"),
                        height=900,
                        scrolling=True,
                    )
                elif "amrc_report.md" in result["files"]:
                    st.markdown(result["files"]["amrc_report.md"].decode("utf-8"))
            with report_tabs[1]:
                if "amrc_report.md" in result["files"]:
                    st.download_button(
                        label="Download analysis report (.md)",
                        data=result["files"]["amrc_report.md"],
                        file_name="amrc_report.md",
                        mime="text/markdown",
                    )
                if "amrc_report.html" in result["files"]:
                    st.download_button(
                        label="Download analysis report (.html)",
                        data=result["files"]["amrc_report.html"],
                        file_name="amrc_report.html",
                        mime="text/html",
                    )
                if "amrc_report.pdf" in result["files"]:
                    st.download_button(
                        label="Download analysis report (.pdf)",
                        data=result["files"]["amrc_report.pdf"],
                        file_name="amrc_report.pdf",
                        mime="application/pdf",
                    )

        if extra_downloads:
            st.subheader("Download bundles")
            for label, filename, mime in extra_downloads:
                st.download_button(
                    label=label,
                    data=result["files"][filename],
                    file_name=filename,
                    mime=mime,
                    key=f"bundle-{filename}",
                )

    with result_tabs[4]:
        with st.expander("Show raw summary JSON", expanded=False):
            st.json(result["summary"], expanded=True)
