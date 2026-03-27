args <- commandArgs(trailingOnly = FALSE)
file_flag <- "--file="
script_path <- sub(file_flag, "", args[grep(file_flag, args)])

if (length(script_path) == 0) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

script_dir <- dirname(normalizePath(script_path))
repo_root <- normalizePath(file.path(script_dir, ".."))
r_dir <- file.path(repo_root, "R")
r_files <- sort(list.files(r_dir, pattern = "[.]R$", full.names = TRUE))

for (path in r_files) {
  sys.source(path, envir = globalenv())
}

raw_dir <- file.path(repo_root, "data-raw", "raw-data", "spneumoniae")
generated_dir <- file.path(repo_root, "inst", "extdata", "generated", "spneumoniae")

amrc_build_spneumoniae_example_outputs(
  raw_dir = raw_dir,
  out_dir = generated_dir,
  download_missing = TRUE
)

message("Example S. pneumoniae data written to: ", generated_dir)
