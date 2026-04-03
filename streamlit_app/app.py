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
            "phenotype_rotation_degrees": maybe_number(st.session_state.get("phenotype_rotation_degrees")),
            "external_rotation_degrees": maybe_number(st.session_state.get("external_rotation_degrees")),
        },
        "comparison": {
            "group_col": maybe_none(st.session_state.get("group_col")),
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
        env={**os.environ, "AMRC_PACKAGE_LOAD_MODE": "source"},
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
        "amrc_result_bundle.rds",
    ):
        path = work_dir / name
        if path.exists():
            result["files"][name] = path.read_bytes()

    for name in (
        "phenotype_map_data.csv",
        "phenotype_cluster_data.csv",
        "phenotype_cluster_scree.csv",
        "comparison_data.csv",
        "external_cluster_data.csv",
        "external_cluster_scree.csv",
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
    }
    [data-testid="stSidebar"] {
        background-color: #fafafa;
        border-right: 1px solid #dddddd;
    }
    h1, h2, h3 {
        letter-spacing: 0.01em;
    }
    h2, h3 {
        color: #202020;
    }
    div.stButton > button[kind="primary"] {
        background-color: #E41A1C;
        color: white;
        border: 1px solid black;
    }
    div.stButton > button[kind="primary"]:hover {
        background-color: #C91A14;
        color: white;
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
        st.checkbox(
            "Use 1-unit grid spacing",
            value=False,
            key="grid_spacing_one",
            help="Use this after calibration if you want one doubling dilution per grid interval.",
        )
        st.checkbox("Add density contours", value=False, key="density")
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
        st.dataframe(phenotype_df.head(10), use_container_width=True)
        if external_df is not None:
            st.subheader("External Preview")
            st.dataframe(external_df.head(10), use_container_width=True)

    with right:
        st.subheader("Run")
        st.markdown(
            "- Requires `Rscript` plus the package dependencies available in the local environment.\n"
            "- This v1 app focuses on the stable generic map workflow, not the full mixed-model layer.\n"
            "- Map scaling to 1-MIC-style units comes from the package calibration model; the app exposes rotation controls but not a free-form dilation slider."
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

    if "reference_distance_relationship.png" in result["files"]:
        st.subheader("Reference-distance relationship")
        st.image(
            result["files"]["reference_distance_relationship.png"],
            caption="Phenotype vs external distance from the selected reference",
        )

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

    if "amrc_report.md" in result["files"] or "amrc_report.html" in result["files"]:
        st.subheader("Report export")
        report_tabs = st.tabs(["Preview", "Downloads"])
        with report_tabs[0]:
            if "amrc_report.md" in result["files"]:
                st.markdown(result["files"]["amrc_report.md"].decode("utf-8"))
            elif "amrc_report.html" in result["files"]:
                st.components.v1.html(
                    result["files"]["amrc_report.html"].decode("utf-8"),
                    height=500,
                    scrolling=True,
                )
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

    extra_downloads = []
    if "summary.json" in result["files"]:
        extra_downloads.append(("Download summary.json", "summary.json", "application/json"))
    if "amrc_result_bundle.rds" in result["files"]:
        extra_downloads.append(("Download result bundle (.rds)", "amrc_result_bundle.rds", "application/octet-stream"))
    if "amrc_report.md" in result["files"]:
        extra_downloads.append(("Download report (.md)", "amrc_report.md", "text/markdown"))
    if "amrc_report.html" in result["files"]:
        extra_downloads.append(("Download report (.html)", "amrc_report.html", "text/html"))

    if extra_downloads:
        st.subheader("Download bundles")
        for label, filename, mime in extra_downloads:
            st.download_button(
                label=label,
                data=result["files"][filename],
                file_name=filename,
                mime=mime,
            )
