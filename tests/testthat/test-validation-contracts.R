validation_manifest_path <- function() {
  installed <- system.file(
    "extdata",
    "validation",
    "expected_metrics.json",
    package = "amrcartography"
  )
  if (nzchar(installed)) {
    return(installed)
  }

  testthat::test_path("..", "..", "inst", "extdata", "validation", "expected_metrics.json")
}

test_that("validation metrics manifest matches bundled generic example datasets", {
  skip_if_not_installed("jsonlite")

  manifest <- jsonlite::read_json(
    validation_manifest_path(),
    simplifyVector = TRUE
  )

  mic_raw <- amrc_example_data("mic_raw")
  ext_numeric <- amrc_example_data("external_numeric")
  ext_character <- amrc_example_data("external_character")
  ext_distance <- amrc_example_data("external_distance")

  expect_equal(nrow(mic_raw), manifest$generic_examples$mic_raw$rows)
  expect_true(all(manifest$generic_examples$mic_raw$required_columns %in% colnames(mic_raw)))
  expect_identical(anyDuplicated(mic_raw$isolate_id), 0L)

  expect_equal(nrow(ext_numeric), manifest$generic_examples$external_numeric$rows)
  expect_true(all(manifest$generic_examples$external_numeric$required_columns %in% colnames(ext_numeric)))
  expect_identical(anyDuplicated(ext_numeric$isolate_id), 0L)

  expect_equal(nrow(ext_character), manifest$generic_examples$external_character$rows)
  expect_true(all(manifest$generic_examples$external_character$required_columns %in% colnames(ext_character)))
  expect_identical(anyDuplicated(ext_character$isolate_id), 0L)

  expect_equal(nrow(ext_distance), manifest$generic_examples$external_distance$rows)
  expect_equal(ncol(ext_distance), manifest$generic_examples$external_distance$cols)
  expect_equal(ext_distance, t(ext_distance))
  expect_equal(unname(diag(ext_distance)), rep(0, nrow(ext_distance)))
})

test_that("validation metrics manifest matches packaged mapping_08 bundle counts", {
  skip_if_not_installed("jsonlite")

  manifest <- jsonlite::read_json(
    validation_manifest_path(),
    simplifyVector = TRUE
  )

  paths <- amrc_spneumoniae_example_paths("mapping_08")

  phenotype_meta <- utils::read.csv(
    paths$mic_metadata,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
  phenotype_map <- utils::read.csv(
    paths$phenotype_map,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
  genotype_map <- utils::read.csv(
    paths$genotype_map,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
  bundle <- readRDS(paths$map_bundle)

  expect_equal(nrow(phenotype_meta), manifest$spneumoniae_08$phenotype_metadata_rows)
  expect_equal(nrow(phenotype_map), manifest$spneumoniae_08$phenotype_map_rows)
  expect_equal(nrow(genotype_map), manifest$spneumoniae_08$genotype_map_rows)

  expect_true(all(manifest$spneumoniae_08$phenotype_metadata_required_columns %in% colnames(phenotype_meta)))
  expect_true(all(manifest$spneumoniae_08$phenotype_map_required_columns %in% colnames(phenotype_map)))
  expect_true(all(manifest$spneumoniae_08$genotype_map_required_columns %in% colnames(genotype_map)))

  expect_identical(anyDuplicated(phenotype_meta$LABID), 0L)
  expect_identical(anyDuplicated(phenotype_map$LABID), 0L)
  expect_identical(anyDuplicated(genotype_map$LABID), 0L)
  expect_true(setequal(phenotype_meta$LABID, phenotype_map$LABID))
  expect_true(all(genotype_map$LABID %in% phenotype_meta$LABID))

  phenotype_only_ids <- setdiff(phenotype_meta$LABID, genotype_map$LABID)
  expect_length(phenotype_only_ids, manifest$spneumoniae_08$phenotype_minus_genotype_rows)
  expect_true(all(phenotype_only_ids %in% bundle$deleted_labids))
  expect_length(bundle$deleted_labids, manifest$spneumoniae_08$deleted_labids_bundle_count)
})

test_that("validation metrics manifest matches packaged S. suis demo bundle counts", {
  skip_if_not_installed("jsonlite")

  manifest <- jsonlite::read_json(
    validation_manifest_path(),
    simplifyVector = TRUE
  )

  paths <- amrc_suis_example_paths()

  phenotype <- utils::read.csv(
    paths$phenotype,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
  metadata <- utils::read.csv(
    paths$metadata,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
  distance <- utils::read.csv(
    paths$pbp_distance,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )

  expect_equal(nrow(phenotype), manifest$suis_demo$phenotype_rows)
  expect_equal(nrow(metadata), manifest$suis_demo$metadata_rows)
  expect_equal(nrow(distance), manifest$suis_demo$distance_rows)
  expect_equal(ncol(distance) - 1L, manifest$suis_demo$distance_cols)

  expect_true(all(manifest$suis_demo$phenotype_required_columns %in% colnames(phenotype)))
  expect_true(all(manifest$suis_demo$metadata_required_columns %in% colnames(metadata)))
  expect_true("LABID" %in% colnames(distance))

  expect_identical(anyDuplicated(phenotype$LABID), 0L)
  expect_identical(anyDuplicated(metadata$LABID), 0L)
  expect_identical(anyDuplicated(distance$LABID), 0L)
  expect_true(setequal(distance$LABID, colnames(distance)[colnames(distance) != "LABID"]))
  expect_true(all(phenotype$LABID %in% distance$LABID))
  expect_true(all(phenotype$LABID %in% metadata$LABID))
})

test_that("validation metrics manifest matches packaged public MIC examples", {
  skip_if_not_installed("jsonlite")

  manifest <- jsonlite::read_json(
    validation_manifest_path(),
    simplifyVector = TRUE
  )

  public_manifest <- amrc_public_mic_example_specs()
  expect_equal(
    nrow(public_manifest),
    manifest$public_mic_examples$public_mic_manifest$rows
  )
  expect_true(all(
    manifest$public_mic_examples$public_mic_manifest$required_columns %in% colnames(public_manifest)
  ))

  for (name in as.character(public_manifest$dataset_name)) {
    data <- amrc_example_data(name)
    expect_equal(nrow(data), manifest$public_mic_examples[[name]]$rows)
    expect_true(all(manifest$public_mic_examples[[name]]$required_columns %in% colnames(data)))
    expect_identical(anyDuplicated(data$ar_bank_id), 0L)

    suggested_cols <- strsplit(
      public_manifest$suggested_mic_cols[public_manifest$dataset_name == name],
      ",",
      fixed = TRUE
    )[[1]]
    expect_true(all(suggested_cols %in% colnames(data)))
  }
})

test_that("streamlit validation contract remains lightweight and internally consistent", {
  skip_if_not_installed("jsonlite")

  manifest <- jsonlite::read_json(
    validation_manifest_path(),
    simplifyVector = TRUE
  )

  required_files <- manifest$streamlit_smoke$required_files
  expect_identical(anyDuplicated(required_files), 0L)
  expect_true(all(c(
    "summary.json",
    "amrc_report.md",
    "amrc_report.html",
    "amrc_report.pdf",
    "amrc_output_bundle.zip",
    "amrc_result_bundle.rds",
    "phenotype_fit_metrics.csv",
    "phenotype_residual_summary.csv",
    "phenotype_stress_summary.csv",
    "phenotype_fit_distances.csv",
    "phenotype_cluster_elbow.png",
    "external_fit_metrics.csv",
    "external_residual_summary.csv",
    "external_stress_summary.csv",
    "external_fit_distances.csv",
    "external_cluster_elbow.png",
    "reference_distance_summary.csv"
  ) %in% required_files))
  expect_gte(manifest$streamlit_smoke$reference_rows_min, 1)
})
