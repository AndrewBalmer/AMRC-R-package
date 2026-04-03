Sys.setenv(
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1"
)

full_args <- commandArgs(trailingOnly = FALSE)
script_flag <- "--file="
script_path <- sub(script_flag, "", full_args[grep(script_flag, full_args)])

if (length(script_path) == 0L) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

repo_root <- normalizePath(file.path(dirname(script_path), ".."))

amrc_load_package <- function(repo_root) {
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

  if (!requireNamespace("amrcartography", quietly = TRUE)) {
    stop(
      "Neither pkgload nor an installed copy of amrcartography is available.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

amrc_load_package(repo_root)

vignettes <- c(
  "vignettes/using-your-own-mic-data.Rmd",
  "vignettes/public-mic-examples-across-species.Rmd",
  "vignettes/advanced-feature-and-mixed-model-analysis.Rmd",
  "vignettes/external-data-structures.Rmd",
  "vignettes/end-to-end-spneumoniae.Rmd"
)

for (path in vignettes) {
  message("Rendering ", path)
  rmarkdown::render(
    input = path,
    output_dir = tempdir(),
    intermediates_dir = tempdir(),
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  )
}

message("All vignettes rendered successfully.")
