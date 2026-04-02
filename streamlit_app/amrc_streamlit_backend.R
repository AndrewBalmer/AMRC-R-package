`%||%` <- function(x, y) {
  if (is.null(x) || identical(x, "")) y else x
}

amrc_scalar_or_null <- function(x) {
  if (is.null(x) || length(x) == 0L || identical(x, "")) {
    return(NULL)
  }
  if (is.atomic(x) && length(x) == 1L) {
    return(as.character(x))
  }
  x
}

amrc_vector_or_null <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NULL)
  }
  x <- as.character(x)
  x <- x[nzchar(x)]
  if (length(x) == 0L) {
    return(NULL)
  }
  unique(x)
}

amrc_numeric_or_null <- function(x) {
  x <- amrc_scalar_or_null(x)
  if (is.null(x)) {
    return(NULL)
  }
  value <- suppressWarnings(as.numeric(x))
  if (length(value) != 1L || is.na(value) || !is.finite(value)) {
    return(NULL)
  }
  value
}

amrc_positive_limit_or_null <- function(x) {
  value <- amrc_numeric_or_null(x)
  if (is.null(value) || !isTRUE(value > 0)) {
    return(NULL)
  }
  c(0, value)
}

amrc_breaks_from_step <- function(values, step, limits = NULL) {
  step <- amrc_numeric_or_null(step)
  if (is.null(step) || !isTRUE(step > 0)) {
    return(NULL)
  }

  if (!is.null(limits)) {
    lower <- limits[[1]]
    upper <- limits[[2]]
  } else {
    finite_values <- values[is.finite(values)]
    if (length(finite_values) == 0L) {
      return(NULL)
    }
    lower <- min(finite_values, na.rm = TRUE)
    upper <- max(finite_values, na.rm = TRUE)
  }

  if (!is.finite(lower) || !is.finite(upper) || upper < lower) {
    return(NULL)
  }

  seq(
    from = floor(lower / step) * step,
    to = ceiling(upper / step) * step,
    by = step
  )
}

amrc_first_existing_column <- function(data, candidates) {
  hits <- candidates[candidates %in% colnames(data)]
  if (length(hits) == 0L) {
    return(NULL)
  }
  hits[[1]]
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Usage: Rscript streamlit_app/amrc_streamlit_backend.R <config.json>", call. = FALSE)
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required for the Streamlit backend.", call. = FALSE)
}

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required for the Streamlit backend.", call. = FALSE)
}

config <- jsonlite::fromJSON(args[[1]], simplifyVector = TRUE)
repo_root <- normalizePath(config$repo_root, mustWork = TRUE)
output_dir <- normalizePath(config$output_dir, winslash = "/", mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

amrc_load_package <- function(repo_root, prefer_installed = FALSE) {
  if (isTRUE(prefer_installed) && requireNamespace("amrcartography", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(
      path = repo_root,
      export_all = FALSE,
      helpers = FALSE,
      attach_testthat = FALSE,
      quiet = TRUE
    )

    return(invisible(TRUE))
  }

  if (requireNamespace("amrcartography", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  stop(
    "Neither pkgload nor an installed copy of amrcartography is available. ",
    "Install pkgload to run the app from the repo checkout, or install the package first.",
    call. = FALSE
  )

  invisible(TRUE)
}

prefer_installed_package <- identical(Sys.getenv("AMRC_PACKAGE_LOAD_MODE"), "installed")

amrc_load_package(repo_root, prefer_installed = prefer_installed_package)

amrc_fn <- function(name) getExportedValue("amrcartography", name)

read_csv_keep_names <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_plot <- function(plot, path, width = 7, height = 6) {
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = width,
    height = height,
    dpi = 300
  )
}

prepare_map_frame <- function(mds_result, metadata, id_col, prefix = "D") {
  coords <- as.data.frame(mds_result$conf, stringsAsFactors = FALSE, check.names = FALSE)
  colnames(coords) <- paste0(prefix, seq_len(ncol(coords)))

  ids <- rownames(coords)
  if (is.null(ids) || any(!nzchar(ids))) {
    ids <- as.character(metadata[[id_col]])
  }

  coords[[id_col]] <- ids
  metadata_aligned <- metadata[match(ids, metadata[[id_col]]), , drop = FALSE]
  cbind(
    coords[, c(id_col, setdiff(colnames(coords), id_col)), drop = FALSE],
    metadata_aligned[, setdiff(colnames(metadata_aligned), id_col), drop = FALSE]
  )
}

parse_precomputed_distance <- function(path, id_col) {
  raw <- read_csv_keep_names(path)

  if (!(id_col %in% colnames(raw))) {
    stop("The external distance file is missing the selected ID column.", call. = FALSE)
  }

  row_ids <- as.character(raw[[id_col]])
  matrix_df <- raw[, setdiff(colnames(raw), id_col), drop = FALSE]
  distance_matrix <- as.matrix(matrix_df)
  storage.mode(distance_matrix) <- "double"
  rownames(distance_matrix) <- row_ids

  if (nrow(distance_matrix) != ncol(distance_matrix)) {
    stop(
      "Precomputed external distance matrices must be square after removing the ID column.",
      call. = FALSE
    )
  }

  if (is.null(colnames(distance_matrix)) || any(!nzchar(colnames(distance_matrix)))) {
    colnames(distance_matrix) <- row_ids
  }

  amrc_fn("amrc_compute_external_distance")(
    distance_matrix,
    isolate_ids = row_ids
  )
}

id_col <- config$phenotype$id_col
metadata_cols <- config$phenotype$metadata_cols %||% character()
fill_col <- amrc_scalar_or_null(config$plot$fill_col)
facet_by <- amrc_scalar_or_null(config$plot$facet_by)
group_col <- amrc_scalar_or_null(config$comparison$group_col)
grid_spacing <- if (isTRUE(config$plot$grid_spacing_one)) 1 else NULL
density_mode <- if (isTRUE(config$plot$density)) "contour" else "none"
cluster_enabled <- isTRUE(config$clustering$enabled)
cluster_n <- as.integer(config$clustering$n_clusters %||% 4L)
cluster_max_k <- as.integer(config$clustering$max_k %||% max(cluster_n + 2L, 10L))
cluster_distinct_col <- amrc_scalar_or_null(config$clustering$distinct_col) %||% id_col
reference_enabled <- isTRUE(config$reference$enabled)
reference_col <- amrc_scalar_or_null(config$reference$reference_col)
reference_value <- amrc_scalar_or_null(config$reference$reference_value)
reference_filter_col <- amrc_scalar_or_null(config$reference$filter_col)
reference_filter_values <- amrc_vector_or_null(config$reference$filter_values)
reference_cluster_mode <- amrc_scalar_or_null(config$reference$cluster_mode) %||% "auto"
reference_x_max <- amrc_numeric_or_null(config$reference$x_max)
reference_y_max <- amrc_numeric_or_null(config$reference$y_max)
reference_x_break_step <- amrc_numeric_or_null(config$reference$x_break_step)
reference_y_break_step <- amrc_numeric_or_null(config$reference$y_break_step)
reference_annotation_text <- amrc_scalar_or_null(config$reference$annotation_text)
reference_annotation_x <- amrc_numeric_or_null(config$reference$annotation_x)
reference_annotation_y <- amrc_numeric_or_null(config$reference$annotation_y)

phenotype_data <- read_csv_keep_names(config$phenotype$path)

mic_data <- amrc_fn("amrc_standardise_mic_data")(
  data = phenotype_data,
  id_col = id_col,
  mic_cols = config$phenotype$mic_cols,
  metadata_cols = metadata_cols,
  transform = config$phenotype$transform,
  drop_incomplete = isTRUE(config$phenotype$drop_incomplete),
  less_than = config$phenotype$less_than,
  greater_than = config$phenotype$greater_than
)

phenotype_distance <- amrc_fn("amrc_compute_mic_distance")(mic_data)
phenotype_map <- amrc_fn("amrc_compute_mds")(phenotype_distance)
phenotype_plot_data <- prepare_map_frame(
  mds_result = phenotype_map,
  metadata = mic_data$metadata,
  id_col = id_col,
  prefix = "D"
)

phenotype_plot <- amrc_fn("amrc_plot_map")(
  data = phenotype_plot_data,
  x = "D1",
  y = "D2",
  fill_col = fill_col,
  facet_by = facet_by,
  grid_spacing = grid_spacing,
  density = density_mode,
  use_cartography_theme = TRUE
)

write_plot(phenotype_plot, file.path(output_dir, "phenotype_map.png"))
utils::write.csv(
  phenotype_plot_data,
  file = file.path(output_dir, "phenotype_map_data.csv"),
  row.names = FALSE
)

phenotype_cluster <- NULL
phenotype_cluster_data <- phenotype_plot_data
if (isTRUE(cluster_enabled)) {
  phenotype_cluster <- amrc_fn("amrc_cluster_map")(
    data = phenotype_plot_data,
    coord_cols = c("D1", "D2"),
    n_clusters = cluster_n,
    distinct_col = cluster_distinct_col,
    max_k = cluster_max_k
  )
  phenotype_cluster_data <- amrc_fn("amrc_add_cluster_assignments")(
    data = phenotype_plot_data,
    assignments = phenotype_cluster$assignments,
    key_col = cluster_distinct_col,
    cluster_col = "phen_cluster"
  )
  phenotype_cluster_plot <- amrc_fn("amrc_plot_cluster_map")(
    data = phenotype_cluster_data,
    x = "D1",
    y = "D2",
    cluster_col = "phen_cluster",
    facet_by = facet_by,
    show_legend = TRUE
  )
  write_plot(phenotype_cluster_plot, file.path(output_dir, "phenotype_cluster_map.png"))
  phenotype_elbow_plot <- amrc_fn("amrc_plot_cluster_elbow")(
    scree_data = phenotype_cluster$scree,
    highlight_cluster = cluster_n,
    draw_path = TRUE
  )
  write_plot(
    phenotype_elbow_plot,
    file.path(output_dir, "phenotype_cluster_elbow.png"),
    width = 7,
    height = 5
  )
  utils::write.csv(
    phenotype_cluster_data,
    file = file.path(output_dir, "phenotype_cluster_data.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    phenotype_cluster$scree,
    file = file.path(output_dir, "phenotype_cluster_scree.csv"),
    row.names = FALSE
  )
}

summary <- list(
  package_release_target = "v0.2.0",
  phenotype = list(
    n_isolates = nrow(phenotype_plot_data),
    n_drugs = ncol(mic_data$mic),
    stress = unname(phenotype_map$stress %||% NA_real_),
    clustering = if (isTRUE(cluster_enabled)) {
      list(
        n_clusters = cluster_n,
        distinct_col = cluster_distinct_col,
        max_k = cluster_max_k,
        selected_inertia = if (!is.null(phenotype_cluster)) {
          phenotype_cluster$scree$within_cluster_inertia[
            phenotype_cluster$scree$n_clusters == cluster_n
          ][1]
        } else {
          NULL
        }
      )
    } else {
      NULL
    }
  ),
  external = NULL
)

result_bundle <- list(
  summary = summary,
  mic_data = mic_data,
  phenotype_distance = phenotype_distance,
  phenotype_map = phenotype_map,
  phenotype_plot_data = phenotype_plot_data,
  phenotype_cluster = phenotype_cluster,
  phenotype_cluster_data = phenotype_cluster_data
)

if (isTRUE(config$external$enabled)) {
  mode <- config$external$mode
  external_path <- config$external$path
  external_id_col <- config$external$id_col
  external_feature_cols <- config$external$feature_cols %||% character()

  if (identical(mode, "precomputed_distance")) {
    external_distance <- parse_precomputed_distance(
      path = external_path,
      id_col = external_id_col
    )
  } else if (identical(mode, "numeric_features")) {
    external_raw <- read_csv_keep_names(external_path)
    external_standardised <- amrc_fn("amrc_standardise_external_data")(
      data = external_raw,
      id_col = external_id_col,
      feature_cols = external_feature_cols,
      feature_mode = "numeric",
      drop_incomplete = TRUE
    )
    external_distance <- amrc_fn("amrc_compute_external_feature_distance")(external_standardised)
  } else if (identical(mode, "character_features")) {
    external_raw <- read_csv_keep_names(external_path)
    external_standardised <- amrc_fn("amrc_standardise_external_data")(
      data = external_raw,
      id_col = external_id_col,
      feature_cols = external_feature_cols,
      feature_mode = "character",
      drop_incomplete = TRUE
    )
    external_distance <- amrc_fn("amrc_compute_external_feature_distance")(external_standardised)
  } else if (identical(mode, "sequence_alleles")) {
    external_raw <- read_csv_keep_names(external_path)
    external_distance <- amrc_fn("amrc_compute_sequence_distance")(
      data = external_raw,
      id_col = external_id_col,
      sequence_cols = external_feature_cols
    )
  } else {
    stop("Unsupported external mode: ", mode, call. = FALSE)
  }

  external_map <- amrc_fn("amrc_compute_mds")(external_distance)
  comparison_bundle <- amrc_fn("amrc_prepare_map_data")(
    metadata = mic_data$metadata,
    phenotype_mds = phenotype_map,
    external_mds = external_map,
    id_col = id_col,
    group_col = group_col
  )

  external_plot <- amrc_fn("amrc_plot_map")(
    data = comparison_bundle$data,
    x = "E1",
    y = "E2",
    fill_col = fill_col,
    facet_by = facet_by,
    grid_spacing = grid_spacing,
    density = density_mode,
    use_cartography_theme = TRUE
  )
  side_plot <- amrc_fn("amrc_plot_side_by_side_maps")(
    data = comparison_bundle$data,
    fill_col = fill_col,
    grid_spacing = grid_spacing
  )

  write_plot(external_plot, file.path(output_dir, "external_map.png"))
  write_plot(side_plot, file.path(output_dir, "side_by_side_maps.png"), width = 10, height = 5)
  utils::write.csv(
    comparison_bundle$data,
    file = file.path(output_dir, "comparison_data.csv"),
    row.names = FALSE
  )

  external_cluster <- NULL
  external_cluster_data <- comparison_bundle$data
  if (isTRUE(cluster_enabled)) {
    join_key <- cluster_distinct_col
    if (!(join_key %in% colnames(external_cluster_data))) {
      join_key <- id_col
    }
    external_cluster <- amrc_fn("amrc_cluster_map")(
      data = external_cluster_data,
      coord_cols = c("E1", "E2"),
      n_clusters = cluster_n,
      distinct_col = join_key,
      max_k = cluster_max_k
    )
    external_cluster_data <- amrc_fn("amrc_add_cluster_assignments")(
      data = external_cluster_data,
      assignments = external_cluster$assignments,
      key_col = join_key,
      cluster_col = "external_cluster"
    )
    external_cluster_plot <- amrc_fn("amrc_plot_cluster_map")(
      data = external_cluster_data,
      x = "E1",
      y = "E2",
      cluster_col = "external_cluster",
      facet_by = facet_by,
      show_legend = TRUE
    )
    write_plot(external_cluster_plot, file.path(output_dir, "external_cluster_map.png"))
    external_elbow_plot <- amrc_fn("amrc_plot_cluster_elbow")(
      scree_data = external_cluster$scree,
      highlight_cluster = cluster_n,
      draw_path = TRUE
    )
    write_plot(
      external_elbow_plot,
      file.path(output_dir, "external_cluster_elbow.png"),
      width = 7,
      height = 5
    )
    utils::write.csv(
      external_cluster_data,
      file = file.path(output_dir, "external_cluster_data.csv"),
      row.names = FALSE
    )
    utils::write.csv(
      external_cluster$scree,
      file = file.path(output_dir, "external_cluster_scree.csv"),
      row.names = FALSE
    )
  }

  reference_outputs <- NULL
  if (isTRUE(reference_enabled) && !is.null(reference_col) && !is.null(reference_value)) {
    ref_cluster_col <- switch(
      reference_cluster_mode,
      "overall" = FALSE,
      "clustered" = if ("external_cluster" %in% colnames(external_cluster_data)) "external_cluster" else FALSE,
      if ("external_cluster" %in% colnames(external_cluster_data)) "external_cluster" else FALSE
    )
    reference_table <- amrc_fn("amrc_compute_reference_distance_table")(
      data = external_cluster_data,
      reference_value = reference_value,
      reference_col = reference_col,
      phenotype_cols = c("D1", "D2"),
      external_cols = c("E1", "E2"),
      id_col = id_col,
      cluster_col = ref_cluster_col,
      keep_cols = unique(stats::na.omit(c(fill_col, group_col, reference_filter_col)))
    )
    if (!is.null(reference_filter_col)) {
      if (!(reference_filter_col %in% colnames(reference_table))) {
        stop("reference filter column was not found in the reference-distance table.", call. = FALSE)
      }
      if (!is.null(reference_filter_values)) {
        reference_table <- reference_table[
          as.character(reference_table[[reference_filter_col]]) %in% reference_filter_values,
          ,
          drop = FALSE
        ]
      }
      if (nrow(reference_table) == 0L) {
        stop("Reference-distance filtering removed all rows.", call. = FALSE)
      }
    }
    reference_summary <- amrc_fn("amrc_summarise_reference_distance_table")(
      distance_table = reference_table,
      cluster_col = ref_cluster_col
    )
    reference_x_limits <- amrc_positive_limit_or_null(reference_x_max)
    reference_y_limits <- amrc_positive_limit_or_null(reference_y_max)
    reference_x_col <- amrc_first_existing_column(reference_table, c("external_distance", "gen_distance"))
    reference_y_col <- amrc_first_existing_column(reference_table, c("phenotype_distance", "phen_distance"))
    reference_plot <- amrc_fn("amrc_plot_reference_distance_relationship")(
      distance_table = reference_table,
      cluster_col = ref_cluster_col,
      x_limits = reference_x_limits,
      y_limits = reference_y_limits,
      x_breaks = if (!is.null(reference_x_col)) {
        amrc_breaks_from_step(reference_table[[reference_x_col]], reference_x_break_step, reference_x_limits)
      } else {
        NULL
      },
      y_breaks = if (!is.null(reference_y_col)) {
        amrc_breaks_from_step(reference_table[[reference_y_col]], reference_y_break_step, reference_y_limits)
      } else {
        NULL
      },
      annotation_text = reference_annotation_text,
      annotation_x = reference_annotation_x,
      annotation_y = reference_annotation_y
    )
    write_plot(
      reference_plot,
      file.path(output_dir, "reference_distance_relationship.png"),
      width = 7,
      height = 6
    )
    utils::write.csv(
      reference_table,
      file = file.path(output_dir, "reference_distance_table.csv"),
      row.names = FALSE
    )
    utils::write.csv(
      reference_summary$summary,
      file = file.path(output_dir, "reference_distance_summary.csv"),
      row.names = FALSE
    )
    reference_outputs <- list(
      table = reference_table,
      summary = reference_summary
    )
  }

  summary$external <- list(
    mode = mode,
    n_isolates = nrow(comparison_bundle$data),
    stress = unname(external_map$stress %||% NA_real_),
    clustering = if (isTRUE(cluster_enabled)) {
      list(
        n_clusters = cluster_n,
        distinct_col = cluster_distinct_col,
        max_k = cluster_max_k,
        selected_inertia = if (!is.null(external_cluster)) {
          external_cluster$scree$within_cluster_inertia[
            external_cluster$scree$n_clusters == cluster_n
          ][1]
        } else {
          NULL
        }
      )
    } else {
      NULL
    },
    reference = if (!is.null(reference_outputs)) {
      list(
        reference_col = reference_col,
        reference_value = reference_value,
        n_rows = nrow(reference_outputs$table),
        cluster_mode = reference_cluster_mode,
        filter_col = reference_filter_col,
        filter_values = reference_filter_values,
        x_break_step = reference_x_break_step,
        y_break_step = reference_y_break_step,
        annotation_text = reference_annotation_text
      )
    } else {
      NULL
    }
  )

  result_bundle$summary <- summary
  result_bundle$external_distance <- external_distance
  result_bundle$external_map <- external_map
  result_bundle$comparison_bundle <- comparison_bundle
  result_bundle$external_cluster <- external_cluster
  result_bundle$external_cluster_data <- external_cluster_data
  result_bundle$reference_outputs <- reference_outputs
}

jsonlite::write_json(
  summary,
  path = file.path(output_dir, "summary.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

saveRDS(
  result_bundle,
  file = file.path(output_dir, "amrc_result_bundle.rds")
)
