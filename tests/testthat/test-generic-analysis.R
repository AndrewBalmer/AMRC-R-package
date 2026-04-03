generic_analysis_fixture <- function() {
  data.frame(
    isolate_id = paste0("iso", 1:8),
    lineage = c("L1", "L1", "L1", "L2", "L2", "L3", "L3", "L3"),
    subtype = c("A", "A", "B", "A", "B", "A", "B", "B"),
    phen_x = c(0, 0.5, 1, 2, 2.5, 4, 4.5, 5),
    phen_y = c(0, 0.4, 1, 2, 2.2, 4, 4.3, 5),
    ext_x = c(0, 0.4, 0.8, 2.1, 2.6, 3.8, 4.2, 4.9),
    ext_y = c(0, 0.3, 0.9, 2.0, 2.5, 3.7, 4.0, 4.8),
    gene_a = c(0, 0, 1, 0, 1, 1, 1, 1),
    gene_b = c("absent", "present", "present", "absent", "absent", "present", "present", "present"),
    response_1 = c(0.5, 1, 2, 2.5, 3, 4, 5, 5.5),
    response_2 = c(1, 1.5, 2.5, 2.8, 3.1, 4.2, 4.8, 5.1),
    stringsAsFactors = FALSE
  )
}

test_that("generic external feature tables can be bound and aligned to metadata", {
  table_1 <- data.frame(
    isolate_id = c("iso1", "iso2"),
    a1 = c("A", "T"),
    a2 = c(TRUE, FALSE),
    stringsAsFactors = FALSE
  )
  table_2 <- data.frame(
    isolate_id = c("iso3"),
    a1 = c("G"),
    a2 = c("TRUE"),
    stringsAsFactors = FALSE
  )
  metadata <- data.frame(
    isolate_id = c("iso1", "iso2", "iso3"),
    lineage = c("L1", "L1", "L2"),
    stringsAsFactors = FALSE
  )

  bound <- amrc_bind_external_tables(list(table_1, table_2))
  expect_equal(bound$isolate_id, c("iso1", "iso2", "iso3"))

  prepared <- amrc_prepare_external_features(
    data = list(table_1, table_2),
    id_col = "isolate_id",
    metadata = metadata,
    metadata_cols = "lineage",
    feature_mode = "character"
  )

  expect_s3_class(prepared, "amrc_external_data")
  expect_equal(prepared$isolate_ids, c("iso1", "iso2", "iso3"))
  expect_equal(as.character(prepared$features$a2), c("T", "F", "T"))
  expect_equal(colnames(prepared$metadata), c("isolate_id", "lineage"))
})

test_that("group distance summaries and cluster comparisons are generic", {
  fixture <- generic_analysis_fixture()

  group_summary <- amrc_compute_group_distance_summary(
    data = fixture,
    group_col = "lineage",
    phenotype_cols = c("phen_x", "phen_y"),
    external_cols = c("ext_x", "ext_y")
  )

  expect_true(all(c(
    "group_1", "group_2", "relation", "n_pairs",
    "phenotype_distance_median", "external_distance_median",
    "median_external_to_phenotypic_ratio"
  ) %in% names(group_summary)))
  expect_true(any(group_summary$relation == "within"))
  expect_true(any(group_summary$relation == "between"))

  cluster_data <- fixture
  cluster_data$phen_cluster <- c(1, 1, 1, 2, 2, 3, 3, 3)
  cluster_data$ext_cluster <- c("A", "A", "B", "B", "B", "C", "C", "C")

  cluster_compare <- amrc_compare_cluster_assignments(
    data = cluster_data,
    cluster_col_1 = "phen_cluster",
    cluster_col_2 = "ext_cluster"
  )

  expect_true(is.matrix(cluster_compare$table))
  expect_true(all(c("phen_cluster", "ext_cluster", "n") %in% names(cluster_compare$counts)))
})

test_that("multivariate model and single-feature association scans work for binary features", {
  fixture <- generic_analysis_fixture()

  mv_fit <- amrc_fit_multivariate_linear_model(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    predictor_cols = "gene_a"
  )

  expect_true(inherits(mv_fit$fit, "mlm"))
  expect_true(!is.null(mv_fit$pillai$stats))

  scan <- amrc_scan_single_feature_associations(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    feature_cols = c("gene_a", "gene_b"),
    min_group_size = 2
  )

  expect_true(all(c(
    "feature", "n_absent", "n_present", "multivariate_p", "multivariate_p_adjusted"
  ) %in% names(scan$feature_summary)))
  expect_true(all(c(
    "feature", "response", "mean_difference", "median_difference", "p_adjusted"
  ) %in% names(scan$response_summary)))
})

test_that("linear mixed model helpers work for grouped generic scans", {
  skip_if_not_installed("lme4")

  fixture <- generic_analysis_fixture()
  fixture$batch <- c("B1", "B1", "B2", "B2", "B3", "B3", "B4", "B4")

  lmm_fit <- amrc_fit_linear_mixed_model(
    data = fixture,
    response_col = "response_1",
    fixed_effect_cols = "gene_a",
    random_effect_col = "batch"
  )

  expect_true(inherits(lmm_fit$fit, "lmerMod"))

  mixed_scan <- amrc_scan_single_feature_mixed_models(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    feature_cols = c("gene_a", "gene_b"),
    random_effect_col = "batch",
    min_group_size = 2
  )

  expect_true(all(c(
    "feature", "min_response_p", "min_response_p_adjusted", "status"
  ) %in% names(mixed_scan$feature_summary)))
  expect_true(all(c(
    "feature", "response", "random_effect", "coefficient", "p_adjusted"
  ) %in% names(mixed_scan$response_summary)))
})

test_that("LIMIX helper wrappers stage generic inputs and commands without executing", {
  fixture <- generic_analysis_fixture()
  fixture$gene_b <- factor(fixture$gene_b)
  kinship <- stats::dist(as.matrix(fixture[, c("ext_x", "ext_y")]))
  kinship <- as.matrix(kinship)
  rownames(kinship) <- fixture$isolate_id
  colnames(kinship) <- fixture$isolate_id

  out_dir <- tempfile("amrc-limix-")

  inputs <- amrc_write_limix_mvlmm_inputs(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    marker_cols = c("gene_a", "gene_b"),
    covariate_cols = "lineage",
    id_col = "isolate_id",
    kinship_matrix = kinship,
    out_dir = out_dir,
    prefix = "toy"
  )

  expect_true(file.exists(inputs$response_path))
  expect_true(file.exists(inputs$marker_path))
  expect_true(file.exists(inputs$covariate_path))
  expect_true(file.exists(inputs$kinship_path))

  marker_data <- utils::read.csv(inputs$marker_path, check.names = FALSE)
  covariate_data <- utils::read.csv(inputs$covariate_path, check.names = FALSE)
  kinship_data <- utils::read.csv(inputs$kinship_path, check.names = FALSE)

  expect_true(all(c("isolate_id", "gene_a", "gene_b") %in% names(marker_data)))
  expect_true(all(marker_data$gene_b %in% c(0, 1)))
  expect_true(any(grepl("^lineage", names(covariate_data))))
  expect_identical(names(kinship_data)[1], "isolate_id")

  mv_cmd <- amrc_run_limix_mvlmm(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    marker_cols = c("gene_a", "gene_b"),
    covariate_cols = "lineage",
    id_col = "isolate_id",
    out_dir = out_dir,
    prefix = "toy_mv",
    execute = FALSE
  )

  uv_cmd <- amrc_run_limix_lmm_scan(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    marker_cols = c("gene_a", "gene_b"),
    covariate_cols = "lineage",
    id_col = "isolate_id",
    out_dir = out_dir,
    prefix = "toy_uv",
    execute = FALSE
  )

  expect_true(any(mv_cmd$args == "--mode"))
  expect_true(any(mv_cmd$args == "multivariate"))
  expect_true(any(uv_cmd$args == "univariate"))
  expect_true(file.exists(mv_cmd$script))
  expect_true(file.exists(uv_cmd$script))
})

test_that("LIMIX script discovery works for installed and source-style layouts", {
  installed_script <- amrcartography:::amrc_limix_script_path()

  expect_true(nzchar(installed_script))
  expect_true(file.exists(installed_script))
  expect_match(basename(installed_script), "^amrc_limix_mvlmm_scan\\.py$")

  root_dir <- tempfile("amrc-source-layout-")
  nested_dir <- file.path(root_dir, "tests", "testthat")
  dir.create(file.path(root_dir, "inst", "python"), recursive = TRUE, showWarnings = FALSE)
  dir.create(nested_dir, recursive = TRUE, showWarnings = FALSE)
  writeLines("Package: fakepkg", file.path(root_dir, "DESCRIPTION"))
  writeLines("#!/usr/bin/env python3", file.path(root_dir, "inst", "python", "amrc_limix_mvlmm_scan.py"))

  source_script <- amrcartography:::amrc_find_repo_file(
    file.path("inst", "python", "amrc_limix_mvlmm_scan.py"),
    start_dir = nested_dir
  )

  expect_true(nzchar(source_script))
  expect_equal(
    normalizePath(source_script, winslash = "/", mustWork = TRUE),
    normalizePath(
      file.path(root_dir, "inst", "python", "amrc_limix_mvlmm_scan.py"),
      winslash = "/",
      mustWork = TRUE
    )
  )
})

test_that("heritability and variance-decomposition helpers stage generic LIMIX inputs", {
  fixture <- generic_analysis_fixture()
  kinship <- stats::dist(as.matrix(fixture[, c("ext_x", "ext_y")]))
  kinship <- as.matrix(kinship)
  rownames(kinship) <- fixture$isolate_id
  colnames(kinship) <- fixture$isolate_id

  out_dir <- tempfile("amrc-limix-components-")

  herit <- amrc_run_limix_heritability(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    kinship_matrix = kinship,
    id_col = "isolate_id",
    out_dir = out_dir,
    prefix = "toy_h2",
    execute = FALSE
  )

  expect_true(any(herit$args == "heritability"))
  expect_true(any(herit$args == "--kinship"))
  expect_true(file.exists(herit$inputs$response_path))
  expect_true(file.exists(herit$inputs$kinship_path))

  vardec <- amrc_run_limix_variance_decomposition(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    kinship_components = list(
      component_a = kinship,
      component_b = kinship + diag(0.1, nrow(kinship))
    ),
    id_col = "isolate_id",
    out_dir = out_dir,
    prefix = "toy_vd",
    execute = FALSE
  )

  manifest <- utils::read.csv(vardec$inputs$component_manifest_path, check.names = FALSE)
  expect_true(any(vardec$args == "variance-decomposition"))
  expect_true(all(c("label", "path") %in% names(manifest)))
  expect_equal(manifest$label, c("component_a", "component_b"))
})

test_that("epistatic and permutation helpers build generic scan workflows", {
  fixture <- generic_analysis_fixture()

  epi_markers <- amrc_generate_epistatic_markers(
    data = fixture,
    feature_cols = c("gene_a", "gene_b"),
    id_col = "isolate_id"
  )

  expect_true("gene_a:gene_b" %in% names(epi_markers))
  expect_true("isolate_id" %in% names(epi_markers))

  epi_run <- amrc_run_limix_epistatic_scan(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    feature_cols = c("gene_a", "gene_b"),
    covariate_cols = "lineage",
    id_col = "isolate_id",
    execute = FALSE,
    out_dir = tempfile("amrc-epi-")
  )

  expect_true(any(epi_run$args == "multivariate"))
  expect_true("gene_a:gene_b" %in% names(epi_run$epistatic_markers))

  perm_runs <- amrc_run_limix_permutation_scan(
    data = fixture,
    response_cols = c("response_1", "response_2"),
    marker_cols = c("gene_a", "gene_b"),
    covariate_cols = "lineage",
    id_col = "isolate_id",
    n_permutations = 3,
    seed = 1,
    execute = FALSE,
    out_dir = tempfile("amrc-perm-")
  )

  expect_length(perm_runs, 3)
  expect_true(all(vapply(perm_runs, function(x) any(x$args == "--mode"), logical(1))))
  expect_true(all(vapply(perm_runs, function(x) length(x$permuted_index) == nrow(fixture), logical(1))))
  expect_true(all(vapply(perm_runs, function(x) length(x$marker_cols_used) == 2L, logical(1))))
})

test_that("BLUP-style kinship prediction helpers work generically", {
  fixture <- generic_analysis_fixture()
  kinship <- stats::dist(as.matrix(fixture[, c("ext_x", "ext_y")]))
  kinship <- as.matrix(kinship)

  split <- amrc_make_train_test_split(nrow(fixture), proportion = 0.75, seed = 1)
  folds <- amrc_make_cv_folds(nrow(fixture), n_folds = 4, seed = 1)

  expect_equal(sum(split$train), 6)
  expect_equal(length(folds), nrow(fixture))

  blup_fit <- amrc_fit_kinship_blup(
    response = fixture$response_1,
    kinship_matrix = kinship,
    train = split$train,
    test = split$test,
    lambda = 0.5,
    return_sd = TRUE
  )

  expect_length(blup_fit$predictions, sum(split$test))
  expect_length(blup_fit$predictive_sd, sum(split$test))

  cv <- amrc_cross_validate_kinship_blup(
    response = fixture$response_1,
    kinship_matrix = kinship,
    n_folds = 4,
    seed = 1,
    lambda = 0.5
  )

  expect_true(all(c("fold", "rmse", "correlation") %in% names(cv$fold_summary)))
  expect_true(all(c("mean_rmse", "mean_correlation") %in% names(cv$overall)))
})

test_that("epistatic and permutation summary helpers combine executed-style outputs", {
  out_dir <- tempfile("amrc-summary-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  epi_stats_path <- file.path(out_dir, "epi_stats.csv")
  epi_effects_path <- file.path(out_dir, "epi_effects.csv")
  utils::write.csv(
    data.frame(
      marker = c("gene_a:gene_b", "gene_a:gene_c"),
      pv20 = c(0.01, 0.2),
      lml0 = c(1, 1),
      stringsAsFactors = FALSE
    ),
    epi_stats_path,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      effect_name = c("gene_a:gene_b", "gene_a:gene_c"),
      effsize = c(0.5, 0.1),
      stringsAsFactors = FALSE
    ),
    epi_effects_path,
    row.names = FALSE
  )

  epi_summary <- amrc_summarise_limix_epistatic_scan(
    list(stats_path = epi_stats_path, effects_path = epi_effects_path)
  )

  expect_true(all(c("feature_1", "feature_2", "p_adjusted") %in% names(epi_summary$summary)))
  expect_equal(epi_summary$summary$feature_1[[1]], "gene_a")
  expect_equal(epi_summary$summary$feature_2[[1]], "gene_b")

  perm_stats_1 <- file.path(out_dir, "perm1_stats.csv")
  perm_stats_2 <- file.path(out_dir, "perm2_stats.csv")
  utils::write.csv(
    data.frame(marker = c("m1", "m2"), pv20 = c(0.05, 0.2), stringsAsFactors = FALSE),
    perm_stats_1,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(marker = c("m1", "m2"), pv20 = c(0.01, 0.3), stringsAsFactors = FALSE),
    perm_stats_2,
    row.names = FALSE
  )

  perm_summary <- amrc_summarise_limix_permutation_scan(
    list(
      list(stats_path = perm_stats_1, permutation = 1, marker_cols_used = c("m1", "m2")),
      list(stats_path = perm_stats_2, permutation = 2, marker_cols_used = c("m1", "m2"))
    )
  )

  expect_true(all(c("permutation", "min_p_value", "median_p_value") %in% names(perm_summary$permutation_summary)))
  expect_equal(nrow(perm_summary$permutation_summary), 2)
  expect_equal(perm_summary$overall$n_permutations[[1]], 2)
})

test_that("map plotting supports faceting and group envelopes", {
  skip_if_not_installed("ggplot2")

  fixture <- generic_analysis_fixture()

  plot <- amrc_plot_map(
    data = fixture,
    x = "phen_x",
    y = "phen_y",
    fill_col = "lineage",
    facet_by = "lineage",
    facet_ncol = 2
  )

  envelope_plot <- amrc_add_group_envelopes(
    plot = amrc_plot_map(
      data = fixture,
      x = "phen_x",
      y = "phen_y",
      fill_col = "lineage"
    ),
    data = fixture,
    x = "phen_x",
    y = "phen_y",
    group_col = "lineage"
  )

  expect_s3_class(plot, "ggplot")
  expect_s3_class(envelope_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(envelope_plot))
})

test_that("within-group dispersion and one-feature contrast helpers work generically", {
  fixture <- generic_analysis_fixture()

  dispersion <- amrc_summarise_within_group_dispersion(
    data = fixture,
    group_col = "lineage",
    phenotype_cols = c("phen_x", "phen_y"),
    external_cols = c("ext_x", "ext_y"),
    threshold = 1
  )

  expect_true(all(c(
    "lineage", "n_members", "n_pairs",
    "phenotype_distance_median", "phenotype_prop_below_threshold",
    "external_distance_median"
  ) %in% names(dispersion)))
  expect_equal(nrow(dispersion), 3)

  group_profiles <- data.frame(
    profile = c("A", "B", "C", "D"),
    feature_1 = c("x", "x", "y", "y"),
    feature_2 = c("m", "n", "n", "m"),
    phen_x = c(0, 1, 2, 3),
    phen_y = c(0, 0, 0, 0),
    ext_x = c(0, 1.2, 2.4, 3.1),
    ext_y = c(0, 0, 0, 0),
    n_isolates = c(10, 8, 9, 7),
    stringsAsFactors = FALSE
  )

  pairs <- amrc_identify_single_feature_pairs(
    data = group_profiles,
    group_col = "profile",
    feature_cols = c("feature_1", "feature_2")
  )

  expect_equal(nrow(pairs), 4)
  expect_true(all(pairs$n_feature_differences == 1L))

  contrasts <- amrc_summarise_single_feature_contrasts(
    data = group_profiles,
    group_col = "profile",
    feature_cols = c("feature_1", "feature_2"),
    phenotype_cols = c("phen_x", "phen_y"),
    external_cols = c("ext_x", "ext_y"),
    count_col = "n_isolates",
    pair_table = pairs
  )

  expect_true(all(c(
    "relative_comparison", "changed_feature", "phenotype_distance",
    "external_distance", "n_group_1", "n_group_2"
  ) %in% names(contrasts)))
  expect_equal(nrow(contrasts), 4)

  duplicated_profiles <- rbind(group_profiles, group_profiles[1, , drop = FALSE])
  duplicated_profiles$profile[[5]] <- "A"
  expect_error(
    amrc_identify_single_feature_pairs(
      data = duplicated_profiles,
      group_col = "profile",
      feature_cols = c("feature_1", "feature_2")
    ),
    "unique values in group_col"
  )

  bad_pairs <- pairs
  bad_pairs$group_2[[1]] <- "missing_group"
  expect_error(
    amrc_summarise_single_feature_contrasts(
      data = group_profiles,
      group_col = "profile",
      feature_cols = c("feature_1", "feature_2"),
      phenotype_cols = c("phen_x", "phen_y"),
      external_cols = c("ext_x", "ext_y"),
      pair_table = bad_pairs
    ),
    "pair_table references groups not present"
  )
})

test_that("cluster-difference and informative-isolate helpers are generic", {
  fixture <- generic_analysis_fixture()
  fixture$cluster <- c("C1", "C1", "C1", "C2", "C2", "C3", "C3", "C3")

  differentiating <- amrc_find_cluster_differentiating_features(
    data = fixture,
    cluster_col = "cluster",
    feature_cols = c("gene_a", "gene_b"),
    cluster_pairs = list(c("C1", "C2")),
    top_n = 2
  )

  expect_true(all(c(
    "cluster_1", "cluster_2", "feature",
    "most_shifted_state", "max_state_frequency_shift"
  ) %in% names(differentiating)))
  expect_true(nrow(differentiating) >= 1)

  informative <- amrc_select_informative_isolates(
    data = fixture,
    cluster_col = "cluster",
    focal_clusters = c("C1", "C2"),
    feature_cols = c("gene_a", "gene_b"),
    id_col = "isolate_id",
    differentiating_features = differentiating,
    max_features = 1
  )

  expect_true("feature_profile" %in% names(informative$data))
  expect_length(informative$selected_features, 1)
  expect_true(all(informative$data$cluster %in% c("C1", "C2")))

  missing_id_fixture <- fixture
  missing_id_fixture$isolate_id <- NULL
  expect_error(
    amrc_select_informative_isolates(
      data = missing_id_fixture,
      cluster_col = "cluster",
      focal_clusters = c("C1", "C2"),
      feature_cols = c("gene_a", "gene_b")
    ),
    "id_col could not be inferred"
  )

  expect_error(
    amrc_select_informative_isolates(
      data = fixture,
      cluster_col = "cluster",
      focal_clusters = c("C1", "missing_cluster"),
      feature_cols = c("gene_a", "gene_b"),
      id_col = "isolate_id"
    ),
    "focal_clusters were not found"
  )
})

test_that("marker preprocessing, model comparison, and overlap helpers work", {
  marker_data <- data.frame(
    isolate_id = paste0("iso", 1:4),
    marker_1 = c(0, 1, 0, 1),
    marker_2 = c(0, 1, 0, 1),
    marker_3 = c(1, 0, 1, 0),
    marker_4 = c(1, 1, 1, 1),
    marker_5 = c(0, 0, 1, 1),
    stringsAsFactors = FALSE
  )

  prepared <- amrc_prepare_marker_matrix(
    data = marker_data,
    marker_cols = c("marker_1", "marker_2", "marker_3", "marker_4", "marker_5"),
    id_col = "isolate_id"
  )

  expect_true(all(c("marker_1", "marker_5") %in% prepared$retained_markers))
  expect_true("marker_4" %in% prepared$dropped_invariant)
  expect_true(any(prepared$collapsed_markers$relation == "duplicate"))
  expect_true(any(prepared$collapsed_markers$relation == "inverse"))

  expect_error(
    amrc_prepare_marker_matrix(
      data = data.frame(
        isolate_id = paste0("iso", 1:4),
        invariant_1 = c(1, 1, 1, 1),
        invariant_2 = c(0, 0, 0, 0),
        stringsAsFactors = FALSE
      ),
      marker_cols = c("invariant_1", "invariant_2"),
      id_col = "isolate_id"
    ),
    "No markers remained after preprocessing"
  )

  model_1 <- data.frame(
    feature = c("feat_a", "feat_b", "feat_c"),
    p_adjusted = c(0.01, 0.2, 0.04),
    effect = c(1.0, 0.1, -0.5),
    stringsAsFactors = FALSE
  )
  model_2 <- data.frame(
    feature = c("feat_a", "feat_b", "feat_c", "feat_d"),
    p_adjusted = c(0.02, 0.03, 0.5, 0.01),
    effect = c(0.8, 0.4, -0.1, 1.2),
    stringsAsFactors = FALSE
  )

  comparison <- amrc_compare_association_models(
    table_1 = model_1,
    table_2 = model_2,
    feature_col = "feature",
    p_col_1 = "p_adjusted",
    p_col_2 = "p_adjusted",
    effect_col_1 = "effect",
    effect_col_2 = "effect",
    labels = c("unadjusted", "adjusted")
  )

  expect_true(all(c(
    "p_value_1", "p_value_2", "presence_status", "significance_change", "effect_size_change"
  ) %in% names(comparison)))
  expect_true(any(comparison$significance_change == "model_2_only"))
  expect_true(any(comparison$significance_change == "lost_significance"))
  expect_true(all(comparison$presence_status %in% c("shared", "model_1_only", "model_2_only")))

  comparison_summary <- amrc_summarise_association_model_comparison(comparison)
  expect_true(all(c("change", "n_features", "proportion") %in% names(comparison_summary$counts)))
  expect_true("effect_size_correlation" %in% names(comparison_summary$overall))

  ranked_tables <- list(
    method_a = data.frame(feature = c("feat_a", "feat_b", "feat_c"), score = c(3, 2, 1), stringsAsFactors = FALSE),
    method_b = data.frame(feature = c("feat_b", "feat_c", "feat_d"), score = c(5, 4, 3), stringsAsFactors = FALSE)
  )

  ranked <- amrc_bind_ranked_feature_tables(
    tables = ranked_tables,
    feature_col = "feature",
    score_col = "score",
    top_n = 2
  )
  expect_true(all(c("method", "feature", "rank", "score") %in% names(ranked)))

  expect_warning(
    amrc_bind_ranked_feature_tables(
      tables = list(method_a = data.frame(feature = c("feat_a", "feat_b"), score = c(3, 2), rank = c(2, 1), stringsAsFactors = FALSE)),
      feature_col = "feature",
      score_col = "score",
      rank_col = "rank"
    ),
    "rank_col determines ordering"
  )

  overlap <- amrc_compute_feature_overlap(
    tables = ranked_tables,
    feature_col = "feature",
    top_n = 2
  )

  expect_true(all(c("feature", "n_methods", "method_list") %in% names(overlap$feature_summary)))
  expect_true(all(c("method_1", "method_2", "n_shared", "jaccard") %in% names(overlap$pairwise_overlap)))
  expect_equal(overlap$pairwise_overlap$n_shared[[1]], 1)
})

test_that("generic workflow and benchmark helpers work", {
  workflow_data <- data.frame(
    isolate_id = paste0("iso", 1:6),
    gen_cluster = c("G1", "G1", "G1", "G1", "G2", "G2"),
    type_id = c("T1", "T1", "T2", "T2", "T3", "T3"),
    D1 = c(0, 0.2, 3, 3.2, 6, 6.1),
    D2 = c(0, 0.1, 3, 3.1, 6, 6.2),
    marker_a = c("A", "A", "B", "B", "C", "C"),
    marker_b = c("low", "low", "high", "high", "high", "high"),
    stringsAsFactors = FALSE
  )

  workflow <- amrc_run_cluster_feature_workflow(
    data = workflow_data,
    outer_cluster_col = "gen_cluster",
    focal_cluster = "G1",
    phenotype_cols = c("D1", "D2"),
    feature_cols = c("marker_a", "marker_b"),
    id_col = "isolate_id",
    type_col = "type_id",
    phenotype_n_clusters = 2,
    max_features = 2
  )

  expect_true("phen_cluster" %in% names(workflow$data_with_clusters))
  expect_true(nrow(workflow$differentiating_features) >= 1)
  expect_true(!is.null(workflow$informative_isolates))

  benchmark_join <- amrc_join_external_benchmarks(
    feature_table = data.frame(feature = c("feat_a", "feat_b", "feat_c"), score = c(3, 2, 1), stringsAsFactors = FALSE),
    benchmark_table = data.frame(feature = c("feat_a", "feat_c"), GWAS = c(TRUE, FALSE), literature = c(TRUE, TRUE), stringsAsFactors = FALSE),
    benchmark_flag_cols = c("GWAS", "literature")
  )

  expect_true(all(c("n_benchmark_sources", "benchmark_source_list", "in_any_benchmark") %in% names(benchmark_join)))
  expect_true(any(benchmark_join$in_any_benchmark))

  effects <- amrc_categorise_effect_directions(
    data = data.frame(feature = c("a", "b", "c", "d"), eff_x = c(2, -2, -2, 2), eff_y = c(2, 2, -2, -2), stringsAsFactors = FALSE),
    effect_x_col = "eff_x",
    effect_y_col = "eff_y",
    x_threshold = 1,
    y_threshold = 1
  )

  expect_true(all(c("effect_direction", "effect_magnitude", "effect_angle_degrees") %in% names(effects)))
  effect_summary <- amrc_summarise_effect_directions(effects)
  expect_true(all(c("direction", "n", "proportion") %in% names(effect_summary)))
})

test_that("generic visualisation helpers build plots", {
  fixture <- generic_analysis_fixture()

  faceted_plot <- amrc_plot_top_group_facets(
    data = fixture,
    group_col = "lineage",
    x = "phen_x",
    y = "phen_y",
    top_n = 2
  )
  expect_s3_class(faceted_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(faceted_plot))

  dispersion <- amrc_summarise_within_group_dispersion(
    data = fixture,
    group_col = "lineage",
    phenotype_cols = c("phen_x", "phen_y")
  )
  dispersion_plot <- amrc_plot_within_group_dispersion_histogram(dispersion)
  expect_s3_class(dispersion_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(dispersion_plot))

  side_by_side <- amrc_plot_side_by_side_maps(
    data = data.frame(
      D1 = fixture$phen_x,
      D2 = fixture$phen_y,
      E1 = fixture$ext_x,
      E2 = fixture$ext_y,
      lineage = fixture$lineage,
      stringsAsFactors = FALSE
    ),
    phenotype_cols = c("D1", "D2"),
    external_cols = c("E1", "E2"),
    fill_col = "lineage"
  )
  expect_s3_class(side_by_side, "ggplot")
  expect_no_error(ggplot2::ggplot_build(side_by_side))

  diff_features <- amrc_find_cluster_differentiating_features(
    data = data.frame(
      cluster = c("A", "A", "B", "B"),
      marker = c("x", "x", "y", "y"),
      stringsAsFactors = FALSE
    ),
    cluster_col = "cluster",
    feature_cols = "marker"
  )
  diff_plot <- amrc_plot_cluster_feature_shifts(diff_features)
  expect_s3_class(diff_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(diff_plot))

  comparison <- amrc_compare_association_models(
    table_1 = data.frame(feature = c("f1", "f2"), p_adjusted = c(0.01, 0.2), effect = c(1, 0.1), stringsAsFactors = FALSE),
    table_2 = data.frame(feature = c("f1", "f2", "f3"), p_adjusted = c(0.02, 0.03, 0.01), effect = c(0.8, 0.4, 1.2), stringsAsFactors = FALSE),
    feature_col = "feature",
    p_col_1 = "p_adjusted",
    p_col_2 = "p_adjusted",
    effect_col_1 = "effect",
    effect_col_2 = "effect"
  )
  comparison_plot <- amrc_plot_association_model_comparison(comparison, mode = "change_counts")
  expect_s3_class(comparison_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(comparison_plot))

  effect_plot <- amrc_plot_effect_direction_summary(
    data = data.frame(eff_x = c(2, -2, -2, 2), eff_y = c(2, 2, -2, -2), stringsAsFactors = FALSE),
    effect_x_col = "eff_x",
    effect_y_col = "eff_y",
    x_threshold = 1,
    y_threshold = 1
  )
  expect_s3_class(effect_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(effect_plot))

  overlap <- amrc_compute_feature_overlap(
    tables = list(
      method_a = data.frame(feature = c("f1", "f2", "f3"), stringsAsFactors = FALSE),
      method_b = data.frame(feature = c("f2", "f3", "f4"), stringsAsFactors = FALSE)
    ),
    feature_col = "feature",
    top_n = 2
  )
  overlap_plot <- amrc_plot_feature_overlap(overlap, mode = "pairwise")
  expect_s3_class(overlap_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(overlap_plot))

  herit_plot <- amrc_plot_heritability_summary(
    data.frame(response = c("D1", "D2"), heritability = c(0.4, 0.7), stringsAsFactors = FALSE)
  )
  expect_s3_class(herit_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(herit_plot))

  variance_plot <- amrc_plot_variance_decomposition(
    data.frame(
      response = c("D1", "D1", "D2", "D2"),
      component = c("kinship", "noise", "kinship", "noise"),
      proportion = c(0.7, 0.3, 0.6, 0.4),
      stringsAsFactors = FALSE
    )
  )
  expect_s3_class(variance_plot, "ggplot")
  expect_no_error(ggplot2::ggplot_build(variance_plot))
})

test_that("manuscript panel composers assemble plot layouts", {
  skip_if_not_installed("patchwork")

  base_data <- data.frame(
    x = c(0, 1, 2),
    y = c(0, 1, 0),
    cluster = c("A", "B", "A"),
    stringsAsFactors = FALSE
  )

  map_plot <- amrc_plot_map(base_data, x = "x", y = "y", fill_col = "cluster")
  ref_plot <- amrc_plot_reference_distance_relationship(
    data.frame(
      external_distance = c(0.5, 1, 1.5),
      phenotype_distance = c(0.4, 1.1, 1.4),
      stringsAsFactors = FALSE
    )
  )

  grid_panel <- amrc_compose_manuscript_panel_grid(list(map_plot, ref_plot), ncol = 2)
  pair_panel <- amrc_compose_map_reference_panel(map_plot, ref_plot)
  side_panel <- amrc_compose_manuscript_side_by_side_panel(map_plot, ref_plot)
  row_panel <- amrc_compose_manuscript_triptych_panel(map_plot, map_plot, ref_plot)
  triptych_panel <- amrc_compose_phenotype_external_reference_panel(
    phenotype_plot = map_plot,
    external_plot = map_plot,
    reference_plot = ref_plot
  )
  storyboard_panel <- amrc_compose_thesis_storyboard_panel(
    top_left = map_plot,
    top_right = map_plot,
    bottom_plot = ref_plot
  )
  cluster_story_panel <- amrc_compose_manuscript_cluster_story_panel(
    phenotype_plot = map_plot,
    external_plot = map_plot,
    feature_plot = ref_plot
  )

  expect_s3_class(grid_panel, "patchwork")
  expect_s3_class(pair_panel, "patchwork")
  expect_s3_class(side_panel, "patchwork")
  expect_s3_class(row_panel, "patchwork")
  expect_s3_class(triptych_panel, "patchwork")
  expect_s3_class(storyboard_panel, "patchwork")
  expect_s3_class(cluster_story_panel, "patchwork")
})
