#' Process the S. pneumoniae Genotype Example Data
#'
#' Reads the raw genotype CSV files referenced by the legacy analysis,
#' optionally merges them with processed phenotype metadata, applies the PBP-type
#' cleaning rules, removes the default indel outliers, and optionally computes
#' amino-acid distance matrices.
#'
#' This is an example-specific wrapper retained for the packaged
#' `S. pneumoniae` case study. It is not intended to define the long-term
#' generic package API.
#'
#' @param input_dir Directory containing the raw genotype CSV files.
#' @param sequence_files Length-2 character vector of genotype file names.
#' @param metadata Optional phenotype metadata `data.frame`. If `NULL`,
#'   `metadata_path` is read instead.
#' @param metadata_path Optional path to a previously written metadata CSV.
#' @param exclude_labids Character vector of isolate identifiers to remove.
#' @param compute_distance Logical; compute distance matrices when `TRUE`.
#' @param sample_n Optional size of a reproducible subsample distance matrix.
#' @param seed Integer seed used when `sample_n` is supplied.
#' @param save_outputs Logical; write processed outputs to `out_dir` when `TRUE`.
#' @param out_dir Directory for optional saved outputs.
#' @param save_legacy_rdata Logical; additionally save legacy `.RData` outputs
#'   expected by the original notebooks when `TRUE`.
#'
#' @return A named list with `metadata_sequences`, `sequence_matrix`,
#'   `distance`, `distance_subsample`, and `lab_ids`.
#' @export
amrc_process_spneumoniae_genotype <- function(
  input_dir = file.path("data-raw", "raw-data", "spneumoniae"),
  sequence_files = c("PBP_Sequence_dataset1.csv", "PBP_Sequence_dataset2.csv"),
  metadata = NULL,
  metadata_path = file.path("inst", "extdata", "generated", "spneumoniae", "meta_data_Spneumoniae.csv"),
  exclude_labids = amrc_default_sequence_exclusions(),
  compute_distance = TRUE,
  sample_n = 200,
  seed = 1234,
  save_outputs = FALSE,
  out_dir = file.path("inst", "extdata", "generated", "spneumoniae"),
  save_legacy_rdata = TRUE
) {
  sequence_paths <- file.path(input_dir, sequence_files)
  amrc_check_files_exist(sequence_paths)

  tables <- lapply(sequence_paths, utils::read.csv, header = TRUE, sep = ",")
  combined <- do.call(rbind, tables)
  combined[] <- lapply(combined, function(column) {
    column <- as.character(column)
    column <- gsub("TRUE", "T", column, fixed = TRUE)
    gsub("FALSE", "F", column, fixed = TRUE)
  })
  combined <- stats::na.omit(combined)

  if (is.null(metadata)) {
    amrc_check_files_exist(metadata_path)
    metadata <- utils::read.csv(metadata_path, header = TRUE, sep = ",")
  }

  combined$LABID <- as.character(combined$LABID)
  metadata$LABID <- as.character(metadata$LABID)

  match_index <- match(metadata$LABID, combined$LABID)
  combined_without_labid <- combined[, setdiff(colnames(combined), "LABID"), drop = FALSE]
  merged <- cbind(
    metadata,
    combined_without_labid[match_index, , drop = FALSE]
  )

  if ("PT" %in% colnames(merged)) {
    merged$PT <- amrc_clean_pbp_type(merged$PT)
  }

  filtered <- merged[!(merged$LABID %in% exclude_labids), , drop = FALSE]
  filtered <- stats::na.omit(filtered)

  sequence_start <- ncol(metadata) + 1L
  sequence_matrix <- as.matrix(filtered[, sequence_start:ncol(filtered), drop = FALSE])
  lab_ids <- filtered$LABID

  distance_matrix <- NULL
  distance_subsample <- NULL

  if (compute_distance) {
    if (!requireNamespace("ape", quietly = TRUE)) {
      stop(
        "Package 'ape' is required to compute genotype distances. ",
        "Install it with tools/install_packages.R.",
        call. = FALSE
      )
    }

    distance_matrix <- ape::dist.gene(
      sequence_matrix,
      method = "pairwise",
      pairwise.deletion = FALSE,
      variance = FALSE
    )

    if (!is.null(sample_n)) {
      set.seed(seed)
      sample_n <- min(sample_n, nrow(sequence_matrix))
      sample_rows <- sample(seq_len(nrow(sequence_matrix)), size = sample_n)
      distance_subsample <- ape::dist.gene(
        sequence_matrix[sample_rows, , drop = FALSE],
        method = "pairwise",
        pairwise.deletion = FALSE,
        variance = FALSE
      )
    }
  }

  if (save_outputs) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    saveRDS(
      filtered,
      file = file.path(out_dir, "genotype_metadata_sequences_Spneumoniae.rds")
    )
    saveRDS(
      sequence_matrix,
      file = file.path(out_dir, "genotype_sequence_matrix_Spneumoniae.rds")
    )
    saveRDS(
      lab_ids,
      file = file.path(out_dir, "genotype_lab_ids_Spneumoniae.rds")
    )

    if (!is.null(distance_matrix)) {
      saveRDS(
        distance_matrix,
        file = file.path(out_dir, "genotype_distance_matrix_Spneumoniae.rds")
      )
    }

    if (!is.null(distance_subsample)) {
      saveRDS(
        distance_subsample,
        file = file.path(out_dir, "genotype_distance_matrix_Spneumoniae_subsample.rds")
      )
    }

    if (isTRUE(save_legacy_rdata)) {
      PBPseq <- filtered
      pbp_dist <- if (is.null(distance_matrix)) NULL else as.data.frame(as.matrix(distance_matrix))
      pbp_dist_200 <- if (is.null(distance_subsample)) NULL else as.data.frame(as.matrix(distance_subsample))
      LABID_for3628_isolates <- lab_ids

      save(
        PBPseq,
        file = file.path(out_dir, "tablemic_pneumo_gen_3628.RData")
      )
      save(
        LABID_for3628_isolates,
        file = file.path(out_dir, "LABID_for3628_isolates.RData")
      )

      if (!is.null(pbp_dist)) {
        save(
          pbp_dist,
          file = amrc_generated_path(out_dir, "genotype_distance_rdata")
        )
      }

      if (!is.null(pbp_dist_200)) {
        save(
          pbp_dist_200,
          file = amrc_generated_path(out_dir, "genotype_distance_subsample_rdata")
        )
      }
    }
  }

  list(
    metadata_sequences = filtered,
    sequence_matrix = sequence_matrix,
    distance = distance_matrix,
    distance_subsample = distance_subsample,
    lab_ids = lab_ids
  )
}
