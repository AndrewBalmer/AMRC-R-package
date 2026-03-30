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

generic_mds_fixture <- function(labels, coords) {
  coords <- as.matrix(coords)
  rownames(coords) <- labels

  list(
    delta = stats::dist(coords),
    conf = coords,
    confdist = as.matrix(stats::dist(coords)),
    spp = rep(0, nrow(coords))
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

test_that("generic map preparation aligns metadata and external structures by isolate id", {
  metadata <- data.frame(
    isolate_id = c("iso1", "iso2", "iso3", "iso4"),
    lineage = c("L1", "L1", "L2", "L3"),
    source = c("ward", "ward", "clinic", "clinic"),
    stringsAsFactors = FALSE
  )

  phenotype_fit <- generic_mds_fixture(
    labels = c("iso2", "iso1", "iso4", "iso3"),
    coords = matrix(
      c(
        0, 0,
        1, 0,
        2, 2,
        3, 2
      ),
      ncol = 2,
      byrow = TRUE
    )
  )
  external_fit <- generic_mds_fixture(
    labels = c("iso1", "iso2", "iso3", "iso4"),
    coords = matrix(
      c(
        10, 0,
        11, 0,
        20, 2,
        21, 2
      ),
      ncol = 2,
      byrow = TRUE
    )
  )

  comparison <- amrc_prepare_map_data(
    metadata = metadata,
    phenotype_mds = phenotype_fit,
    external_mds = external_fit,
    id_col = "isolate_id",
    group_col = "lineage"
  )

  expect_equal(comparison$data$isolate_id, c("iso2", "iso1", "iso4", "iso3"))
  expect_equal(comparison$data$lineage, c("L1", "L1", "L3", "L2"))
  expect_equal(comparison$data$E1, c(11, 10, 21, 20))
  expect_true(all(c("D1_centroid", "D2_centroid") %in% colnames(comparison$data)))
  expect_equal(nrow(comparison$group_data), 3L)
  expect_equal(comparison$group_data$lineage, c("L1", "L3", "L2"))
})

test_that("S. pneumoniae compatibility wrapper delegates to the generic map-preparation path", {
  metadata <- data.frame(
    LABID = c("iso1", "iso2", "iso3"),
    PT = c("pbpA", "pbpA", "pbpB"),
    country = c("UK", "UK", "KE"),
    stringsAsFactors = FALSE
  )

  phenotype_fit <- generic_mds_fixture(
    labels = c("iso1", "iso2", "iso3"),
    coords = matrix(
      c(
        0, 0,
        1, 0,
        2, 1
      ),
      ncol = 2,
      byrow = TRUE
    )
  )
  genotype_fit <- generic_mds_fixture(
    labels = c("iso3", "iso1", "iso2"),
    coords = matrix(
      c(
        10, 1,
        20, 1,
        21, 2
      ),
      ncol = 2,
      byrow = TRUE
    )
  )

  comparison <- amrc_prepare_spneumoniae_map_data(
    tablemic_meta = metadata,
    phenotype_mds = phenotype_fit,
    genotype_mds = genotype_fit,
    phenotype_rotation_degrees = NULL,
    exclude_labids = character()
  )

  expect_equal(comparison$data$LABID, c("iso1", "iso2", "iso3"))
  expect_equal(comparison$data$PBP_type, c("pbpA", "pbpA", "pbpB"))
  expect_equal(comparison$data$G1, c(20, 21, 10))
  expect_true(all(c("x_centroid", "y_centroid") %in% colnames(comparison$data)))
  expect_equal(nrow(comparison$pbp_data), 2L)
})
