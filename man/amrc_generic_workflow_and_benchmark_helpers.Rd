% Manual documentation because roxygen2 could not complete on this machine.
\name{amrc_run_cluster_feature_workflow}
\alias{amrc_run_cluster_feature_workflow}
\alias{amrc_join_external_benchmarks}
\alias{amrc_categorise_effect_directions}
\alias{amrc_summarise_effect_directions}
\title{Generic Workflow and Benchmark Helpers}
\usage{
amrc_run_cluster_feature_workflow(
  data,
  outer_cluster_col,
  focal_cluster,
  phenotype_cols = c("D1", "D2"),
  feature_cols,
  id_col = NULL,
  type_col = NULL,
  phenotype_n_clusters = 2,
  phenotype_cluster_col = "phen_cluster",
  min_frequency_shift = 0.8,
  max_features = 10,
  cluster_method = "ward.D2"
)

amrc_join_external_benchmarks(
  feature_table,
  benchmark_table,
  feature_col = "feature",
  benchmark_feature_col = feature_col,
  benchmark_flag_cols = NULL,
  keep_all_features = TRUE
)

amrc_categorise_effect_directions(
  data,
  effect_x_col,
  effect_y_col,
  x_threshold = 0,
  y_threshold = 0,
  category_col = "effect_direction"
)

amrc_summarise_effect_directions(
  data,
  category_col = "effect_direction"
)
}
\arguments{
\item{data}{A data frame containing the required coordinate, grouping, or effect columns.}
\item{outer_cluster_col}{Column defining the outer cluster or region to analyse.}
\item{focal_cluster}{Value in \code{outer_cluster_col} to subset.}
\item{phenotype_cols}{Character vector naming phenotype coordinate columns.}
\item{feature_cols}{Character vector naming categorical or binary feature columns.}
\item{id_col}{Optional identifier column.}
\item{type_col}{Optional grouping column used to collapse to one row per type before phenotype clustering.}
\item{phenotype_n_clusters}{Number of phenotype clusters to cut.}
\item{phenotype_cluster_col}{Output column name for the phenotype cluster.}
\item{min_frequency_shift}{Minimum differentiating-feature threshold retained in the workflow output.}
\item{max_features}{Maximum number of differentiating features retained for informative-isolate summaries.}
\item{cluster_method}{Linkage method passed to \code{hclust()}.}
\item{feature_table}{Primary feature table.}
\item{benchmark_table}{External benchmark table.}
\item{feature_col}{Feature identifier column in the primary table.}
\item{benchmark_feature_col}{Matching feature identifier column in the benchmark table.}
\item{benchmark_flag_cols}{Optional logical or indicator columns naming benchmark sources.}
\item{keep_all_features}{Logical; keep all rows from \code{feature_table}.}
\item{effect_x_col, effect_y_col}{Numeric effect columns.}
\item{x_threshold, y_threshold}{Minimum absolute effect required on each axis before the point is treated as directionally shifted.}
\item{category_col}{Direction-category column name.}
}
\value{
\code{amrc_run_cluster_feature_workflow()} returns a list containing the
filtered subset, phenotype clustering, cluster-labelled data, differentiating
features, and informative isolates when the phenotype contrast has exactly two
clusters.

\code{amrc_join_external_benchmarks()} returns a merged feature table with
benchmark membership summaries.

\code{amrc_categorise_effect_directions()} returns \code{data} with added
direction, angle, and magnitude columns.

\code{amrc_summarise_effect_directions()} returns a two-column count/proportion
summary by directional category.
}
\description{
Generic helpers for orchestrating cluster-to-feature workflows, joining package
results to external benchmark sets, and summarising effect directions in
two-dimensional phenotype space.
}
\details{
\code{amrc_run_cluster_feature_workflow()} is the reusable package version of
the manuscript-era pattern "subset one genotype region, identify phenotype
subclusters, then find differentiating markers".

\code{amrc_join_external_benchmarks()} is intended for generic overlap checks
against literature, GWAS, or laboratory validation tables. It does not assume
any pneumococcal naming scheme.
}
