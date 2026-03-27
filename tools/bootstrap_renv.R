args <- commandArgs(trailingOnly = FALSE)
file_flag <- "--file="
script_path <- sub(file_flag, "", args[grep(file_flag, args)])

if (length(script_path) == 0) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

script_dir <- dirname(normalizePath(script_path))
repo_root <- normalizePath(file.path(script_dir, ".."))
options(timeout = max(600, getOption("timeout")))
Sys.setenv(RENV_PATHS_LIBRARY = file.path(repo_root, "renv", "library"))

if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv", repos = "https://cloud.r-project.org")
}

source(file.path(repo_root, "tools", "install_packages.R"), local = TRUE)

packages <- unique(c(core_packages, analysis_packages))

renv::settings$use.cache(FALSE)
renv::settings$snapshot.type("all")
renv::load(project = repo_root)

available_global <- rownames(installed.packages())
hydrate_packages <- intersect(packages, available_global)
hydrate_result <- list(missing = character())

if (length(hydrate_packages) > 0) {
  hydrate_result <- renv::hydrate(
    project = repo_root,
    packages = hydrate_packages,
    prompt = FALSE
  )
}

project_library <- renv::paths$library(project = repo_root)
installed_project <- rownames(installed.packages(lib.loc = project_library))
missing_direct <- setdiff(packages, installed_project)
missing_hydrate <- names(hydrate_result$missing)
missing <- unique(c(missing_direct, missing_hydrate))

if (length(missing) > 0) {
  renv::install(missing, project = repo_root)
}

renv::snapshot(project = repo_root, prompt = FALSE)
