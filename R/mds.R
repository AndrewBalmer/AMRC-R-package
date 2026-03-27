#' Compute an MDS Map
#'
#' Thin wrapper around `smacof::mds()` with defaults aligned to the legacy AMR
#' cartography scripts.
#'
#' @param distance_matrix A `dist` object or matrix coercible to `dist`.
#' @param ndim Number of dimensions.
#' @param type MDS transformation type.
#' @param init Initial configuration method.
#' @param modulus Numeric modulus argument passed to `smacof::mds()`.
#' @param itmax Maximum number of iterations.
#' @param eps Convergence tolerance.
#' @param ... Additional arguments passed to `smacof::mds()`.
#'
#' @return A `smacof` MDS result object.
#' @export
amrc_compute_mds <- function(
  distance_matrix,
  ndim = 2,
  type = "ratio",
  init = "torgerson",
  modulus = 1,
  itmax = 1000,
  eps = 1e-06,
  ...
) {
  if (!requireNamespace("smacof", quietly = TRUE)) {
    stop(
      "Package 'smacof' is required to compute MDS maps. ",
      "Install it with tools/install_packages.R.",
      call. = FALSE
    )
  }

  if (!inherits(distance_matrix, "dist")) {
    distance_matrix <- stats::as.dist(distance_matrix)
  }

  smacof::mds(
    delta = distance_matrix,
    ndim = ndim,
    type = type,
    init = init,
    modulus = modulus,
    itmax = itmax,
    eps = eps,
    ...
  )
}

#' Run an MDS Dimensionality Sweep
#'
#' Evaluates stress across multiple dimensions and transformation types using
#' the package MDS defaults.
#'
#' @param distance_matrix A `dist` object or matrix coercible to `dist`.
#' @param dimensions Integer vector of dimensions to evaluate.
#' @param transformations Named character vector mapping output labels to SMACOF
#'   transformation types.
#' @param ordinal_ties Ties strategy used for ordinal fits.
#' @param ... Additional arguments passed to `amrc_compute_mds()`.
#'
#' @return A `data.frame` with columns `method`, `type`, `dimension`, and
#'   `stress`.
#' @export
amrc_run_dimensionality_sweep <- function(
  distance_matrix,
  dimensions = 1:10,
  transformations = c(metric = "ratio", ordinal = "ordinal", interval = "interval"),
  ordinal_ties = "primary",
  ...
) {
  if (is.null(names(transformations)) || any(names(transformations) == "")) {
    names(transformations) <- transformations
  }

  results <- vector("list", length(transformations) * length(dimensions))
  index <- 1L

  for (method in names(transformations)) {
    type <- transformations[[method]]

    for (dimension in dimensions) {
      fit <- amrc_compute_mds(
        distance_matrix = distance_matrix,
        ndim = dimension,
        type = type,
        ties = if (identical(type, "ordinal")) ordinal_ties else NULL,
        ...
      )

      results[[index]] <- data.frame(
        method = method,
        type = type,
        dimension = dimension,
        stress = fit$stress
      )
      index <- index + 1L
    }
  }

  do.call(rbind, results)
}

#' Fit the Standard Legacy MDS Transformation Set
#'
#' Fits the metric, ordinal, and interval variants used repeatedly in the
#' legacy notebooks.
#'
#' @param distance_matrix A `dist` object or matrix coercible to `dist`.
#' @param ndim Number of dimensions.
#' @param transformations Named character vector mapping output labels to SMACOF
#'   transformation types.
#' @param ordinal_ties Ties strategy used for ordinal fits.
#' @param ... Additional arguments passed to `amrc_compute_mds()`.
#'
#' @return A named list of fitted MDS objects.
#' @export
amrc_fit_mds_transformations <- function(
  distance_matrix,
  ndim = 2,
  transformations = c(metric = "ratio", ordinal = "ordinal", interval = "interval"),
  ordinal_ties = "secondary",
  ...
) {
  if (is.null(names(transformations)) || any(names(transformations) == "")) {
    names(transformations) <- transformations
  }

  fits <- vector("list", length(transformations))
  names(fits) <- names(transformations)

  for (method in names(transformations)) {
    type <- transformations[[method]]
    fits[[method]] <- amrc_compute_mds(
      distance_matrix = distance_matrix,
      ndim = ndim,
      type = type,
      ties = if (identical(type, "ordinal")) ordinal_ties else NULL,
      ...
    )
  }

  fits
}

#' Search for a Low-Stress Random-Start MDS Solution
#'
#' Repeats MDS from random initial configurations and returns the best fit, with
#' optional `smacof::icExplore()` output for compatibility with the legacy map
#' notebooks.
#'
#' @param distance_matrix A `dist` object or matrix coercible to `dist`.
#' @param nrep Number of random starts.
#' @param ndim Number of dimensions.
#' @param type MDS transformation type.
#' @param return_all Logical; include all fitted solutions when `TRUE`.
#' @param run_icexplore Logical; also run `smacof::icExplore()` when `TRUE`.
#' @param ... Additional arguments passed to `amrc_compute_mds()`.
#'
#' @return A list with `best_fit`, `best_index`, `exploration`, and optionally
#'   `fits`.
#' @export
amrc_run_random_start_search <- function(
  distance_matrix,
  nrep = 100,
  ndim = 2,
  type = "ratio",
  return_all = FALSE,
  run_icexplore = TRUE,
  ...
) {
  fits <- vector("list", nrep)

  for (i in seq_len(nrep)) {
    fits[[i]] <- amrc_compute_mds(
      distance_matrix = distance_matrix,
      ndim = ndim,
      type = type,
      init = "random",
      ...
    )
  }

  best_index <- which.min(vapply(fits, function(x) x$stress, numeric(1)))
  exploration <- NULL

  if (isTRUE(run_icexplore)) {
    exploration <- smacof::icExplore(
      delta = if (inherits(distance_matrix, "dist")) distance_matrix else stats::as.dist(distance_matrix),
      type = type,
      ndim = ndim,
      nrep = nrep,
      returnfit = TRUE,
      ...
    )
  }

  result <- list(
    best_fit = fits[[best_index]],
    best_index = best_index,
    exploration = exploration
  )

  if (isTRUE(return_all)) {
    result$fits <- fits
  }

  result
}

#' Search for a Low-Stress Weighted MDS Solution
#'
#' Runs repeated weighted MDS fits using the specified `dissWeights()` scheme and
#' returns the best fit.
#'
#' @param distance_matrix A `dist` object or matrix coercible to `dist`.
#' @param nrep Number of repeated fits.
#' @param ndim Number of dimensions.
#' @param type MDS transformation type.
#' @param weight_type Weighting scheme passed to `smacof::dissWeights()`.
#' @param return_all Logical; include all fitted solutions when `TRUE`.
#' @param ... Additional arguments passed to `amrc_compute_mds()`.
#'
#' @return A list with `best_fit`, `best_index`, and optionally `fits`.
#' @export
amrc_run_weighted_mds_search <- function(
  distance_matrix,
  nrep = 100,
  ndim = 2,
  type = "ratio",
  weight_type = "unif",
  return_all = FALSE,
  ...
) {
  if (!inherits(distance_matrix, "dist")) {
    distance_matrix <- stats::as.dist(distance_matrix)
  }

  weight_matrix <- smacof::dissWeights(distance_matrix, type = weight_type)
  fits <- vector("list", nrep)

  for (i in seq_len(nrep)) {
    fits[[i]] <- amrc_compute_mds(
      distance_matrix = distance_matrix,
      ndim = ndim,
      type = type,
      init = "torgerson",
      weightmat = weight_matrix,
      ...
    )
  }

  best_index <- which.min(vapply(fits, function(x) x$stress, numeric(1)))
  result <- list(
    best_fit = fits[[best_index]],
    best_index = best_index
  )

  if (isTRUE(return_all)) {
    result$fits <- fits
  }

  result
}

#' Rotate a Configuration Matrix
#'
#' @param configuration Numeric matrix with one row per isolate and one column
#'   per dimension.
#' @param degrees Rotation angle in degrees.
#'
#' @return A rotated numeric matrix.
#' @export
amrc_rotate_configuration <- function(configuration, degrees) {
  theta <- degrees * pi / 180
  rotation <- matrix(
    c(cos(theta), sin(theta), -sin(theta), cos(theta)),
    ncol = 2
  )

  as.matrix(configuration) %*% rotation
}

#' Calibrate an MDS Configuration to the Original Distance Scale
#'
#' Fits a linear model between original table distances and map distances, then
#' returns a dilated configuration and fit summary. This captures the repeated
#' scale-calibration pattern used across the legacy notebooks.
#'
#' @param mds_result A result from `amrc_compute_mds()` or `smacof::mds()`.
#' @param rotation_degrees Optional rotation to apply after dilation.
#'
#' @return A list containing the calibrated configuration, the dilation factor,
#'   and the fitted linear model.
#' @export
amrc_calibrate_mds <- function(mds_result, rotation_degrees = NULL) {
  calibration <- amrc_fit_distance_calibration(mds_result)
  components <- amrc_mds_components(mds_result)
  calibrated <- components$conf * calibration$dilation

  if (!is.null(rotation_degrees)) {
    calibrated <- amrc_rotate_configuration(calibrated, rotation_degrees)
  }

  list(
    configuration = calibrated,
    dilation = calibration$dilation,
    fit = calibration$fit,
    distances = calibration$distances,
    rotation_degrees = rotation_degrees
  )
}
