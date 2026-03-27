amrc_mds_components <- function(mds_result) {
  delta <- mds_result$delta
  confdist <- mds_result$confdist
  configuration <- mds_result$conf

  if (is.null(delta)) {
    delta <- mds_result[[1]]
  }
  if (is.null(configuration)) {
    configuration <- mds_result[[2]]
  }
  if (is.null(confdist)) {
    confdist <- mds_result[[3]]
  }

  if (is.null(delta) || is.null(configuration) || is.null(confdist)) {
    stop(
      "Could not extract delta, configuration, and map distances from the MDS result.",
      call. = FALSE
    )
  }

  list(
    delta = delta,
    conf = as.matrix(configuration),
    confdist = confdist
  )
}

#' Extract Pairwise Table and Map Distances from an MDS Fit
#'
#' Returns the original distances and fitted map distances in a single tidy
#' `data.frame`, which replaces the repeated reshaping code in the legacy
#' goodness-of-fit notebooks.
#'
#' @param mds_result A result from `amrc_compute_mds()` or `smacof::mds()`.
#'
#' @return A `data.frame` with `table_distance` and `map_distance` columns.
#' @export
amrc_mds_pairwise_distances <- function(mds_result) {
  components <- amrc_mds_components(mds_result)

  data.frame(
    table_distance = as.numeric(stats::as.dist(components$delta)),
    map_distance = as.numeric(stats::as.dist(components$confdist))
  )
}

#' Fit the Table-vs-Map Distance Calibration Model
#'
#' Fits the linear model used throughout the legacy notebooks to calibrate map
#' distances back onto the original measurement scale.
#'
#' @param mds_result A result from `amrc_compute_mds()` or `smacof::mds()`.
#'
#' @return A list with the pairwise `distances`, fitted model `fit`, and the
#'   implied `dilation` factor.
#' @export
amrc_fit_distance_calibration <- function(mds_result) {
  distances <- amrc_mds_pairwise_distances(mds_result)
  fit <- stats::lm(map_distance ~ table_distance, data = distances)
  slope <- unname(stats::coef(fit)[2])

  if (is.na(slope) || slope == 0) {
    stop("Could not estimate a non-zero slope for MDS calibration.", call. = FALSE)
  }

  dilation <- 1 / slope
  distances$map_distance_scaled <- distances$map_distance * dilation
  distances$residual <- distances$table_distance - distances$map_distance_scaled
  distances$abs_residual <- abs(distances$residual)

  list(
    distances = distances,
    fit = fit,
    slope = slope,
    dilation = dilation
  )
}

#' Summarise MDS Residual Error Bands
#'
#' @param x Either an MDS result or a `data.frame` created by
#'   `amrc_fit_distance_calibration()$distances`.
#' @param thresholds Numeric vector of residual thresholds to summarise.
#'
#' @return A one-row `data.frame` with mean absolute residuals, standard
#'   deviation, and percentages above each threshold.
#' @export
amrc_residual_summary <- function(x, thresholds = c(1, 2)) {
  distances <- if (is.data.frame(x)) {
    x
  } else {
    amrc_fit_distance_calibration(x)$distances
  }

  summary_df <- data.frame(
    mean_abs_residual = mean(distances$abs_residual, na.rm = TRUE),
    sd_abs_residual = stats::sd(distances$abs_residual, na.rm = TRUE)
  )

  for (threshold in thresholds) {
    column_name <- paste0("pct_abs_residual_gt_", format(threshold, trim = TRUE))
    summary_df[[column_name]] <- mean(distances$abs_residual > threshold, na.rm = TRUE) * 100
  }

  summary_df
}

#' Summarise Stress-per-Point from an MDS Fit
#'
#' @param mds_result A result from `amrc_compute_mds()` or `smacof::mds()`.
#'
#' @return A one-row `data.frame` containing mean, standard deviation, minimum,
#'   and maximum stress-per-point values.
#' @export
amrc_stress_per_point_summary <- function(mds_result) {
  spp <- as.numeric(mds_result$spp)

  if (length(spp) == 0) {
    stop("The MDS result does not contain stress-per-point values.", call. = FALSE)
  }

  data.frame(
    mean_spp = mean(spp, na.rm = TRUE),
    sd_spp = stats::sd(spp, na.rm = TRUE),
    min_spp = min(spp, na.rm = TRUE),
    max_spp = max(spp, na.rm = TRUE)
  )
}

#' Build a Reusable Goodness-of-Fit Report for an MDS Solution
#'
#' Aggregates the repeated goodness-of-fit calculations used across the legacy
#' notebooks into one structured object.
#'
#' @param mds_result A result from `amrc_compute_mds()` or `smacof::mds()`.
#' @param thresholds Numeric vector of residual thresholds to summarise.
#' @param rotation_degrees Optional rotation applied to the calibrated
#'   configuration.
#' @param correlation_method Correlation method passed to [stats::cor.test()].
#'
#' @return A list containing the calibrated configuration, linear fit,
#'   pairwise-distance table, residual summary, stress summary, correlation
#'   test, and model `r_squared`.
#' @export
amrc_map_fit_report <- function(
  mds_result,
  thresholds = c(1, 2),
  rotation_degrees = NULL,
  correlation_method = "pearson"
) {
  calibration <- amrc_fit_distance_calibration(mds_result)
  calibrated <- amrc_calibrate_mds(mds_result, rotation_degrees = rotation_degrees)

  list(
    configuration = calibrated$configuration,
    fit = calibration$fit,
    dilation = calibration$dilation,
    distances = calibration$distances,
    residual_summary = amrc_residual_summary(calibration$distances, thresholds = thresholds),
    stress_summary = amrc_stress_per_point_summary(mds_result),
    correlation = stats::cor.test(
      calibration$distances$table_distance,
      calibration$distances$map_distance,
      method = correlation_method
    ),
    r_squared = summary(calibration$fit)$r.squared
  )
}
