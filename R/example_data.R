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

  public_root <- system.file("extdata", "examples", "public-mic", package = "amrcartography")
  if (!nzchar(public_root)) {
    public_root <- file.path("inst", "extdata", "examples", "public-mic")
  }

  paths <- list(
    root = root,
    mic_raw = file.path(root, "mic_raw.csv"),
    external_numeric = file.path(root, "external_numeric.csv"),
    external_character = file.path(root, "external_character.csv"),
    external_distance = file.path(root, "external_distance.csv"),
    public_root = public_root,
    salmonella_enterica_mic = file.path(public_root, "salmonella_enterica_mic.csv"),
    campylobacter_jejuni_mic = file.path(public_root, "campylobacter_jejuni_mic.csv"),
    escherichia_coli_o157_mic = file.path(public_root, "escherichia_coli_o157_mic.csv"),
    public_mic_manifest = file.path(public_root, "public_mic_manifest.csv")
  )

  if (isTRUE(mustWork)) {
    missing_paths <- unlist(paths[!names(paths) %in% c("root", "public_root")], use.names = TRUE)
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
  name = c(
    "mic_raw",
    "external_numeric",
    "external_character",
    "external_distance",
    "salmonella_enterica_mic",
    "campylobacter_jejuni_mic",
    "escherichia_coli_o157_mic",
    "public_mic_manifest"
  )
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

#' Load Metadata for the Bundled Public MIC Species Examples
#'
#' Returns the packaged manifest describing the small public MIC subsets bundled
#' for the cross-species vignette. The suggested MIC columns can be split on
#' commas and passed directly to [amrc_standardise_mic_data()].
#'
#' @return A `data.frame` describing the packaged public MIC examples.
#' @export
amrc_public_mic_example_specs <- function() {
  amrc_example_data("public_mic_manifest")
}
