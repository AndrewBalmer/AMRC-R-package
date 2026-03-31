% Generated manually because local roxygen regeneration is blocked by OpenMP on this machine.
\name{amrc_read_limix_scan_results}
\alias{amrc_read_limix_scan_results}
\alias{amrc_summarise_limix_epistatic_scan}
\alias{amrc_summarise_limix_permutation_scan}
\title{Read and Summarise LIMIX Scan Outputs}
\usage{
amrc_read_limix_scan_results(scan_result, include_effects = TRUE)

amrc_summarise_limix_epistatic_scan(
  scan_result,
  p_col = "pv20",
  separator = ":",
  p_adjust_method = "BH"
)

amrc_summarise_limix_permutation_scan(scan_results, p_col = "pv20")
}
\arguments{
\item{scan_result}{A result list returned by one of the LIMIX helper functions.}

\item{scan_results}{A list returned by \code{amrc_run_limix_permutation_scan()}.}

\item{include_effects}{Logical; include the effects table when available.}

\item{p_col}{Name of the p-value column in the LIMIX stats tables.}

\item{separator}{Separator used in epistatic marker names.}

\item{p_adjust_method}{Multiple-testing correction method passed to \code{stats::p.adjust()}.}
}
\value{
\code{amrc_read_limix_scan_results()} returns raw stats/effects tables.
\code{amrc_summarise_limix_epistatic_scan()} returns parsed interaction
summaries. \code{amrc_summarise_limix_permutation_scan()} returns combined
permutation summaries and overall null-distribution summaries.
}
\description{
Helpers for reading staged or executed LIMIX output files back into R and
turning them into cleaner epistatic and permutation summary tables.
}
