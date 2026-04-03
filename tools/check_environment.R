required_for_package <- c("renv", "roxygen2", "knitr")
recommended_for_package <- c("testthat", "rmarkdown")
required_for_example_pipeline <- c("ape", "smacof")
legacy_analysis_packages <- c(
  "tidyverse",
  "curl",
  "seqinr",
  "ape",
  "ggdendro",
  "psych",
  "GGally",
  "RColorBrewer",
  "calibrate",
  "ggExtra",
  "ggdensity",
  "foreach",
  "doParallel",
  "matrixStats",
  "naniar",
  "broom",
  "cluster",
  "FactoMineR",
  "ggpubr",
  "patchwork",
  "factoextra",
  "NbClust",
  "proxy",
  "ggforce",
  "ggnewscale",
  "doRNG"
)

installed <- rownames(installed.packages())

report_group <- function(label, packages) {
  cat("\n", label, "\n", sep = "")
  cat(strrep("-", nchar(label)), "\n", sep = "")

  for (pkg in packages) {
    status <- if (pkg %in% installed) "installed" else "missing"
    cat(sprintf("%-18s %s\n", pkg, status))
  }
}

cat("R version:", R.version.string, "\n")
cat("pandoc:", if (nzchar(Sys.which("pandoc"))) "found" else "missing", "\n")

report_group("Required for package development", required_for_package)
report_group("Recommended for package development", recommended_for_package)
report_group("Required for example data pipeline", required_for_example_pipeline)
report_group("Needed to run all legacy notebooks", legacy_analysis_packages)
