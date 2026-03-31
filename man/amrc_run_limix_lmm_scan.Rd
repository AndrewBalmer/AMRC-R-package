% Generated manually because local roxygen regeneration is blocked by OpenMP on this machine.
\name{amrc_run_limix_lmm_scan}
\alias{amrc_run_limix_lmm_scan}
\title{Run a LIMIX Univariate Mixed-Model Scan}
\usage{
amrc_run_limix_lmm_scan(
  data,
  response_cols,
  marker_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
)
}
\arguments{
\item{data}{A data frame containing responses, markers, and optional covariates.}

\item{response_cols}{Character vector naming numeric response columns.}

\item{marker_cols}{Character vector naming marker or feature columns.}

\item{covariate_cols}{Optional character vector naming covariate columns.}

\item{id_col}{Optional isolate identifier column.}

\item{kinship_matrix}{Optional precomputed kinship/relatedness matrix. When
omitted, the Python script recomputes kinship from the marker matrix with the
tested marker removed at each iteration.}

\item{out_dir}{Output directory for the intermediate and result files.}

\item{prefix}{File-name prefix.}

\item{python}{Command used to invoke Python.}

\item{script}{Optional path to the Python mixed-model script. By default the
packaged script is used.}

\item{execute}{Logical; run the Python command when \code{TRUE}, otherwise
return the prepared command and file paths without executing it.}

\item{drop_incomplete}{Logical; drop incomplete rows before writing inputs.}
}
\value{
A list with input paths, output paths, and the constructed command.
}
\description{
Writes generic response/marker inputs, builds the bundled Python/LIMIX
univariate LMM command, and optionally executes it. This mirrors the
manuscript-era single-trait mixed-model scans in a reusable generic form.
}
\details{
This is the optional advanced route for users who want a LIMIX-backed
univariate mixed-model scan across one or more phenotype responses. It requires
a working Python environment with \code{limix}, \code{numpy}, and
\code{pandas}.
}
