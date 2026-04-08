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
#' This helper is example-data infrastructure for the pneumococcal case study,
#' not part of the intended generic MIC analysis API.
#'
#' @param example Which example path set to locate: `mini_raw` for the tiny
#'   bundled raw-input example in `inst/extdata/examples/spneumoniae-mini/raw`,
#'   `mapping_08` for the compact tracked bundle used by the legacy
#'   `08-Mapping-external-variables` notebook, or `generated` for the canonical
#'   generated-output location used by local source checkouts and
#'   notebook-scale rebuilds.
#' @param mustWork Logical; fail if the requested example path set is
#'   unavailable. Keep `TRUE` when you need real bundled files; use `FALSE` when
#'   you only want the conventional generated-output location.
#'
#' @return A named list of file paths.
#' @export
amrc_spneumoniae_example_paths <- function(
  example = c("generated", "mini_raw", "mapping_08"),
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
  } else if (identical(example, "mini_raw")) {
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
  } else {
    root <- system.file("extdata", "examples", "spneumoniae-08", package = "amrcartography")
    if (identical(root, "")) {
      root <- file.path("inst", "extdata", "examples", "spneumoniae-08")
    }

    paths <- list(
      root = root,
      mic_table = file.path(root, "MIC_table_Spneumoniae.csv"),
      mic_metadata = file.path(root, "meta_data_Spneumoniae.csv"),
      mlst_metadata = file.path(root, "MIC_S.Pneumo_metadata.csv"),
      post2015_metadata = file.path(root, "Meta_data_spneumoniae_isolates_post_2015.csv"),
      map_bundle = file.path(root, "spneumoniae_08_map_bundle.rds"),
      phenotype_map = file.path(root, "phenotype_map_calibrated.csv"),
      genotype_map = file.path(root, "genotype_map_calibrated.csv")
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

#' Locate Bundled S. suis Demo Data Paths
#'
#' Returns the installed-file paths for the compact `S. suis` example bundle
#' used by the Streamlit app and reproducibility checks. This helper is
#' case-study infrastructure, not part of the primary generic MIC API.
#'
#' @param mustWork Logical; fail if the bundled files are unavailable.
#'
#' @return A named list of file paths.
#' @export
amrc_suis_example_paths <- function(mustWork = TRUE) {
  root <- system.file("extdata", "examples", "suis-demo", package = "amrcartography")
  if (identical(root, "")) {
    root <- file.path("inst", "extdata", "examples", "suis-demo")
  }

  paths <- list(
    root = root,
    phenotype = file.path(root, "phenotype_map_input_non_divergent_log2.csv"),
    metadata = file.path(root, "mic_metadata_non_divergent.csv"),
    pbp_distance = file.path(root, "pbp_distance_matrix_non_divergent.csv")
  )

  if (isTRUE(mustWork)) {
    missing_paths <- unlist(paths, use.names = TRUE)
    missing_paths <- missing_paths[!file.exists(missing_paths)]
    if (length(missing_paths) > 0) {
      stop(
        "The requested packaged S. suis example is not available at:\n",
        paste(missing_paths, collapse = "\n"),
        call. = FALSE
      )
    }
  }

  paths
}
