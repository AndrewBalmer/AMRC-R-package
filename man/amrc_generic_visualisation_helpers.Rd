% Manual documentation because roxygen2 could not complete on this machine.
\name{amrc_plot_top_group_facets}
\alias{amrc_plot_top_group_facets}
\alias{amrc_plot_within_group_dispersion_histogram}
\alias{amrc_plot_side_by_side_maps}
\alias{amrc_plot_cluster_feature_shifts}
\alias{amrc_plot_association_model_comparison}
\alias{amrc_plot_effect_direction_summary}
\alias{amrc_plot_feature_overlap}
\alias{amrc_plot_heritability_summary}
\alias{amrc_plot_variance_decomposition}
\title{Generic Visualisation Helpers}
\usage{
amrc_plot_top_group_facets(
  data,
  group_col,
  x = "D1",
  y = "D2",
  top_n = 10,
  count_col = NULL,
  fill_col = NULL,
  facet_ncol = NULL,
  label_with_counts = TRUE
)

amrc_plot_within_group_dispersion_histogram(
  summary_table,
  value_col = "phenotype_distance_median",
  bins = 30,
  fill = "#E41A1C",
  reference_line = NULL
)

amrc_plot_side_by_side_maps(
  data,
  phenotype_cols = c("D1", "D2"),
  external_cols = c("E1", "E2"),
  fill_col = NULL,
  panel_col = ".amrc_panel",
  panel_labels = c("Phenotype", "External"),
  grid_spacing = NULL
)

amrc_plot_cluster_feature_shifts(
  feature_summary,
  cluster_pair = NULL,
  top_n = 20,
  feature_col = "feature",
  shift_col = "max_state_frequency_shift"
)

amrc_plot_association_model_comparison(
  comparison_table,
  mode = c("change_counts", "p_values", "effect_sizes")
)

amrc_plot_effect_direction_summary(
  data,
  effect_x_col,
  effect_y_col,
  category_col = "effect_direction",
  x_threshold = 0,
  y_threshold = 0,
  show_counts = TRUE
)

amrc_plot_feature_overlap(
  overlap_result,
  mode = c("pairwise", "membership"),
  top_n = 25
)

amrc_plot_heritability_summary(
  heritability_table,
  trait_col = NULL,
  value_col = NULL
)

amrc_plot_variance_decomposition(
  variance_table,
  trait_col = NULL,
  component_col = NULL,
  value_col = NULL
)
}
\arguments{
\item{data}{A data frame containing the required columns for the chosen plot.}
\item{group_col}{Grouping column used to rank or facet map panels.}
\item{x, y}{Coordinate column names.}
\item{top_n}{Number of groups or features to retain.}
\item{count_col}{Optional precomputed count column.}
\item{fill_col}{Optional fill column passed to the plotting layer.}
\item{facet_ncol}{Optional facet layout setting.}
\item{label_with_counts}{Logical; append sample counts to facet labels.}
\item{summary_table}{One-row-per-group dispersion summary table.}
\item{value_col}{Numeric column to plot.}
\item{bins}{Number of histogram bins.}
\item{fill}{Fill colour.}
\item{reference_line}{Optional vertical reference line.}
\item{phenotype_cols, external_cols}{Length-2 character vectors naming the phenotype and external coordinate columns.}
\item{panel_col}{Internal panel column name used when combining phenotype and external maps.}
\item{panel_labels}{Length-2 character vector naming the two panels.}
\item{grid_spacing}{Optional grid spacing passed through to the generic map plotter.}
\item{feature_summary}{Output from \code{amrc_find_cluster_differentiating_features()}.}
\item{cluster_pair}{Optional length-2 character vector selecting one cluster pair.}
\item{feature_col}{Feature column.}
\item{shift_col}{Frequency-shift column.}
\item{comparison_table}{Output from \code{amrc_compare_association_models()}.}
\item{mode}{Plot type for the chosen helper.}
\item{effect_x_col, effect_y_col}{Numeric effect columns.}
\item{category_col}{Direction-category column.}
\item{x_threshold, y_threshold}{Thresholds used when direction categories must be inferred.}
\item{show_counts}{Logical; annotate directional counts.}
\item{overlap_result}{Output from \code{amrc_compute_feature_overlap()}.}
\item{heritability_table}{Table containing one row per response with heritability estimates.}
\item{trait_col}{Trait column.}
\item{component_col}{Variance-component column.}
\item{variance_table}{Variance-decomposition summary table.}
}
\value{
Each helper returns a reusable \code{ggplot} object.
}
\description{
Generic visualisation helpers for the genotype-to-phenotype comparison layer,
including top-group faceting, side-by-side phenotype/external panels,
cluster-difference rankings, adjusted-vs-unadjusted association summaries,
effect-direction plots, overlap visualisation, and mixed-model summary plots.
}
