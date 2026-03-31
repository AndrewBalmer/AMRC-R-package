#' Locate Bundled Generic Example Data Files
#'
#' Returns the packaged file paths for the lightweight generic example datasets
#' used in the generic vignettes.
#'
#' @param mustWork Logical; when `TRUE`, fail if any expected file is missing.
#'
#' @return A named list of file paths.
#' @export
amrc_example_data_paths <- function(mustWork = TRUE) {
  root <- system.file("extdata", "examples", "generic", package = "amrcartography")
  if (!nzchar(root)) {
    root <- file.path("inst", "extdata", "examples", "generic")
  }

  paths <- list(
    root = root,
    mic_raw = file.path(root, "mic_raw.csv"),
    external_numeric = file.path(root, "external_numeric.csv"),
    external_character = file.path(root, "external_character.csv"),
    external_distance = file.path(root, "external_distance.csv")
  )

  if (isTRUE(mustWork)) {
    missing_paths <- unlist(paths[names(paths) != "root"], use.names = TRUE)
    missing_paths <- missing_paths[!file.exists(missing_paths)]
    if (length(missing_paths) > 0) {
      stop(
        "Missing packaged generic example files: ",
        paste(missing_paths, collapse = ", "),
        call. = FALSE
      )
    }
  }

  paths
}

#' Load a Bundled Generic Example Dataset
#'
#' Loads one of the small generic datasets that ship with the package. These
#' are intended for documentation, teaching, and quick checks of the generic
#' MIC-cartography workflow.
#'
#' @param name Which dataset to load.
#'
#' @return A `data.frame` for the tabular examples, or a numeric matrix for the
#'   precomputed distance example.
#' @export
amrc_example_data <- function(
  name = c("mic_raw", "external_numeric", "external_character", "external_distance")
) {
  name <- match.arg(name)
  paths <- amrc_example_data_paths()
  path <- paths[[name]]

  if (identical(name, "external_distance")) {
    distance_matrix <- as.matrix(
      utils::read.csv(path, row.names = 1, check.names = FALSE)
    )
    storage.mode(distance_matrix) <- "double"
    return(distance_matrix)
  }

  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
