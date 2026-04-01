#' Default S. pneumoniae PBP-deletion Isolates to Exclude
#'
#' Returns the isolate identifiers excluded from the original manuscript-era
#' comparison notebooks because they carry large PBP indels that distort the
#' phenotype/genotype comparison plots.
#'
#' @return A character vector of isolate identifiers.
#' @export
amrc_default_pbp_deletion_labids <- function() {
  c(
    "20156696", "20162849", "20151885", "20153985", "20154509",
    "2013224047", "2013218247", "2014200662", "5869-99", "2513-99"
  )
}

amrc_require_coordinate_columns <- function(data, columns, arg_name = "data") {
  missing_columns <- setdiff(columns, colnames(data))
  if (length(missing_columns) > 0) {
    stop(
      arg_name,
      " is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(columns)
}

amrc_within_cluster_inertia <- function(coords, clusters) {
  split_index <- split(seq_len(nrow(coords)), clusters)
  inertia <- vapply(split_index, function(index) {
    cluster_coords <- coords[index, , drop = FALSE]
    centroid <- colMeans(cluster_coords)
    sum(rowSums((cluster_coords - matrix(
      centroid,
      nrow = nrow(cluster_coords),
      ncol = ncol(cluster_coords),
      byrow = TRUE
    ))^2))
  }, numeric(1))

  sum(inertia)
}

amrc_between_group_distances <- function(group_a, group_b) {
  group_a <- as.matrix(group_a)
  group_b <- as.matrix(group_b)
  if (ncol(group_a) != ncol(group_b)) {
    stop("group_a and group_b must have the same number of columns.", call. = FALSE)
  }

  distances <- vapply(seq_len(nrow(group_a)), function(i) {
    sqrt(rowSums((group_b - matrix(
      group_a[i, ],
      nrow = nrow(group_b),
      ncol = ncol(group_b),
      byrow = TRUE
    ))^2))
  }, numeric(nrow(group_b)))

  as.vector(distances)
}

amrc_summary_function <- function(summary_fun) {
  if (is.function(summary_fun)) {
    return(summary_fun)
  }

  if (is.character(summary_fun) && length(summary_fun) == 1L && !is.na(summary_fun)) {
    if (identical(summary_fun, "median")) {
      return(stats::median)
    }
    if (identical(summary_fun, "mean")) {
      return(base::mean)
    }
  }

  stop("summary_fun must be a function or one of 'median' or 'mean'.", call. = FALSE)
}

amrc_resolve_optional_external_cols <- function(data, external_cols = NULL, genotype_cols = NULL) {
  if (!is.null(external_cols) || !is.null(genotype_cols)) {
    return(amrc_resolve_external_coord_cols(
      data = data,
      external_cols = external_cols,
      genotype_cols = genotype_cols
    ))
  }

  if (all(c("E1", "E2") %in% colnames(data))) {
    return(c("E1", "E2"))
  }
  if (all(c("G1", "G2") %in% colnames(data))) {
    return(c("G1", "G2"))
  }

  NULL
}

amrc_mds_labels <- function(mds_result) {
  components <- amrc_mds_components(mds_result)
  labels <- amrc_distance_labels(components$delta)

  if (is.null(labels) || length(labels) == 0) {
    labels <- rownames(components$conf)
  }

  if (is.null(labels) || length(labels) == 0) {
    return(NULL)
  }

  as.character(labels)
}

amrc_prepare_configuration_table <- function(
  mds_result,
  coord_names,
  rotation_degrees = NULL,
  label_col = ".amrc_id"
) {
  calibration <- amrc_calibrate_mds(
    mds_result,
    rotation_degrees = rotation_degrees
  )

  configuration <- as.data.frame(calibration$configuration)
  if (length(coord_names) != ncol(configuration)) {
    stop(
      "coord_names must have length ",
      ncol(configuration),
      " to match the map dimensionality.",
      call. = FALSE
    )
  }

  colnames(configuration) <- coord_names

  labels <- amrc_mds_labels(mds_result)
  if (!is.null(labels)) {
    if (length(labels) != nrow(configuration)) {
      stop("Could not align MDS labels to the calibrated configuration.", call. = FALSE)
    }
    configuration[[label_col]] <- labels
  }

  list(
    data = configuration,
    calibration = calibration,
    labels = labels
  )
}

amrc_align_rows_by_id <- function(data, id_col, target_ids, data_name = "data") {
  ids <- as.character(data[[id_col]])
  if (anyDuplicated(ids) > 0) {
    stop(
      data_name,
      " must contain unique values in column '",
      id_col,
      "'.",
      call. = FALSE
    )
  }

  match_index <- match(target_ids, ids)
  if (anyNA(match_index)) {
    missing_ids <- unique(target_ids[is.na(match_index)])
    missing_ids <- missing_ids[seq_len(min(length(missing_ids), 5L))]
    stop(
      data_name,
      " is missing identifiers required by the map data: ",
      paste(missing_ids, collapse = ", "),
      call. = FALSE
    )
  }

  aligned <- data[match_index, , drop = FALSE]
  rownames(aligned) <- NULL
  aligned
}

amrc_align_configuration_rows <- function(
  configuration_data,
  target_ids,
  label_col = ".amrc_id",
  data_name = "configuration_data"
) {
  if (!(label_col %in% colnames(configuration_data))) {
    if (nrow(configuration_data) != length(target_ids)) {
      stop(
        data_name,
        " must either contain explicit labels or match the metadata row count.",
        call. = FALSE
      )
    }

    aligned <- configuration_data
  } else {
    aligned <- amrc_align_rows_by_id(
      data = configuration_data,
      id_col = label_col,
      target_ids = target_ids,
      data_name = data_name
    )
    aligned[[label_col]] <- NULL
  }

  rownames(aligned) <- NULL
  aligned
}

amrc_attach_group_centroids <- function(
  data,
  group_col,
  coord_cols,
  centroid_cols
) {
  data$.amrc_row_index <- seq_len(nrow(data))

  centroid_parts <- Map(function(coord_col, centroid_col) {
    centroid <- stats::aggregate(
      data[[coord_col]],
      by = list(data[[group_col]]),
      FUN = stats::median
    )
    colnames(centroid) <- c(group_col, centroid_col)
    centroid
  }, coord_cols, centroid_cols)

  centroid_data <- Reduce(function(x, y) {
    merge(x, y, by = group_col, sort = FALSE)
  }, centroid_parts)

  merged <- merge(
    data,
    centroid_data,
    by = group_col,
    all.x = TRUE,
    sort = FALSE
  )

  merged <- merged[order(merged$.amrc_row_index), , drop = FALSE]
  merged$.amrc_row_index <- NULL
  rownames(merged) <- NULL

  merged
}

#' Prepare a Generic Phenotype/External Map Comparison Table
#'
#' Calibrates one phenotype map and one external map onto interpretable scales,
#' aligns them to a shared metadata table, and returns a combined comparison
#' object that downstream clustering, plotting, and summary helpers can reuse.
#'
#' This is the generic comparison-preparation entry point. Organism-specific
#' helpers such as [amrc_prepare_spneumoniae_map_data()] should wrap this
#' function rather than reimplementing the join logic themselves.
#'
#' @param metadata A metadata `data.frame` containing at least the isolate ID
#'   column and any optional grouping columns.
#' @param phenotype_mds Phenotype MDS fit.
#' @param external_mds External MDS fit, for example from a genotype or
#'   phylogenetic distance structure.
#' @param id_col Name of the isolate identifier column in `metadata`.
#' @param group_col Optional grouping column used to compute centroid summaries,
#'   for example lineage or strain type.
#' @param group_output_col Optional output name for `group_col`. Defaults to the
#'   same value as `group_col`.
#' @param phenotype_rotation_degrees Optional rotation applied to the phenotype
#'   map after calibration.
#' @param external_rotation_degrees Optional rotation applied to the external
#'   map after calibration.
#' @param exclude_ids Optional character vector of isolate identifiers to
#'   remove after alignment.
#' @param phenotype_coord_names Output names for the phenotype coordinates.
#' @param external_coord_names Output names for the external coordinates.
#' @param centroid_coord_names Output names for group-centroid columns computed
#'   from the phenotype coordinates. Defaults to `paste0(phenotype_coord_names,
#'   "_centroid")`.
#'
#' @return A list with the combined isolate-level `data`, optional distinct
#'   `group_data`, and the phenotype/external calibration objects.
#' @export
amrc_prepare_map_data <- function(
  metadata,
  phenotype_mds,
  external_mds,
  id_col,
  group_col = NULL,
  group_output_col = group_col,
  phenotype_rotation_degrees = NULL,
  external_rotation_degrees = NULL,
  exclude_ids = NULL,
  phenotype_coord_names = c("D1", "D2"),
  external_coord_names = c("E1", "E2"),
  centroid_coord_names = paste0(phenotype_coord_names, "_centroid")
) {
  amrc_assert_is_data_frame(metadata, arg_name = "metadata")
  amrc_assert_single_column_name(id_col, metadata, arg_name = "id_col")

  if (!is.null(group_col)) {
    amrc_assert_single_column_name(group_col, metadata, arg_name = "group_col")
  }
  if (!is.null(group_output_col) &&
      (!is.character(group_output_col) ||
       length(group_output_col) != 1L ||
       is.na(group_output_col) ||
       !nzchar(group_output_col))) {
    stop("group_output_col must be NULL or a single non-empty column name.", call. = FALSE)
  }

  reserved_cols <- c(
    phenotype_coord_names,
    external_coord_names,
    centroid_coord_names
  )
  reserved_overlap <- intersect(colnames(metadata), reserved_cols)
  if (length(reserved_overlap) > 0) {
    stop(
      "metadata contains columns reserved for map outputs: ",
      paste(reserved_overlap, collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.null(group_col) &&
      !identical(group_output_col, group_col) &&
      group_output_col %in% colnames(metadata)) {
    stop(
      "group_output_col already exists in metadata and would overwrite an existing column.",
      call. = FALSE
    )
  }

  if (length(centroid_coord_names) != length(phenotype_coord_names)) {
    stop(
      "centroid_coord_names must have the same length as phenotype_coord_names.",
      call. = FALSE
    )
  }

  phenotype_prepared <- amrc_prepare_configuration_table(
    mds_result = phenotype_mds,
    coord_names = phenotype_coord_names,
    rotation_degrees = phenotype_rotation_degrees
  )
  external_prepared <- amrc_prepare_configuration_table(
    mds_result = external_mds,
    coord_names = external_coord_names,
    rotation_degrees = external_rotation_degrees
  )

  target_ids <- phenotype_prepared$labels
  if (is.null(target_ids)) {
    target_ids <- external_prepared$labels
  }
  if (is.null(target_ids)) {
    if (nrow(metadata) != nrow(phenotype_prepared$data) ||
        nrow(metadata) != nrow(external_prepared$data)) {
      stop(
        "When the maps do not carry isolate labels, metadata and both map fits must have the same number of rows.",
        call. = FALSE
      )
    }
    target_ids <- as.character(metadata[[id_col]])
  }

  metadata_aligned <- amrc_align_rows_by_id(
    data = metadata,
    id_col = id_col,
    target_ids = target_ids,
    data_name = "metadata"
  )
  phenotype_aligned <- amrc_align_configuration_rows(
    configuration_data = phenotype_prepared$data,
    target_ids = target_ids,
    data_name = "phenotype_mds"
  )
  external_aligned <- amrc_align_configuration_rows(
    configuration_data = external_prepared$data,
    target_ids = target_ids,
    data_name = "external_mds"
  )

  comparison_data <- cbind(
    phenotype_aligned,
    metadata_aligned,
    external_aligned
  )
  rownames(comparison_data) <- NULL

  if (!is.null(group_col) && !identical(group_output_col, group_col)) {
    colnames(comparison_data)[colnames(comparison_data) == group_col] <- group_output_col
    group_col <- group_output_col
  }

  if (!is.null(exclude_ids) && length(exclude_ids) > 0) {
    comparison_data <- comparison_data[
      !(comparison_data[[id_col]] %in% exclude_ids),
      ,
      drop = FALSE
    ]
  }

  group_data <- NULL
  if (!is.null(group_col)) {
    comparison_data <- amrc_attach_group_centroids(
      data = comparison_data,
      group_col = group_col,
      coord_cols = phenotype_coord_names,
      centroid_cols = centroid_coord_names
    )

    group_data <- comparison_data[!duplicated(comparison_data[[group_col]]), , drop = FALSE]
    rownames(group_data) <- NULL
  }

  list(
    data = comparison_data,
    group_data = group_data,
    phenotype_calibration = phenotype_prepared$calibration,
    external_calibration = external_prepared$calibration
  )
}

#' Prepare the S. pneumoniae Example Phenotype/Genotype Comparison Table
#'
#' Builds the combined comparison data frame reused across the clustering and
#' side-by-side phenotype/genotype notebooks. The phenotype and genotype maps
#' are calibrated onto interpretable scales with [amrc_calibrate_mds()], then
#' joined to the processed phenotype metadata.
#'
#' This is an example-specific wrapper for the pneumococcal case study. The
#' generic replacement target is a dataset-agnostic `amrc_prepare_map_data()`
#' workflow.
#'
#' Lifecycle note: this function remains exported for case-study compatibility,
#' but new analyses should prefer [amrc_prepare_map_data()]. In the `0.1.0`
#' public milestone it should be read as a supported case-study helper, not as
#' the recommended entry point for new analyses.
#'
#' @param tablemic_meta Processed metadata table containing at least `LABID` and
#'   `PT`.
#' @param phenotype_mds Phenotype MDS fit.
#' @param genotype_mds Genotype MDS fit.
#' @param phenotype_rotation_degrees Optional rotation applied to the phenotype
#'   map after calibration.
#' @param exclude_labids Optional character vector of isolate identifiers to
#'   remove.
#' @param phenotype_pbp_col Name of the phenotype metadata column containing PBP
#'   types.
#' @param pbp_col_name Output column name for the PBP type field.
#' @param phenotype_coord_names Output names for the phenotype coordinates.
#' @param genotype_coord_names Output names for the genotype coordinates.
#'
#' @return A list with the combined isolate-level `data`, a distinct
#'   `pbp_data` table, and the phenotype/genotype calibration objects.
#' @export
amrc_prepare_spneumoniae_map_data <- function(
  tablemic_meta,
  phenotype_mds,
  genotype_mds,
  phenotype_rotation_degrees = 326,
  exclude_labids = amrc_default_pbp_deletion_labids(),
  phenotype_pbp_col = "PT",
  pbp_col_name = "PBP_type",
  phenotype_coord_names = c("D1", "D2"),
  genotype_coord_names = c("G1", "G2")
) {
  comparison_bundle <- amrc_prepare_map_data(
    metadata = tablemic_meta,
    phenotype_mds = phenotype_mds,
    external_mds = genotype_mds,
    id_col = "LABID",
    group_col = phenotype_pbp_col,
    group_output_col = pbp_col_name,
    phenotype_rotation_degrees = phenotype_rotation_degrees,
    exclude_ids = exclude_labids,
    phenotype_coord_names = phenotype_coord_names,
    external_coord_names = genotype_coord_names,
    centroid_coord_names = c("x_centroid", "y_centroid")
  )

  list(
    data = comparison_bundle$data,
    pbp_data = comparison_bundle$group_data,
    phenotype_calibration = comparison_bundle$phenotype_calibration,
    genotype_calibration = comparison_bundle$external_calibration
  )
}

#' Compute Generic Group Centroids from a Comparison Table
#'
#' Aggregates phenotype and optional external map coordinates to one row per
#' metadata group or nested group. This is the generic form of the centroid
#' calculations used repeatedly in the manuscript notebooks for PBP types,
#' MLSTs, and similar classifications.
#'
#' @param data A comparison table, typically produced by
#'   [amrc_prepare_map_data()].
#' @param group_cols Character vector naming one or more grouping columns.
#' @param phenotype_cols Character vector naming phenotype coordinate columns.
#' @param external_cols Optional character vector naming external coordinate
#'   columns.
#' @param genotype_cols Legacy alias for `external_cols`.
#' @param summary_fun Summary function used for each coordinate. May be a
#'   function or one of `"median"` or `"mean"`.
#' @param phenotype_output_cols Output column names for the aggregated phenotype
#'   coordinates. Defaults to `paste0(phenotype_cols, "_centroid")`.
#' @param external_output_cols Output column names for the aggregated external
#'   coordinates. Defaults to `paste0(external_cols, "_centroid")`.
#'
#' @return A `data.frame` with one row per group.
#' @export
amrc_compute_group_centroids <- function(
  data,
  group_cols,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  summary_fun = "median",
  phenotype_output_cols = paste0(phenotype_cols, "_centroid"),
  external_output_cols = NULL
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(group_cols, data, arg_name = "group_cols")
  amrc_require_coordinate_columns(data, phenotype_cols)

  external_cols <- amrc_resolve_optional_external_cols(
    data = data,
    external_cols = external_cols,
    genotype_cols = genotype_cols
  )
  if (!is.null(external_cols)) {
    amrc_require_coordinate_columns(data, external_cols)
  }

  if (length(phenotype_output_cols) != length(phenotype_cols)) {
    stop(
      "phenotype_output_cols must have the same length as phenotype_cols.",
      call. = FALSE
    )
  }

  if (!is.null(external_cols)) {
    if (is.null(external_output_cols)) {
      external_output_cols <- paste0(external_cols, "_centroid")
    }
    if (length(external_output_cols) != length(external_cols)) {
      stop(
        "external_output_cols must have the same length as external_cols.",
        call. = FALSE
      )
    }
  }

  summary_fun <- amrc_summary_function(summary_fun)

  summarise_coords <- function(coord_cols, output_cols) {
    aggregated <- stats::aggregate(
      data[, coord_cols, drop = FALSE],
      by = data[, group_cols, drop = FALSE],
      FUN = summary_fun,
      na.rm = TRUE
    )
    colnames(aggregated) <- c(group_cols, output_cols)
    aggregated
  }

  centroid_table <- summarise_coords(phenotype_cols, phenotype_output_cols)

  if (!is.null(external_cols)) {
    external_table <- summarise_coords(external_cols, external_output_cols)
    centroid_table <- merge(
      centroid_table,
      external_table,
      by = group_cols,
      sort = FALSE
    )
  }

  centroid_table
}

#' Compute Pairwise Distances Between Metadata Groups
#'
#' Builds a one-row-per-pair table of phenotype and optional external distances
#' between metadata-group centroids.
#'
#' @param data A comparison table, typically produced by
#'   [amrc_prepare_map_data()].
#' @param group_col Metadata grouping column.
#' @param phenotype_cols Character vector naming phenotype coordinate columns.
#' @param external_cols Optional character vector naming external coordinate
#'   columns.
#' @param genotype_cols Legacy alias for `external_cols`.
#' @param summary_fun Summary function used when building group centroids.
#' @param group_pair_col_names Length-2 character vector naming the output group
#'   columns.
#' @param phenotype_distance_col Output column name for phenotype distances.
#' @param external_distance_col Output column name for external distances.
#'
#' @return A `data.frame` with one row per pair of groups.
#' @export
amrc_compute_group_pairwise_distances <- function(
  data,
  group_col,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  summary_fun = "median",
  group_pair_col_names = c("group_1", "group_2"),
  phenotype_distance_col = "phenotype_distance",
  external_distance_col = "external_distance"
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")
  if (length(group_pair_col_names) != 2L) {
    stop("group_pair_col_names must contain exactly two column names.", call. = FALSE)
  }

  external_cols_resolved <- amrc_resolve_optional_external_cols(
    data = data,
    external_cols = external_cols,
    genotype_cols = genotype_cols
  )

  centroids <- amrc_compute_group_centroids(
    data = data,
    group_cols = group_col,
    phenotype_cols = phenotype_cols,
    external_cols = external_cols_resolved,
    summary_fun = summary_fun,
    phenotype_output_cols = phenotype_cols,
    external_output_cols = external_cols_resolved
  )

  if (nrow(centroids) < 2) {
    out <- data.frame(stringsAsFactors = FALSE, check.names = FALSE)
    out[[group_pair_col_names[[1]]]] <- character()
    out[[group_pair_col_names[[2]]]] <- character()
    out[[phenotype_distance_col]] <- numeric()
    if (!is.null(external_cols_resolved)) {
      out[[external_distance_col]] <- numeric()
    }
    return(out)
  }

  group_pairs <- utils::combn(as.character(centroids[[group_col]]), 2, simplify = FALSE)
  phenotype_matrix <- as.matrix(centroids[, phenotype_cols, drop = FALSE])
  rownames(phenotype_matrix) <- as.character(centroids[[group_col]])

  external_matrix <- NULL
  if (!is.null(external_cols_resolved)) {
    external_matrix <- as.matrix(centroids[, external_cols_resolved, drop = FALSE])
    rownames(external_matrix) <- as.character(centroids[[group_col]])
  }

  pair_rows <- lapply(group_pairs, function(group_pair) {
    row <- data.frame(
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    row <- as.data.frame(stats::setNames(
      list(
        group_pair[[1]],
        group_pair[[2]],
        sqrt(sum((phenotype_matrix[group_pair[[1]], ] - phenotype_matrix[group_pair[[2]], ])^2))
      ),
      c(group_pair_col_names[[1]], group_pair_col_names[[2]], phenotype_distance_col)
    ), stringsAsFactors = FALSE, check.names = FALSE)
    if (!is.null(external_matrix)) {
      row[[external_distance_col]] <- sqrt(sum((external_matrix[group_pair[[1]], ] - external_matrix[group_pair[[2]], ])^2))
    }
    row
  })

  do.call(rbind, pair_rows)
}

#' Summarise Within-Group Pairwise Distances Across Nested Subgroups
#'
#' Computes phenotype and optional external pairwise distances among subgroup
#' centroids within each outer metadata group. This generalises the manuscript
#' summaries that were originally written for distances among PBP centroids
#' within each MLST.
#'
#' @param data A comparison table, typically produced by
#'   [amrc_prepare_map_data()].
#' @param group_col Outer grouping column, for example `MLST`.
#' @param subgroup_col Nested grouping column, for example `PBP_type`.
#' @param phenotype_cols Character vector naming phenotype coordinate columns.
#' @param external_cols Optional character vector naming external coordinate
#'   columns.
#' @param genotype_cols Legacy alias for `external_cols`.
#' @param summary_fun Summary function used to build subgroup centroids.
#'
#' @return A `data.frame` with within-group pairwise distance summaries.
#' @export
amrc_summarise_nested_group_pairwise_distances <- function(
  data,
  group_col,
  subgroup_col,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  summary_fun = "median"
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")
  amrc_assert_single_column_name(subgroup_col, data, arg_name = "subgroup_col")

  external_cols_resolved <- amrc_resolve_optional_external_cols(
    data = data,
    external_cols = external_cols,
    genotype_cols = genotype_cols
  )

  centroids <- amrc_compute_group_centroids(
    data = data,
    group_cols = c(group_col, subgroup_col),
    phenotype_cols = phenotype_cols,
    external_cols = external_cols_resolved,
    summary_fun = summary_fun,
    phenotype_output_cols = phenotype_cols,
    external_output_cols = external_cols_resolved
  )

  split_centroids <- split(centroids, centroids[[group_col]])
  summary_rows <- lapply(names(split_centroids), function(group_value) {
    group_data <- split_centroids[[group_value]]

    phen_dists <- if (nrow(group_data) < 2) {
      numeric(0)
    } else {
      as.numeric(stats::dist(group_data[, phenotype_cols, drop = FALSE]))
    }

    row <- data.frame(
      stats::setNames(
        list(
          group_value,
          nrow(group_data),
          if (length(phen_dists) == 0) 0 else mean(phen_dists, na.rm = TRUE),
          if (length(phen_dists) == 0) 0 else stats::median(phen_dists, na.rm = TRUE),
          if (length(phen_dists) <= 1) 0 else stats::sd(phen_dists, na.rm = TRUE)
        ),
        c(
          group_col,
          "n_subgroups",
          "phenotype_pairwise_mean",
          "phenotype_pairwise_median",
          "phenotype_pairwise_sd"
        )
      ),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    if (!is.null(external_cols_resolved)) {
      ext_dists <- if (nrow(group_data) < 2) {
        numeric(0)
      } else {
        as.numeric(stats::dist(group_data[, external_cols_resolved, drop = FALSE]))
      }
      row[["external_pairwise_mean"]] <- if (length(ext_dists) == 0) 0 else mean(ext_dists, na.rm = TRUE)
      row[["external_pairwise_median"]] <- if (length(ext_dists) == 0) 0 else stats::median(ext_dists, na.rm = TRUE)
      row[["external_pairwise_sd"]] <- if (length(ext_dists) <= 1) 0 else stats::sd(ext_dists, na.rm = TRUE)
    }

    row
  })

  do.call(rbind, summary_rows)
}

#' Summarise Pairwise Distances Between Metadata Groups
#'
#' Computes within-group and/or between-group pairwise distances directly from
#' isolate-level phenotype and optional external map coordinates, then reports
#' mean, median, and standard deviation summaries for each pair of metadata
#' groups.
#'
#' @param data A comparison table, typically produced by
#'   [amrc_prepare_map_data()].
#' @param group_col Metadata grouping column.
#' @param phenotype_cols Character vector naming phenotype coordinate columns.
#' @param external_cols Optional character vector naming external coordinate
#'   columns.
#' @param genotype_cols Legacy alias for `external_cols`.
#' @param include_within Logical; include within-group summaries.
#' @param include_between Logical; include between-group summaries.
#' @param group_pair_col_names Length-2 character vector naming the output group
#'   columns.
#'
#' @return A `data.frame` with one row per group pair summary.
#' @export
amrc_compute_group_distance_summary <- function(
  data,
  group_col,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  include_within = TRUE,
  include_between = TRUE,
  group_pair_col_names = c("group_1", "group_2")
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")
  amrc_require_coordinate_columns(data, phenotype_cols)
  if (length(group_pair_col_names) != 2L) {
    stop("group_pair_col_names must contain exactly two column names.", call. = FALSE)
  }

  external_cols_resolved <- amrc_resolve_optional_external_cols(
    data = data,
    external_cols = external_cols,
    genotype_cols = genotype_cols
  )
  if (!is.null(external_cols_resolved)) {
    amrc_require_coordinate_columns(data, external_cols_resolved)
  }

  split_groups <- split(data, as.character(data[[group_col]]))
  group_names <- names(split_groups)
  summary_rows <- list()

  add_summary_row <- function(group_a_name, group_b_name, relation, phen_values, ext_values = NULL) {
    row <- data.frame(
      relation = relation,
      n_pairs = length(phen_values),
      phenotype_distance_mean = if (length(phen_values) == 0) 0 else mean(phen_values, na.rm = TRUE),
      phenotype_distance_median = if (length(phen_values) == 0) 0 else stats::median(phen_values, na.rm = TRUE),
      phenotype_distance_sd = if (length(phen_values) <= 1) 0 else stats::sd(phen_values, na.rm = TRUE),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    row[[group_pair_col_names[[1]]]] <- group_a_name
    row[[group_pair_col_names[[2]]]] <- group_b_name
    row <- row[, c(group_pair_col_names[[1]], group_pair_col_names[[2]], "relation", "n_pairs",
                   "phenotype_distance_mean", "phenotype_distance_median", "phenotype_distance_sd"), drop = FALSE]

    if (!is.null(ext_values)) {
      row[["external_distance_mean"]] <- if (length(ext_values) == 0) 0 else mean(ext_values, na.rm = TRUE)
      row[["external_distance_median"]] <- if (length(ext_values) == 0) 0 else stats::median(ext_values, na.rm = TRUE)
      row[["external_distance_sd"]] <- if (length(ext_values) <= 1) 0 else stats::sd(ext_values, na.rm = TRUE)
      row[["mean_external_to_phenotypic_ratio"]] <- if (row[["phenotype_distance_mean"]] == 0) NA_real_ else row[["external_distance_mean"]] / row[["phenotype_distance_mean"]]
      row[["median_external_to_phenotypic_ratio"]] <- if (row[["phenotype_distance_median"]] == 0) NA_real_ else row[["external_distance_median"]] / row[["phenotype_distance_median"]]
    }

    row
  }

  if (isTRUE(include_within)) {
    for (group_name in group_names) {
      group_data <- split_groups[[group_name]]
      phen_values <- if (nrow(group_data) < 2) numeric(0) else as.numeric(stats::dist(group_data[, phenotype_cols, drop = FALSE]))
      ext_values <- NULL
      if (!is.null(external_cols_resolved)) {
        ext_values <- if (nrow(group_data) < 2) numeric(0) else as.numeric(stats::dist(group_data[, external_cols_resolved, drop = FALSE]))
      }
      summary_rows[[length(summary_rows) + 1L]] <- add_summary_row(group_name, group_name, "within", phen_values, ext_values)
    }
  }

  if (isTRUE(include_between) && length(group_names) > 1) {
    group_pairs <- utils::combn(group_names, 2, simplify = FALSE)
    for (group_pair in group_pairs) {
      group_a <- split_groups[[group_pair[[1]]]]
      group_b <- split_groups[[group_pair[[2]]]]

      phen_values <- amrc_between_group_distances(
        group_a[, phenotype_cols, drop = FALSE],
        group_b[, phenotype_cols, drop = FALSE]
      )

      ext_values <- NULL
      if (!is.null(external_cols_resolved)) {
        ext_values <- amrc_between_group_distances(
          group_a[, external_cols_resolved, drop = FALSE],
          group_b[, external_cols_resolved, drop = FALSE]
        )
      }

      summary_rows[[length(summary_rows) + 1L]] <- add_summary_row(
        group_pair[[1]],
        group_pair[[2]],
        "between",
        phen_values,
        ext_values
      )
    }
  }

  do.call(rbind, summary_rows)
}

#' Compare Two Cluster Assignments
#'
#' Builds a contingency table and simple agreement summaries for any two
#' clusterings or categorical partitionings, such as phenotype-defined clusters
#' versus genotype-defined clusters.
#'
#' @param data A data frame containing both clustering columns.
#' @param cluster_col_1 First cluster column.
#' @param cluster_col_2 Second cluster column.
#'
#' @return A list containing the raw `table`, a long-form `counts` table, and
#'   per-cluster purity summaries for both directions.
#' @export
amrc_compare_cluster_assignments <- function(
  data,
  cluster_col_1,
  cluster_col_2
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(cluster_col_1, data, arg_name = "cluster_col_1")
  amrc_assert_single_column_name(cluster_col_2, data, arg_name = "cluster_col_2")

  complete <- stats::complete.cases(data[, c(cluster_col_1, cluster_col_2), drop = FALSE])
  aligned <- data[complete, c(cluster_col_1, cluster_col_2), drop = FALSE]

  contingency <- table(aligned[[cluster_col_1]], aligned[[cluster_col_2]])
  counts <- as.data.frame(contingency, stringsAsFactors = FALSE)
  colnames(counts) <- c(cluster_col_1, cluster_col_2, "n")
  counts <- counts[counts$n > 0, , drop = FALSE]

  purity_1 <- stats::aggregate(
    counts$n,
    by = list(cluster = counts[[cluster_col_1]]),
    FUN = function(x) max(x) / sum(x)
  )
  colnames(purity_1) <- c(cluster_col_1, "dominant_fraction_in_second")

  purity_2 <- stats::aggregate(
    counts$n,
    by = list(cluster = counts[[cluster_col_2]]),
    FUN = function(x) max(x) / sum(x)
  )
  colnames(purity_2) <- c(cluster_col_2, "dominant_fraction_in_first")

  list(
    table = contingency,
    counts = counts,
    cluster_1_purity = purity_1,
    cluster_2_purity = purity_2
  )
}

#' Cluster a Map with Ward Hierarchical Clustering
#'
#' Fits hierarchical clustering to a set of map coordinates and returns cluster
#' assignments plus an elbow-style within-cluster inertia curve.
#'
#' @param data A data frame containing the map coordinates.
#' @param coord_cols Length-2 character vector naming the coordinate columns.
#' @param n_clusters Number of clusters to cut from the dendrogram.
#' @param distinct_col Optional column used to keep one row per unique type
#'   before clustering.
#' @param cluster_method Linkage method passed to [stats::hclust()].
#' @param max_k Maximum number of clusters for the inertia curve.
#'
#' @return A list containing the `input` data, distance matrix, `hclust`
#'   object, cluster `assignments`, and `scree` data frame.
#' @export
amrc_cluster_map <- function(
  data,
  coord_cols = c("G1", "G2"),
  n_clusters = 12,
  distinct_col = NULL,
  cluster_method = "ward.D2",
  max_k = 20
) {
  amrc_require_coordinate_columns(data, coord_cols)

  cluster_input <- data
  if (!is.null(distinct_col)) {
    if (!(distinct_col %in% colnames(cluster_input))) {
      stop("distinct_col was not found in data.", call. = FALSE)
    }
    cluster_input <- cluster_input[!duplicated(cluster_input[[distinct_col]]), , drop = FALSE]
  }

  coords <- as.matrix(cluster_input[, coord_cols, drop = FALSE])
  storage.mode(coords) <- "double"
  dd <- stats::dist(coords)
  hc <- stats::hclust(dd, method = cluster_method)
  clusters <- stats::cutree(hc, k = n_clusters)

  assignments <- data.frame(
    row_id = seq_len(nrow(cluster_input)),
    cluster = clusters
  )
  if (!is.null(distinct_col)) {
    assignments[[distinct_col]] <- cluster_input[[distinct_col]]
    assignments <- assignments[, c(distinct_col, "cluster"), drop = FALSE]
  }

  k_values <- seq_len(min(max_k, nrow(cluster_input)))
  scree <- data.frame(
    n_clusters = k_values,
    within_cluster_inertia = vapply(k_values, function(k) {
      amrc_within_cluster_inertia(coords, stats::cutree(hc, k = k))
    }, numeric(1))
  )

  list(
    input = cluster_input,
    distance = dd,
    hclust = hc,
    assignments = assignments,
    scree = scree
  )
}

#' Add Cluster Assignments to a Comparison Table
#'
#' @param data A data frame.
#' @param assignments Output from [amrc_cluster_map()]$assignments.
#' @param key_col Join key shared between `data` and `assignments`.
#' @param cluster_col Output column name for the cluster assignment.
#'
#' @return `data` with an added cluster column.
#' @export
amrc_add_cluster_assignments <- function(
  data,
  assignments,
  key_col = "PBP_type",
  cluster_col = "gen_cluster"
) {
  if (!(key_col %in% colnames(data)) || !(key_col %in% colnames(assignments))) {
    stop("Both data and assignments must contain the key column.", call. = FALSE)
  }

  match_index <- match(data[[key_col]], assignments[[key_col]])
  if (anyNA(match_index)) {
    stop("Some rows in data could not be matched to assignments.", call. = FALSE)
  }

  data[[cluster_col]] <- assignments$cluster[match_index]
  data
}

#' Summarise Within- and Between-Cluster Separation
#'
#' Calculates Euclidean distances within clusters and between all pairs of
#' clusters, returning the raw histogram-ready values and compact summary
#' statistics.
#'
#' @param data A data frame containing map coordinates and cluster labels.
#' @param coord_cols Length-2 character vector naming the coordinate columns.
#' @param cluster_col Cluster column.
#' @param distinct_col Optional column used to collapse to one row per type
#'   before summarising.
#'
#' @return A list with raw `hist_data`, a two-row `summary`, and overall mean
#'   and median intra/inter-cluster distances.
#' @export
amrc_summarise_cluster_separation <- function(
  data,
  coord_cols = c("D1", "D2"),
  cluster_col = "gen_cluster",
  distinct_col = NULL
) {
  amrc_require_coordinate_columns(data, coord_cols)
  if (!(cluster_col %in% colnames(data))) {
    stop("data must contain the cluster column.", call. = FALSE)
  }

  working <- data
  if (!is.null(distinct_col)) {
    if (!(distinct_col %in% colnames(working))) {
      stop("distinct_col was not found in data.", call. = FALSE)
    }
    working <- working[!duplicated(working[[distinct_col]]), , drop = FALSE]
  }

  cluster_levels <- unique(working[[cluster_col]])
  split_data <- lapply(cluster_levels, function(level) {
    working[working[[cluster_col]] == level, coord_cols, drop = FALSE]
  })
  names(split_data) <- cluster_levels

  intra_group <- unlist(lapply(split_data, function(cluster_data) {
    if (nrow(cluster_data) < 2) {
      numeric(0)
    } else {
      as.vector(stats::dist(cluster_data))
    }
  }), use.names = FALSE)

  inter_group <- numeric(0)
  if (length(split_data) > 1) {
    group_pairs <- utils::combn(seq_along(split_data), 2, simplify = FALSE)
    inter_group <- unlist(lapply(group_pairs, function(index) {
      amrc_between_group_distances(split_data[[index[[1]]]], split_data[[index[[2]]]])
    }), use.names = FALSE)
  }

  hist_data <- rbind(
    data.frame(DistanceType = "Intra-Group", Distance = intra_group),
    data.frame(DistanceType = "Inter-Group", Distance = inter_group)
  )

  summary <- do.call(
    rbind,
    lapply(split(hist_data$Distance, hist_data$DistanceType), function(x) {
      data.frame(
        mean_distance = mean(x),
        median_distance = stats::median(x)
      )
    })
  )
  summary$DistanceType <- rownames(summary)
  summary <- summary[, c("DistanceType", "mean_distance", "median_distance"), drop = FALSE]
  rownames(summary) <- NULL

  list(
    hist_data = hist_data,
    summary = summary,
    mean_intra_distance = mean(intra_group),
    median_intra_distance = stats::median(intra_group),
    mean_inter_distance = mean(inter_group),
    median_inter_distance = stats::median(inter_group)
  )
}

#' Prepare Cluster Label Positions
#'
#' Calculates mean cluster-centre positions and applies optional manual offsets,
#' which keeps the genotype comparison notebook plotting code compact.
#'
#' @param data A data frame containing coordinates and a cluster column.
#' @param x_col,y_col Coordinate column names.
#' @param cluster_col Cluster column name.
#' @param adjustments Optional data frame with columns `cluster`, `dx`, and
#'   `dy`.
#'
#' @return A data frame of label positions.
#' @export
amrc_cluster_label_positions <- function(
  data,
  x_col = "G1",
  y_col = "G2",
  cluster_col = "gen_cluster",
  adjustments = NULL
) {
  amrc_require_coordinate_columns(data, c(x_col, y_col))
  if (!(cluster_col %in% colnames(data))) {
    stop("data must contain the cluster column.", call. = FALSE)
  }

  labels <- stats::aggregate(
    data[, c(x_col, y_col), drop = FALSE],
    by = list(cluster = data[[cluster_col]]),
    FUN = mean
  )
  colnames(labels) <- c("cluster", "x", "y")

  if (!is.null(adjustments)) {
    required_cols <- c("cluster", "dx", "dy")
    if (!all(required_cols %in% colnames(adjustments))) {
      stop("adjustments must contain cluster, dx, and dy columns.", call. = FALSE)
    }

    match_index <- match(labels$cluster, adjustments$cluster)
    labels$x <- labels$x + ifelse(is.na(match_index), 0, adjustments$dx[match_index])
    labels$y <- labels$y + ifelse(is.na(match_index), 0, adjustments$dy[match_index])
  }

  labels
}

amrc_default_existing_column <- function(data, candidates) {
  matches <- candidates[candidates %in% colnames(data)]
  if (length(matches) == 0) {
    return(NULL)
  }

  matches[[1]]
}

amrc_resolve_external_coord_cols <- function(data, external_cols = NULL, genotype_cols = NULL) {
  if (!is.null(external_cols) && !is.null(genotype_cols)) {
    stop("Specify only one of external_cols or genotype_cols.", call. = FALSE)
  }

  resolved <- external_cols
  if (is.null(resolved)) {
    resolved <- genotype_cols
  }
  if (is.null(resolved)) {
    resolved <- if (all(c("E1", "E2") %in% colnames(data))) {
      c("E1", "E2")
    } else if (all(c("G1", "G2") %in% colnames(data))) {
      c("G1", "G2")
    } else {
      NULL
    }
  }

  if (is.null(resolved)) {
    stop(
      "Could not infer the external coordinate columns. Supply external_cols explicitly.",
      call. = FALSE
    )
  }

  resolved
}

amrc_resolve_distance_column <- function(data, explicit, candidates, arg_name) {
  if (!is.null(explicit)) {
    if (!(explicit %in% colnames(data))) {
      stop(arg_name, " '", explicit, "' was not found in the input data.", call. = FALSE)
    }
    return(explicit)
  }

  resolved <- amrc_default_existing_column(data, candidates)
  if (is.null(resolved)) {
    stop(
      "Could not infer ",
      arg_name,
      ". Supply it explicitly.",
      call. = FALSE
    )
  }

  resolved
}

#' Compute Distances from a Generic Reference Entry
#'
#' Computes phenotype and external-map distances from a chosen reference entry
#' in a generic comparison table. The reference can be defined by any grouping
#' column, not just a pneumococcal PBP type.
#'
#' @param data A comparison table, typically produced by
#'   [amrc_prepare_map_data()].
#' @param reference_value Reference value to locate in `reference_col`.
#' @param reference_col Column used to identify the reference row or group. When
#'   omitted, the function falls back to `PBP_type` for case-study
#'   compatibility.
#' @param phenotype_cols Character vector for phenotype coordinates.
#' @param external_cols Character vector for external coordinates.
#' @param genotype_cols Legacy alias for `external_cols` retained for the
#'   pneumococcal case study.
#' @param phenotype_reference_cols Optional alternate phenotype coordinate
#'   columns used to define the phenotype distances, for example centroid
#'   columns.
#' @param id_col Optional identifier column to carry through to the output.
#' @param cluster_col Optional cluster column to carry through to the output.
#'   When omitted, the function falls back to `external_cluster`, `gen_cluster`,
#'   or `cluster` if present. Use `FALSE` to suppress cluster handling even when
#'   a cluster column is available.
#' @param keep_cols Optional additional metadata columns to carry through.
#' @param phenotype_distance_col Output column name for phenotype distances.
#' @param external_distance_col Output column name for external distances.
#' @param reference_pbp_type Legacy alias for `reference_value` retained for the
#'   pneumococcal case study.
#'
#' @return A data frame of per-row phenotype and external distances from the
#'   chosen reference entry.
#'
#' @details
#' When `reference_col` matches multiple rows, the function uses the centroid of
#' those rows to define the phenotype and external reference positions. This
#' avoids order-dependent behaviour when the reference group contains multiple
#' isolates.
#' @export
amrc_compute_reference_distance_table <- function(
  data,
  reference_value = NULL,
  reference_col = NULL,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  phenotype_reference_cols = phenotype_cols,
  id_col = NULL,
  cluster_col = NULL,
  keep_cols = NULL,
  phenotype_distance_col = "phen_distance",
  external_distance_col = "gen_distance",
  reference_pbp_type = NULL
) {
  amrc_assert_is_data_frame(data, arg_name = "data")

  if (is.null(reference_value)) {
    reference_value <- reference_pbp_type
  }
  if (is.null(reference_value) || length(reference_value) != 1L || is.na(reference_value)) {
    stop("reference_value must identify exactly one reference entry.", call. = FALSE)
  }

  if (is.null(reference_col)) {
    reference_col <- amrc_default_existing_column(data, c("PBP_type"))
  }
  if (is.null(reference_col)) {
    stop(
      "reference_col could not be inferred. Supply a column that identifies the reference entry.",
      call. = FALSE
    )
  }

  if (!(reference_col %in% colnames(data))) {
    stop("reference_col was not found in data.", call. = FALSE)
  }

  external_cols <- amrc_resolve_external_coord_cols(
    data = data,
    external_cols = external_cols,
    genotype_cols = genotype_cols
  )

  amrc_require_coordinate_columns(data, phenotype_cols)
  amrc_require_coordinate_columns(data, external_cols)
  amrc_require_coordinate_columns(data, phenotype_reference_cols)

  if (is.null(id_col)) {
    id_col <- amrc_default_existing_column(data, c("isolate_id", "LABID"))
  } else if (!(id_col %in% colnames(data))) {
    stop("id_col was not found in data.", call. = FALSE)
  }

  if (identical(cluster_col, FALSE)) {
    cluster_col <- NULL
  } else if (is.null(cluster_col)) {
    cluster_col <- amrc_default_existing_column(data, c("external_cluster", "gen_cluster", "cluster"))
  } else if (!(cluster_col %in% colnames(data))) {
    stop("cluster_col was not found in data.", call. = FALSE)
  }

  if (!is.null(keep_cols)) {
    amrc_assert_column_set(keep_cols, data, arg_name = "keep_cols")
  }

  reference_rows <- data[data[[reference_col]] == reference_value, , drop = FALSE]
  if (nrow(reference_rows) == 0) {
    stop("reference_value was not found in reference_col.", call. = FALSE)
  }

  phenotype_reference <- colMeans(
    as.matrix(reference_rows[, phenotype_reference_cols, drop = FALSE]),
    na.rm = TRUE
  )
  external_reference <- colMeans(
    as.matrix(reference_rows[, external_cols, drop = FALSE]),
    na.rm = TRUE
  )

  result <- list()
  if (!is.null(id_col)) {
    result[[id_col]] <- data[[id_col]]
  }
  result[[reference_col]] <- data[[reference_col]]
  if (!is.null(cluster_col)) {
    result[[cluster_col]] <- data[[cluster_col]]
  }
  if (!is.null(keep_cols) && length(keep_cols) > 0) {
    for (column in keep_cols) {
      result[[column]] <- data[[column]]
    }
  }

  phenotype_matrix <- as.matrix(data[, phenotype_cols, drop = FALSE])
  external_matrix <- as.matrix(data[, external_cols, drop = FALSE])

  result[[phenotype_distance_col]] <- sqrt(
    rowSums((sweep(phenotype_matrix, 2, phenotype_reference, "-"))^2)
  )
  result[[external_distance_col]] <- sqrt(
    rowSums((sweep(external_matrix, 2, external_reference, "-"))^2)
  )

  as.data.frame(result, stringsAsFactors = FALSE, check.names = FALSE)
}

#' Summarise Reference-Distance Comparisons
#'
#' Summarises phenotype-vs-external distances either by cluster or overall when
#' no cluster column is available.
#'
#' @param distance_table Output from [amrc_compute_reference_distance_table()].
#' @param cluster_col Optional cluster column in `distance_table`. When omitted,
#'   the function falls back to `external_cluster`, `gen_cluster`, or `cluster`
#'   if present. Use `FALSE` to force an overall-only summary. When no cluster
#'   column is available, only an overall summary is returned.
#' @param phenotype_distance_col Column containing phenotype distances.
#' @param external_distance_col Column containing external distances.
#' @param digits Number of digits used when rounding the summary tables.
#'
#' @return A list containing the raw `distance_table`, grouped `summary`,
#'   separate `overall_summary`, `average_row`, and `sd_row` summaries, a
#'   compatibility `summary_with_overall` table, a linear-model fit, and a
#'   Spearman correlation test.
#' @export
amrc_summarise_reference_distance_table <- function(
  distance_table,
  cluster_col = NULL,
  phenotype_distance_col = NULL,
  external_distance_col = NULL,
  digits = 2
) {
  phenotype_distance_col <- amrc_resolve_distance_column(
    data = distance_table,
    explicit = phenotype_distance_col,
    candidates = c("phenotype_distance", "phen_distance"),
    arg_name = "phenotype_distance_col"
  )
  external_distance_col <- amrc_resolve_distance_column(
    data = distance_table,
    explicit = external_distance_col,
    candidates = c("external_distance", "gen_distance"),
    arg_name = "external_distance_col"
  )

  if (identical(cluster_col, FALSE)) {
    cluster_col <- NULL
  } else if (is.null(cluster_col)) {
    cluster_col <- amrc_default_existing_column(
      distance_table,
      c("external_cluster", "gen_cluster", "cluster")
    )
  } else if (!(cluster_col %in% colnames(distance_table))) {
    stop("cluster_col was not found in distance_table.", call. = FALSE)
  }

  if (is.null(cluster_col)) {
    summary <- data.frame(
      cluster = "Overall",
      mean_phenotypic_distance = mean(distance_table[[phenotype_distance_col]]),
      mean_external_distance = mean(distance_table[[external_distance_col]]),
      external_to_phenotypic_ratio =
        mean(distance_table[[external_distance_col]]) /
        mean(distance_table[[phenotype_distance_col]]),
      stringsAsFactors = FALSE
    )
    rounded_summary <- summary
    rounded_summary[, 2:4] <- round(rounded_summary[, 2:4, drop = FALSE], digits = digits)
    rounded_overall <- rounded_summary
    rounded_average <- NULL
    rounded_sd <- NULL
    rounded_with_overall <- rounded_summary
  } else {
    phen_means <- stats::aggregate(
      distance_table[[phenotype_distance_col]],
      by = list(cluster = distance_table[[cluster_col]]),
      FUN = mean
    )
    ext_means <- stats::aggregate(
      distance_table[[external_distance_col]],
      by = list(cluster = distance_table[[cluster_col]]),
      FUN = mean
    )

    summary <- merge(phen_means, ext_means, by = "cluster", sort = FALSE)
    colnames(summary) <- c(
      "cluster",
      "mean_phenotypic_distance",
      "mean_external_distance"
    )
    summary$external_to_phenotypic_ratio <-
      summary$mean_external_distance / summary$mean_phenotypic_distance
    summary <- summary[order(summary$mean_external_distance), , drop = FALSE]

    average_row <- data.frame(
      cluster = "Average",
      mean_phenotypic_distance = mean(summary$mean_phenotypic_distance),
      mean_external_distance = mean(summary$mean_external_distance),
      external_to_phenotypic_ratio = mean(summary$external_to_phenotypic_ratio, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
    sd_row <- data.frame(
      cluster = "SD",
      mean_phenotypic_distance = stats::sd(summary$mean_phenotypic_distance),
      mean_external_distance = stats::sd(summary$mean_external_distance),
      external_to_phenotypic_ratio = stats::sd(summary$external_to_phenotypic_ratio, na.rm = TRUE),
      stringsAsFactors = FALSE
    )

    rounded_summary <- summary
    rounded_summary[, 2:4] <- round(rounded_summary[, 2:4, drop = FALSE], digits = digits)
    rounded_average <- average_row
    rounded_average[, 2:4] <- round(rounded_average[, 2:4, drop = FALSE], digits = digits)
    rounded_sd <- sd_row
    rounded_sd[, 2:4] <- round(rounded_sd[, 2:4, drop = FALSE], digits = digits)
    rounded_overall <- data.frame(
      cluster = "Overall",
      mean_phenotypic_distance = round(mean(distance_table[[phenotype_distance_col]]), digits = digits),
      mean_external_distance = round(mean(distance_table[[external_distance_col]]), digits = digits),
      external_to_phenotypic_ratio = round(
        mean(distance_table[[external_distance_col]]) /
          mean(distance_table[[phenotype_distance_col]]),
        digits = digits
      ),
      stringsAsFactors = FALSE
    )

    rounded_with_overall <- rbind(rounded_summary, rounded_average, rounded_sd)
  }

  fit_formula <- stats::as.formula(
    paste(phenotype_distance_col, "~", external_distance_col)
  )
  fit <- stats::lm(fit_formula, data = distance_table)
  correlation <- stats::cor.test(
    distance_table[[phenotype_distance_col]],
    distance_table[[external_distance_col]],
    method = "spearman",
    exact = FALSE
  )

  list(
    distance_table = distance_table,
    summary = rounded_summary,
    overall_summary = rounded_overall,
    average_row = rounded_average,
    sd_row = rounded_sd,
    summary_with_overall = rounded_with_overall,
    fit = fit,
    correlation = correlation
  )
}

amrc_feature_frequency_table <- function(values) {
  values <- as.character(values)
  values[trimws(values) == ""] <- NA_character_
  values <- values[!is.na(values)]

  if (length(values) == 0L) {
    return(data.frame(
      state = character(0),
      frequency = numeric(0),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }

  counts <- sort(table(values), decreasing = TRUE)
  data.frame(
    state = names(counts),
    frequency = as.numeric(counts) / sum(counts),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

amrc_mode_with_frequency <- function(values) {
  freq_table <- amrc_feature_frequency_table(values)
  if (nrow(freq_table) == 0L) {
    return(list(state = NA_character_, frequency = NA_real_))
  }

  list(
    state = freq_table$state[[1]],
    frequency = freq_table$frequency[[1]]
  )
}

#' Summarise Within-Group Metadata Dispersion
#'
#' Computes within-group pairwise distance summaries directly from isolate-level
#' phenotype and optional external coordinates. This generalises the
#' manuscript-era "within PBP type variance" analysis to any metadata grouping.
#'
#' @param data A comparison table or map data frame.
#' @param group_col Grouping column used to define the within-group summaries.
#' @param phenotype_cols Character vector naming phenotype coordinate columns.
#' @param external_cols Optional character vector naming external coordinate
#'   columns.
#' @param genotype_cols Legacy alias for `external_cols`.
#' @param distinct_col Optional column used to keep one row per unique type
#'   before calculating distances.
#' @param threshold Optional numeric threshold used to count the proportion of
#'   phenotype distances below a user-defined cutoff.
#'
#' @return A `data.frame` with one row per group.
#' @export
amrc_summarise_within_group_dispersion <- function(
  data,
  group_col,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  distinct_col = NULL,
  threshold = NULL
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")
  amrc_require_coordinate_columns(data, phenotype_cols)

  if (!is.null(distinct_col)) {
    amrc_assert_single_column_name(distinct_col, data, arg_name = "distinct_col")
    data <- data[!duplicated(data[[distinct_col]]), , drop = FALSE]
  }

  external_cols <- amrc_resolve_optional_external_cols(
    data = data,
    external_cols = external_cols,
    genotype_cols = genotype_cols
  )
  if (!is.null(external_cols)) {
    amrc_require_coordinate_columns(data, external_cols)
  }

  if (!is.null(threshold) && (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold))) {
    stop("threshold must be NULL or a single numeric value.", call. = FALSE)
  }

  split_groups <- split(data, as.character(data[[group_col]]))

  rows <- lapply(names(split_groups), function(group_value) {
    group_data <- split_groups[[group_value]]
    phen_values <- if (nrow(group_data) < 2L) {
      numeric(0)
    } else {
      as.numeric(stats::dist(group_data[, phenotype_cols, drop = FALSE]))
    }

    row <- data.frame(
      group_value = group_value,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    colnames(row) <- group_col
    row[["n_members"]] <- nrow(group_data)
    row[["n_pairs"]] <- length(phen_values)
    row[["phenotype_distance_mean"]] <- if (length(phen_values) == 0L) NA_real_ else mean(phen_values, na.rm = TRUE)
    row[["phenotype_distance_median"]] <- if (length(phen_values) == 0L) NA_real_ else stats::median(phen_values, na.rm = TRUE)
    row[["phenotype_distance_sd"]] <- if (length(phen_values) <= 1L) NA_real_ else stats::sd(phen_values, na.rm = TRUE)
    row[["phenotype_distance_max"]] <- if (length(phen_values) == 0L) NA_real_ else max(phen_values, na.rm = TRUE)

    if (!is.null(threshold)) {
      row[["phenotype_pairs_below_threshold"]] <- sum(phen_values < threshold, na.rm = TRUE)
      row[["phenotype_prop_below_threshold"]] <- if (length(phen_values) == 0L) NA_real_ else mean(phen_values < threshold, na.rm = TRUE)
    }

    if (!is.null(external_cols)) {
      ext_values <- if (nrow(group_data) < 2L) {
        numeric(0)
      } else {
        as.numeric(stats::dist(group_data[, external_cols, drop = FALSE]))
      }
      row[["external_distance_mean"]] <- if (length(ext_values) == 0L) NA_real_ else mean(ext_values, na.rm = TRUE)
      row[["external_distance_median"]] <- if (length(ext_values) == 0L) NA_real_ else stats::median(ext_values, na.rm = TRUE)
      row[["external_distance_sd"]] <- if (length(ext_values) <= 1L) NA_real_ else stats::sd(ext_values, na.rm = TRUE)
      row[["external_distance_max"]] <- if (length(ext_values) == 0L) NA_real_ else max(ext_values, na.rm = TRUE)
    }

    row
  })

  do.call(rbind, rows)
}

#' Identify Pairs of Groups Differing by Exactly One Feature
#'
#' Compares feature profiles across unique groups or types and returns the
#' pairs that differ at exactly one feature. This is the generic package form
#' of the single-substitution screening step used in the manuscript notebooks.
#'
#' @param data A data frame containing one row per group or type.
#' @param group_col Unique group identifier column.
#' @param feature_cols Character vector naming the feature columns to compare.
#'
#' @return A `data.frame` of one-feature-difference pairs.
#' @export
amrc_identify_single_feature_pairs <- function(
  data,
  group_col,
  feature_cols
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")
  amrc_assert_column_set(feature_cols, data, arg_name = "feature_cols")

  group_ids <- as.character(data[[group_col]])
  if (anyDuplicated(group_ids) > 0L) {
    stop(
      "data must contain unique values in group_col for single-feature pair detection.",
      call. = FALSE
    )
  }

  feature_data <- data[, feature_cols, drop = FALSE]
  feature_data[] <- lapply(feature_data, function(column) {
    out <- as.character(column)
    out[trimws(out) == ""] <- NA_character_
    out
  })

  group_pairs <- utils::combn(group_ids, 2, simplify = FALSE)
  rows <- lapply(group_pairs, function(group_pair) {
    row_1 <- feature_data[group_ids == group_pair[[1]], , drop = FALSE]
    row_2 <- feature_data[group_ids == group_pair[[2]], , drop = FALSE]

    comparable <- !(is.na(row_1[1, ]) | is.na(row_2[1, ]))
    differing <- comparable & (row_1[1, ] != row_2[1, ])
    differing_features <- feature_cols[as.logical(differing)]

    if (length(differing_features) != 1L) {
      return(NULL)
    }

    changed_feature <- differing_features[[1]]
    data.frame(
      group_1 = group_pair[[1]],
      group_2 = group_pair[[2]],
      changed_feature = changed_feature,
      state_1 = as.character(row_1[[changed_feature]][[1]]),
      state_2 = as.character(row_2[[changed_feature]][[1]]),
      n_feature_differences = 1L,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })

  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(data.frame(
      group_1 = character(0),
      group_2 = character(0),
      changed_feature = character(0),
      state_1 = character(0),
      state_2 = character(0),
      n_feature_differences = integer(0),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }

  do.call(rbind, rows)
}

#' Summarise One-Feature Contrasts Between Groups
#'
#' Aggregates phenotype and optional external coordinates to one row per group,
#' identifies the pairs that differ by exactly one feature, and reports the
#' corresponding between-group distances plus group sizes.
#'
#' @param data A data frame containing group identifiers, feature columns, and
#'   phenotype/external coordinates.
#' @param group_col Group identifier column.
#' @param feature_cols Character vector naming the feature columns used to
#'   define contrasts.
#' @param phenotype_cols Character vector naming phenotype coordinate columns.
#' @param external_cols Optional character vector naming external coordinate
#'   columns.
#' @param genotype_cols Legacy alias for `external_cols`.
#' @param count_col Optional column containing precomputed per-group counts.
#' @param pair_table Optional output from [amrc_identify_single_feature_pairs()].
#'
#' @return A `data.frame` of one-feature contrast summaries.
#' @export
amrc_summarise_single_feature_contrasts <- function(
  data,
  group_col,
  feature_cols,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  count_col = NULL,
  pair_table = NULL
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")
  amrc_assert_column_set(feature_cols, data, arg_name = "feature_cols")
  amrc_require_coordinate_columns(data, phenotype_cols)

  if (!is.null(count_col)) {
    amrc_assert_single_column_name(count_col, data, arg_name = "count_col")
  }

  external_cols <- amrc_resolve_optional_external_cols(
    data = data,
    external_cols = external_cols,
    genotype_cols = genotype_cols
  )
  if (!is.null(external_cols)) {
    amrc_require_coordinate_columns(data, external_cols)
  }

  group_features <- data[!duplicated(data[[group_col]]), c(group_col, feature_cols), drop = FALSE]
  if (is.null(pair_table)) {
    pair_table <- amrc_identify_single_feature_pairs(
      data = group_features,
      group_col = group_col,
      feature_cols = feature_cols
    )
  }

  if (nrow(pair_table) == 0L) {
    return(pair_table)
  }

  amrc_assert_column_set(
    c("group_1", "group_2"),
    pair_table,
    arg_name = "pair_table"
  )

  centroids <- amrc_compute_group_centroids(
    data = data,
    group_cols = group_col,
    phenotype_cols = phenotype_cols,
    external_cols = external_cols,
    summary_fun = "median",
    phenotype_output_cols = phenotype_cols,
    external_output_cols = external_cols
  )

  counts <- stats::aggregate(
    rep(1L, nrow(data)),
    by = list(group = data[[group_col]]),
    FUN = sum
  )
  colnames(counts) <- c(group_col, "n_group_members")

  if (!is.null(count_col)) {
    counts <- data[!duplicated(data[[group_col]]), c(group_col, count_col), drop = FALSE]
    colnames(counts) <- c(group_col, "n_group_members")
  }

  available_groups <- unique(as.character(centroids[[group_col]]))
  requested_groups <- unique(c(as.character(pair_table$group_1), as.character(pair_table$group_2)))
  missing_groups <- setdiff(requested_groups, available_groups)
  if (length(missing_groups) > 0L) {
    stop(
      "pair_table references groups not present in data: ",
      paste(utils::head(missing_groups, 10L), collapse = ", "),
      call. = FALSE
    )
  }

  pair_rows <- lapply(seq_len(nrow(pair_table)), function(i) {
    pair_row <- pair_table[i, , drop = FALSE]
    group_1 <- pair_row$group_1[[1]]
    group_2 <- pair_row$group_2[[1]]

    centroid_1 <- centroids[centroids[[group_col]] == group_1, , drop = FALSE]
    centroid_2 <- centroids[centroids[[group_col]] == group_2, , drop = FALSE]
    count_1 <- counts[counts[[group_col]] == group_1, "n_group_members", drop = TRUE]
    count_2 <- counts[counts[[group_col]] == group_2, "n_group_members", drop = TRUE]

    out <- pair_row
    out[["relative_comparison"]] <- paste(sort(c(group_1, group_2)), collapse = ":")
    out[["phenotype_distance"]] <- sqrt(sum((as.numeric(centroid_1[, phenotype_cols, drop = TRUE]) - as.numeric(centroid_2[, phenotype_cols, drop = TRUE]))^2))
    out[["n_group_1"]] <- count_1[[1]]
    out[["n_group_2"]] <- count_2[[1]]

    if (!is.null(external_cols)) {
      out[["external_distance"]] <- sqrt(sum((as.numeric(centroid_1[, external_cols, drop = TRUE]) - as.numeric(centroid_2[, external_cols, drop = TRUE]))^2))
    }

    out
  })

  do.call(rbind, pair_rows)
}

#' Find Features that Differentiate Cluster Pairs
#'
#' Computes per-feature state-frequency shifts between clusters and highlights
#' the features that change most strongly between each pair of clusters.
#'
#' @param data A data frame containing cluster assignments and feature columns.
#' @param cluster_col Cluster column.
#' @param feature_cols Character vector naming the feature columns to compare.
#' @param cluster_pairs Optional two-column structure defining the cluster pairs
#'   to compare. When `NULL`, all pairwise cluster comparisons are used.
#' @param min_frequency_shift Minimum `max_state_frequency_shift` retained in the
#'   output.
#' @param top_n Optional number of top features to keep per cluster pair.
#'
#' @return A `data.frame` of cluster-pair feature-difference summaries.
#' @export
amrc_find_cluster_differentiating_features <- function(
  data,
  cluster_col,
  feature_cols,
  cluster_pairs = NULL,
  min_frequency_shift = 0,
  top_n = NULL
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(cluster_col, data, arg_name = "cluster_col")
  amrc_assert_column_set(feature_cols, data, arg_name = "feature_cols")

  clusters <- unique(as.character(stats::na.omit(data[[cluster_col]])))
  if (length(clusters) < 2L) {
    stop("At least two clusters are required.", call. = FALSE)
  }

  if (is.null(cluster_pairs)) {
    cluster_pairs <- utils::combn(clusters, 2, simplify = FALSE)
  } else if (is.matrix(cluster_pairs) || is.data.frame(cluster_pairs)) {
    cluster_pairs <- split(as.data.frame(cluster_pairs, stringsAsFactors = FALSE), seq_len(nrow(cluster_pairs)))
    cluster_pairs <- lapply(cluster_pairs, function(x) as.character(unlist(x[1, , drop = TRUE])))
  }

  rows <- list()
  for (pair in cluster_pairs) {
    pair <- as.character(pair)
    if (length(pair) != 2L) {
      stop("Each cluster pair must contain exactly two cluster labels.", call. = FALSE)
    }

    data_1 <- data[data[[cluster_col]] == pair[[1]], , drop = FALSE]
    data_2 <- data[data[[cluster_col]] == pair[[2]], , drop = FALSE]
    if (nrow(data_1) == 0L || nrow(data_2) == 0L) {
      next
    }

    pair_rows <- lapply(feature_cols, function(feature) {
      freq_1 <- amrc_feature_frequency_table(data_1[[feature]])
      freq_2 <- amrc_feature_frequency_table(data_2[[feature]])
      states <- sort(unique(c(freq_1$state, freq_2$state)))
      if (length(states) == 0L) {
        return(NULL)
      }

      prop_1 <- stats::setNames(rep(0, length(states)), states)
      prop_2 <- stats::setNames(rep(0, length(states)), states)
      prop_1[freq_1$state] <- freq_1$frequency
      prop_2[freq_2$state] <- freq_2$frequency

      mode_1 <- amrc_mode_with_frequency(data_1[[feature]])
      mode_2 <- amrc_mode_with_frequency(data_2[[feature]])
      shifts <- abs(prop_1 - prop_2)
      max_state <- names(which.max(shifts))[[1]]

      data.frame(
        cluster_1 = pair[[1]],
        cluster_2 = pair[[2]],
        feature = feature,
        dominant_state_1 = mode_1$state,
        dominant_state_2 = mode_2$state,
        dominant_frequency_1 = mode_1$frequency,
        dominant_frequency_2 = mode_2$frequency,
        same_dominant_state = identical(mode_1$state, mode_2$state),
        most_shifted_state = max_state,
        max_state_frequency_shift = max(shifts, na.rm = TRUE),
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    })

    pair_rows <- Filter(Negate(is.null), pair_rows)
    if (length(pair_rows) == 0L) {
      next
    }

    pair_rows <- do.call(rbind, pair_rows)
    pair_rows <- pair_rows[pair_rows$max_state_frequency_shift >= min_frequency_shift, , drop = FALSE]
    if (!is.null(top_n) && nrow(pair_rows) > top_n) {
      pair_rows <- pair_rows[order(-pair_rows$max_state_frequency_shift, pair_rows$feature), , drop = FALSE]
      pair_rows <- utils::head(pair_rows, top_n)
    }

    rows[[length(rows) + 1L]] <- pair_rows
  }

  if (length(rows) == 0L) {
    return(data.frame(
      cluster_1 = character(0),
      cluster_2 = character(0),
      feature = character(0),
      dominant_state_1 = character(0),
      dominant_state_2 = character(0),
      dominant_frequency_1 = numeric(0),
      dominant_frequency_2 = numeric(0),
      same_dominant_state = logical(0),
      most_shifted_state = character(0),
      max_state_frequency_shift = numeric(0),
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
  }

  do.call(rbind, rows)
}

#' Select Informative Isolates for a Cluster Contrast
#'
#' Uses the strongest differentiating features between two clusters to build a
#' compact profile string for each isolate and returns the subset of rows needed
#' for downstream plotting or manual review.
#'
#' @param data A data frame containing cluster assignments and feature columns.
#' @param cluster_col Cluster column.
#' @param focal_clusters Length-2 character vector naming the clusters to
#'   compare.
#' @param feature_cols Character vector naming feature columns.
#' @param id_col Optional isolate identifier column. When `NULL`, the function
#'   falls back to `isolate_id` or `LABID` when present.
#' @param differentiating_features Optional output from
#'   [amrc_find_cluster_differentiating_features()] restricted to the focal
#'   clusters.
#' @param min_frequency_shift Minimum feature-shift threshold used when
#'   `differentiating_features` is not supplied.
#' @param max_features Maximum number of top differentiating features used to
#'   define the profile string.
#' @param profile_col Output column name for the concatenated feature profile.
#'
#' @return A list containing the filtered `data`, the `selected_features`, and
#'   the underlying `feature_summary`.
#' @export
amrc_select_informative_isolates <- function(
  data,
  cluster_col,
  focal_clusters,
  feature_cols,
  id_col = NULL,
  differentiating_features = NULL,
  min_frequency_shift = 0.8,
  max_features = 10,
  profile_col = "feature_profile"
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(cluster_col, data, arg_name = "cluster_col")
  amrc_assert_column_set(feature_cols, data, arg_name = "feature_cols")

  focal_clusters <- as.character(focal_clusters)
  if (length(focal_clusters) != 2L) {
    stop("focal_clusters must contain exactly two cluster labels.", call. = FALSE)
  }

  if (is.null(id_col)) {
    id_col <- amrc_default_existing_column(data, c("isolate_id", "LABID"))
    if (is.null(id_col)) {
      stop(
        "id_col could not be inferred. Supply an identifier column such as 'isolate_id' or 'LABID'.",
        call. = FALSE
      )
    }
  } else {
    amrc_assert_single_column_name(id_col, data, arg_name = "id_col")
  }

  missing_clusters <- setdiff(focal_clusters, unique(as.character(stats::na.omit(data[[cluster_col]]))))
  if (length(missing_clusters) > 0L) {
    stop(
      "focal_clusters were not found in data: ",
      paste(utils::head(missing_clusters, 10L), collapse = ", "),
      call. = FALSE
    )
  }

  cluster_subset <- data[data[[cluster_col]] %in% focal_clusters, , drop = FALSE]
  if (nrow(cluster_subset) == 0L) {
    stop("No rows matched focal_clusters.", call. = FALSE)
  }

  if (is.null(differentiating_features)) {
    differentiating_features <- amrc_find_cluster_differentiating_features(
      data = cluster_subset,
      cluster_col = cluster_col,
      feature_cols = feature_cols,
      cluster_pairs = list(focal_clusters),
      min_frequency_shift = min_frequency_shift,
      top_n = max_features
    )
  }

  if (nrow(differentiating_features) == 0L) {
    stop("No differentiating features met the requested criteria.", call. = FALSE)
  }

  feature_summary <- differentiating_features[
    order(-differentiating_features$max_state_frequency_shift, differentiating_features$feature),
    ,
    drop = FALSE
  ]
  selected_features <- unique(utils::head(feature_summary$feature, max_features))

  out <- cluster_subset
  out[[profile_col]] <- apply(out[, selected_features, drop = FALSE], 1, function(row) {
    paste(paste(selected_features, as.character(row), sep = "="), collapse = " | ")
  })

  keep_cols <- unique(c(id_col, cluster_col, selected_features, profile_col, colnames(out)))
  keep_cols <- keep_cols[keep_cols %in% colnames(out)]

  list(
    data = out[, keep_cols, drop = FALSE],
    selected_features = selected_features,
    feature_summary = feature_summary
  )
}
