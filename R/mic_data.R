amrc_assert_is_data_frame <- function(data, arg_name = "data") {
  if (!is.data.frame(data)) {
    stop(arg_name, " must be a data.frame.", call. = FALSE)
  }

  invisible(data)
}

amrc_assert_single_column_name <- function(column, data, arg_name = "column") {
  if (!is.character(column) || length(column) != 1L || is.na(column) || !nzchar(column)) {
    stop(arg_name, " must be a single non-empty column name.", call. = FALSE)
  }

  if (!(column %in% colnames(data))) {
    stop(arg_name, " '", column, "' is not present in the input data.", call. = FALSE)
  }

  invisible(column)
}

amrc_assert_column_set <- function(columns, data, arg_name = "columns") {
  if (is.null(columns)) {
    return(invisible(character()))
  }

  if (!is.character(columns) || anyNA(columns) || any(!nzchar(columns))) {
    stop(arg_name, " must be a character vector of non-empty column names.", call. = FALSE)
  }

  missing_columns <- setdiff(columns, colnames(data))
  if (length(missing_columns) > 0) {
    stop(
      arg_name,
      " contains columns not present in the input data: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(columns)
}

amrc_numeric_coercion <- function(x, column_name) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }

  x_chr <- as.character(x)
  x_chr[trimws(x_chr) == ""] <- NA_character_
  out <- suppressWarnings(as.numeric(x_chr))

  bad <- !is.na(x_chr) & is.na(out)
  if (any(bad)) {
    bad_values <- unique(x_chr[bad])
    bad_values <- bad_values[seq_len(min(length(bad_values), 5L))]
    stop(
      "MIC column '",
      column_name,
      "' contains values that could not be coerced to numeric: ",
      paste(bad_values, collapse = ", "),
      call. = FALSE
    )
  }

  out
}

amrc_resolve_metadata_cols <- function(data, id_col, mic_cols, metadata_cols = NULL) {
  if (is.null(metadata_cols)) {
    return(setdiff(colnames(data), mic_cols))
  }

  unique(c(id_col, metadata_cols))
}

amrc_mic_matrix_from_input <- function(x) {
  if (inherits(x, "amrc_mic_data")) {
    mic <- as.data.frame(x$mic, check.names = FALSE)
    rownames(mic) <- x$isolate_ids
    return(mic)
  }

  if (is.matrix(x)) {
    x <- as.data.frame(x, check.names = FALSE)
  }

  amrc_assert_is_data_frame(x, arg_name = "x")

  mic <- as.data.frame(
    Map(
      function(column, name) amrc_numeric_coercion(column, name),
      x,
      colnames(x)
    ),
    check.names = FALSE
  )
  rownames(mic) <- rownames(x)
  mic
}

amrc_distance_labels <- function(distance_matrix) {
  attr(distance_matrix, "Labels")
}

#' Validate a Generic MIC Input Table
#'
#' Checks that a user-supplied MIC table has the required identifier and MIC
#' columns, that those columns do not overlap in invalid ways, and that the MIC
#' columns are numeric or cleanly coercible to numeric.
#'
#' @param data A `data.frame` containing isolate identifiers, MIC columns, and
#'   optional metadata columns.
#' @param id_col Name of the isolate identifier column.
#' @param mic_cols Character vector naming the MIC measurement columns.
#' @param metadata_cols Optional character vector naming metadata columns to
#'   retain. When `NULL`, all non-MIC columns are treated as metadata.
#' @param allow_duplicate_ids Logical; allow duplicate isolate identifiers when
#'   `TRUE`.
#' @param require_complete_mic Logical; fail validation if any MIC value is
#'   missing.
#'
#' @return A named list describing the validated schema.
#' @export
amrc_validate_mic_data <- function(
  data,
  id_col,
  mic_cols,
  metadata_cols = NULL,
  allow_duplicate_ids = FALSE,
  require_complete_mic = FALSE
) {
  amrc_assert_is_data_frame(data)
  amrc_assert_single_column_name(id_col, data, arg_name = "id_col")
  amrc_assert_column_set(mic_cols, data, arg_name = "mic_cols")
  metadata_cols <- amrc_resolve_metadata_cols(data, id_col, mic_cols, metadata_cols)
  amrc_assert_column_set(metadata_cols, data, arg_name = "metadata_cols")

  overlap <- intersect(mic_cols, metadata_cols)
  if (length(overlap) > 0) {
    stop(
      "MIC columns and metadata columns must not overlap: ",
      paste(overlap, collapse = ", "),
      call. = FALSE
    )
  }

  ids <- as.character(data[[id_col]])
  if (anyNA(ids) || any(!nzchar(ids))) {
    stop("The isolate identifier column contains missing or blank values.", call. = FALSE)
  }
  if (!isTRUE(allow_duplicate_ids) && anyDuplicated(ids) > 0) {
    stop("The isolate identifier column contains duplicate values.", call. = FALSE)
  }

  mic <- amrc_extract_mic_matrix(data, mic_cols = mic_cols, transform = "none")
  complete_rows <- stats::complete.cases(mic)
  if (isTRUE(require_complete_mic) && any(!complete_rows)) {
    stop("MIC columns contain missing values.", call. = FALSE)
  }

  list(
    id_col = id_col,
    mic_cols = mic_cols,
    metadata_cols = metadata_cols,
    isolate_ids = ids,
    n_rows = nrow(data),
    n_mic_cols = length(mic_cols),
    n_metadata_cols = length(setdiff(metadata_cols, id_col)),
    has_complete_mic = all(complete_rows)
  )
}

#' Extract a Numeric MIC Matrix
#'
#' Pulls a set of MIC columns out of a wider table, coerces them to numeric, and
#' optionally applies a log2 transform.
#'
#' @param data A `data.frame` containing MIC columns.
#' @param mic_cols Character vector naming the MIC measurement columns.
#' @param transform Either `"none"` or `"log2"`.
#' @param log2_round Logical; round transformed values after applying `log2()`.
#'
#' @return A numeric `data.frame` containing only MIC columns.
#' @export
amrc_extract_mic_matrix <- function(
  data,
  mic_cols,
  transform = c("none", "log2"),
  log2_round = FALSE
) {
  transform <- match.arg(transform)
  amrc_assert_is_data_frame(data)
  amrc_assert_column_set(mic_cols, data, arg_name = "mic_cols")

  mic <- as.data.frame(
    Map(
      function(column, name) amrc_numeric_coercion(column, name),
      data[, mic_cols, drop = FALSE],
      mic_cols
    ),
    check.names = FALSE
  )

  if (identical(transform, "log2")) {
    invalid <- vapply(mic, function(column) any(column <= 0, na.rm = TRUE), logical(1))
    if (any(invalid)) {
      stop(
        "MIC columns must contain positive values to apply a log2 transform: ",
        paste(names(invalid)[invalid], collapse = ", "),
        call. = FALSE
      )
    }

    mic[] <- lapply(mic, log2)
    if (isTRUE(log2_round)) {
      mic[] <- lapply(mic, round)
    }
  }

  mic
}

#' Extract Isolate Metadata from a MIC Table
#'
#' Returns the identifier column plus any requested metadata columns, excluding
#' MIC measurement columns.
#'
#' @param data A `data.frame` containing isolate identifiers, MIC columns, and
#'   optional metadata columns.
#' @param id_col Name of the isolate identifier column.
#' @param mic_cols Character vector naming the MIC measurement columns.
#' @param metadata_cols Optional character vector naming metadata columns to
#'   retain. When `NULL`, all non-MIC columns are returned.
#'
#' @return A `data.frame` of metadata columns aligned to the input rows.
#' @export
amrc_extract_isolate_metadata <- function(
  data,
  id_col,
  mic_cols,
  metadata_cols = NULL
) {
  amrc_assert_is_data_frame(data)
  amrc_assert_single_column_name(id_col, data, arg_name = "id_col")
  amrc_assert_column_set(mic_cols, data, arg_name = "mic_cols")
  metadata_cols <- amrc_resolve_metadata_cols(data, id_col, mic_cols, metadata_cols)
  amrc_assert_column_set(metadata_cols, data, arg_name = "metadata_cols")

  metadata_cols <- unique(c(id_col, setdiff(metadata_cols, mic_cols)))
  data[, metadata_cols, drop = FALSE]
}

#' Standardise a Generic MIC Dataset
#'
#' Converts a user-supplied MIC table into a standard package object with
#' aligned isolate identifiers, MIC matrix, metadata table, and row exclusions.
#'
#' @param data A `data.frame` containing isolate identifiers, MIC columns, and
#'   optional metadata columns.
#' @param id_col Name of the isolate identifier column.
#' @param mic_cols Character vector naming the MIC measurement columns.
#' @param metadata_cols Optional character vector naming metadata columns to
#'   retain. When `NULL`, all non-MIC columns are retained.
#' @param transform Either `"none"` or `"log2"`.
#' @param log2_round Logical; round transformed values after applying `log2()`.
#' @param drop_incomplete Logical; drop rows with incomplete MIC profiles.
#' @param allow_duplicate_ids Logical; allow duplicate isolate identifiers when
#'   `TRUE`.
#'
#' @return An `amrc_mic_data` object.
#' @export
amrc_standardise_mic_data <- function(
  data,
  id_col,
  mic_cols,
  metadata_cols = NULL,
  transform = c("none", "log2"),
  log2_round = FALSE,
  drop_incomplete = TRUE,
  allow_duplicate_ids = FALSE
) {
  transform <- match.arg(transform)

  validation <- amrc_validate_mic_data(
    data = data,
    id_col = id_col,
    mic_cols = mic_cols,
    metadata_cols = metadata_cols,
    allow_duplicate_ids = allow_duplicate_ids,
    require_complete_mic = FALSE
  )

  ids <- validation$isolate_ids
  mic <- amrc_extract_mic_matrix(
    data = data,
    mic_cols = mic_cols,
    transform = transform,
    log2_round = log2_round
  )
  metadata <- amrc_extract_isolate_metadata(
    data = data,
    id_col = id_col,
    mic_cols = mic_cols,
    metadata_cols = validation$metadata_cols
  )

  excluded_rows <- integer()
  if (isTRUE(drop_incomplete)) {
    keep <- stats::complete.cases(mic)
    excluded_rows <- which(!keep)
    ids <- ids[keep]
    mic <- mic[keep, , drop = FALSE]
    metadata <- metadata[keep, , drop = FALSE]
  }

  rownames(mic) <- ids
  rownames(metadata) <- ids

  structure(
    list(
      isolate_ids = ids,
      mic = mic,
      metadata = metadata,
      drug_columns = mic_cols,
      id_column = id_col,
      transform = transform,
      excluded_rows = excluded_rows
    ),
    class = "amrc_mic_data"
  )
}

#' Compute a Distance Matrix from MIC Data
#'
#' Computes a phenotype distance matrix from either an `amrc_mic_data` object or
#' a numeric MIC table.
#'
#' @param x An `amrc_mic_data` object, `data.frame`, or numeric matrix.
#' @param method Distance method passed to [stats::dist()].
#' @param ... Additional arguments passed to [stats::dist()].
#'
#' @return A `dist` object.
#' @export
amrc_compute_mic_distance <- function(x, method = "euclidean", ...) {
  mic <- amrc_mic_matrix_from_input(x)

  if (anyNA(mic)) {
    stop(
      "MIC distance matrices cannot be computed from inputs with missing values. ",
      "Use amrc_standardise_mic_data(drop_incomplete = TRUE) or impute values first.",
      call. = FALSE
    )
  }

  stats::dist(mic, method = method, ...)
}

#' Standardise an External Distance Structure
#'
#' Coerces a user-supplied `dist` object or square matrix/data frame into a
#' validated `dist` object.
#'
#' @param x A `dist` object, square matrix, or square `data.frame`.
#' @param isolate_ids Optional character vector used to name or align the
#'   distance structure.
#' @param check_symmetric Logical; require square matrix inputs to be symmetric.
#' @param tolerance Numeric tolerance used when checking symmetry.
#'
#' @return A `dist` object.
#' @export
amrc_compute_external_distance <- function(
  x,
  isolate_ids = NULL,
  check_symmetric = TRUE,
  tolerance = 1e-08
) {
  if (inherits(x, "dist")) {
    distance_matrix <- x
  } else {
    if (is.data.frame(x)) {
      x <- as.matrix(x)
    }
    if (!is.matrix(x)) {
      stop("x must be a dist object, matrix, or data.frame.", call. = FALSE)
    }
    if (nrow(x) != ncol(x)) {
      stop("External distance matrices must be square.", call. = FALSE)
    }

    storage.mode(x) <- "double"

    if (isTRUE(check_symmetric) &&
        !isTRUE(all.equal(x, t(x), tolerance = tolerance, check.attributes = FALSE))) {
      stop("External distance matrices must be symmetric.", call. = FALSE)
    }

    if (!is.null(isolate_ids)) {
      if (length(isolate_ids) != nrow(x)) {
        stop("isolate_ids must have the same length as the matrix dimensions.", call. = FALSE)
      }
      rownames(x) <- isolate_ids
      colnames(x) <- isolate_ids
    }

    distance_matrix <- stats::as.dist(x)
  }

  labels <- amrc_distance_labels(distance_matrix)

  if (!is.null(isolate_ids)) {
    isolate_ids <- as.character(isolate_ids)

    if (is.null(labels)) {
      distance_matrix <- stats::as.dist(`dimnames<-`(
        as.matrix(distance_matrix),
        list(isolate_ids, isolate_ids)
      ))
    } else {
      distance_matrix <- amrc_subset_distance(distance_matrix, isolate_ids = isolate_ids)
    }
  }

  distance_matrix
}

#' Subset a Distance Matrix by Isolate IDs or Positions
#'
#' @param distance_matrix A `dist` object or square matrix/data frame.
#' @param isolate_ids Optional character vector of isolate IDs to retain, in the
#'   desired output order.
#' @param positions Optional integer vector of positions to retain.
#'
#' @return A subsetted `dist` object.
#' @export
amrc_subset_distance <- function(distance_matrix, isolate_ids = NULL, positions = NULL) {
  distance_matrix <- amrc_compute_external_distance(distance_matrix)

  if (is.null(isolate_ids) && is.null(positions)) {
    stop("Provide isolate_ids or positions when subsetting a distance matrix.", call. = FALSE)
  }

  matrix_form <- as.matrix(distance_matrix)

  if (!is.null(isolate_ids)) {
    labels <- amrc_distance_labels(distance_matrix)
    if (is.null(labels)) {
      stop("distance_matrix does not contain isolate labels.", call. = FALSE)
    }

    isolate_ids <- as.character(isolate_ids)
    missing_ids <- setdiff(isolate_ids, labels)
    if (length(missing_ids) > 0) {
      stop(
        "The following isolate_ids are not present in the distance matrix: ",
        paste(missing_ids, collapse = ", "),
        call. = FALSE
      )
    }

    positions <- match(isolate_ids, labels)
  }

  matrix_form <- matrix_form[positions, positions, drop = FALSE]
  stats::as.dist(matrix_form)
}

#' Create a Standard Distance Bundle
#'
#' Bundles phenotype and optional external distance structures into one standard
#' object with explicit isolate ordering.
#'
#' @param phenotype_distance A phenotype `dist` object or square distance matrix.
#' @param isolate_ids Optional character vector defining the isolate order.
#' @param external_distance Optional external `dist` object or square distance
#'   matrix aligned to the same isolates.
#'
#' @return An `amrc_distance_bundle` object.
#' @export
amrc_distance_bundle <- function(
  phenotype_distance,
  isolate_ids = NULL,
  external_distance = NULL
) {
  phenotype_distance <- amrc_compute_external_distance(
    phenotype_distance,
    isolate_ids = isolate_ids
  )

  if (is.null(isolate_ids)) {
    isolate_ids <- amrc_distance_labels(phenotype_distance)
  }

  external_standardised <- NULL
  if (!is.null(external_distance)) {
    external_standardised <- amrc_compute_external_distance(
      external_distance,
      isolate_ids = isolate_ids
    )
  }

  structure(
    list(
      isolate_ids = isolate_ids,
      phenotype_distance = phenotype_distance,
      external_distance = external_standardised
    ),
    class = "amrc_distance_bundle"
  )
}
