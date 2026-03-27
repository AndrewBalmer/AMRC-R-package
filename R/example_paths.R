amrc_spneumoniae_generated_filenames <- function() {
  list(
    mic_csv = "MIC_table_Spneumoniae.csv",
    metadata_csv = "meta_data_Spneumoniae.csv",
    phenotype_distance_rds = "phenotype_distance_matrix_Spneumoniae.rds",
    phenotype_distance_rdata = "phenotype_distance_matrix_Spneumoniae.Rdata",
    genotype_distance_rds = "genotype_distance_matrix_Spneumoniae.rds",
    genotype_distance_subsample_rds = "genotype_distance_matrix_Spneumoniae_subsample.rds",
    genotype_distance_rdata = "spneumo_gen_dist.RData",
    genotype_distance_subsample_rdata = "spneumo_gen_dist_sub200.RData",
    genotype_map_metric = "Spneumo_3628_PCA_start_2D_METRIC_genetic.RData",
    phenotype_map_metric = "Spneumo_3628_PCA_start_2D_METRIC.RData",
    genotype_metadata_rds = "genotype_metadata_sequences_Spneumoniae.rds",
    genotype_sequence_rds = "genotype_sequence_matrix_Spneumoniae.rds",
    genotype_labids_rds = "genotype_lab_ids_Spneumoniae.rds",
    legacy_sequence_table = "tablemic_pneumo_gen_3628.RData",
    legacy_labids = "LABID_for3628_isolates.RData"
  )
}

amrc_spneumoniae_legacy_generated_filenames <- function() {
  list(
    genotype_distance_rdata = "tablemic_pneumo_3628_meta_gen_distance_matrix.RData",
    genotype_distance_subsample_rdata = "tablemic_pneumo_3628_meta_gen_distance_matrix_200_subsample.RData"
  )
}

amrc_generated_path <- function(generated_dir, key, must_exist = FALSE, allow_legacy = TRUE) {
  filenames <- amrc_spneumoniae_generated_filenames()
  if (!(key %in% names(filenames))) {
    stop("Unknown generated file key: ", key, call. = FALSE)
  }

  path <- file.path(generated_dir, filenames[[key]])
  if (file.exists(path) || !isTRUE(must_exist)) {
    return(path)
  }

  if (isTRUE(allow_legacy)) {
    legacy <- amrc_spneumoniae_legacy_generated_filenames()
    if (key %in% names(legacy)) {
      legacy_path <- file.path(generated_dir, legacy[[key]])
      if (file.exists(legacy_path)) {
        return(legacy_path)
      }
    }
  }

  stop("Generated file does not exist: ", path, call. = FALSE)
}

#' Locate Packaged Example Data Paths
#'
#' Returns the installed-file paths for the packaged S. pneumoniae examples used
#' in the README and vignette.
#'
#' @param example Which packaged example to locate: `generated` for the
#'   processed example outputs bundled in `inst/extdata/generated/spneumoniae`,
#'   or `mini_raw` for the tiny raw-input example bundled in
#'   `inst/extdata/examples/spneumoniae-mini/raw`.
#' @param mustWork Logical; fail if the packaged example is unavailable.
#'
#' @return A named list of file paths.
#' @export
amrc_spneumoniae_example_paths <- function(
  example = c("generated", "mini_raw"),
  mustWork = TRUE
) {
  example <- match.arg(example)

  if (identical(example, "generated")) {
    root <- system.file("extdata", "generated", "spneumoniae", package = "amrcartography")
    if (identical(root, "")) {
      root <- file.path("inst", "extdata", "generated", "spneumoniae")
    }

    paths <- lapply(amrc_spneumoniae_generated_filenames(), function(filename) {
      file.path(root, filename)
    })
    paths$root <- root
  } else {
    root <- system.file("extdata", "examples", "spneumoniae-mini", "raw", package = "amrcartography")
    if (identical(root, "")) {
      root <- file.path("inst", "extdata", "examples", "spneumoniae-mini", "raw")
    }

    paths <- list(
      root = root,
      mic_1 = file.path(root, "MIC_pneumo.csv"),
      mic_2 = file.path(root, "MIC_pneumo2.csv"),
      seq_1 = file.path(root, "PBP_Sequence_dataset1.csv"),
      seq_2 = file.path(root, "PBP_Sequence_dataset2.csv")
    )
  }

  if (isTRUE(mustWork)) {
    missing_paths <- unlist(paths, use.names = TRUE)
    missing_paths <- missing_paths[!file.exists(missing_paths)]
    if (length(missing_paths) > 0) {
      stop(
        "The requested packaged example is not available at:\n",
        paste(missing_paths, collapse = "\n"),
        call. = FALSE
      )
    }
  }

  paths
}
