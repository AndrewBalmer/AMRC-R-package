% Generated manually because local roxygen regeneration is blocked by OpenMP on this machine.
\name{amrc_write_limix_mvlmm_inputs}
\alias{amrc_write_limix_mvlmm_inputs}
\title{Write Inputs for a LIMIX Multivariate Mixed-Model Scan}
\usage{
amrc_write_limix_mvlmm_inputs(
  data,
  response_cols,
  marker_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  drop_incomplete = TRUE
)
}
\arguments{
\item{data}{A data frame containing responses, markers, and optional covariates.}

\item{response_cols}{Character vector naming numeric response columns.}

\item{marker_cols}{Character vector naming marker or feature columns. Binary
logical/character markers are automatically encoded to \code{0/1}.}

\item{covariate_cols}{Optional character vector naming covariate columns.
Categorical covariates are expanded to a model matrix before writing.}

\item{id_col}{Optional identifier column to carry into the written CSVs.}

\item{kinship_matrix}{Optional precomputed kinship/relatedness matrix.}

\item{out_dir}{Output directory for the written CSV files.}

\item{prefix}{File-name prefix.}

\item{drop_incomplete}{Logical; drop incomplete rows before writing.}
}
\value{
A list of file paths plus the retained isolate IDs.
}
\description{
Writes response, marker, optional covariate, and optional kinship matrices to
CSV files so they can be consumed by the generic LIMIX-based Python mixed-model
scripts bundled with the package.
}
