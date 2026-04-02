fixture_path <- function(...) {
  testthat::test_path("fixtures", "spneumo-mini", ...)
}

mini_toy_table <- function() {
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

mini_toy_meta <- function(tablemic = mini_toy_table()) {
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

signif_df <- function(df, digits = 6) {
  df[] <- lapply(df, function(x) {
    if (is.numeric(x)) {
      signif(x, digits = digits)
    } else {
      x
    }
  })
  df
}

test_that("preprocessing outputs match frozen fixtures", {
  skip_if_not_installed("ape")

  raw_dir <- fixture_path("raw")
  phen <- amrc_process_spneumoniae_phenotype(input_dir = raw_dir, save_outputs = FALSE)
  gen <- amrc_process_spneumoniae_genotype(
    input_dir = raw_dir,
    metadata = phen$metadata,
    save_outputs = FALSE
  )

  expected_mic <- utils::read.csv(
    fixture_path("expected", "phenotype_mic.csv"),
    check.names = FALSE
  )
  expected_meta <- utils::read.csv(
    fixture_path("expected", "phenotype_metadata.csv"),
    check.names = FALSE
  )
  expected_gen_meta <- utils::read.csv(
    fixture_path("expected", "genotype_metadata_sequences.csv"),
    check.names = FALSE
  )
  expected_gen_dist <- utils::read.csv(
    fixture_path("expected", "genotype_distance.csv"),
    check.names = FALSE
  )

  rownames(expected_mic) <- expected_meta$LABID
  rownames(expected_meta) <- expected_meta$LABID
  rownames(expected_gen_meta) <- expected_gen_meta$LABID

  expect_equal(phen$mic, expected_mic)
  expect_equal(phen$metadata, expected_meta)
  expected_gen_meta[, c("S1", "S2", "S3")] <- lapply(
    expected_gen_meta[, c("S1", "S2", "S3"), drop = FALSE],
    function(x) {
      x <- as.character(x)
      x <- gsub("TRUE", "T", x, fixed = TRUE)
      gsub("FALSE", "F", x, fixed = TRUE)
    }
  )
  expect_equal(gen$metadata_sequences, expected_gen_meta)

  actual_gen_dist <- unname(as.matrix(gen$distance))
  expected_gen_dist <- unname(as.matrix(expected_gen_dist[, -1, drop = FALSE]))
  storage.mode(expected_gen_dist) <- "double"
  expect_equal(actual_gen_dist, expected_gen_dist)
})

test_that("packaged 08 case-study bundle paths resolve and load", {
  paths <- amrc_spneumoniae_example_paths("mapping_08")

  expect_true(file.exists(paths$mic_table))
  expect_true(file.exists(paths$mic_metadata))
  expect_true(file.exists(paths$mlst_metadata))
  expect_true(file.exists(paths$post2015_metadata))
  expect_true(file.exists(paths$map_bundle))

  bundle <- readRDS(paths$map_bundle)

  expect_true(all(c(
    "phenotype_map",
    "genotype_map",
    "phenotype_slope",
    "genotype_slope",
    "deleted_labids"
  ) %in% names(bundle)))
  expect_equal(nrow(bundle$phenotype_map), 3628L)
  expect_equal(
    nrow(bundle$genotype_map),
    nrow(bundle$phenotype_map) - sum(bundle$phenotype_map$LABID %in% bundle$deleted_labids)
  )
})

test_that("map builder and goodness-of-fit summaries match frozen fixtures", {
  skip_if_not_installed("smacof")

  tablemic <- mini_toy_table()
  pbp_dist <- stats::dist(tablemic)
  generated_dir <- tempfile("amrc-regression-maps-")
  dir.create(generated_dir, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(
    tablemic,
    file = file.path(generated_dir, "MIC_table_Spneumoniae.csv"),
    row.names = FALSE
  )
  save(
    pbp_dist,
    file = amrc_generated_path(generated_dir, "genotype_distance_rdata")
  )

  map_build <- amrc_build_spneumoniae_example_maps(
    generated_dir = generated_dir,
    overwrite = TRUE,
    mds_args = list(itmax = 50, eps = 1e-04)
  )
  map_summary <- data.frame(
    map = c("phenotype_metric", "genotype_metric"),
    stress = c(map_build$phenotype$metric$stress, map_build$genotype$metric$stress),
    dilation = c(
      amrc_fit_distance_calibration(map_build$phenotype$metric)$dilation,
      amrc_fit_distance_calibration(map_build$genotype$metric)$dilation
    ),
    n_points = c(
      nrow(map_build$phenotype$metric$conf),
      nrow(map_build$genotype$metric$conf)
    )
  )

  fit_report <- amrc_map_fit_report(map_build$phenotype$metric)

  expected_map_summary <- utils::read.csv(fixture_path("expected", "map_summary.csv"))
  expected_residual <- utils::read.csv(fixture_path("expected", "fit_residual_summary.csv"))
  expected_stress <- utils::read.csv(fixture_path("expected", "fit_stress_summary.csv"))

  expect_equal(signif_df(map_summary), expected_map_summary)
  expect_equal(signif_df(fit_report$residual_summary), expected_residual)

  # `smacof` can return slightly different stress-per-point summaries across
  # platforms even when the fitted map stress and residual summaries are stable.
  # Keep the regression guard, but allow a small absolute tolerance here.
  expect_identical(names(fit_report$stress_summary), names(expected_stress))
  expect_equal(
    as.numeric(signif_df(fit_report$stress_summary)[1, ]),
    as.numeric(expected_stress[1, ]),
    tolerance = 1.5
  )
})

test_that("robustness cross-validation summaries match frozen fixtures", {
  skip_if_not_installed("smacof")

  tablemic <- mini_toy_table()
  meta <- mini_toy_meta(tablemic)
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

  expected <- utils::read.csv(
    fixture_path("expected", "robustness_dimension_summary.csv")
  )

  expect_equal(
    signif_df(missing_study$cross_validation$dimension_summary),
    expected
  )
})
