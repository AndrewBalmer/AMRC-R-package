amrc_test_find_repo_root <- function(start_dir = getwd()) {
  current <- normalizePath(start_dir, winslash = "/", mustWork = TRUE)

  repeat {
    if (file.exists(file.path(current, "DESCRIPTION"))) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the repository root from the current working directory.", call. = FALSE)
    }
    current <- parent
  }
}

if (!exists("amrc_standardise_mic_data", mode = "function")) {
  if (requireNamespace("amrcartography", quietly = TRUE)) {
    suppressPackageStartupMessages(
      library("amrcartography", character.only = TRUE)
    )
  } else if (requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(
      path = amrc_test_find_repo_root(),
      export_all = FALSE,
      helpers = FALSE,
      attach_testthat = FALSE,
      quiet = TRUE
    )
  }
}
