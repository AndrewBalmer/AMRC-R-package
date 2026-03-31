% Generated manually because local roxygen regeneration is blocked by OpenMP on this machine.
\name{amrc_make_train_test_split}
\alias{amrc_make_train_test_split}
\alias{amrc_make_cv_folds}
\alias{amrc_fit_kinship_blup}
\alias{amrc_cross_validate_kinship_blup}
\title{Generic Kinship-BLUP Prediction Helpers}
\usage{
amrc_make_train_test_split(n, proportion = 0.8, seed = NULL)

amrc_make_cv_folds(n, n_folds = 5, seed = NULL)

amrc_fit_kinship_blup(
  response,
  kinship_matrix,
  train = NULL,
  test = NULL,
  lambda = 1,
  center = TRUE,
  return_sd = FALSE
)

amrc_cross_validate_kinship_blup(
  response,
  kinship_matrix,
  n_folds = 5,
  seed = NULL,
  lambda = 1
)
}
\arguments{
\item{n}{Number of observations.}

\item{proportion}{Proportion assigned to the training set.}

\item{seed}{Optional random seed.}

\item{n_folds}{Number of cross-validation folds.}

\item{response}{Numeric response vector.}

\item{kinship_matrix}{Square kinship/relatedness matrix.}

\item{train}{Optional logical vector indicating training rows.}

\item{test}{Optional logical vector indicating test rows.}

\item{lambda}{Ridge/noise penalty added to the training kernel diagonal.}

\item{center}{Logical; center the training response before prediction.}

\item{return_sd}{Logical; return predictive standard deviations.}
}
\value{
Split helpers return logical or fold assignments. The BLUP helpers return
predictions and cross-validation summaries.
}
\description{
Generic helpers for train/test splitting, fold construction, and simple
kinship-BLUP prediction workflows.
}
