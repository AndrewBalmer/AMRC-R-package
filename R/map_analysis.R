#' Summarise an MDS Dimensionality Sweep
#'
#' Converts the long-form output of [amrc_run_dimensionality_sweep()] into a
#' wide summary table with sequential stress-drop percentages.
#'
#' @param sweep_results A `data.frame` returned by
#'   [amrc_run_dimensionality_sweep()].
#'
#' @return A list with `long` and `summary` `data.frame`s.
#' @export
amrc_summarise_dimension_sweep <- function(sweep_results) {
  if (!all(c("method", "dimension", "stress") %in% colnames(sweep_results))) {
    stop("sweep_results must contain method, dimension, and stress columns.", call. = FALSE)
  }

  dims <- sort(unique(sweep_results$dimension))
  wide <- stats::reshape(
    sweep_results[, c("method", "dimension", "stress")],
    idvar = "method",
    timevar = "dimension",
    direction = "wide"
  )

  colnames(wide) <- sub("^stress\\.", "D", colnames(wide))
  baseline_col <- paste0("D", dims[[1]])

  for (i in seq_len(length(dims) - 1L)) {
    from_dim <- dims[[i]]
    to_dim <- dims[[i + 1L]]
    from_col <- paste0("D", from_dim)
    to_col <- paste0("D", to_dim)
    drop_col <- paste0("drop_", from_dim, "Dto", to_dim, "D")

    wide[[drop_col]] <- round(
      (wide[[from_col]] - wide[[to_col]]) / wide[[baseline_col]] * 100,
      3
    )
  }

  list(
    long = sweep_results,
    summary = wide
  )
}

#' Cluster Restart Solutions from `smacof::icExplore()`
#'
#' @param exploration An object returned by `smacof::icExplore(..., returnfit =
#'   TRUE)`.
#' @param n_clusters Integer number of clusters to cut from the dendrogram.
#' @param distance_method Distance metric used on the exploration coordinates.
#' @param cluster_method Linkage method passed to [stats::hclust()].
#'
#' @return A list containing the restart distance matrix, hierarchical
#'   clustering object, cluster assignments, selected representative fits, and a
#'   `selected` summary table.
#' @export
amrc_cluster_restart_solutions <- function(
  exploration,
  n_clusters = 4,
  distance_method = "euclidean",
  cluster_method = "ward.D2"
) {
  if (is.null(exploration$conf) || is.null(exploration$stressvec)) {
    stop("exploration must contain conf and stressvec elements.", call. = FALSE)
  }

  dd <- stats::dist(exploration$conf, method = distance_method)
  hc <- stats::hclust(dd, method = cluster_method)
  clusters <- stats::cutree(hc, n_clusters)

  selected <- data.frame(
    ID = seq_along(exploration$stressvec),
    Stress = as.numeric(exploration$stressvec),
    Cluster = clusters
  )
  selected <- do.call(
    rbind,
    lapply(split(selected, selected$Cluster), function(df) {
      df[which.min(df$Stress), , drop = FALSE]
    })
  )
  selected <- selected[order(selected$Cluster), , drop = FALSE]
  rownames(selected) <- NULL

  representative_fits <- NULL
  if (length(exploration) >= 1 && is.list(exploration[[1]])) {
    representative_fits <- exploration[[1]][selected$ID]
  }

  list(
    distance = dd,
    hclust = hc,
    clusters = clusters,
    selected = selected,
    representative_fits = representative_fits
  )
}

#' Build a Dimension-by-Dimension Fit Summary Table
#'
#' Fits a series of MDS solutions across dimensions and summarises stress and
#' residual behaviour in a compact results table.
#'
#' @param distance_matrix A `dist` object or matrix coercible to `dist`.
#' @param dimensions Integer vector of dimensions to evaluate.
#' @param type MDS transformation type.
#' @param thresholds Two numeric thresholds used for residual-band summaries.
#' @param ... Additional arguments passed to [amrc_compute_mds()].
#'
#' @return A list with `results`, `fits`, and `residuals`.
#' @export
amrc_build_dimension_fit_table <- function(
  distance_matrix,
  dimensions = 1:5,
  type = "ratio",
  thresholds = c(1, 2),
  ...
) {
  if (length(thresholds) != 2) {
    stop("thresholds must contain exactly two numeric values.", call. = FALSE)
  }

  fits <- vector("list", length(dimensions))
  residuals <- vector("list", length(dimensions))
  names(fits) <- as.character(dimensions)
  names(residuals) <- as.character(dimensions)
  results <- vector("list", length(dimensions))

  baseline_stress <- NULL

  for (i in seq_along(dimensions)) {
    dimension <- dimensions[[i]]
    fit <- amrc_compute_mds(
      distance_matrix = distance_matrix,
      ndim = dimension,
      type = type,
      ...
    )
    calibration <- amrc_fit_distance_calibration(fit)
    abs_residual <- calibration$distances$abs_residual

    if (is.null(baseline_stress)) {
      baseline_stress <- fit$stress
    }

    fits[[i]] <- fit
    residuals[[i]] <- calibration$distances$residual
    results[[i]] <- data.frame(
      dimension = dimension,
      stress_per_point_pct = round(mean(as.numeric(fit$spp), na.rm = TRUE), 3),
      stress_drop_vs_baseline_pct = if (identical(dimension, dimensions[[1]])) {
        0
      } else {
        round(100 * (baseline_stress - fit$stress) / baseline_stress, 3)
      },
      mean_abs_residual = round(mean(abs_residual, na.rm = TRUE), 3),
      sd_abs_residual = round(stats::sd(abs_residual, na.rm = TRUE), 3),
      pct_abs_residual_lt_first = round(mean(abs_residual < thresholds[[1]], na.rm = TRUE) * 100, 3),
      pct_abs_residual_between = round(
        mean(abs_residual >= thresholds[[1]] & abs_residual < thresholds[[2]], na.rm = TRUE) * 100,
        3
      ),
      pct_abs_residual_ge_second = round(mean(abs_residual >= thresholds[[2]], na.rm = TRUE) * 100, 3),
      paired_t_p_vs_previous = NA_real_
    )
  }

  if (length(residuals) > 1) {
    for (i in 2:length(residuals)) {
      results[[i]]$paired_t_p_vs_previous <- signif(
        stats::t.test(residuals[[i]], residuals[[i - 1L]], paired = TRUE)$p.value,
        3
      )
    }
  }

  list(
    results = do.call(rbind, results),
    fits = fits,
    residuals = residuals
  )
}

#' Compare Adjacent-Dimension Projections
#'
#' Uses Procrustes alignment to quantify how far isolate positions move when a
#' lower-dimensional solution is projected into the next-highest dimension.
#'
#' @param mds_fits A list of MDS fit objects, typically from
#'   [amrc_build_dimension_fit_table()]$fits.
#' @param lab_ids Character vector of isolate identifiers.
#' @param compare_dims Integer vector of dimensions to compare against the next
#'   lower dimension.
#'
#' @return A list with per-isolate `projection_distances` and a `summary`
#'   `data.frame`.
#' @export
amrc_compare_adjacent_dimensions <- function(
  mds_fits,
  lab_ids,
  compare_dims = 2:length(mds_fits)
) {
  if (!requireNamespace("smacof", quietly = TRUE)) {
    stop(
      "Package 'smacof' is required for Procrustes comparisons. ",
      "Install it with tools/install_packages.R.",
      call. = FALSE
    )
  }

  projection_rows <- vector("list", length(compare_dims))

  for (i in seq_along(compare_dims)) {
    dimension <- compare_dims[[i]]
    fit_high <- mds_fits[[as.character(dimension)]]
    fit_low <- mds_fits[[as.character(dimension - 1L)]]

    if (is.null(fit_high) || is.null(fit_low)) {
      stop("Missing MDS fits for dimensions ", dimension, " and/or ", dimension - 1L, ".", call. = FALSE)
    }

    dilation <- amrc_fit_distance_calibration(fit_high)$dilation
    map_high <- as.matrix(fit_high$conf) * dilation
    map_low <- as.matrix(fit_low$conf) * dilation
    pad_dims <- ncol(map_high) - ncol(map_low)
    map_low_padded <- cbind(map_low, matrix(0, nrow = nrow(map_low), ncol = pad_dims))

    proc <- smacof::Procrustes(map_high, map_low_padded)
    dist_to_lower <- sqrt((proc$X[, 1] - proc$Yhat[, 1])^2 + (proc$X[, 2] - proc$Yhat[, 2])^2)

    projection_rows[[i]] <- data.frame(
      LABID = lab_ids,
      dimension = dimension,
      dist_to_lower_dim = dist_to_lower
    )
  }

  projection_distances <- do.call(rbind, projection_rows)
  summary <- stats::aggregate(
    dist_to_lower_dim ~ dimension,
    data = projection_distances,
    FUN = function(x) round(mean(x, na.rm = TRUE), 3)
  )
  colnames(summary) <- c("dimension", "mean_projection_error")

  list(
    projection_distances = projection_distances,
    summary = summary
  )
}
