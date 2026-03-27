#' Build the Legacy S. pneumoniae Analysis Inputs from Package Functions
#'
#' Downloads the example source data when needed, then generates the processed
#' phenotype and genotype outputs used by the legacy analysis notebooks.
#'
#' @param raw_dir Directory containing or receiving the raw input CSVs.
#' @param out_dir Directory where processed outputs should be written.
#' @param download_missing Logical; download any missing source files when
#'   `TRUE`.
#' @param overwrite Logical; passed to the download helper when fetching raw
#'   files.
#' @param phenotype_sample_n Optional phenotype subsample size for the saved
#'   distance matrix.
#' @param genotype_sample_n Optional genotype subsample size for the saved
#'   distance matrix.
#' @param seed Integer seed for reproducible subsampling.
#'
#' @return A named list with `phenotype`, `genotype`, `raw_dir`, and `out_dir`.
#' @export
amrc_build_spneumoniae_example_outputs <- function(
  raw_dir = file.path("data-raw", "raw-data", "spneumoniae"),
  out_dir = file.path("inst", "extdata", "generated", "spneumoniae"),
  download_missing = TRUE,
  overwrite = FALSE,
  phenotype_sample_n = NULL,
  genotype_sample_n = 200,
  seed = 1234
) {
  manifest <- amrc_spneumoniae_sources()
  raw_paths <- file.path(raw_dir, manifest$filename)

  if (download_missing && !all(file.exists(raw_paths))) {
    amrc_download_spneumoniae_example_data(
      dest_dir = raw_dir,
      overwrite = overwrite
    )
  }

  phenotype <- amrc_process_spneumoniae_phenotype(
    input_dir = raw_dir,
    sample_n = phenotype_sample_n,
    seed = seed,
    save_outputs = TRUE,
    out_dir = out_dir
  )

  genotype <- amrc_process_spneumoniae_genotype(
    input_dir = raw_dir,
    metadata = phenotype$metadata,
    sample_n = genotype_sample_n,
    seed = seed,
    save_outputs = TRUE,
    out_dir = out_dir
  )

  list(
    phenotype = phenotype,
    genotype = genotype,
    raw_dir = raw_dir,
    out_dir = out_dir
  )
}

#' Build Canonical Example Phenotype and Genotype Maps
#'
#' Fits the standard metric, ordinal, and interval MDS maps used by the legacy
#' notebooks and writes the resulting `.RData` objects into the canonical
#' generated-data directory.
#'
#' @param generated_dir Directory containing processed example outputs and where
#'   map objects should be written.
#' @param overwrite Logical; overwrite existing map files when `TRUE`.
#' @param phenotype_transformations Named character vector of transformations to
#'   build for the phenotype map. Defaults to the canonical metric map only.
#' @param genotype_transformations Named character vector of transformations to
#'   build for the genotype map. Defaults to the canonical metric map only.
#' @param mds_args Optional named list of extra arguments passed to
#'   [amrc_compute_mds()].
#'
#' @return A named list with `phenotype` and `genotype` map fits.
#' @export
amrc_build_spneumoniae_example_maps <- function(
  generated_dir = file.path("inst", "extdata", "generated", "spneumoniae"),
  overwrite = FALSE,
  phenotype_transformations = c(metric = "ratio"),
  genotype_transformations = c(metric = "ratio"),
  mds_args = list()
) {
  phenotype_path <- file.path(generated_dir, "MIC_table_Spneumoniae.csv")
  genotype_path <- amrc_generated_path(generated_dir, "genotype_distance_rdata", must_exist = TRUE)
  amrc_check_files_exist(c(phenotype_path, genotype_path))
  dir.create(generated_dir, recursive = TRUE, showWarnings = FALSE)

  phenotype_filenames <- c(
    metric = "Spneumo_3628_PCA_start_2D_METRIC.RData",
    ordinal = "Spneumo_3628_PCA_start_2D_ORDINAL.RData",
    interval = "Spneumo_3628_PCA_start_2D_INTERVAL.RData"
  )
  genotype_filenames <- c(
    metric = "Spneumo_3628_PCA_start_2D_METRIC_genetic.RData",
    ordinal = "Spneumo_3628_PCA_start_2D_ORDINAL_genetic.RData",
    interval = "Spneumo_3628_PCA_start_2D_INTERVAL_genetic.RData"
  )
  object_names <- c(metric = "torg_met", ordinal = "torg_ord", interval = "torg_int")

  fit_or_load_suite <- function(distance_matrix, transformations, filenames) {
    requested <- intersect(names(transformations), names(filenames))
    fits <- vector("list", length(requested))
    names(fits) <- requested

    for (name in requested) {
      output_path <- file.path(generated_dir, filenames[[name]])

      if (!overwrite && file.exists(output_path)) {
        tmp_env <- new.env(parent = emptyenv())
        load(output_path, envir = tmp_env)

        if (!exists(object_names[[name]], envir = tmp_env, inherits = FALSE)) {
          stop(
            "Expected object '", object_names[[name]], "' was not found in: ",
            output_path,
            call. = FALSE
          )
        }

        fits[[name]] <- get(object_names[[name]], envir = tmp_env, inherits = FALSE)
        next
      }

      args <- c(
        list(
          distance_matrix = distance_matrix,
          ndim = 2,
          type = unname(transformations[[name]])
        ),
        mds_args
      )

      if (identical(unname(transformations[[name]]), "ordinal") &&
          is.null(args$ties)) {
        args$ties <- "secondary"
      }

      fits[[name]] <- do.call(amrc_compute_mds, args)

      tmp_env <- new.env(parent = emptyenv())
      assign(object_names[[name]], fits[[name]], envir = tmp_env)
      save(list = object_names[[name]], file = output_path, envir = tmp_env)
    }

    fits
  }

  tablemic <- utils::read.csv(phenotype_path, header = TRUE, sep = ",")
  phenotype_dist <- stats::dist(tablemic)
  phenotype_maps <- fit_or_load_suite(phenotype_dist, phenotype_transformations, phenotype_filenames)

  genotype_env <- new.env(parent = emptyenv())
  load(genotype_path, envir = genotype_env)
  if (!exists("pbp_dist", envir = genotype_env, inherits = FALSE)) {
    stop("Expected object 'pbp_dist' was not found in: ", genotype_path, call. = FALSE)
  }
  genotype_maps <- fit_or_load_suite(
    get("pbp_dist", envir = genotype_env),
    genotype_transformations,
    genotype_filenames
  )

  list(
    phenotype = phenotype_maps,
    genotype = genotype_maps
  )
}
