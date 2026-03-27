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
  save(pbp_dist, file = file.path(generated_dir, "tablemic_pneumo_3628_meta_gen_distance_matrix.RData"))

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
