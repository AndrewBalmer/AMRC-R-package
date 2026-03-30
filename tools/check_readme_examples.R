library(amrcartography)

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
  metadata_cols = c("country", "lineage"),
  transform = "log2"
)

phenotype_distance <- amrc_compute_mic_distance(mic_data)
phenotype_map <- amrc_compute_mds(phenotype_distance, itmax = 50, eps = 1e-04)
phenotype_report <- amrc_map_fit_report(phenotype_map)

external_distance <- amrc_compute_external_feature_distance(
  data = external_features,
  id_col = "isolate_id"
)
external_map <- amrc_compute_mds(external_distance, itmax = 50, eps = 1e-04)

comparison_bundle <- amrc_prepare_map_data(
  metadata = mic_data$metadata,
  phenotype_mds = phenotype_map,
  external_mds = external_map,
  id_col = "isolate_id",
  group_col = "lineage"
)

reference_distances <- amrc_compute_reference_distance_table(
  data = comparison_bundle$data,
  reference_value = "L1",
  reference_col = "lineage",
  phenotype_distance_col = "phenotype_distance",
  external_distance_col = "external_distance"
)

reference_summary <- amrc_summarise_reference_distance_table(
  distance_table = reference_distances,
  phenotype_distance_col = "phenotype_distance",
  external_distance_col = "external_distance",
  cluster_col = FALSE
)

stopifnot(
  inherits(phenotype_distance, "dist"),
  inherits(external_distance, "dist"),
  nrow(comparison_bundle$data) == 6L,
  nrow(comparison_bundle$group_data) == 3L,
  all(c("residual_summary", "stress_summary") %in% names(phenotype_report)),
  identical(reference_summary$summary$cluster, "Overall")
)

message("README example workflow completed successfully.")
