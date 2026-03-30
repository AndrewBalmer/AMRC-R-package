generic_mic_fixture <- function() {
  data.frame(
    isolate_id = c("iso1", "iso2", "iso3", "iso4"),
    host = c("human", "human", "mouse", "mouse"),
    lineage = c("L1", "L1", "L2", "L3"),
    drug_a = c("1", "2", "4", "8"),
    drug_b = c("0.5", "1", "", "4"),
    drug_c = c(2, 4, 8, 16),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

test_that("generic MIC validation checks schema and duplicate isolate IDs", {
  toy <- generic_mic_fixture()

  validation <- amrc_validate_mic_data(
    data = toy,
    id_col = "isolate_id",
    mic_cols = c("drug_a", "drug_b", "drug_c"),
    metadata_cols = c("host", "lineage")
  )

  expect_equal(validation$id_col, "isolate_id")
  expect_equal(validation$mic_cols, c("drug_a", "drug_b", "drug_c"))
  expect_equal(validation$metadata_cols, c("isolate_id", "host", "lineage"))
  expect_false(validation$has_complete_mic)

  toy_dup <- toy
  toy_dup$isolate_id[4] <- "iso1"

  expect_error(
    amrc_validate_mic_data(
      data = toy_dup,
      id_col = "isolate_id",
      mic_cols = c("drug_a", "drug_b", "drug_c")
    ),
    "duplicate"
  )
})

test_that("generic MIC extraction and standardisation work on arbitrary datasets", {
  toy <- generic_mic_fixture()

  mic <- amrc_extract_mic_matrix(
    data = toy,
    mic_cols = c("drug_a", "drug_b", "drug_c"),
    transform = "log2"
  )

  expect_equal(unname(as.numeric(mic$drug_a)), c(0, 1, 2, 3))
  expect_equal(unname(as.numeric(mic$drug_b))[1:2], c(-1, 0))

  standardised <- amrc_standardise_mic_data(
    data = toy,
    id_col = "isolate_id",
    mic_cols = c("drug_a", "drug_b", "drug_c"),
    metadata_cols = c("host", "lineage"),
    transform = "log2",
    drop_incomplete = TRUE
  )

  expect_s3_class(standardised, "amrc_mic_data")
  expect_equal(standardised$isolate_ids, c("iso1", "iso2", "iso4"))
  expect_equal(standardised$excluded_rows, 3)
  expect_equal(colnames(standardised$mic), c("drug_a", "drug_b", "drug_c"))
  expect_equal(colnames(standardised$metadata), c("isolate_id", "host", "lineage"))
  expect_equal(rownames(standardised$mic), c("iso1", "iso2", "iso4"))
})

test_that("generic MIC preprocessing rejects non-numeric MIC entries", {
  toy <- generic_mic_fixture()
  toy$drug_c[2] <- "not-a-number"

  expect_error(
    amrc_extract_mic_matrix(
      data = toy,
      mic_cols = c("drug_a", "drug_b", "drug_c")
    ),
    "could not be coerced to numeric"
  )
})

test_that("generic MIC and external distance helpers preserve isolate ordering", {
  toy <- generic_mic_fixture()

  standardised <- amrc_standardise_mic_data(
    data = toy,
    id_col = "isolate_id",
    mic_cols = c("drug_a", "drug_b", "drug_c"),
    metadata_cols = c("host", "lineage"),
    transform = "log2",
    drop_incomplete = TRUE
  )

  phenotype_distance <- amrc_compute_mic_distance(standardised)
  expect_s3_class(phenotype_distance, "dist")
  expect_equal(attr(phenotype_distance, "Labels"), c("iso1", "iso2", "iso4"))

  external_matrix <- matrix(
    c(
      0, 1, 2,
      1, 0, 3,
      2, 3, 0
    ),
    nrow = 3,
    byrow = TRUE
  )

  external_distance <- amrc_compute_external_distance(
    external_matrix,
    isolate_ids = c("iso2", "iso1", "iso4")
  )
  subset_external <- amrc_subset_distance(
    external_distance,
    isolate_ids = c("iso1", "iso4")
  )

  expect_equal(attr(subset_external, "Labels"), c("iso1", "iso4"))

  bundle <- amrc_distance_bundle(
    phenotype_distance = phenotype_distance,
    isolate_ids = c("iso1", "iso2", "iso4"),
    external_distance = external_distance
  )

  expect_s3_class(bundle, "amrc_distance_bundle")
  expect_equal(bundle$isolate_ids, c("iso1", "iso2", "iso4"))
  expect_equal(attr(bundle$phenotype_distance, "Labels"), c("iso1", "iso2", "iso4"))
  expect_equal(attr(bundle$external_distance, "Labels"), c("iso1", "iso2", "iso4"))
})
