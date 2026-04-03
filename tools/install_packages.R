core_packages <- c(
  "renv",
  "roxygen2",
  "knitr",
  "testthat",
  "rmarkdown"
)

analysis_packages <- c(
  "tidyverse",
  "smacof",
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

install_missing_packages <- function(
  lib = NULL,
  repos = "https://cloud.r-project.org"
) {
  packages <- unique(c(core_packages, analysis_packages))
  installed <- rownames(installed.packages())
  missing <- setdiff(packages, installed)

  if (length(missing) == 0) {
    message("All requested packages are already installed.")
  } else {
    install.packages(missing, repos = repos, lib = lib)
  }
}

if (sys.nframe() == 0) {
  install_missing_packages()
}
