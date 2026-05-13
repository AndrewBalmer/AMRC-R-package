`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

full_args <- commandArgs(trailingOnly = FALSE)
script_flag <- "--file="
script_path <- sub(script_flag, "", full_args[grep(script_flag, full_args)])

if (length(script_path) == 0L) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

repo_root <- normalizePath(file.path(dirname(script_path[[1]]), ".."), mustWork = TRUE)
out_dir <- file.path(repo_root, "docs", "manuscript-tables")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Package 'pkgload' is required to build manuscript tables.", call. = FALSE)
}

pkgload::load_all(repo_root, export_all = FALSE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE)

write_table <- function(x, name) {
  path <- file.path(out_dir, paste0(name, ".csv"))
  utils::write.csv(x, path, row.names = FALSE, na = "")
  message("Wrote ", path)
}

count_rows <- function(path) {
  if (!file.exists(path)) {
    return(NA_integer_)
  }
  nrow(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
}

count_cols <- function(path) {
  if (!file.exists(path)) {
    return(NA_integer_)
  }
  ncol(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
}

workflow_components <- data.frame(
  workflow_stage = c(
    "MIC ingestion and cleaning",
    "Phenotype distance construction",
    "Map fitting and calibration",
    "External/genotype structure",
    "Map comparison and summaries",
    "Manuscript-style plotting",
    "Validation and reproducibility",
    "Interactive prototype"
  ),
  representative_functions = c(
    "amrc_validate_mic_data(); amrc_clean_mic_values(); amrc_standardise_mic_data()",
    "amrc_compute_mic_distance(); amrc_distance_bundle()",
    "amrc_compute_mds(); amrc_map_fit_report(); amrc_fit_distance_calibration(); amrc_calibrate_mds()",
    "amrc_standardise_external_data(); amrc_compute_external_distance(); amrc_compute_hamming_distance(); amrc_compute_sequence_distance()",
    "amrc_prepare_map_data(); amrc_compute_reference_distance_table(); amrc_compute_group_distance_summary()",
    "amrc_plot_map(); amrc_plot_side_by_side_maps(); amrc_compose_phenotype_external_reference_panel()",
    "tools/run_validation.R; streamlit_app/check_ui_contract.py; streamlit_app/run_browser_qa.py",
    "streamlit_app/app.py; streamlit_app/amrc_streamlit_backend.R"
  ),
  output_or_role = c(
    "Cleaned MIC matrix and aligned metadata",
    "Pairwise isolate phenotype distances",
    "Low-dimensional map coordinates, stress summaries, residual summaries, calibration parameters",
    "External distance matrices or fitted external maps aligned to phenotype isolates",
    "Joined phenotype/external map tables, group centroids, reference-distance summaries",
    "Reusable ggplot/patchwork figures with thesis/manuscript visual defaults",
    "Stage-aware checks for schemas, bundled data, generated artefacts, reports, and app contracts",
    "Phenotype-first app exposing the core workflow and lightweight reporting"
  ),
  manuscript_claim_supported = c(
    "Generic raw MIC input rather than species-specific notebooks",
    "Multivariate phenotype representation",
    "MIC-style interpretability through model-based calibration",
    "Comparison with genotype, feature, sequence, or precomputed-distance structure",
    "Interpretable summaries linking maps to metadata and reference groups",
    "Visual consistency between package, app, thesis, and manuscript outputs",
    "Reusable validation instead of one-off manual checks",
    "Accessible exploratory interface without making the app the primary scientific product"
  ),
  stringsAsFactors = FALSE
)

public_specs <- amrc_public_mic_example_specs()
public_examples <- data.frame(
  dataset = public_specs$dataset_name,
  organism_or_scope = public_specs$species_group,
  input_type = "Public MIC subset",
  n_isolates = public_specs$n_isolates,
  n_mic_columns = vapply(
    strsplit(public_specs$suggested_mic_cols, ",", fixed = TRUE),
    length,
    integer(1)
  ),
  source = public_specs$source_collection,
  source_or_note = public_specs$panel_url,
  stringsAsFactors = FALSE
)

generic_path <- amrc_example_data_paths("mic_raw")$mic_raw
spn_paths <- amrc_spneumoniae_example_paths("mapping_08")
suis_paths <- amrc_suis_example_paths()

example_datasets <- rbind(
  data.frame(
    dataset = "generic_mic_raw",
    organism_or_scope = "Synthetic generic fixture",
    input_type = "Bundled package fixture",
    n_isolates = count_rows(generic_path),
    n_mic_columns = 3L,
    source = "Package fixture",
    source_or_note = "Small deterministic example for vignettes, tests, and app smoke checks",
    stringsAsFactors = FALSE
  ),
  public_examples,
  data.frame(
    dataset = "spneumoniae_mapping_08",
    organism_or_scope = "Streptococcus pneumoniae",
    input_type = "Packaged retained case-study bundle",
    n_isolates = count_rows(spn_paths$mic_metadata),
    n_mic_columns = 6L,
    source = "Retained AMR cartography validation bundle linked to Li et al. 2017",
    source_or_note = "Used as provenance and regression validation for the original cartography workflow; DOI 10.1186/s12864-017-4017-7",
    stringsAsFactors = FALSE
  ),
  data.frame(
    dataset = "suis_demo",
    organism_or_scope = "Streptococcus suis",
    input_type = "Packaged large app/demo bundle",
    n_isolates = count_rows(suis_paths$phenotype_raw),
    n_mic_columns = 4L,
    source = "S. suis cartography-derived demonstration bundle linked to Hadjirin et al. 2021",
    source_or_note = "Large non-pneumococcal integration example with raw MICs, metadata and external PBP structure; DOI 10.1186/s12915-021-01094-1",
    stringsAsFactors = FALSE
  )
)

validation_gates <- data.frame(
  validation_layer = c(
    "R package tests",
    "Staged repository smoke validation",
    "README/vignette examples",
    "Manuscript figure build",
    "Streamlit backend contract",
    "Browser-level app QA",
    "GitHub Actions release gate"
  ),
  command_or_location = c(
    "testthat::test_local()",
    "Rscript tools/run_validation.R --stage smoke",
    "Rscript tools/check_readme_examples.R; Rscript tools/render_vignettes.R",
    "Rscript tools/build_manuscript_figures.R",
    "python3 streamlit_app/check_ui_contract.py",
    "python3 streamlit_app/run_browser_qa.py --include-case-studies",
    "R-CMD-check workflow on Ubuntu release/devel plus docs-sanity"
  ),
  checks_emphasised = c(
    "Function behaviour, error paths, helper contracts",
    "Bundled data manifests, source artefacts, app backend smoke path",
    "User-facing code remains executable",
    "Static figure assets regenerate from package-backed code",
    "App shell and backend configuration contract",
    "Phenotype-only, phenotype-plus-genotype, S. pneumoniae, S. suis, reports, zip bundle",
    "Installed-package and source-checkout validation on Linux"
  ),
  release_status = c(
    "Used during development",
    "Passed locally before v0.2.1",
    "Passed locally before v0.2.1",
    "Passed locally before v0.2.1",
    "Passed locally before v0.2.1",
    "Passed locally before v0.2.1",
    "Passed for v0.2.1 tag head"
  ),
  stringsAsFactors = FALSE
)

write_table(workflow_components, "table01_workflow_components")
write_table(example_datasets, "table02_example_datasets")
write_table(validation_gates, "table03_validation_gates")
