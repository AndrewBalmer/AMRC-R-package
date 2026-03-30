#' S. pneumoniae Example Source Manifest
#'
#' Returns a manifest of the external source files referenced by the legacy
#' phenotype and genotype input scripts.
#'
#' This helper is example-data infrastructure for the pneumococcal case study,
#' not part of the intended generic MIC analysis API.
#'
#' @return A `data.frame` with one row per external source file.
#' @export
amrc_spneumoniae_sources <- function() {
  data.frame(
    dataset = c("phenotype", "phenotype", "genotype", "genotype"),
    filename = c(
      "MIC_pneumo.csv",
      "MIC_pneumo2.csv",
      "PBP_Sequence_dataset1.csv",
      "PBP_Sequence_dataset2.csv"
    ),
    url = c(
      "https://static-content.springer.com/esm/art%3A10.1186%2Fs12864-017-4017-7/MediaObjects/12864_2017_4017_MOESM1_ESM.csv",
      "https://static-content.springer.com/esm/art%3A10.1186%2Fs12864-017-4017-7/MediaObjects/12864_2017_4017_MOESM2_ESM.csv",
      "https://static-content.springer.com/esm/art%3A10.1186%2Fs12864-017-4017-7/MediaObjects/12864_2017_4017_MOESM4_ESM.csv",
      "https://static-content.springer.com/esm/art%3A10.1186%2Fs12864-017-4017-7/MediaObjects/12864_2017_4017_MOESM5_ESM.csv"
    ),
    doi = rep("10.1186/s12864-017-4017-7", 4),
    stringsAsFactors = FALSE
  )
}

#' Download Example S. pneumoniae Source Data
#'
#' Downloads the external CSV files used by the legacy S. pneumoniae scripts
#' into a single reproducible directory.
#'
#' This helper is example-data infrastructure for the pneumococcal case study,
#' not part of the intended generic MIC analysis API.
#'
#' @param dest_dir Directory where source files should be written.
#' @param overwrite Logical; overwrite existing files if `TRUE`.
#' @param quiet Logical; suppress `download.file()` output when `TRUE`.
#' @param mode Download mode passed to [utils::download.file()].
#'
#' @return A `data.frame` manifest including the local file paths.
#' @export
amrc_download_spneumoniae_example_data <- function(
  dest_dir = file.path("data-raw", "raw-data", "spneumoniae"),
  overwrite = FALSE,
  quiet = FALSE,
  mode = "wb"
) {
  manifest <- amrc_spneumoniae_sources()
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  local_path <- file.path(dest_dir, manifest$filename)

  for (i in seq_len(nrow(manifest))) {
    if (!overwrite && file.exists(local_path[i])) {
      next
    }

    utils::download.file(
      url = manifest$url[i],
      destfile = local_path[i],
      mode = mode,
      quiet = quiet
    )
  }

  manifest$local_path <- local_path
  manifest
}
