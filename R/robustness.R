amrc_long_table_values <- function(table, lab_ids, value_name = "value") {
  matrix_table <- as.matrix(table)
  row_labels <- rownames(matrix_table)
  if (is.null(row_labels)) {
    row_labels <- as.character(seq_len(nrow(matrix_table)))
    rownames(matrix_table) <- row_labels
  }

  values <- as.data.frame(as.table(matrix_table), stringsAsFactors = FALSE)
  colnames(values) <- c("row_id", "drug", value_name)
  row_lookup <- stats::setNames(seq_along(row_labels), row_labels)
  values$LABID <- lab_ids[unname(row_lookup[as.character(values$row_id)])]
  values$row_id <- NULL
  values <- values[, c("LABID", "drug", value_name)]
  rownames(values) <- NULL
  values
}

amrc_true_value_long <- function(table, lab_ids) {
  amrc_long_table_values(table, lab_ids, value_name = "true_value")
}

amrc_weight_counts_from_na <- function(table) {
  na_count <- rowSums(is.na(table))
  max(na_count) - na_count + 1
}

amrc_pair_weight_matrix <- function(counts, square = TRUE) {
  weights <- outer(counts, counts, "*")
  diag(weights) <- 0

  if (isTRUE(square)) {
    weights <- weights * weights
  }

  weights
}

amrc_weight_matrix_from_na <- function(table, square = TRUE) {
  amrc_pair_weight_matrix(amrc_weight_counts_from_na(table), square = square)
}

amrc_simplify_mds_fit <- function(fit, lab_ids = NULL) {
  list(
    conf = as.matrix(fit$conf),
    stress = fit$stress,
    spp = as.numeric(fit$spp),
    lab_ids = lab_ids,
    fit = fit
  )
}

#' Run a Collection of MDS Fits
#'
#' @param distance_list List of `dist` objects.
#' @param weight_matrices Optional list of weight matrices.
#' @param lab_ids Optional character vector of isolate identifiers.
#' @param ndim Number of dimensions.
#' @param type Transformation type.
#' @param init Initialisation strategy.
#' @param ... Additional arguments passed to [amrc_compute_mds()].
#'
#' @return A list of simplified MDS fit objects.
#' @export
amrc_run_mds_collection <- function(
  distance_list,
  weight_matrices = NULL,
  lab_ids = NULL,
  ndim = 2,
  type = "ratio",
  init = "torgerson",
  ...
) {
  fits <- vector("list", length(distance_list))

  for (i in seq_along(distance_list)) {
    args <- list(
      distance_matrix = distance_list[[i]],
      ndim = ndim,
      type = type,
      init = init
    )

    if (!is.null(weight_matrices)) {
      args$weightmat <- weight_matrices[[i]]
    }

    fit <- do.call(amrc_compute_mds, c(args, list(...)))
    fits[[i]] <- amrc_simplify_mds_fit(fit, lab_ids = lab_ids)
  }

  fits
}

amrc_reference_configuration <- function(reference_mds, lab_ids, rotation_degrees = NULL) {
  configuration <- amrc_calibrate_mds(reference_mds, rotation_degrees = rotation_degrees)$configuration
  configuration <- as.data.frame(configuration)
  dimension_names <- paste0("D", seq_len(ncol(configuration)))
  colnames(configuration) <- dimension_names
  configuration$LABID <- lab_ids
  configuration[, c("LABID", dimension_names)]
}

#' Compare a Collection of MDS Fits to a Reference Configuration
#'
#' @param reference_configuration A calibrated reference configuration matrix or
#'   data frame.
#' @param fit_collection List of simplified MDS fits from
#'   [amrc_run_mds_collection()].
#' @param lab_ids Character vector of isolate identifiers.
#'
#' @return A list containing raw `comparisons`, a summary table, and per-isolate
#'   pairwise comparison distances.
#' @export
amrc_compare_procrustes_collection <- function(reference_configuration, fit_collection, lab_ids) {
  if (!requireNamespace("smacof", quietly = TRUE)) {
    stop(
      "Package 'smacof' is required for Procrustes comparisons. ",
      "Install it with tools/install_packages.R.",
      call. = FALSE
    )
  }

  if (is.data.frame(reference_configuration) &&
      "LABID" %in% colnames(reference_configuration)) {
    reference_configuration <- reference_configuration[, setdiff(colnames(reference_configuration), "LABID"), drop = FALSE]
  } else if (!is.null(colnames(reference_configuration)) &&
             "LABID" %in% colnames(reference_configuration)) {
    reference_configuration <- reference_configuration[, setdiff(colnames(reference_configuration), "LABID"), drop = FALSE]
  }
  reference_matrix <- as.matrix(reference_configuration)
  storage.mode(reference_matrix) <- "double"

  comparisons <- vector("list", length(fit_collection))
  summary_rows <- vector("list", length(fit_collection))
  pairwise_rows <- vector("list", length(fit_collection))

  for (i in seq_along(fit_collection)) {
    comparison <- smacof::Procrustes(reference_matrix, as.matrix(fit_collection[[i]]$conf))
    comparisons[[i]] <- comparison

    pairwise <- cbind(comparison$X, comparison$Yhat)
    pairwise <- as.data.frame(pairwise)
    colnames(pairwise) <- c(
      paste0("ref_D", seq_len(ncol(comparison$X))),
      paste0("alt_D", seq_len(ncol(comparison$Yhat)))
    )
    pairwise$dist_phen <- sqrt(rowSums((comparison$X - comparison$Yhat)^2))
    pairwise$LABID <- lab_ids
    pairwise$sample_id <- i
    pairwise_rows[[i]] <- pairwise

    summary_rows[[i]] <- data.frame(
      sample_id = i,
      congcoef = comparison$congcoef,
      aliencoef = comparison$aliencoef
    )
  }

  list(
    comparisons = comparisons,
    summary = do.call(rbind, summary_rows),
    pairwise = do.call(rbind, pairwise_rows)
  )
}

amrc_collect_spp_annotations <- function(fit_collection, lab_ids, annotation_list = NULL) {
  spp_rows <- vector("list", length(fit_collection))

  for (i in seq_along(fit_collection)) {
    spp_df <- data.frame(
      sample_id = i,
      LABID = lab_ids,
      spp = fit_collection[[i]]$spp
    )

    if (!is.null(annotation_list)) {
      spp_df <- merge(spp_df, annotation_list[[i]], by = "LABID", all.x = TRUE, sort = FALSE)
    }

    spp_rows[[i]] <- spp_df
  }

  do.call(rbind, spp_rows)
}

#' Cross-Validate Perturbed Maps Across Dimensions
#'
#' @param sample_distances List of perturbed `dist` objects.
#' @param reference_distance Reference `dist` object.
#' @param lab_ids Character vector of isolate identifiers.
#' @param weight_matrices Optional list of weight matrices.
#' @param dimensions Integer vector of dimensions to fit.
#' @param n_samples Number of perturbed samples to use.
#' @param type MDS transformation type.
#' @param init Initialisation strategy.
#' @param ... Additional arguments passed to [amrc_compute_mds()].
#'
#' @return A list containing per-dimension reference fits, perturbed fits, and
#'   summary error tables.
#' @export
amrc_cross_validate_robustness <- function(
  sample_distances,
  reference_distance,
  lab_ids,
  weight_matrices = NULL,
  dimensions = 1:4,
  n_samples = min(25, length(sample_distances)),
  type = "ratio",
  init = "torgerson",
  ...
) {
  if (!requireNamespace("smacof", quietly = TRUE)) {
    stop(
      "Package 'smacof' is required for Procrustes comparisons. ",
      "Install it with tools/install_packages.R.",
      call. = FALSE
    )
  }

  n_samples <- min(n_samples, length(sample_distances))
  sample_index <- seq_len(n_samples)

  reference_fits <- vector("list", length(dimensions))
  sample_fits <- vector("list", length(dimensions))
  reference_configurations <- vector("list", length(dimensions))
  names(reference_fits) <- as.character(dimensions)
  names(sample_fits) <- as.character(dimensions)
  names(reference_configurations) <- as.character(dimensions)

  pairwise_rows <- list()
  row_index <- 1L

  for (dimension in dimensions) {
    ref_fit <- amrc_compute_mds(
      distance_matrix = reference_distance,
      ndim = dimension,
      type = type,
      init = init,
      ...
    )
    reference_fits[[as.character(dimension)]] <- amrc_simplify_mds_fit(ref_fit, lab_ids = lab_ids)
    reference_configurations[[as.character(dimension)]] <- amrc_calibrate_mds(ref_fit)$configuration

    dim_fits <- vector("list", n_samples)
    for (i in sample_index) {
      args <- list(
        distance_matrix = sample_distances[[i]],
        ndim = dimension,
        type = type,
        init = init
      )
      if (!is.null(weight_matrices)) {
        args$weightmat <- weight_matrices[[i]]
      }
      fit <- do.call(amrc_compute_mds, c(args, list(...)))
      dim_fits[[i]] <- amrc_simplify_mds_fit(fit, lab_ids = lab_ids)

      comparison <- smacof::Procrustes(
        reference_configurations[[as.character(dimension)]],
        as.matrix(dim_fits[[i]]$conf)
      )

      pairwise_rows[[row_index]] <- data.frame(
        sample_id = i,
        dimension = dimension,
        LABID = lab_ids,
        dist_phen = sqrt(rowSums((comparison$X - comparison$Yhat)^2))
      )
      row_index <- row_index + 1L
    }
    sample_fits[[as.character(dimension)]] <- dim_fits
  }

  pairwise <- do.call(rbind, pairwise_rows)
  sample_summary <- stats::aggregate(
    dist_phen ~ sample_id + dimension,
    data = pairwise,
    FUN = function(x) mean(x, na.rm = TRUE)
  )

  dimension_split <- split(sample_summary$dist_phen, sample_summary$dimension)
  dimension_summary <- do.call(
    rbind,
    lapply(names(dimension_split), function(name) {
      x <- dimension_split[[name]]
      data.frame(
        dimension = as.integer(name),
        mean_dist_phen = mean(x, na.rm = TRUE),
        sd_dist_phen = stats::sd(x, na.rm = TRUE),
        se_dist_phen = stats::sd(x, na.rm = TRUE) / sqrt(length(x))
      )
    })
  )
  rownames(dimension_summary) <- NULL

  list(
    reference_fits = reference_fits,
    reference_configurations = reference_configurations,
    sample_fits = sample_fits,
    pairwise = pairwise,
    sample_summary = sample_summary,
    dimension_summary = dimension_summary
  )
}

amrc_legacy_dimension_objects <- function(cross_validation) {
  dimensions <- names(cross_validation$reference_fits)

  sample_fits <- lapply(dimensions, function(d) {
    cross_validation$sample_fits[[d]]
  })
  names(sample_fits) <- dimensions

  sample_confs <- lapply(sample_fits, function(fits) {
    lapply(fits, function(fit) as.data.frame(fit$conf))
  })

  sample_stress <- lapply(sample_fits, function(fits) {
    data.frame(value = vapply(fits, function(fit) fit$stress, numeric(1)))
  })

  reference_fits <- cross_validation$reference_fits
  reference_confs <- lapply(cross_validation$reference_configurations, function(conf) {
    conf <- as.data.frame(conf)
    colnames(conf) <- paste0("D", seq_len(ncol(conf)))
    conf
  })

  comparison_dim <- lapply(dimensions, function(d) {
    amrc_compare_procrustes_collection(
      reference_configuration = cross_validation$reference_configurations[[d]],
      fit_collection = sample_fits[[d]],
      lab_ids = sample_fits[[d]][[1]]$lab_ids
    )$comparisons
  })
  names(comparison_dim) <- dimensions

  list(
    sample_fits = sample_fits,
    sample_confs = sample_confs,
    sample_stress = sample_stress,
    reference_fits = reference_fits,
    reference_confs = reference_confs,
    comparison_dim = comparison_dim
  )
}

#' Run the Missing-Value Robustness Analysis
#'
#' @param tablemic Numeric MIC table.
#' @param tablemic_meta Metadata table containing `LABID`.
#' @param reference_mds Baseline MDS fit used as the reference map.
#' @param n_samples Number of perturbed datasets to generate.
#' @param missing_pct Percentage of cells to set to `NA` in each sample.
#' @param cross_validation_n Number of samples used for dimensional
#'   cross-validation.
#' @param seed Integer random seed.
#'
#' @return A structured list containing perturbed datasets, fitted maps, and
#'   summary tables suitable for plotting.
#' @export
amrc_missing_value_study <- function(
  tablemic,
  tablemic_meta,
  reference_mds,
  n_samples = 100,
  missing_pct = 10,
  cross_validation_n = 25,
  seed = 1234
) {
  tablemic <- as.data.frame(tablemic)
  lab_ids <- as.character(tablemic_meta$LABID)
  total_cells <- nrow(tablemic) * ncol(tablemic)
  target_missing <- floor(total_cells * missing_pct / 100)
  true_values <- amrc_true_value_long(tablemic, lab_ids)

  set.seed(seed)
  sample_tables <- vector("list", n_samples)
  sample_distances <- vector("list", n_samples)
  sample_values_long <- vector("list", n_samples)
  weight_matrices <- vector("list", n_samples)
  annotation_list <- vector("list", n_samples)

  for (i in seq_len(n_samples)) {
    sample_table <- as.matrix(tablemic)
    missing_cells <- sample(seq_len(total_cells), size = target_missing)
    sample_table[missing_cells] <- NA_real_
    sample_table <- as.data.frame(sample_table, stringsAsFactors = FALSE)
    colnames(sample_table) <- colnames(tablemic)

    sample_tables[[i]] <- sample_table
    sample_distances[[i]] <- stats::dist(sample_table)
    weight_matrices[[i]] <- amrc_weight_matrix_from_na(sample_table, square = TRUE)

    values_long <- amrc_long_table_values(sample_table, lab_ids, value_name = "MIC_value")
    values_long <- merge(values_long, true_values, by = c("LABID", "drug"), all.x = TRUE, sort = FALSE)
    values_long$sample_id <- i
    sample_values_long[[i]] <- values_long

    annotation_list[[i]] <- data.frame(
      LABID = lab_ids,
      missing_count = rowSums(is.na(sample_table))
    )
  }

  fits <- amrc_run_mds_collection(
    sample_distances,
    weight_matrices = weight_matrices,
    lab_ids = lab_ids,
    ndim = 2,
    type = "ratio"
  )

  reference_configuration <- amrc_reference_configuration(reference_mds, lab_ids)[, c("D1", "D2")]
  procrustes <- amrc_compare_procrustes_collection(reference_configuration, fits, lab_ids)
  stress_values <- data.frame(value = vapply(fits, function(fit) fit$stress, numeric(1)))
  stress_per_point <- amrc_collect_spp_annotations(fits, lab_ids, annotation_list = annotation_list)

  cross_validation <- amrc_cross_validate_robustness(
    sample_distances = sample_distances,
    reference_distance = stats::dist(tablemic),
    lab_ids = lab_ids,
    weight_matrices = weight_matrices,
    dimensions = 1:4,
    n_samples = cross_validation_n,
    type = "ratio"
  )
  legacy_dim <- amrc_legacy_dimension_objects(cross_validation)

  list(
    sample_tables = sample_tables,
    sample_distances = sample_distances,
    sample_values_long = sample_values_long,
    weight_matrices = weight_matrices,
    fits = fits,
    configurations = lapply(fits, function(fit) as.data.frame(fit$conf)),
    stress_values = stress_values,
    reference_configuration = as.data.frame(reference_configuration),
    procrustes = procrustes,
    stress_per_point = stress_per_point,
    cross_validation = cross_validation,
    missing_samples = sample_values_long,
    missing_samples_tables = sample_tables,
    missing_samples_dists = sample_distances,
    missing_samples_values = sample_values_long,
    missing_samples_weight_matrices = weight_matrices,
    missing_samples_mds_objects = fits,
    missing_samples_dists_confs = lapply(fits, function(fit) as.data.frame(fit$conf)),
    missing_samples_stress = stress_values,
    torg_met_conf = as.data.frame(reference_configuration),
    met_ord_comparison = procrustes$comparisons,
    met_ord_comparison_congcoef = data.frame(value = procrustes$summary$congcoef),
    met_ord_comparison_aliencoef = data.frame(value = procrustes$summary$aliencoef),
    stress_per_point_comparison = stress_per_point,
    missing_samples_dists_dimensions = legacy_dim$sample_fits,
    missing_samples_dists_confs_dim = legacy_dim$sample_confs,
    missing_samples_stress_dim = legacy_dim$sample_stress,
    torg_met_dimensions = legacy_dim$reference_fits,
    torg_met_dimensions_conf = legacy_dim$reference_confs,
    met_ord_comparison_dim = legacy_dim$comparison_dim
  )
}

#' Run the Noise-Added Robustness Analysis
#'
#' @param tablemic Numeric MIC table that has already been shifted onto a
#'   positive scale where thresholded values equal `threshold_value`.
#' @param tablemic_meta Metadata table containing `LABID`.
#' @param reference_mds Baseline MDS fit used as the reference map.
#' @param n_samples Number of perturbed datasets to generate.
#' @param perturb_pct Percentage of cells to sample for potential noise.
#' @param threshold_value Value representing thresholded measurements that should
#'   not be perturbed.
#' @param cross_validation_n Number of samples used for dimensional
#'   cross-validation.
#' @param seed Integer random seed.
#'
#' @return A structured list containing perturbed datasets, fitted maps, and
#'   summary tables suitable for plotting.
#' @export
amrc_noise_added_study <- function(
  tablemic,
  tablemic_meta,
  reference_mds,
  n_samples = 100,
  perturb_pct = 10,
  threshold_value = 1,
  cross_validation_n = 25,
  seed = 1234
) {
  tablemic <- as.data.frame(tablemic)
  lab_ids <- as.character(tablemic_meta$LABID)
  total_cells <- nrow(tablemic) * ncol(tablemic)
  target_cells <- floor(total_cells * perturb_pct / 100)
  true_values <- amrc_true_value_long(tablemic, lab_ids)

  set.seed(seed)
  noise_added_samples <- vector("list", n_samples)
  noise_tables <- vector("list", n_samples)
  sample_distances <- vector("list", n_samples)
  sample_values_long <- vector("list", n_samples)
  annotation_list <- vector("list", n_samples)

  for (i in seq_len(n_samples)) {
    sample_table <- tablemic
    error_table <- matrix(0, nrow = nrow(tablemic), ncol = ncol(tablemic))
    error_cells <- sample(seq_len(total_cells), size = target_cells)
    error_values <- sample(c(-1, 1), size = target_cells, replace = TRUE)
    error_table[error_cells] <- error_values

    eligible <- sample_table != threshold_value
    sample_table[eligible & error_table != 0] <- sample_table[eligible & error_table != 0] + error_table[eligible & error_table != 0]

    noise_added_samples[[i]] <- sample_table
    sample_distances[[i]] <- stats::dist(sample_table)

    noise_df <- data.frame(error_table)
    colnames(noise_df) <- colnames(tablemic)
    noise_long <- amrc_long_table_values(noise_df, lab_ids, value_name = "error_added")
    noise_long <- noise_long[noise_long$error_added != 0, , drop = FALSE]
    noise_long <- merge(noise_long, true_values, by = c("LABID", "drug"), all.x = TRUE, sort = FALSE)
    noise_long <- noise_long[noise_long$true_value != threshold_value, , drop = FALSE]
    noise_long$noise_added_value <- noise_long$true_value + noise_long$error_added
    noise_long$sample_id <- i
    noise_tables[[i]] <- noise_long

    values_long <- amrc_long_table_values(sample_table, lab_ids, value_name = "MIC_value")
    values_long <- merge(values_long, true_values, by = c("LABID", "drug"), all.x = TRUE, sort = FALSE)
    values_long$sample_id <- i
    sample_values_long[[i]] <- values_long

    annotation_list[[i]] <- data.frame(
      LABID = lab_ids,
      noise_count = rowSums(error_table != 0 & tablemic != threshold_value)
    )
  }

  fits <- amrc_run_mds_collection(
    sample_distances,
    lab_ids = lab_ids,
    ndim = 2,
    type = "ratio"
  )

  reference_configuration <- amrc_reference_configuration(reference_mds, lab_ids)[, c("D1", "D2")]
  procrustes <- amrc_compare_procrustes_collection(reference_configuration, fits, lab_ids)
  stress_values <- data.frame(value = vapply(fits, function(fit) fit$stress, numeric(1)))
  stress_per_point <- amrc_collect_spp_annotations(fits, lab_ids, annotation_list = annotation_list)

  cross_validation <- amrc_cross_validate_robustness(
    sample_distances = sample_distances,
    reference_distance = stats::dist(tablemic),
    lab_ids = lab_ids,
    dimensions = 1:4,
    n_samples = cross_validation_n,
    type = "ratio"
  )
  legacy_dim <- amrc_legacy_dimension_objects(cross_validation)

  list(
    sample_tables = noise_added_samples,
    sample_distances = sample_distances,
    perturbations_long = noise_tables,
    sample_values_long = sample_values_long,
    fits = fits,
    configurations = lapply(fits, function(fit) as.data.frame(fit$conf)),
    stress_values = stress_values,
    reference_configuration = as.data.frame(reference_configuration),
    procrustes = procrustes,
    stress_per_point = stress_per_point,
    cross_validation = cross_validation,
    noise_added_samples = noise_added_samples,
    noise = noise_tables,
    noise_added_samples_dists = sample_distances,
    noise_samples_mds_objects = fits,
    noise_samples_dists_confs = lapply(fits, function(fit) as.data.frame(fit$conf)),
    noise_samples_stress = stress_values,
    torg_met_conf = as.data.frame(reference_configuration),
    met_ord_comparison = procrustes$comparisons,
    met_ord_comparison_congcoef = data.frame(value = procrustes$summary$congcoef),
    met_ord_comparison_aliencoef = data.frame(value = procrustes$summary$aliencoef),
    stress_per_point_comparison = stress_per_point,
    noise_added_samples_dists_dimensions = legacy_dim$sample_fits,
    noise_added_samples_dists_confs_dim = legacy_dim$sample_confs,
    noise_added_samples_stress_dim = legacy_dim$sample_stress,
    torg_met_dimensions = legacy_dim$reference_fits,
    torg_met_dimensions_conf = legacy_dim$reference_confs,
    met_ord_comparison_dim = legacy_dim$comparison_dim
  )
}

amrc_disc_diffusion_breakpoints <- function() {
  list(
    Penicillin = function(x) ifelse(x <= 0.06, "S", "R"),
    Amoxicillin = function(x) ifelse(x <= 2, "S", ifelse(x == 4, "I", "R")),
    Meropenem = function(x) ifelse(x <= 0.25, "S", ifelse(x == 0.5, "I", "R")),
    Cefotaxime = function(x) ifelse(x <= 0.5, "S", ifelse(x == 1, "I", "R")),
    Ceftriaxone = function(x) ifelse(x <= 0.5, "S", ifelse(x == 1, "I", "R")),
    Cefuroxime = function(x) ifelse(x <= 0.5, "S", ifelse(x == 1, "I", "R"))
  )
}

amrc_mode_string <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

#' Run the Mixed MIC/Disc-Diffusion Robustness Analysis
#'
#' @param tablemic Numeric MIC table.
#' @param tablemic_meta Metadata table containing `LABID`.
#' @param reference_mds Baseline MDS fit used as the reference map.
#' @param n_samples Number of perturbed datasets to generate.
#' @param disc_pct Percentage of eligible isolates to replace with disc
#'   diffusion-like values.
#' @param cross_validation_n Number of samples used for dimensional
#'   cross-validation.
#' @param seed Integer random seed.
#'
#' @return A structured list containing perturbed datasets, fitted maps, and
#'   summary tables suitable for plotting.
#' @export
amrc_disc_diffusion_study <- function(
  tablemic,
  tablemic_meta,
  reference_mds,
  n_samples = 100,
  disc_pct = 10,
  cross_validation_n = 25,
  seed = 1234
) {
  tablemic <- as.data.frame(tablemic)
  lab_ids <- as.character(tablemic_meta$LABID)
  mic_meta <- as.data.frame(tablemic_meta)
  colnames(mic_meta)[3:8] <- paste0(colnames(tablemic), "_MIC")
  breakpoints <- amrc_disc_diffusion_breakpoints()
  true_values <- amrc_true_value_long(tablemic, lab_ids)

  set.seed(seed)
  bootstrap_samples <- vector("list", n_samples)
  disc_diffusion_samples <- vector("list", n_samples)
  bootstrap_samples_values <- vector("list", n_samples)
  bootstrap_samples_2 <- vector("list", n_samples)
  sample_distances <- vector("list", n_samples)
  weight_matrices <- vector("list", n_samples)
  annotation_list <- vector("list", n_samples)

  base_df <- cbind(data.frame(LABID = lab_ids), tablemic)
  base_df <- merge(base_df, mic_meta, by = "LABID", all.x = TRUE, sort = FALSE)

  for (i in seq_len(n_samples)) {
    sample_df <- base_df
    for (drug in colnames(tablemic)) {
      mic_col <- paste0(drug, "_MIC")
      sample_df[[mic_col]] <- breakpoints[[drug]](sample_df[[mic_col]])
    }

    res_comb <- apply(sample_df[, paste0(colnames(tablemic), "_MIC"), drop = FALSE], 1, paste, collapse = "_")
    dist_comb <- apply(sample_df[, colnames(tablemic), drop = FALSE], 1, paste, collapse = "_")
    freq <- table(res_comb)
    eligible <- res_comb %in% names(freq[freq != 1])

    eligible_ids <- sample_df$LABID[eligible]
    n_disc <- floor(sum(eligible) * disc_pct / 100)
    selected_ids <- if (n_disc > 0) sample(eligible_ids, size = n_disc) else character()

    sample_numeric <- sample_df[!sample_df$LABID %in% selected_ids, c("LABID", colnames(tablemic), paste0(colnames(tablemic), "_MIC")), drop = FALSE]
    sample_numeric$res_comb <- apply(sample_numeric[, paste0(colnames(tablemic), "_MIC"), drop = FALSE], 1, paste, collapse = "_")
    sample_numeric$dist_comb <- apply(sample_numeric[, colnames(tablemic), drop = FALSE], 1, paste, collapse = "_")

    combinations <- stats::aggregate(
      dist_comb ~ res_comb,
      data = sample_numeric,
      FUN = amrc_mode_string
    )

    selected_rows <- sample_df[sample_df$LABID %in% selected_ids, c("LABID", paste0(colnames(tablemic), "_MIC")), drop = FALSE]
    selected_rows$res_comb <- apply(selected_rows[, paste0(colnames(tablemic), "_MIC"), drop = FALSE], 1, paste, collapse = "_")
    selected_rows <- merge(selected_rows, combinations, by = "res_comb", all.x = TRUE, sort = FALSE)
    if (nrow(selected_rows) > 0 && anyNA(selected_rows$dist_comb)) {
      fallback <- apply(
        sample_df[sample_df$LABID %in% selected_rows$LABID, colnames(tablemic), drop = FALSE],
        1,
        paste,
        collapse = "_"
      )
      selected_rows$dist_comb[is.na(selected_rows$dist_comb)] <- fallback[is.na(selected_rows$dist_comb)]
    }

    if (nrow(selected_rows) > 0) {
      reconstructed <- do.call(rbind, strsplit(selected_rows$dist_comb, "_", fixed = TRUE))
      reconstructed <- as.data.frame(reconstructed, stringsAsFactors = FALSE)
      colnames(reconstructed) <- colnames(tablemic)
      for (drug in colnames(tablemic)) {
        reconstructed[[drug]] <- as.numeric(reconstructed[[drug]])
      }
      selected_numeric <- cbind(data.frame(LABID = selected_rows$LABID), reconstructed)
    } else {
      selected_numeric <- data.frame(LABID = character())
      for (drug in colnames(tablemic)) {
        selected_numeric[[drug]] <- numeric()
      }
    }

    combined_sample <- rbind(
      sample_df[!sample_df$LABID %in% selected_ids, c("LABID", colnames(tablemic)), drop = FALSE],
      selected_numeric
    )
    combined_sample <- merge(data.frame(LABID = lab_ids), combined_sample, by = "LABID", all.x = TRUE, sort = FALSE)

    bootstrap_samples[[i]] <- combined_sample
    sample_distances[[i]] <- stats::dist(combined_sample[, colnames(tablemic), drop = FALSE])

    values_sample <- combined_sample
    values_sample[values_sample$LABID %in% selected_ids, colnames(tablemic)] <- NA
    bootstrap_samples_2[[i]] <- values_sample
    weight_matrices[[i]] <- amrc_weight_matrix_from_na(values_sample[, colnames(tablemic), drop = FALSE], square = TRUE)

    value_long <- amrc_long_table_values(values_sample[, colnames(tablemic), drop = FALSE], lab_ids, value_name = "MIC_value")
    value_long <- merge(value_long, true_values, by = c("LABID", "drug"), all.x = TRUE, sort = FALSE)
    value_long$sample_id <- i
    bootstrap_samples_values[[i]] <- value_long

    disc_df <- data.frame(
      LABID = lab_ids,
      disc_diffusion_count = ifelse(lab_ids %in% selected_ids, ncol(tablemic), 0)
    )
    annotation_list[[i]] <- disc_df
    disc_diffusion_samples[[i]] <- data.frame(LABID = selected_ids)
  }

  fits <- amrc_run_mds_collection(
    sample_distances,
    weight_matrices = weight_matrices,
    lab_ids = lab_ids,
    ndim = 2,
    type = "ratio"
  )

  reference_configuration <- amrc_reference_configuration(reference_mds, lab_ids)[, c("D1", "D2")]
  procrustes <- amrc_compare_procrustes_collection(reference_configuration, fits, lab_ids)
  stress_values <- data.frame(value = vapply(fits, function(fit) fit$stress, numeric(1)))
  stress_per_point <- amrc_collect_spp_annotations(fits, lab_ids, annotation_list = annotation_list)

  cross_validation <- amrc_cross_validate_robustness(
    sample_distances = sample_distances,
    reference_distance = stats::dist(tablemic),
    lab_ids = lab_ids,
    weight_matrices = weight_matrices,
    dimensions = 1:4,
    n_samples = cross_validation_n,
    type = "ratio"
  )
  legacy_dim <- amrc_legacy_dimension_objects(cross_validation)

  list(
    sample_tables = bootstrap_samples,
    sample_distances = sample_distances,
    sample_values_long = bootstrap_samples_values,
    weight_matrices = weight_matrices,
    fits = fits,
    configurations = lapply(fits, function(fit) as.data.frame(fit$conf)),
    stress_values = stress_values,
    reference_configuration = as.data.frame(reference_configuration),
    procrustes = procrustes,
    stress_per_point = stress_per_point,
    cross_validation = cross_validation,
    bootstrap_samples = bootstrap_samples,
    bootstrap_samples_dists = sample_distances,
    bootstrap_samples_values = bootstrap_samples_values,
    bootstrap_samples_weight_matrices = weight_matrices,
    bootstrap_samples_dists_mds = fits,
    bootstrap_samples_dists_confs = lapply(fits, function(fit) as.data.frame(fit$conf)),
    bootstrap_samples_stress = stress_values,
    disc_diffusion_samples = disc_diffusion_samples,
    torg_met_conf = as.data.frame(reference_configuration),
    met_ord_comparison = procrustes$comparisons,
    met_ord_comparison_congcoef = data.frame(value = procrustes$summary$congcoef),
    met_ord_comparison_aliencoef = data.frame(value = procrustes$summary$aliencoef),
    stress_per_point_comp = stress_per_point,
    bootstrap_samples_dists_dimensions = legacy_dim$sample_fits,
    bootstrap_samples_dists_confs_dim = legacy_dim$sample_confs,
    bootstrap_samples_stress_dim = legacy_dim$sample_stress,
    torg_met_dimensions = legacy_dim$reference_fits,
    torg_met_dimensions_conf = legacy_dim$reference_confs,
    met_ord_comparison_dim = legacy_dim$comparison_dim
  )
}

#' Run the Threshold-Value Robustness Analysis
#'
#' @param tablemic Numeric MIC table that has already been shifted onto a
#'   positive scale where thresholded values equal `threshold_value`.
#' @param tablemic_meta Metadata table containing `LABID`.
#' @param reference_mds Baseline MDS fit used as the reference map.
#' @param threshold_value Numeric value denoting a thresholded MIC.
#' @param weighted_repeats Number of repeated weighted fits to run.
#' @param seed Integer random seed.
#'
#' @return A structured list of threshold-related comparison fits and summary
#'   objects.
#' @export
amrc_threshold_effect_study <- function(
  tablemic,
  tablemic_meta,
  reference_mds,
  threshold_value = 1,
  weighted_repeats = 10,
  seed = 1234
) {
  tablemic <- as.data.frame(tablemic)
  lab_ids <- as.character(tablemic_meta$LABID)
  base_reference <- amrc_reference_configuration(reference_mds, lab_ids)[, c("LABID", "D1", "D2")]
  threshold_count <- rowSums(tablemic == threshold_value, na.rm = TRUE)
  numeric_count <- rowSums(tablemic != threshold_value, na.rm = TRUE)

  fit_subset <- function(keep) {
    fit <- amrc_compute_mds(stats::dist(tablemic[keep, , drop = FALSE]), ndim = 2, type = "ratio", init = "torgerson", modulus = 1, itmax = 1000, eps = 1e-06)
    list(
      keep = keep,
      fit = fit,
      conf = as.data.frame(fit$conf),
      lab_ids = lab_ids[keep]
    )
  }

  exclude_all <- fit_subset(numeric_count >= 1)
  exclude_two <- fit_subset(numeric_count >= 2)

  compare_subset <- function(subset_fit) {
    ref_subset <- base_reference[base_reference$LABID %in% subset_fit$lab_ids, , drop = FALSE]
    ref_subset <- ref_subset[match(subset_fit$lab_ids, ref_subset$LABID), c("D1", "D2"), drop = FALSE]
    amrc_compare_procrustes_collection(ref_subset, list(amrc_simplify_mds_fit(subset_fit$fit, lab_ids = subset_fit$lab_ids)), subset_fit$lab_ids)
  }

  metric_subset_all <- compare_subset(exclude_all)
  metric_subset_two <- compare_subset(exclude_two)

  ordinal_fit <- amrc_compute_mds(stats::dist(tablemic), ndim = 2, type = "ordinal", ties = "secondary", init = "torgerson", modulus = 1, itmax = 1000, eps = 1e-06)
  threshold_weights <- amrc_pair_weight_matrix(numeric_count + 1, square = FALSE)

  set.seed(seed)
  weighted_metric <- amrc_run_mds_collection(
    distance_list = rep(list(stats::dist(tablemic)), weighted_repeats),
    weight_matrices = rep(list(threshold_weights), weighted_repeats),
    lab_ids = lab_ids,
    ndim = 2,
    type = "ratio",
    init = "torgerson",
    modulus = 1,
    itmax = 10000,
    eps = 1e-06
  )
  weighted_metric_best <- weighted_metric[[which.min(vapply(weighted_metric, function(x) x$stress, numeric(1)))]]

  weighted_ordinal <- amrc_run_mds_collection(
    distance_list = rep(list(stats::dist(tablemic)), weighted_repeats),
    weight_matrices = rep(list(threshold_weights), weighted_repeats),
    lab_ids = lab_ids,
    ndim = 2,
    type = "ordinal",
    init = "torgerson",
    ties = "secondary",
    modulus = 1,
    itmax = 10000,
    eps = 1e-06
  )
  weighted_ordinal_best <- weighted_ordinal[[which.min(vapply(weighted_ordinal, function(x) x$stress, numeric(1)))]]

  base_metric_conf <- base_reference[, c("D1", "D2"), drop = FALSE]
  base_ordinal_conf <- as.data.frame(ordinal_fit$conf)
  colnames(base_ordinal_conf) <- c("D1", "D2")

  metric_weight_comparison <- amrc_compare_procrustes_collection(
    base_metric_conf,
    list(weighted_metric_best),
    lab_ids
  )
  ordinal_weight_comparison <- amrc_compare_procrustes_collection(
    base_ordinal_conf,
    list(weighted_ordinal_best),
    lab_ids
  )
  metric_ordinal_comparison <- amrc_compare_procrustes_collection(
    base_metric_conf,
    list(amrc_simplify_mds_fit(ordinal_fit, lab_ids = lab_ids)),
    lab_ids
  )

  list(
    base_reference = base_reference,
    exclude_all_thresholds = exclude_all,
    exclude_two_thresholds = exclude_two,
    exclude_all_comparison = metric_subset_all,
    exclude_two_comparison = metric_subset_two,
    ordinal_fit = amrc_simplify_mds_fit(ordinal_fit, lab_ids = lab_ids),
    threshold_weights = threshold_weights,
    weighted_metric_fit = weighted_metric_best,
    weighted_ordinal_fit = weighted_ordinal_best,
    metric_weight_comparison = metric_weight_comparison,
    ordinal_weight_comparison = ordinal_weight_comparison,
    metric_ordinal_comparison = metric_ordinal_comparison
  )
}
