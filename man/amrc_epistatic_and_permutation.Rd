% Generated manually because local roxygen regeneration is blocked by OpenMP on this machine.
\name{amrc_generate_epistatic_markers}
\alias{amrc_generate_epistatic_markers}
\alias{amrc_run_limix_epistatic_scan}
\alias{amrc_run_limix_permutation_scan}
\title{Generic Epistatic and Permutation Scan Helpers}
\usage{
amrc_generate_epistatic_markers(
  data,
  feature_cols,
  id_col = NULL,
  separator = ":",
  min_present = 1
)

amrc_run_limix_epistatic_scan(
  data,
  response_cols,
  feature_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  mode = c("multivariate", "univariate"),
  include_main_effects = TRUE,
  min_present = 1,
  out_dir = tempdir(),
  prefix = "amrc_limix_epi",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
)

amrc_run_limix_permutation_scan(
  data,
  response_cols,
  marker_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  n_permutations = 100,
  mode = c("multivariate", "univariate"),
  marker_sample_size = NULL,
  marker_sample_replace = FALSE,
  seed = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix_perm",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
)
}
\arguments{
\item{data}{A data frame containing response and feature columns.}

\item{response_cols}{Character vector naming numeric response columns.}

\item{feature_cols}{Character vector naming binary feature columns.}

\item{marker_cols}{Character vector naming marker columns.}

\item{covariate_cols}{Optional covariate columns.}

\item{id_col}{Optional isolate identifier column.}

\item{kinship_matrix}{Optional square kinship/relatedness matrix.}

\item{mode}{Either \code{"multivariate"} or \code{"univariate"}.}

\item{include_main_effects}{Logical; append original features to the
covariate set before epistatic scanning.}

\item{separator}{String used when naming interaction columns.}

\item{min_present}{Minimum present count required for interaction markers.}

\item{n_permutations}{Number of phenotype permutations to stage or run.}

\item{marker_sample_size}{Optional number of markers to sample per
permutation. Useful for manuscript-style interaction-marker subsampling.}

\item{marker_sample_replace}{Logical; sample markers with replacement when
\code{marker_sample_size} is set.}

\item{seed}{Optional random seed.}

\item{out_dir}{Output directory for staged input and output files.}

\item{prefix}{File-name prefix.}

\item{python}{Command used to invoke Python.}

\item{script}{Optional path to the packaged Python LIMIX helper script.}

\item{execute}{Logical; run the Python command(s) when \code{TRUE}.}

\item{drop_incomplete}{Logical; drop incomplete rows before writing inputs.}
}
\value{
\code{amrc_generate_epistatic_markers()} returns an interaction-marker table.
The run helpers return staged or executed LIMIX scan metadata.
}
\description{
Helpers for building pairwise interaction markers and using them in generic
LIMIX epistatic or permutation scan workflows.
}
