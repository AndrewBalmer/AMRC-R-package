% Manual documentation because roxygen2 could not complete on this machine.
\name{amrc_summarise_within_group_dispersion}
\alias{amrc_summarise_within_group_dispersion}
\alias{amrc_identify_single_feature_pairs}
\alias{amrc_summarise_single_feature_contrasts}
\alias{amrc_find_cluster_differentiating_features}
\alias{amrc_select_informative_isolates}
\title{Generic Group-Contrast and Cluster-Difference Helpers}
\usage{
amrc_summarise_within_group_dispersion(
  data,
  group_col,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  distinct_col = NULL,
  threshold = NULL
)

amrc_identify_single_feature_pairs(
  data,
  group_col,
  feature_cols
)

amrc_summarise_single_feature_contrasts(
  data,
  group_col,
  feature_cols,
  phenotype_cols = c("D1", "D2"),
  external_cols = NULL,
  genotype_cols = NULL,
  count_col = NULL,
  pair_table = NULL
)

amrc_find_cluster_differentiating_features(
  data,
  cluster_col,
  feature_cols,
  cluster_pairs = NULL,
  min_frequency_shift = 0,
  top_n = NULL
)

amrc_select_informative_isolates(
  data,
  cluster_col,
  focal_clusters,
  feature_cols,
  id_col = NULL,
  differentiating_features = NULL,
  min_frequency_shift = 0.8,
  max_features = 10,
  profile_col = "feature_profile"
)
}
\arguments{
\item{data}{A data frame containing grouping columns, map coordinates, and/or feature columns.}

\item{group_col}{Grouping column used to define groups or feature profiles.}

\item{phenotype_cols}{Character vector naming phenotype coordinate columns.}

\item{external_cols}{Optional character vector naming external coordinate columns.}

\item{genotype_cols}{Legacy alias for \code{external_cols}.}

\item{distinct_col}{Optional column used to keep one row per unique type before distance summaries.}

\item{threshold}{Optional numeric threshold used to count the proportion of phenotype distances below a cutoff.}

\item{feature_cols}{Character vector naming the feature columns to compare.}

\item{count_col}{Optional column containing precomputed per-group counts.}

\item{pair_table}{Optional output from \code{amrc_identify_single_feature_pairs()}.}

\item{cluster_col}{Cluster column.}

\item{cluster_pairs}{Optional two-column structure or list defining which cluster pairs to compare.}

\item{min_frequency_shift}{Minimum feature-frequency shift retained in the output.}

\item{top_n}{Optional number of top rows to keep per cluster pair.}

\item{focal_clusters}{Length-2 character vector naming the clusters to compare.}

\item{id_col}{Optional isolate identifier column.}

\item{differentiating_features}{Optional output from \code{amrc_find_cluster_differentiating_features()} restricted to the focal clusters.}

\item{max_features}{Maximum number of differentiating features used to define the profile string.}

\item{profile_col}{Output column name for the concatenated feature profile.}
}
\value{
\code{amrc_summarise_within_group_dispersion()} returns one row per group with
within-group phenotype and optional external distance summaries.

\code{amrc_identify_single_feature_pairs()} returns one row per pair of groups
that differ at exactly one feature.

\code{amrc_summarise_single_feature_contrasts()} returns one row per one-feature
contrast with phenotype/external distances and group sizes.

\code{amrc_find_cluster_differentiating_features()} returns one row per
cluster-pair/feature combination with dominant-state and frequency-shift
summaries.

\code{amrc_select_informative_isolates()} returns a list with the filtered
\code{data}, the \code{selected_features}, and the underlying
\code{feature_summary}.
}
\description{
Generic helpers for the group-dispersion, single-feature contrast, and
cluster-difference analyses that were previously spread across the
manuscript-era genotype-to-phenotype notebooks.
}
\details{
These helpers are intended for generic MIC-to-external comparisons. They do
not assume pneumococcal PBP types and can be used with any metadata grouping,
binary feature table, or aligned categorical feature set.

\code{amrc_identify_single_feature_pairs()} expects one unique row per
\code{group_col}; duplicated group identifiers are treated as an error rather
than being silently collapsed.

\code{amrc_summarise_single_feature_contrasts()} requires every group named in
\code{pair_table} to be present in \code{data}. This prevents cryptic
subsetting failures when a user supplies a stale or mismatched pair table.

\code{amrc_select_informative_isolates()} currently supports exactly one
two-cluster contrast at a time. If \code{id_col} is omitted, it must be
inferable from \code{isolate_id} or \code{LABID}; otherwise the function stops
and asks for an explicit identifier column.
}
