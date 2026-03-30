test_that("generic vignette-style workflow runs on small synthetic data", {
  skip_on_os("mac")
  skip_if_not_installed("smacof")

  mic_table <- data.frame(
    isolate_id = paste0("iso", 1:6),
    lineage = c("L1", "L1", "L2", "L2", "L3", "L3"),
    country = c("UK", "UK", "KE", "KE", "BR", "BR"),
    drug_a = c(0.5, 1, 2, 2, 4, 8),
    drug_b = c(1, 1, 2, 4, 4, 8),
    drug_c = c(0.25, 0.5, 1, 2, 4, 4),
    stringsAsFactors = FALSE
  )

  external_features <- data.frame(
    isolate_id = c("iso3", "iso1", "iso2", "iso4", "iso6", "iso5"),
    axis1 = c(0.0, 0.1, 0.3, 1.2, 2.2, 2.0),
    axis2 = c(0.0, 0.2, 0.1, 1.0, 2.1, 1.8),
    stringsAsFactors = FALSE
  )

  mic_data <- amrc_standardise_mic_data(
    data = mic_table,
    id_col = "isolate_id",
    mic_cols = c("drug_a", "drug_b", "drug_c"),
    metadata_cols = c("lineage", "country"),
    transform = "log2"
  )

  phenotype_distance <- amrc_compute_mic_distance(mic_data)
  external_distance <- amrc_compute_external_feature_distance(
    data = external_features,
    id_col = "isolate_id"
  )

  phenotype_map <- amrc_compute_mds(phenotype_distance, itmax = 50, eps = 1e-04)
  external_map <- amrc_compute_mds(external_distance, itmax = 50, eps = 1e-04)

  comparison_bundle <- amrc_prepare_map_data(
    metadata = mic_data$metadata,
    phenotype_mds = phenotype_map,
    external_mds = external_map,
    id_col = "isolate_id",
    group_col = "lineage"
  )

  cluster_fit <- amrc_cluster_map(
    data = comparison_bundle$group_data,
    coord_cols = c("E1", "E2"),
    distinct_col = "lineage",
    n_clusters = 2,
    max_k = 3
  )

  comparison_data <- amrc_add_cluster_assignments(
    data = comparison_bundle$data,
    assignments = cluster_fit$assignments,
    key_col = "lineage",
    cluster_col = "external_cluster"
  )

  reference_distances <- amrc_compute_reference_distance_table(
    data = comparison_data,
    reference_value = "L1",
    reference_col = "lineage",
    id_col = "isolate_id",
    cluster_col = "external_cluster",
    phenotype_distance_col = "phenotype_distance",
    external_distance_col = "external_distance"
  )

  reference_summary <- amrc_summarise_reference_distance_table(
    distance_table = reference_distances,
    cluster_col = "external_cluster",
    phenotype_distance_col = "phenotype_distance",
    external_distance_col = "external_distance"
  )

  expect_equal(nrow(comparison_bundle$data), 6L)
  expect_equal(nrow(comparison_bundle$group_data), 3L)
  expect_true(all(c("phenotype_distance", "external_distance") %in% names(reference_distances)))
  expect_true(all(c("mean_phenotypic_distance", "mean_external_distance") %in% names(reference_summary$summary)))
})
