#' Run a Single-Column Permutation Stress Study
#'
#' Wraps repeated calls to `smacof::permtest()` so the dimensionality notebook
#' can treat the permutation analysis as a reusable package function rather than
#' inline batch-processing code.
#'
#' @param reference_fit Reference MDS fit used by `smacof::permtest()`.
#' @param tablemic Numeric MIC table.
#' @param nrep Number of permutations.
#' @param method_dat Distance method passed to `smacof::permtest()`.
#' @param seed Optional integer seed for reproducibility.
#'
#' @return A list containing the `stress` vector and a one-row `summary` table.
#' @export
amrc_single_column_permutation_study <- function(
  reference_fit,
  tablemic,
  nrep = 100,
  method_dat = "euclidean",
  seed = NULL
) {
  if (!requireNamespace("smacof", quietly = TRUE)) {
    stop(
      "Package 'smacof' is required for permutation studies. ",
      "Install it with tools/install_packages.R.",
      call. = FALSE
    )
  }

  if (!is.null(seed)) {
    set.seed(seed)
  }

  stress <- vapply(seq_len(nrep), function(i) {
    smacof::permtest(
      reference_fit,
      data = t(as.matrix(tablemic)),
      method.dat = method_dat,
      nrep = 1,
      verbose = FALSE
    )$stressvec
  }, numeric(1))

  summary <- data.frame(
    sd = stats::sd(stress),
    Mean = mean(stress),
    Median = stats::median(stress),
    Mean_percent_increase = ((mean(stress) - reference_fit$stress) / reference_fit$stress) * 100
  )

  list(
    stress = stress,
    summary = summary
  )
}

amrc_sample_noise_matrix <- function(nrow, ncol, noise_pct) {
  n_cells <- nrow * ncol
  n_noisy <- max(1L, floor(n_cells * noise_pct / 100))
  index <- sample(seq_len(n_cells), size = n_noisy)
  noise <- matrix(0, nrow = nrow, ncol = ncol)
  noise[index] <- sample(c(-1, 1), size = length(index), replace = TRUE)
  noise
}

#' Generate Noisy One-Dimensional MIC Tables
#'
#' Creates synthetic one-dimensional tables by copying a single observed drug
#' column across all drugs and perturbing a subset of entries by one log2
#' dilution in either direction.
#'
#' @param tablemic Numeric MIC table.
#' @param nrep Number of synthetic tables to generate.
#' @param noise_pct Percentage of cells to perturb.
#' @param lower_bound Minimum allowed value after perturbation.
#' @param seed Optional integer seed.
#'
#' @return A list containing the generated `tables`, selected `column_index`,
#'   and the additive `noise`.
#' @export
amrc_generate_one_dimensional_noise_samples <- function(
  tablemic,
  nrep = 100,
  noise_pct = 10,
  lower_bound = 1,
  seed = NULL
) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  table_matrix <- as.matrix(tablemic)
  column_index <- sample(seq_len(ncol(table_matrix)), size = nrep, replace = TRUE)
  samples <- vector("list", nrep)
  noise <- vector("list", nrep)

  for (i in seq_len(nrep)) {
    base_column <- table_matrix[, column_index[[i]]]
    sample_table <- matrix(
      rep(base_column, ncol(table_matrix)),
      nrow = nrow(table_matrix),
      ncol = ncol(table_matrix)
    )
    sample_noise <- amrc_sample_noise_matrix(nrow(table_matrix), ncol(table_matrix), noise_pct = noise_pct)
    sample_table <- pmax(sample_table + sample_noise, lower_bound)
    colnames(sample_table) <- colnames(table_matrix)

    samples[[i]] <- as.data.frame(sample_table)
    noise[[i]] <- as.data.frame(sample_noise)
    colnames(noise[[i]]) <- colnames(table_matrix)
  }

  list(
    tables = samples,
    column_index = column_index,
    noise = noise
  )
}

#' Run a One-Dimensional Noise Stress Study
#'
#' @param tablemic Numeric MIC table with positive values.
#' @param nrep Number of synthetic tables to generate.
#' @param noise_pct Percentage of cells to perturb.
#' @param seed Optional integer seed.
#' @param mds_args Optional named list of extra arguments passed to
#'   [amrc_compute_mds()].
#'
#' @return A list containing the synthetic `samples`, fitted 1D `stress`
#'   distribution, the observed 1D fit, and a compact `summary`.
#' @export
amrc_one_dimensional_noise_study <- function(
  tablemic,
  nrep = 100,
  noise_pct = 10,
  seed = NULL,
  mds_args = list()
) {
  generated <- amrc_generate_one_dimensional_noise_samples(
    tablemic = tablemic,
    nrep = nrep,
    noise_pct = noise_pct,
    seed = seed
  )

  stress <- vapply(generated$tables, function(sample_table) {
    fit <- do.call(
      amrc_compute_mds,
      c(
        list(
          distance_matrix = stats::dist(sample_table),
          ndim = 1,
          type = "ratio",
          init = "torgerson"
        ),
        mds_args
      )
    )
    fit$stress
  }, numeric(1))

  observed_fit <- do.call(
    amrc_compute_mds,
    c(
      list(
        distance_matrix = stats::dist(tablemic),
        ndim = 1,
        type = "ratio",
        init = "torgerson"
      ),
      mds_args
    )
  )

  summary <- data.frame(
    sd = stats::sd(stress),
    Mean = mean(stress),
    Median = stats::median(stress),
    Mean_perc_diff = mean((observed_fit$stress - stress) / observed_fit$stress * 100)
  )

  list(
    samples = generated$tables,
    noise = generated$noise,
    column_index = generated$column_index,
    stress = stress,
    observed_fit = observed_fit,
    summary = summary
  )
}

#' Compare One- and Two-Dimensional Phenotype Maps
#'
#' Uses Procrustes alignment to project a calibrated 1D solution into the 2D
#' phenotype map and returns both per-isolate and deduplicated per-phenotype
#' comparison tables.
#'
#' @param one_dim_fit One-dimensional MDS fit.
#' @param two_dim_fit Two-dimensional MDS fit.
#' @param lab_ids Character vector of isolate identifiers.
#' @param rotation_degrees Optional post-calibration rotation for the 2D map.
#' @param dedupe_digits Number of digits used when collapsing identical 2D
#'   phenotypes.
#'
#' @return A list containing the `procrustes` fit, the full per-isolate
#'   `comparison` table, and a `unique_phenotypes` subset.
#' @export
amrc_compare_one_and_two_dimensional_maps <- function(
  one_dim_fit,
  two_dim_fit,
  lab_ids,
  rotation_degrees = 326,
  dedupe_digits = 10
) {
  if (!requireNamespace("smacof", quietly = TRUE)) {
    stop(
      "Package 'smacof' is required for Procrustes comparisons. ",
      "Install it with tools/install_packages.R.",
      call. = FALSE
    )
  }

  two_dim_calibrated <- amrc_calibrate_mds(
    two_dim_fit,
    rotation_degrees = rotation_degrees
  )$configuration
  one_dim_conf <- as.matrix(one_dim_fit$conf)
  one_dim_padded <- cbind(one_dim_conf, rep(0, nrow(one_dim_conf)))

  comparison <- smacof::Procrustes(as.matrix(two_dim_calibrated), one_dim_padded)
  pairwise <- as.data.frame(cbind(comparison$X, comparison$Yhat))
  colnames(pairwise) <- c(
    "X_axis_2D_map",
    "Y_axis_2D_map",
    "X_axis_1D_map",
    "Y_axis_1D_map"
  )
  pairwise$dist_phen <- sqrt(
    (pairwise$X_axis_2D_map - pairwise$X_axis_1D_map)^2 +
      (pairwise$Y_axis_2D_map - pairwise$Y_axis_1D_map)^2
  )
  pairwise$LABID <- lab_ids
  pairwise$spp_2D <- as.numeric(two_dim_fit$spp)
  pairwise$spp_1D <- as.numeric(one_dim_fit$spp)

  unique_key <- paste(
    round(pairwise$X_axis_2D_map, digits = dedupe_digits),
    round(pairwise$Y_axis_2D_map, digits = dedupe_digits)
  )
  unique_phenotypes <- pairwise[!duplicated(unique_key), , drop = FALSE]
  rownames(pairwise) <- NULL
  rownames(unique_phenotypes) <- NULL

  list(
    procrustes = comparison,
    comparison = pairwise,
    unique_phenotypes = unique_phenotypes
  )
}
