#' Default PBP-Type Replacement Lookup
#'
#' Returns the lookup used throughout the legacy analysis to repair PBP-type
#' values that were converted into year-like strings by spreadsheet software.
#'
#' @return A named character vector where names are corrupted values and values
#'   are corrected replacements.
#' @export
amrc_pbp_type_lookup <- function() {
  c(
    "1930" = "30",
    "1938" = "38",
    "1940" = "40",
    "1941" = "41",
    "1959" = "59",
    "2000" = "0",
    "2001" = "1",
    "2002" = "2",
    "2003" = "3",
    "2004" = "4",
    "2005" = "5",
    "2006" = "6",
    "2007" = "7",
    "2008" = "8",
    "2009" = "9",
    "2010" = "10",
    "2011" = "11",
    "2013" = "13",
    "2016" = "16",
    "2018" = "18",
    "2021" = "21",
    "2027" = "27"
  )
}

#' Clean PBP-Type Labels
#'
#' Repairs year-like PBP-type labels and replaces `/` separators with `-`,
#' following the transformations hard-coded in the original scripts.
#'
#' @param x A character vector of PBP-type labels.
#'
#' @return A character vector with repaired PBP-type labels.
#' @export
amrc_clean_pbp_type <- function(x) {
  x <- as.character(x)
  lookup <- amrc_pbp_type_lookup()

  for (i in seq_along(lookup)) {
    x <- gsub(names(lookup)[i], lookup[[i]], x, fixed = TRUE)
  }

  gsub("/", "-", x, fixed = TRUE)
}

#' Default Sequence Exclusions for the Legacy S. pneumoniae Genotype Map
#'
#' These are the isolates removed in the legacy genotype-map script because of
#' clear indel mutations.
#'
#' @return A character vector of isolate identifiers.
#' @export
amrc_default_sequence_exclusions <- function() {
  c(
    "20156696",
    "20162849",
    "20151885",
    "20153985",
    "20154509",
    "2013224047",
    "2013218247",
    "2014200662",
    "5869-99",
    "2513-99"
  )
}
