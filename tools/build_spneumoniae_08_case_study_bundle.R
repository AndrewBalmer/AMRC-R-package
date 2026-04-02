find_repo_root <- function(start_dir = getwd()) {
  current <- normalizePath(start_dir, winslash = "/", mustWork = TRUE)

  repeat {
    if (file.exists(file.path(current, "DESCRIPTION"))) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not locate the repository root.", call. = FALSE)
    }

    current <- parent
  }
}

map_slope <- function(mds_fit) {
  delta <- mds_fit$delta
  confdist <- mds_fit$confdist

  if (!inherits(delta, "dist")) {
    delta <- stats::as.dist(delta)
  }

  if (!inherits(confdist, "dist")) {
    confdist <- stats::as.dist(confdist)
  }

  as.numeric(stats::coef(stats::lm(as.numeric(confdist) ~ as.numeric(delta)))[2])
}

repo_root <- find_repo_root()
input_dir <- file.path(repo_root, "data")
output_dir <- file.path(repo_root, "inst", "extdata", "examples", "spneumoniae-08")

required_files <- c(
  "MIC_table_Spneumoniae.csv",
  "meta_data_Spneumoniae.csv",
  "MIC_S.Pneumo_metadata.csv",
  "Meta_data_spneumoniae_isolates_post_2015.csv",
  "Spneumo_3628_PCA_start_2D_METRIC.RData",
  "Spneumo_3628_PCA_start_2D_METRIC_genetic.RData"
)

missing_files <- required_files[!file.exists(file.path(input_dir, required_files))]
if (length(missing_files) > 0L) {
  stop(
    "Missing local inputs for the 08 case-study bundle: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

tablemic <- utils::read.csv(
  file.path(input_dir, "MIC_table_Spneumoniae.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
tablemic_meta <- utils::read.csv(
  file.path(input_dir, "meta_data_Spneumoniae.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)

phen_env <- new.env(parent = emptyenv())
load(file.path(input_dir, "Spneumo_3628_PCA_start_2D_METRIC.RData"), envir = phen_env)
phen_fit <- phen_env$torg_met

phen_slope <- map_slope(phen_fit)
phen_dilation <- 1 / phen_slope
theta <- 326 * pi / 180
rot <- matrix(c(cos(theta), sin(theta), -sin(theta), cos(theta)), ncol = 2)
phen_conf <- phen_fit$conf * phen_dilation
phen_conf <- phen_conf %*% rot

phenotype_map <- data.frame(
  LABID = tablemic_meta$LABID,
  PT = tablemic_meta$PT,
  D1 = phen_conf[, 1],
  D2 = phen_conf[, 2],
  stringsAsFactors = FALSE,
  check.names = FALSE
)

gen_env <- new.env(parent = emptyenv())
load(file.path(input_dir, "Spneumo_3628_PCA_start_2D_METRIC_genetic.RData"), envir = gen_env)
gen_fit <- gen_env$torg_met

gen_slope <- map_slope(gen_fit)
gen_dilation <- 1 / gen_slope

isolates_with_PBP_deletion <- c(
  "20156696", "20162849", "20151885", "20153985", "20154509",
  "2013224047", "2013218247", "2014200662", "5869-99", "2513-99"
)

genotype_meta <- tablemic_meta[!tablemic_meta$LABID %in% isolates_with_PBP_deletion, , drop = FALSE]
if (nrow(genotype_meta) != nrow(gen_fit$conf)) {
  stop(
    "Filtered genotype metadata has ", nrow(genotype_meta),
    " rows but the genotype map has ", nrow(gen_fit$conf), ".",
    call. = FALSE
  )
}

gen_conf <- gen_fit$conf * gen_dilation
genotype_map <- data.frame(
  LABID = genotype_meta$LABID,
  PT = genotype_meta$PT,
  G1 = gen_conf[, 1],
  G2 = gen_conf[, 2],
  stringsAsFactors = FALSE,
  check.names = FALSE
)

bundle <- list(
  phenotype_map = phenotype_map,
  genotype_map = genotype_map,
  phenotype_slope = phen_slope,
  phenotype_dilation = phen_dilation,
  phenotype_rotation_degrees = 326,
  genotype_slope = gen_slope,
  genotype_dilation = gen_dilation,
  deleted_labids = isolates_with_PBP_deletion
)

for (filename in c(
  "MIC_table_Spneumoniae.csv",
  "meta_data_Spneumoniae.csv",
  "MIC_S.Pneumo_metadata.csv",
  "Meta_data_spneumoniae_isolates_post_2015.csv"
)) {
  ok <- file.copy(
    from = file.path(input_dir, filename),
    to = file.path(output_dir, filename),
    overwrite = TRUE
  )

  if (!isTRUE(ok)) {
    stop("Failed to copy ", filename, " into the packaged 08 example bundle.", call. = FALSE)
  }
}

utils::write.csv(
  phenotype_map,
  file = file.path(output_dir, "phenotype_map_calibrated.csv"),
  row.names = FALSE
)
utils::write.csv(
  genotype_map,
  file = file.path(output_dir, "genotype_map_calibrated.csv"),
  row.names = FALSE
)
saveRDS(bundle, file = file.path(output_dir, "spneumoniae_08_map_bundle.rds"))

message("Wrote compact 08 case-study bundle to ", output_dir)
