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
out_dir <- file.path(repo_root, "docs", "manuscript-figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Package 'pkgload' is required to build manuscript figures.", call. = FALSE)
}
if (!requireNamespace("patchwork", quietly = TRUE)) {
  stop("Package 'patchwork' is required to build manuscript figures.", call. = FALSE)
}

pkgload::load_all(repo_root, export_all = FALSE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE)

write_plot <- function(plot, path, width = 8, height = 6) {
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = width,
    height = height,
    dpi = 300
  )
}

build_generic_workflow_figure <- function() {
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
  phenotype_fit <- amrc_map_fit_report(phenotype_map)

  plot_data <- data.frame(
    isolate_id = rownames(phenotype_fit$configuration),
    D1 = phenotype_fit$configuration[, 1],
    D2 = phenotype_fit$configuration[, 2],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  plot_data <- merge(plot_data, mic_data$metadata, by = "isolate_id", all.x = TRUE, sort = FALSE)

  map_plot <- amrc_plot_map(
    data = plot_data,
    x = "D1",
    y = "D2",
    fill_col = "lineage",
    grid_spacing = 1,
    use_cartography_theme = TRUE
  ) + ggplot2::labs(title = "Generic MIC phenotype map")

  residual_table <- phenotype_fit$residual_summary
  residual_table$panel <- "Residual summary"
  residual_plot <- ggplot2::ggplot(
    residual_table,
    ggplot2::aes(x = panel, y = mean_abs_residual)
  ) +
    ggplot2::geom_col(fill = "#377EB8", colour = "black", width = 0.55) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = pmax(mean_abs_residual - sd_abs_residual, 0),
        ymax = mean_abs_residual + sd_abs_residual
      ),
      width = 0.15
    ) +
    amrc_theme_cartography() +
    ggplot2::labs(
      title = "Goodness of fit",
      x = NULL,
      y = "Mean absolute residual"
    )

  amrc_compose_manuscript_side_by_side_panel(
    left_plot = map_plot,
    right_plot = residual_plot
  )
}

build_comparison_figure <- function() {
  mic_raw <- amrc_example_data("mic_raw")
  mic_data <- amrc_standardise_mic_data(
    data = mic_raw,
    id_col = "isolate_id",
    mic_cols = c("drug_a", "drug_b", "drug_c"),
    metadata_cols = c("lineage", "source"),
    transform = "log2"
  )
  phenotype_distance <- amrc_compute_mic_distance(mic_data)
  phenotype_map <- amrc_compute_mds(phenotype_distance)

  external_raw <- amrc_example_data("external_numeric")
  external_std <- amrc_standardise_external_data(
    data = external_raw,
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

  phenotype_plot <- amrc_plot_map(
    comparison_bundle$data,
    x = "D1",
    y = "D2",
    fill_col = "lineage",
    grid_spacing = 1,
    use_cartography_theme = TRUE
  ) + ggplot2::labs(title = "Phenotype map")

  external_plot <- amrc_plot_map(
    comparison_bundle$data,
    x = "E1",
    y = "E2",
    fill_col = "lineage",
    grid_spacing = 1,
    use_cartography_theme = TRUE
  ) + ggplot2::labs(title = "External map")

  reference_table <- amrc_compute_reference_distance_table(
    data = comparison_bundle$data,
    reference_col = "lineage",
    reference_value = "L1",
    phenotype_cols = c("D1", "D2"),
    external_cols = c("E1", "E2"),
    id_col = "isolate_id"
  )
  reference_plot <- amrc_plot_reference_distance_relationship(reference_table) +
    ggplot2::labs(title = "Reference-distance relationship")

  amrc_compose_phenotype_external_reference_panel(
    phenotype_plot = phenotype_plot,
    external_plot = external_plot,
    reference_plot = reference_plot
  )
}

build_cross_species_figure <- function() {
  public_specs <- amrc_public_mic_example_specs()
  datasets <- c(
    "salmonella_enterica_mic",
    "campylobacter_jejuni_mic",
    "acinetobacter_baumannii_mic"
  )

  build_species_plot <- function(dataset_name) {
    spec <- public_specs[public_specs$dataset_name == dataset_name, , drop = FALSE]
    mic_cols <- strsplit(spec$suggested_mic_cols, ",", fixed = TRUE)[[1]]
    data <- amrc_example_data(dataset_name)

    mic_data <- amrc_standardise_mic_data(
      data = data,
      id_col = "ar_bank_id",
      mic_cols = mic_cols,
      metadata_cols = c("species_group", "organism", "source", "biosample_accession"),
      transform = "log2",
      less_than = "numeric",
      greater_than = "numeric"
    )
    phenotype_distance <- amrc_compute_mic_distance(mic_data)
    phenotype_map <- amrc_compute_mds(phenotype_distance, itmax = 100, eps = 1e-06)
    fit_report <- amrc_map_fit_report(phenotype_map)

    plot_data <- data.frame(
      ar_bank_id = rownames(fit_report$configuration),
      D1 = fit_report$configuration[, 1],
      D2 = fit_report$configuration[, 2],
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    plot_data <- merge(plot_data, mic_data$metadata, by = "ar_bank_id", all.x = TRUE, sort = FALSE)

    amrc_plot_map(
      data = plot_data,
      x = "D1",
      y = "D2",
      point_fill = "#377EB8",
      grid_spacing = 1,
      use_cartography_theme = TRUE
    ) + ggplot2::labs(title = spec$species_group[[1]])
  }

  amrc_compose_manuscript_triptych_panel(
    plot_a = build_species_plot(datasets[[1]]),
    plot_b = build_species_plot(datasets[[2]]),
    plot_c = build_species_plot(datasets[[3]])
  )
}

build_spneumoniae_validation_figure <- function() {
  paths <- amrc_spneumoniae_example_paths("mapping_08")
  phenotype_map <- utils::read.csv(paths$phenotype_map, stringsAsFactors = FALSE, check.names = FALSE)
  genotype_map <- utils::read.csv(paths$genotype_map, stringsAsFactors = FALSE, check.names = FALSE)

  phenotype_plot <- amrc_plot_map(
    data = phenotype_map,
    x = "D1",
    y = "D2",
    fill_col = "PT",
    grid_spacing = 1,
    use_cartography_theme = TRUE
  ) + ggplot2::labs(title = expression(italic("S. pneumoniae") ~ "phenotype map"))

  genotype_plot <- amrc_plot_map(
    data = genotype_map,
    x = "G1",
    y = "G2",
    fill_col = "PT",
    grid_spacing = 1,
    use_cartography_theme = TRUE
  ) + ggplot2::labs(title = expression(italic("S. pneumoniae") ~ "genotype map"))

  amrc_compose_manuscript_side_by_side_panel(
    left_plot = phenotype_plot,
    right_plot = genotype_plot
  )
}

plots <- list(
  figure01_generic_workflow = list(plot = build_generic_workflow_figure(), width = 10, height = 5),
  figure02_comparison = list(plot = build_comparison_figure(), width = 10, height = 8),
  figure03_cross_species = list(plot = build_cross_species_figure(), width = 12, height = 4.8),
  figure04_spneumoniae_validation = list(plot = build_spneumoniae_validation_figure(), width = 10, height = 5)
)

for (name in names(plots)) {
  spec <- plots[[name]]
  path <- file.path(out_dir, paste0(name, ".png"))
  write_plot(spec$plot, path = path, width = spec$width, height = spec$height)
  message("Wrote ", path)
}
