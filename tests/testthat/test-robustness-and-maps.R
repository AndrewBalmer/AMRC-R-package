toy_amrc_table <- function() {
  data.frame(
    Penicillin = c(1, 1, 4, 4, 8, 8),
    Amoxicillin = c(1, 1, 4, 4, 8, 8),
    Meropenem = c(0.25, 0.25, 0.5, 0.5, 1, 1),
    Cefotaxime = c(0.5, 0.5, 1, 1, 2, 2),
    Ceftriaxone = c(0.5, 0.5, 1, 1, 2, 2),
    Cefuroxime = c(0.5, 0.5, 1, 1, 2, 2),
    check.names = FALSE
  )
}

toy_amrc_meta <- function(tablemic = toy_amrc_table()) {
  data.frame(
    LABID = paste0("L", seq_len(nrow(tablemic))),
    PT = paste0("PT", seq_len(nrow(tablemic))),
    Penicillin = tablemic$Penicillin,
    Amoxicillin = tablemic$Amoxicillin,
    Meropenem = tablemic$Meropenem,
    Cefotaxime = tablemic$Cefotaxime,
    Ceftriaxone = tablemic$Ceftriaxone,
    Cefuroxime = tablemic$Cefuroxime,
    check.names = FALSE
  )
}

shift_positive <- function(tablemic) {
  as.data.frame(lapply(tablemic, function(x) x - min(x, na.rm = TRUE) + 1))
}

test_that("amrc_build_spneumoniae_example_maps builds and reloads canonical metric maps", {
  skip_if_not_installed("smacof")

  tablemic <- toy_amrc_table()
  pbp_dist <- stats::dist(tablemic)
  generated_dir <- tempfile("amrc-maps-")
  dir.create(generated_dir, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(
    tablemic,
    file = file.path(generated_dir, "MIC_table_Spneumoniae.csv"),
    row.names = FALSE
  )
  save(pbp_dist, file = amrc_generated_path(generated_dir, "genotype_distance_rdata"))

  first_build <- amrc_build_spneumoniae_example_maps(
    generated_dir = generated_dir,
    overwrite = TRUE,
    mds_args = list(itmax = 50, eps = 1e-04)
  )

  expect_named(first_build$phenotype, "metric")
  expect_named(first_build$genotype, "metric")
  expect_true(file.exists(file.path(generated_dir, "Spneumo_3628_PCA_start_2D_METRIC.RData")))
  expect_true(file.exists(file.path(generated_dir, "Spneumo_3628_PCA_start_2D_METRIC_genetic.RData")))

  second_build <- amrc_build_spneumoniae_example_maps(
    generated_dir = generated_dir,
    overwrite = FALSE
  )

  expect_named(second_build$phenotype, "metric")
  expect_named(second_build$genotype, "metric")
})

test_that("amrc_compare_procrustes_collection handles LABID-labelled references", {
  skip_if_not_installed("smacof")

  tablemic <- toy_amrc_table()
  meta <- toy_amrc_meta(tablemic)
  reference_fit <- amrc_compute_mds(stats::dist(tablemic), itmax = 50, eps = 1e-04)
  reference_configuration <- amrc_reference_configuration(reference_fit, meta$LABID)
  fit_collection <- amrc_run_mds_collection(
    distance_list = rep(list(stats::dist(tablemic)), 2),
    lab_ids = meta$LABID,
    itmax = 50,
    eps = 1e-04
  )

  comparison <- amrc_compare_procrustes_collection(
    reference_configuration = reference_configuration,
    fit_collection = fit_collection,
    lab_ids = meta$LABID
  )

  expect_equal(nrow(comparison$summary), 2L)
  expect_equal(nrow(comparison$pairwise), 2L * nrow(tablemic))
  expect_true(all(c("LABID", "dist_phen") %in% names(comparison$pairwise)))
})

test_that("robustness study helpers return canonical structures on toy data", {
  skip_if_not_installed("smacof")

  tablemic <- toy_amrc_table()
  meta <- toy_amrc_meta(tablemic)
  reference_fit <- amrc_compute_mds(stats::dist(tablemic), itmax = 50, eps = 1e-04)

  missing_study <- amrc_missing_value_study(
    tablemic = tablemic,
    tablemic_meta = meta,
    reference_mds = reference_fit,
    n_samples = 3,
    missing_pct = 15,
    cross_validation_n = 2,
    seed = 1
  )

  expect_length(missing_study$missing_samples, 3L)
  expect_true(all(c("LABID", "drug", "MIC_value", "true_value", "sample_id") %in% names(missing_study$missing_samples[[1]])))
  expect_true(all(c("dimension", "mean_dist_phen", "sd_dist_phen", "se_dist_phen") %in% names(missing_study$cross_validation$dimension_summary)))

  shifted_table <- shift_positive(tablemic)
  shifted_meta <- toy_amrc_meta(shifted_table)
  shifted_reference <- amrc_compute_mds(stats::dist(shifted_table), itmax = 50, eps = 1e-04)

  noise_study <- amrc_noise_added_study(
    tablemic = shifted_table,
    tablemic_meta = shifted_meta,
    reference_mds = shifted_reference,
    n_samples = 3,
    perturb_pct = 20,
    threshold_value = 1,
    cross_validation_n = 2,
    seed = 1
  )

  expect_length(noise_study$noise, 3L)
  expect_true(all(c("LABID", "drug", "error_added", "true_value", "noise_added_value", "sample_id") %in% names(noise_study$noise[[1]])))
  expect_equal(nrow(noise_study$cross_validation$dimension_summary), 4L)

  disc_study <- amrc_disc_diffusion_study(
    tablemic = tablemic,
    tablemic_meta = meta,
    reference_mds = reference_fit,
    n_samples = 3,
    disc_pct = 50,
    cross_validation_n = 2,
    seed = 1
  )

  expect_length(disc_study$bootstrap_samples, 3L)
  expect_true(all(c("LABID", "drug", "MIC_value", "true_value", "sample_id") %in% names(disc_study$bootstrap_samples_values[[1]])))
  expect_equal(nrow(disc_study$cross_validation$dimension_summary), 4L)

  threshold_study <- amrc_threshold_effect_study(
    tablemic = shifted_table,
    tablemic_meta = shifted_meta,
    reference_mds = shifted_reference,
    threshold_value = 1,
    weighted_repeats = 2,
    seed = 1
  )

  expect_true(all(c(
    "exclude_all_thresholds",
    "exclude_two_thresholds",
    "ordinal_fit",
    "weighted_metric_fit",
    "weighted_ordinal_fit",
    "metric_weight_comparison"
  ) %in% names(threshold_study)))
  expect_s3_class(threshold_study$metric_weight_comparison$summary, "data.frame")
})

test_that("comparison and clustering helpers return reusable canonical tables", {
  skip_if_not_installed("smacof")

  tablemic <- toy_amrc_table()
  meta <- toy_amrc_meta(tablemic)
  rownames(tablemic) <- meta$LABID
  phenotype_fit <- amrc_compute_mds(stats::dist(tablemic), itmax = 50, eps = 1e-04)
  genotype_fit <- amrc_compute_mds(stats::dist(tablemic), itmax = 50, eps = 1e-04)

  comparison_bundle <- amrc_prepare_spneumoniae_map_data(
    tablemic_meta = meta,
    phenotype_mds = phenotype_fit,
    genotype_mds = genotype_fit,
    exclude_labids = character()
  )

  expect_true(all(c("D1", "D2", "G1", "G2", "PBP_type", "x_centroid", "y_centroid") %in% names(comparison_bundle$data)))
  expect_equal(nrow(comparison_bundle$pbp_data), nrow(meta))

  cluster_fit <- amrc_cluster_map(
    data = comparison_bundle$pbp_data,
    coord_cols = c("G1", "G2"),
    n_clusters = 3,
    distinct_col = "PBP_type",
    max_k = 4
  )

  expect_true(all(c("PBP_type", "cluster") %in% names(cluster_fit$assignments)))
  expect_equal(nrow(cluster_fit$scree), 4L)

  clustered <- amrc_add_cluster_assignments(
    data = comparison_bundle$data,
    assignments = cluster_fit$assignments,
    key_col = "PBP_type",
    cluster_col = "gen_cluster"
  )
  separation <- amrc_summarise_cluster_separation(
    data = clustered,
    coord_cols = c("D1", "D2"),
    cluster_col = "gen_cluster"
  )

  expect_true(all(c("DistanceType", "Distance") %in% names(separation$hist_data)))

  ref_distance <- amrc_compute_reference_distance_table(
    data = clustered,
    reference_pbp_type = clustered$PBP_type[[1]],
    cluster_col = "gen_cluster"
  )
  ref_summary <- amrc_summarise_reference_distance_table(
    distance_table = ref_distance,
    cluster_col = "gen_cluster"
  )

  expect_true(all(c("phen_distance", "gen_distance") %in% names(ref_distance)))
  expect_true(all(c("cluster", "mean_phenotypic_distance", "mean_external_distance") %in% names(ref_summary$summary)))
})

test_that("plotting helpers accept numeric cluster identifiers", {
  skip_if_not_installed("ggplot2")

  plot_data <- data.frame(
    x = c(0, 1, 2, 3),
    y = c(0, 1, 0, 1),
    cluster = c(1, 1, 2, 2)
  )

  cluster_plot <- amrc_plot_cluster_map(
    data = plot_data,
    x = "x",
    y = "y",
    cluster_col = "cluster",
    show_legend = TRUE
  )
  expect_s3_class(cluster_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(cluster_plot))

  distance_plot <- amrc_plot_reference_distance_relationship(
    distance_table = data.frame(
      gen_distance = c(1, 2, 3, 4),
      phen_distance = c(2, 3, 4, 5),
      gen_cluster = c(1, 1, 2, 2)
    ),
    cluster_col = "gen_cluster"
  )
  expect_s3_class(distance_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(distance_plot))
})

test_that("dimension-comparison helpers preserve configurable identifier columns", {
  skip_if_not_installed("smacof")

  tablemic <- toy_amrc_table()
  ids <- paste0("iso", seq_len(nrow(tablemic)))
  rownames(tablemic) <- ids

  fit_2d <- amrc_compute_mds(stats::dist(tablemic), ndim = 2, itmax = 50, eps = 1e-04)
  fit_3d <- amrc_compute_mds(stats::dist(tablemic), ndim = 3, itmax = 50, eps = 1e-04)

  adjacent <- amrc_compare_adjacent_dimensions(
    mds_fits = list("2" = fit_2d, "3" = fit_3d),
    lab_ids = ids,
    compare_dims = 3,
    id_col = "isolate_id"
  )

  one_vs_two <- amrc_compare_one_and_two_dimensional_maps(
    one_dim_fit = amrc_compute_mds(stats::dist(tablemic), ndim = 1, itmax = 50, eps = 1e-04),
    two_dim_fit = fit_2d,
    lab_ids = ids,
    id_col = "isolate_id"
  )

  expect_true("isolate_id" %in% names(adjacent$projection_distances))
  expect_true("isolate_id" %in% names(one_vs_two$comparison))
})
