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

  distances <- sqrt(
    outer(group_a[, 1], group_b[, 1], "-")^2 +
      outer(group_a[, 2], group_b[, 2], "-")^2
  )

  as.vector(distances)
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

#' Compute Distances from a Reference PBP Type
#'
#' @param data A comparison table produced by
#'   [amrc_prepare_spneumoniae_map_data()].
#' @param reference_pbp_type Reference PBP type.
#' @param phenotype_cols Length-2 character vector for phenotype coordinates.
#' @param genotype_cols Length-2 character vector for genotype coordinates.
#' @param phenotype_reference_cols Optional alternate phenotype coordinate
#'   columns used to define the distances, for example `x_centroid` and
#'   `y_centroid`.
#' @param cluster_col Cluster column to carry through.
#'
#' @return A data frame of per-row phenotype/genotype distances from the
#'   reference PBP type.
#' @export
amrc_compute_reference_distance_table <- function(
  data,
  reference_pbp_type,
  phenotype_cols = c("D1", "D2"),
  genotype_cols = c("G1", "G2"),
  phenotype_reference_cols = phenotype_cols,
  cluster_col = "gen_cluster"
) {
  amrc_require_coordinate_columns(data, phenotype_cols)
  amrc_require_coordinate_columns(data, genotype_cols)
  amrc_require_coordinate_columns(data, phenotype_reference_cols)

  if (!("PBP_type" %in% colnames(data))) {
    stop("data must contain a PBP_type column.", call. = FALSE)
  }
  if (!(cluster_col %in% colnames(data))) {
    stop("data must contain the cluster column.", call. = FALSE)
  }

  reference_rows <- data[data$PBP_type == reference_pbp_type, , drop = FALSE]
  if (nrow(reference_rows) == 0) {
    stop("reference_pbp_type was not found in data.", call. = FALSE)
  }

  reference_row <- reference_rows[1, , drop = FALSE]
  phenotype_reference <- as.numeric(reference_row[1, phenotype_reference_cols, drop = TRUE])
  genotype_reference <- as.numeric(reference_row[1, genotype_cols, drop = TRUE])

  result <- data.frame(
    LABID = data$LABID,
    PBP_type = data$PBP_type,
    gen_cluster = data[[cluster_col]],
    phen_distance = sqrt(
      (data[[phenotype_cols[[1]]]] - phenotype_reference[[1]])^2 +
        (data[[phenotype_cols[[2]]]] - phenotype_reference[[2]])^2
    ),
    gen_distance = sqrt(
      (data[[genotype_cols[[1]]]] - genotype_reference[[1]])^2 +
        (data[[genotype_cols[[2]]]] - genotype_reference[[2]])^2
    )
  )

  colnames(result)[colnames(result) == "gen_cluster"] <- cluster_col
  result
}

#' Summarise Reference-Distance Comparisons by Cluster
#'
#' @param distance_table Output from [amrc_compute_reference_distance_table()].
#' @param cluster_col Cluster column in `distance_table`.
#' @param digits Number of digits used when rounding the summary tables.
#'
#' @return A list containing the raw `distance_table`, per-cluster `summary`,
#'   `summary_with_overall` rows, a linear-model fit, and a Spearman
#'   correlation test.
#' @export
amrc_summarise_reference_distance_table <- function(
  distance_table,
  cluster_col = "gen_cluster",
  digits = 2
) {
  required_cols <- c(cluster_col, "phen_distance", "gen_distance")
  missing_cols <- setdiff(required_cols, colnames(distance_table))
  if (length(missing_cols) > 0) {
    stop(
      "distance_table is missing required columns: ",
      paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  }

  phen_means <- stats::aggregate(
    distance_table$phen_distance,
    by = list(cluster = distance_table[[cluster_col]]),
    FUN = mean
  )
  gen_means <- stats::aggregate(
    distance_table$gen_distance,
    by = list(cluster = distance_table[[cluster_col]]),
    FUN = mean
  )

  summary <- merge(phen_means, gen_means, by = "cluster", sort = FALSE)
  colnames(summary) <- c(
    "cluster",
    "mean_phenotypic_distance",
    "mean_genetic_distance"
  )
  summary$genetic_to_phenotypic_ratio <- summary$mean_genetic_distance / summary$mean_phenotypic_distance
  summary <- summary[order(summary$mean_genetic_distance), , drop = FALSE]

  average_row <- data.frame(
    cluster = "Average",
    mean_phenotypic_distance = mean(summary$mean_phenotypic_distance),
    mean_genetic_distance = mean(summary$mean_genetic_distance),
    genetic_to_phenotypic_ratio = mean(summary$genetic_to_phenotypic_ratio, na.rm = TRUE)
  )
  sd_row <- data.frame(
    cluster = "SD",
    mean_phenotypic_distance = stats::sd(summary$mean_phenotypic_distance),
    mean_genetic_distance = stats::sd(summary$mean_genetic_distance),
    genetic_to_phenotypic_ratio = stats::sd(summary$genetic_to_phenotypic_ratio, na.rm = TRUE)
  )

  rounded_summary <- summary
  rounded_summary[, 2:4] <- round(rounded_summary[, 2:4, drop = FALSE], digits = digits)

  rounded_with_overall <- rbind(rounded_summary, average_row, sd_row)
  rounded_with_overall[, 2:4] <- round(rounded_with_overall[, 2:4, drop = FALSE], digits = digits)

  fit <- stats::lm(phen_distance ~ gen_distance, data = distance_table)
  correlation <- stats::cor.test(
    distance_table$phen_distance,
    distance_table$gen_distance,
    method = "spearman",
    exact = FALSE
  )

  list(
    distance_table = distance_table,
    summary = rounded_summary,
    summary_with_overall = rounded_with_overall,
    fit = fit,
    correlation = correlation
  )
}
