% Manual documentation because roxygen2 could not complete on this machine.
\name{amrc_prepare_marker_matrix}
\alias{amrc_prepare_marker_matrix}
\alias{amrc_compare_association_models}
\alias{amrc_summarise_association_model_comparison}
\alias{amrc_bind_ranked_feature_tables}
\alias{amrc_compute_feature_overlap}
\title{Marker Preprocessing and Cross-Method Association Summaries}
\usage{
amrc_prepare_marker_matrix(
  data,
  marker_cols,
  id_col = NULL,
  drop_invariant = TRUE,
  collapse_duplicates = TRUE,
  collapse_inverse = TRUE
)

amrc_compare_association_models(
  table_1,
  table_2,
  feature_col = "feature",
  p_col_1 = NULL,
  p_col_2 = NULL,
  effect_col_1 = NULL,
  effect_col_2 = NULL,
  threshold = 0.05,
  labels = c("model_1", "model_2")
)

amrc_summarise_association_model_comparison(
  comparison_table,
  change_col = "significance_change"
)

amrc_bind_ranked_feature_tables(
  tables,
  feature_col,
  score_col = NULL,
  rank_col = NULL,
  top_n = NULL,
  method_names = names(tables)
)

amrc_compute_feature_overlap(
  tables,
  feature_col,
  top_n = NULL
)
}
\arguments{
\item{data}{A data frame containing marker columns.}

\item{marker_cols}{Character vector naming the marker columns to prepare.}

\item{id_col}{Optional identifier column to retain alongside the matrix.}

\item{drop_invariant}{Logical; remove columns with no variation.}

\item{collapse_duplicates}{Logical; collapse exact duplicate markers.}

\item{collapse_inverse}{Logical; collapse inverse binary markers.}

\item{table_1, table_2}{Association result tables.}

\item{feature_col}{Feature identifier column shared by the supplied tables.}

\item{p_col_1, p_col_2}{P-value columns. When omitted, the function tries to infer a sensible default from common package output names.}

\item{effect_col_1, effect_col_2}{Optional effect-size columns to compare.}

\item{threshold}{Significance threshold.}

\item{labels}{Length-2 character vector naming the compared models.}

\item{comparison_table}{Output from \code{amrc_compare_association_models()}.}

\item{change_col}{Column containing the significance-change classification.}

\item{tables}{Named list of data frames.}

\item{score_col}{Optional score column used to derive ranks when \code{rank_col} is absent.}

\item{rank_col}{Optional existing rank column.}

\item{top_n}{Optional number of top rows to keep per method.}

\item{method_names}{Optional method labels. Defaults to \code{names(tables)}.}
}
\value{
\code{amrc_prepare_marker_matrix()} returns a list containing the cleaned
\code{marker_matrix}, retained marker names, and the dropped/collapsed marker
mapping. It errors if no markers remain after invariant-marker removal and
duplicate/inverse collapsing.

\code{amrc_compare_association_models()} returns a feature-level comparison
table for two model outputs, including presence flags for features that appear
in only one model table.

\code{amrc_summarise_association_model_comparison()} returns a list with change
counts and overall summary metrics.

\code{amrc_bind_ranked_feature_tables()} returns one long-form ranking table
with one row per method/feature combination.

\code{amrc_compute_feature_overlap()} returns a list containing the long-form
ranked features, a membership matrix, per-feature overlap counts, and pairwise
method overlap summaries.
}
\description{
Generic helpers for preprocessing marker matrices and comparing, ranking, and
summarising association-analysis outputs across multiple methods.
}
\details{
These helpers package the generic parts of the mvLMM, adjusted-versus-
unadjusted comparison, and cross-method ranking/overlap workflows without
assuming a specific organism, lineage scheme, or feature naming convention.

\code{amrc_compare_association_models()} performs a full outer join on
\code{feature_col}. Features present in only one model are retained and marked
via \code{present_in_model_1}, \code{present_in_model_2}, and
\code{presence_status} instead of being dropped.

When both \code{rank_col} and \code{score_col} are supplied to
\code{amrc_bind_ranked_feature_tables()}, \code{rank_col} controls ordering and
\code{score_col} is retained only as metadata; the function emits a warning so
that precedence is explicit.
}
