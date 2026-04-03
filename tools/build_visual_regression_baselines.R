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

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Package 'pkgload' is required to build visual regression baselines.", call. = FALSE)
}
if (!requireNamespace("ragg", quietly = TRUE)) {
  stop("Package 'ragg' is required to build visual regression baselines.", call. = FALSE)
}

pkgload::load_all(repo_root, export_all = TRUE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE)

out_dir <- file.path(repo_root, "tests", "visual-regression", "baseline")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

mic_raw <- amrc_example_data("mic_raw")
mic_data <- amrc_standardise_mic_data(
  data = mic_raw,
  id_col = "isolate_id",
  mic_cols = c("drug_a", "drug_b", "drug_c"),
  metadata_cols = c("lineage", "source"),
  transform = "log2",
  less_than = "numeric",
  greater_than = "numeric"
)
phenotype_distance <- amrc_compute_mic_distance(mic_data)
phenotype_map <- amrc_compute_mds(phenotype_distance)
phenotype_calibration <- amrc_calibrate_mds(phenotype_map)
plot_data <- data.frame(
  isolate_id = rownames(phenotype_calibration$configuration),
  D1 = phenotype_calibration$configuration[, 1],
  D2 = phenotype_calibration$configuration[, 2],
  stringsAsFactors = FALSE,
  check.names = FALSE
)
plot_data <- merge(plot_data, mic_data$metadata, by = "isolate_id", all.x = TRUE, sort = FALSE)

external <- amrc_example_data("external_numeric")
external_std <- amrc_standardise_external_data(
  data = external,
  id_col = "isolate_id",
  feature_cols = c("axis1", "axis2"),
  feature_mode = "numeric"
)
external_distance <- amrc_compute_external_feature_distance(external_std)
external_map <- amrc_compute_mds(external_distance)
comparison_bundle <- amrc_prepare_map_data(
  metadata = mic_data$metadata,
  phenotype_mds = phenotype_map,
  external_mds = external_map,
  id_col = "isolate_id",
  group_col = "lineage"
)

map_plot <- amrc_plot_map(
  data = plot_data,
  x = "D1",
  y = "D2",
  fill_col = "lineage",
  grid_spacing = 1,
  use_cartography_theme = TRUE
)

reference_table <- amrc_compute_reference_distance_table(
  data = comparison_bundle$data,
  reference_col = "lineage",
  reference_value = "L1",
  phenotype_cols = c("D1", "D2"),
  external_cols = c("E1", "E2"),
  id_col = "isolate_id"
)
reference_plot <- amrc_plot_reference_distance_relationship(reference_table)

panel_plot <- amrc_compose_manuscript_cluster_story_panel(
  phenotype_plot = amrc_plot_map(comparison_bundle$data, x = "D1", y = "D2", fill_col = "lineage"),
  external_plot = amrc_plot_map(comparison_bundle$data, x = "E1", y = "E2", fill_col = "lineage"),
  feature_plot = reference_plot
)

plots <- list(
  manuscript_map = list(plot = map_plot, width = 1800, height = 1400),
  manuscript_reference = list(plot = reference_plot, width = 1800, height = 1400),
  manuscript_cluster_story = list(plot = panel_plot, width = 2200, height = 1800)
)

for (name in names(plots)) {
  spec <- plots[[name]]
  path <- file.path(out_dir, paste0(name, ".png"))
  ragg::agg_png(filename = path, width = spec$width, height = spec$height, res = 144, scaling = 1)
  print(spec$plot)
  grDevices::dev.off()
  message("Wrote ", path)
}
