amrc_check_files_exist <- function(paths) {
  missing_paths <- paths[!file.exists(paths)]
  if (length(missing_paths) > 0) {
    stop(
      "The following input files do not exist:\n",
      paste(missing_paths, collapse = "\n"),
      call. = FALSE
    )
  }

  invisible(paths)
}

#' Process Example S. pneumoniae Phenotype Data
#'
#' Reads the two phenotype CSV files used in the legacy input script, combines
#' them, repairs the PBP-type metadata, log2-transforms MIC values, and
#' optionally computes a phenotype distance matrix.
#'
#' @param input_dir Directory containing the raw phenotype CSV files.
#' @param mic_files Length-2 character vector of phenotype file names.
#' @param drop_incomplete Logical; drop rows with missing MIC values.
#' @param compute_distance Logical; compute [stats::dist()] on the processed MIC
#'   table when `TRUE`.
#' @param sample_n Optional integer. When supplied, compute the distance matrix
#'   on a reproducible random subsample instead of the full table.
#' @param seed Integer seed used when `sample_n` is supplied.
#' @param save_outputs Logical; write processed files to `out_dir` when `TRUE`.
#' @param out_dir Directory for optional saved outputs.
#' @param save_legacy_rdata Logical; additionally save legacy `.RData` outputs
#'   expected by the original notebooks when `TRUE`.
#'
#' @return A named list with `metadata`, `mic`, and `distance`.
#' @export
amrc_process_spneumoniae_phenotype <- function(
  input_dir = file.path("data-raw", "raw-data", "spneumoniae"),
  mic_files = c("MIC_pneumo.csv", "MIC_pneumo2.csv"),
  drop_incomplete = TRUE,
  compute_distance = TRUE,
  sample_n = NULL,
  seed = 1234,
  save_outputs = FALSE,
  out_dir = file.path("inst", "extdata", "generated", "spneumoniae"),
  save_legacy_rdata = TRUE
) {
  mic_paths <- file.path(input_dir, mic_files)
  amrc_check_files_exist(mic_paths)

  tables <- lapply(mic_paths, utils::read.csv, header = TRUE, sep = ",")
  tables <- lapply(tables, function(x) x[, 1:8, drop = FALSE])
  combined <- do.call(rbind, tables)

  colnames(combined) <- c(
    "LABID",
    "PT",
    "Penicillin",
    "Amoxicillin",
    "Meropenem",
    "Cefotaxime",
    "Ceftriaxone",
    "Cefuroxime"
  )

  if (drop_incomplete) {
    mic_columns <- colnames(combined)[3:8]
    combined <- combined[stats::complete.cases(combined[, mic_columns]), , drop = FALSE]
  }

  metadata <- combined
  metadata$PT <- amrc_clean_pbp_type(metadata$PT)

  mic <- combined[, 3:8, drop = FALSE]
  mic[] <- lapply(mic, function(column) {
    round(log2(as.numeric(column)))
  })

  distance_matrix <- NULL
  if (compute_distance) {
    mic_for_distance <- mic

    if (!is.null(sample_n)) {
      set.seed(seed)
      sample_n <- min(sample_n, nrow(mic_for_distance))
      sample_rows <- sample(seq_len(nrow(mic_for_distance)), size = sample_n)
      mic_for_distance <- mic_for_distance[sample_rows, , drop = FALSE]
    }

    distance_matrix <- stats::dist(mic_for_distance)
  }

  if (save_outputs) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(
      mic,
      file = file.path(out_dir, "MIC_table_Spneumoniae.csv"),
      row.names = FALSE
    )
    utils::write.csv(
      metadata,
      file = file.path(out_dir, "meta_data_Spneumoniae.csv"),
      row.names = FALSE
    )

    if (!is.null(distance_matrix)) {
      saveRDS(
        distance_matrix,
        file = file.path(out_dir, "phenotype_distance_matrix_Spneumoniae.rds")
      )

      if (isTRUE(save_legacy_rdata)) {
        dist_pne <- distance_matrix
        save(
          dist_pne,
          file = file.path(out_dir, "phenotype_distance_matrix_Spneumoniae.Rdata")
        )
      }
    }
  }

  list(
    metadata = metadata,
    mic = mic,
    distance = distance_matrix
  )
}
