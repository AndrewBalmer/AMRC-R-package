args <- commandArgs(trailingOnly = FALSE)
file_flag <- "--file="
script_path <- sub(file_flag, "", args[grep(file_flag, args)])

if (length(script_path) == 0) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

script_dir <- dirname(normalizePath(script_path))
repo_root <- normalizePath(file.path(script_dir, ".."))
source(file.path(repo_root, "tools", "notebook_helpers.R"), local = FALSE)

analysis_paths <- amrc_notebook_setup(
  repo_root = repo_root,
  ensure_outputs = TRUE,
  download_missing = TRUE,
  source_package = TRUE,
  envir = globalenv()
)

legacy_reference_phenotype <- function(input_dir) {
  tables <- lapply(
    file.path(input_dir, c("MIC_pneumo.csv", "MIC_pneumo2.csv")),
    utils::read.csv,
    header = TRUE,
    sep = ","
  )
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
  combined <- combined[stats::complete.cases(combined[, 3:8]), , drop = FALSE]

  metadata <- combined
  metadata$PT <- amrc_clean_pbp_type(metadata$PT)

  mic <- combined[, 3:8, drop = FALSE]
  mic[] <- lapply(mic, function(column) round(log2(as.numeric(column))))

  list(
    metadata = metadata,
    mic = mic,
    distance = stats::dist(mic)
  )
}

legacy_reference_genotype <- function(input_dir, metadata, sample_n = 200, seed = 1234) {
  if (!requireNamespace("ape", quietly = TRUE)) {
    stop("Package 'ape' is required for genotype verification.", call. = FALSE)
  }

  tables <- lapply(
    file.path(input_dir, c("PBP_Sequence_dataset1.csv", "PBP_Sequence_dataset2.csv")),
    utils::read.csv,
    header = TRUE,
    sep = ","
  )
  combined <- do.call(rbind, tables)
  combined[] <- lapply(combined, function(column) {
    column <- as.character(column)
    column <- gsub("TRUE", "T", column, fixed = TRUE)
    gsub("FALSE", "F", column, fixed = TRUE)
  })
  combined <- stats::na.omit(combined)

  combined$LABID <- as.character(combined$LABID)
  metadata$LABID <- as.character(metadata$LABID)

  match_index <- match(metadata$LABID, combined$LABID)
  combined_without_labid <- combined[, setdiff(colnames(combined), "LABID"), drop = FALSE]
  merged <- cbind(
    metadata,
    combined_without_labid[match_index, , drop = FALSE]
  )
  merged$PT <- amrc_clean_pbp_type(merged$PT)

  filtered <- merged[!(merged$LABID %in% amrc_default_sequence_exclusions()), , drop = FALSE]
  filtered <- stats::na.omit(filtered)

  sequence_start <- ncol(metadata) + 1L
  sequence_matrix <- as.matrix(filtered[, sequence_start:ncol(filtered), drop = FALSE])

  set.seed(seed)
  sample_rows <- sample(seq_len(nrow(sequence_matrix)), size = min(sample_n, nrow(sequence_matrix)))

  list(
    metadata_sequences = filtered,
    sequence_matrix = sequence_matrix,
    distance_subsample = ape::dist.gene(
      sequence_matrix[sample_rows, , drop = FALSE],
      method = "pairwise",
      pairwise.deletion = FALSE,
      variance = FALSE
    ),
    lab_ids = filtered$LABID
  )
}

package_phenotype <- amrc_process_spneumoniae_phenotype(
  input_dir = analysis_paths$raw_dir,
  save_outputs = TRUE,
  out_dir = analysis_paths$generated_dir
)
reference_phenotype <- legacy_reference_phenotype(analysis_paths$raw_dir)

package_genotype <- amrc_process_spneumoniae_genotype(
  input_dir = analysis_paths$raw_dir,
  metadata = package_phenotype$metadata,
  compute_distance = FALSE,
  save_outputs = FALSE,
  out_dir = analysis_paths$generated_dir
)
reference_genotype <- legacy_reference_genotype(
  analysis_paths$raw_dir,
  metadata = reference_phenotype$metadata,
  sample_n = 200
)

check_equal <- function(label, x, y) {
  result <- isTRUE(all.equal(x, y, check.attributes = FALSE))
  message(if (result) "[OK] " else "[FAIL] ", label)

  if (!result) {
    stop(label, " verification failed.", call. = FALSE)
  }
}

check_equal("Phenotype metadata", package_phenotype$metadata, reference_phenotype$metadata)
check_equal("Phenotype MIC table", package_phenotype$mic, reference_phenotype$mic)
check_equal(
  "Phenotype distance matrix",
  as.matrix(package_phenotype$distance),
  as.matrix(reference_phenotype$distance)
)
check_equal(
  "Genotype metadata/sequence table",
  package_genotype$metadata_sequences,
  reference_genotype$metadata_sequences
)
check_equal(
  "Genotype sequence matrix",
  package_genotype$sequence_matrix,
  reference_genotype$sequence_matrix
)
check_equal(
  "Genotype LABID vector",
  package_genotype$lab_ids,
  reference_genotype$lab_ids
)

if (!requireNamespace("ape", quietly = TRUE)) {
  stop("Package 'ape' is required for genotype distance verification.", call. = FALSE)
}

set.seed(1234)
sample_rows <- sample(
  seq_len(nrow(package_genotype$sequence_matrix)),
  size = min(200, nrow(package_genotype$sequence_matrix))
)
package_distance_subsample <- ape::dist.gene(
  package_genotype$sequence_matrix[sample_rows, , drop = FALSE],
  method = "pairwise",
  pairwise.deletion = FALSE,
  variance = FALSE
)

check_equal(
  "Genotype subsample distance matrix",
  as.matrix(package_distance_subsample),
  as.matrix(reference_genotype$distance_subsample)
)

message(
  "All preprocessing verification checks passed. ",
  "The full genotype distance matrix is implied by the verified sequence matrix ",
  "and the same deterministic ape::dist.gene() call used by the package."
)
