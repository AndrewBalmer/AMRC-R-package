from __future__ import annotations

import io
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import pandas as pd
import streamlit as st


REPO_ROOT = Path(__file__).resolve().parents[1]
BACKEND = REPO_ROOT / "streamlit_app" / "amrc_streamlit_backend.R"


def read_uploaded_csv(uploaded_file) -> pd.DataFrame | None:
    if uploaded_file is None:
        return None
    return pd.read_csv(io.BytesIO(uploaded_file.getvalue()))


def none_option(label: str = "(none)") -> str:
    return label


def maybe_none(value: str | None) -> str | None:
    if value in (None, "", "(none)"):
        return None
    return value


def save_uploaded_file(uploaded_file, target: Path) -> None:
    target.write_bytes(uploaded_file.getvalue())


def build_config(
    phenotype_upload,
    phenotype_df: pd.DataFrame,
    external_upload,
    external_df: pd.DataFrame | None,
    work_dir: Path,
) -> dict:
    phenotype_path = work_dir / "phenotype.csv"
    save_uploaded_file(phenotype_upload, phenotype_path)

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
        },
        "comparison": {
            "group_col": maybe_none(st.session_state.get("group_col")),
        },
        "external": {
            "enabled": bool(st.session_state["use_external"]),
        },
    }

    if st.session_state["use_external"]:
        external_path = work_dir / "external.csv"
        save_uploaded_file(external_upload, external_path)
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

    completed = subprocess.run(
        ["Rscript", str(BACKEND), str(config_path)],
        capture_output=True,
        text=True,
        cwd=str(REPO_ROOT),
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

    for name in ("phenotype_map.png", "external_map.png", "side_by_side_maps.png"):
        path = work_dir / name
        if path.exists():
            result["files"][name] = path.read_bytes()

    for name in ("phenotype_map_data.csv", "comparison_data.csv"):
        path = work_dir / name
        if path.exists():
            result["tables"][name] = pd.read_csv(path)
            result["files"][name] = path.read_bytes()

    return result


st.set_page_config(page_title="amrcartography", layout="wide")
st.title("amrcartography")
st.caption(
    "Experimental Streamlit front end for the generic phenotype/external workflow. "
    "The R package remains the primary supported interface."
)

with st.sidebar:
    st.header("Phenotype Input")
    phenotype_upload = st.file_uploader("Phenotype MIC CSV", type=["csv"])

phenotype_df = read_uploaded_csv(phenotype_upload)

if phenotype_df is not None:
    columns = phenotype_df.columns.tolist()

    with st.sidebar:
        st.selectbox(
            "Phenotype ID column",
            options=columns,
            key="phenotype_id_col",
        )

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
        st.checkbox("Use 1-unit grid spacing", value=False, key="grid_spacing_one")
        st.checkbox("Add density contours", value=False, key="density")

        st.header("External Structure")
        st.checkbox("Include external/genotype structure", value=False, key="use_external")

    if st.session_state["use_external"]:
        with st.sidebar:
            external_upload = st.file_uploader("External CSV", type=["csv"])
        external_df = read_uploaded_csv(external_upload)

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
        else:
            external_upload = None
    else:
        external_upload = None
        external_df = None

    left, right = st.columns((1.1, 1))

    with left:
        st.subheader("Input Preview")
        st.dataframe(phenotype_df.head(10), use_container_width=True)
        if external_df is not None:
            st.subheader("External Preview")
            st.dataframe(external_df.head(10), use_container_width=True)

    with right:
        st.subheader("Run")
        st.markdown(
            "- Requires `Rscript` plus the package dependencies available in the local environment.\n"
            "- This v1 app focuses on the stable generic map workflow, not the full mixed-model layer."
        )

        can_run = bool(st.session_state.get("mic_cols"))
        if st.session_state["use_external"]:
            can_run = can_run and external_upload is not None

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
    st.json(result["summary"], expanded=True)

    image_cols = st.columns(2)
    if "phenotype_map.png" in result["files"]:
        image_cols[0].image(result["files"]["phenotype_map.png"], caption="Phenotype map")
    if "external_map.png" in result["files"]:
        image_cols[1].image(result["files"]["external_map.png"], caption="External map")

    if "side_by_side_maps.png" in result["files"]:
        st.image(result["files"]["side_by_side_maps.png"], caption="Side-by-side phenotype vs external maps")

    if result["tables"]:
        st.subheader("Output Tables")
        for name, table in result["tables"].items():
            st.markdown(f"**{name}**")
            st.dataframe(table.head(50), use_container_width=True)
            st.download_button(
                label=f"Download {name}",
                data=result["files"][name],
                file_name=name,
                mime="text/csv",
            )
