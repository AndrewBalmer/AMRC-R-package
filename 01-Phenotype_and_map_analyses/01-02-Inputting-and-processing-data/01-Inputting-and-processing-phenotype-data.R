remove(list = ls())

args <- commandArgs(trailingOnly = FALSE)
file_flag <- "--file="
script_path <- sub(file_flag, "", args[grep(file_flag, args)])

if (length(script_path) == 0) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

script_dir <- dirname(normalizePath(script_path))
repo_root <- normalizePath(file.path(script_dir, "..", "..", ".."))
source(file.path(repo_root, "tools", "notebook_helpers.R"))

analysis_paths <- amrc_notebook_setup(
  repo_root = repo_root,
  ensure_outputs = FALSE,
  download_missing = TRUE,
  source_package = TRUE,
  envir = globalenv()
)

amrc_download_spneumoniae_example_data(dest_dir = analysis_paths$raw_dir)

phenotype <- amrc_process_spneumoniae_phenotype(
  input_dir = analysis_paths$raw_dir,
  save_outputs = TRUE,
  out_dir = analysis_paths$generated_dir
)

message(
  "Phenotype preprocessing complete. Outputs written to: ",
  analysis_paths$generated_dir,
  " (",
  nrow(phenotype$mic),
  " isolates)"
)
