% Generated manually because local roxygen regeneration is blocked by OpenMP on this machine.
\name{amrc_run_limix_heritability}
\alias{amrc_run_limix_heritability}
\alias{amrc_write_limix_heritability_inputs}
\alias{amrc_run_limix_variance_decomposition}
\alias{amrc_write_limix_variance_decomposition_inputs}
\title{Generic LIMIX Heritability and Variance-Decomposition Helpers}
\usage{
amrc_write_limix_heritability_inputs(
  data,
  response_cols,
  kinship_matrix,
  id_col = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  drop_incomplete = TRUE
)

amrc_run_limix_heritability(
  data,
  response_cols,
  kinship_matrix,
  id_col = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
)

amrc_write_limix_variance_decomposition_inputs(
  data,
  response_cols,
  kinship_components,
  id_col = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  drop_incomplete = TRUE
)

amrc_run_limix_variance_decomposition(
  data,
  response_cols,
  kinship_components,
  id_col = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
)
}
\arguments{
\item{data}{A data frame containing numeric response columns.}

\item{response_cols}{Character vector naming numeric response columns.}

\item{kinship_matrix}{Square kinship/relatedness matrix aligned to the retained isolates.}

\item{kinship_components}{Named list of square kinship/relatedness matrices.}

\item{id_col}{Optional isolate identifier column.}

\item{out_dir}{Output directory for staged input and output files.}

\item{prefix}{File-name prefix.}

\item{python}{Command used to invoke Python.}

\item{script}{Optional path to the packaged Python LIMIX helper script.}

\item{execute}{Logical; run the Python command when \code{TRUE}.}

\item{drop_incomplete}{Logical; drop incomplete rows before writing inputs.}
}
\value{
The write helpers return staged CSV paths plus retained isolate IDs. The run
helpers return staged inputs, output paths, and the constructed command.
}
\description{
Generic helpers for staging and optionally running LIMIX heritability and
variance-decomposition analyses from the package.
}
\details{
These helpers expose the manuscript-era mixed-model ideas in a reusable form
for arbitrary aligned responses and kinship structures. They require a working
Python environment with \code{limix}, \code{numpy}, and \code{pandas} when
\code{execute = TRUE}.
}
