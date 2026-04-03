render_visual_fixture <- function(plot, path, width = 1800, height = 1400) {
  ragg::agg_png(filename = path, width = width, height = height, res = 144, scaling = 1)
  on.exit(grDevices::dev.off(), add = TRUE)
  print(plot)
}

expect_png_snapshot_equal <- function(plot, baseline_name, width = 1800, height = 1400) {
  baseline_path <- testthat::test_path("..", "visual-regression", "baseline", baseline_name)
  expect_true(file.exists(baseline_path), info = paste("Missing baseline:", baseline_name))

  temp_path <- tempfile(fileext = ".png")
  render_visual_fixture(plot, temp_path, width = width, height = height)

  baseline_img <- png::readPNG(baseline_path)
  temp_img <- png::readPNG(temp_path)

  expect_identical(dim(temp_img), dim(baseline_img))
  expect_equal(temp_img, baseline_img, tolerance = 0)
}

test_that("key manuscript plots retain their visual baselines", {
  skip_on_cran()
  skip_if_not_installed("ragg")
  skip_if_not_installed("png")
  skip_if_not_installed("patchwork")

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

  expect_png_snapshot_equal(map_plot, "manuscript_map.png")
  expect_png_snapshot_equal(reference_plot, "manuscript_reference.png")
  expect_png_snapshot_equal(
    panel_plot,
    "manuscript_cluster_story.png",
    width = 2200,
    height = 1800
  )
})
