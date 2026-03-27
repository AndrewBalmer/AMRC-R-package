amrc_find_repo_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    if (file.exists(file.path(current, "DESCRIPTION"))) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the repository root from: ", start, call. = FALSE)
    }

    current <- parent
  }
}

amrc_source_package_files <- function(repo_root = amrc_find_repo_root(), envir = globalenv()) {
  r_files <- sort(list.files(file.path(repo_root, "R"), pattern = "[.]R$", full.names = TRUE))

  for (path in r_files) {
    sys.source(path, envir = envir)
  }

  invisible(r_files)
}

amrc_load_rdata <- function(path, envir = parent.frame()) {
  if (!file.exists(path)) {
    stop("RData file does not exist: ", path, call. = FALSE)
  }

  load(path, envir = envir)
  invisible(path)
}

amrc_notebook_setup <- function(
  repo_root = amrc_find_repo_root(),
  ensure_outputs = TRUE,
  ensure_maps = FALSE,
  download_missing = TRUE,
  source_package = TRUE,
  envir = globalenv()
) {
  if (isTRUE(source_package)) {
    amrc_source_package_files(repo_root = repo_root, envir = envir)
  }

  raw_dir <- file.path(repo_root, "data-raw", "raw-data", "spneumoniae")
  generated_dir <- file.path(repo_root, "inst", "extdata", "generated", "spneumoniae")

  if (isTRUE(ensure_outputs)) {
    required_outputs <- file.path(
      generated_dir,
      c(
        "MIC_table_Spneumoniae.csv",
        "meta_data_Spneumoniae.csv",
        "tablemic_pneumo_3628_meta_gen_distance_matrix.RData"
      )
    )

    if (!all(file.exists(required_outputs))) {
      amrc_build_spneumoniae_example_outputs(
        raw_dir = raw_dir,
        out_dir = generated_dir,
        download_missing = download_missing
      )
    }
  }

  if (isTRUE(ensure_maps)) {
    required_maps <- file.path(
      generated_dir,
      c(
        "Spneumo_3628_PCA_start_2D_METRIC.RData",
        "Spneumo_3628_PCA_start_2D_METRIC_genetic.RData"
      )
    )

    if (!all(file.exists(required_maps))) {
      amrc_build_spneumoniae_example_maps(generated_dir = generated_dir)
    }
  }

  list(
    repo_root = repo_root,
    raw_dir = raw_dir,
    generated_dir = generated_dir
  )
}
