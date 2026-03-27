#' Plot a Histogram with Reference Lines
#'
#' @param values Numeric vector of values to plot.
#' @param xlab X-axis label.
#' @param ylab Y-axis label.
#' @param fill Fill colour.
#' @param bins Number of bins.
#' @param mean_line Logical; draw a dashed line at the mean.
#' @param reference_line Optional numeric x-position for an additional solid
#'   reference line.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_histogram_with_reference <- function(
  values,
  xlab,
  ylab = "Count",
  fill = "#E41A1C",
  bins = 30,
  mean_line = TRUE,
  reference_line = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  data <- data.frame(value = values)
  plot <- ggplot2::ggplot(data, ggplot2::aes(x = value)) +
    ggplot2::geom_histogram(fill = fill, colour = "black", alpha = 0.8, bins = bins) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = xlab, y = ylab)

  if (isTRUE(mean_line)) {
    plot <- plot + ggplot2::geom_vline(
      xintercept = mean(values, na.rm = TRUE),
      linetype = "dashed",
      colour = fill
    )
  }

  if (!is.null(reference_line)) {
    plot <- plot + ggplot2::geom_vline(
      xintercept = reference_line,
      linetype = "solid",
      colour = "black"
    )
  }

  plot
}

#' Plot Displacements Between Two Configurations
#'
#' @param data A `data.frame` containing paired coordinates.
#' @param x_ref,y_ref Column names for the reference coordinates.
#' @param x_alt,y_alt Column names for the alternative coordinates.
#' @param fill Reference-point fill colour.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_configuration_displacement <- function(
  data,
  x_ref,
  y_ref,
  x_alt,
  y_alt,
  fill = "#E41A1C"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  ggplot2::ggplot(data, ggplot2::aes_string(x = x_ref, y = y_ref)) +
    ggplot2::geom_segment(
      ggplot2::aes_string(xend = x_alt, yend = y_alt),
      colour = "grey",
      linewidth = 0.5
    ) +
    ggplot2::geom_point(
      ggplot2::aes_string(x = x_alt, y = y_alt),
      shape = 21,
      size = 2,
      fill = "black",
      colour = "white"
    ) +
    ggplot2::geom_point(shape = 21, size = 2, fill = fill, colour = "white") +
    ggplot2::theme_bw() +
    ggplot2::coord_fixed()
}

amrc_default_cluster_palette <- function(n) {
  palette <- c(
    "#4DAF4A", "#377EB8", "#E41A1C", "#984EA3", "#FF7F00", "#000000",
    "#FFFFFF", "#7570B3", "#E7298A", "#FFFF33", "#A65628", "#00BFC4",
    "#999999", "#FF0000", "#FF00FF", "#800080", "#8B4513", "#008000"
  )

  rep(palette, length.out = n)
}

#' Theme Used Throughout the Legacy Cartography Plots
#'
#' @return A `ggplot2` theme object.
#' @export
amrc_theme_cartography <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  ggplot2::theme(
    panel.grid.major = ggplot2::element_line(colour = "grey", linewidth = 0.3),
    panel.grid.minor = ggplot2::element_blank(),
    axis.title.x = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank(),
    axis.title.y = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank()
  )
}

#' Plot a Cluster Elbow Curve
#'
#' @param scree_data Data frame containing `n_clusters` and
#'   `within_cluster_inertia`.
#' @param highlight_cluster Optional vertical reference line.
#' @param x_limits Optional numeric limits for the x-axis.
#' @param y_limits Optional numeric limits for the y-axis.
#' @param draw_path Logical; connect points with a line.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_cluster_elbow <- function(
  scree_data,
  highlight_cluster = NULL,
  x_limits = NULL,
  y_limits = NULL,
  draw_path = FALSE
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  plot <- ggplot2::ggplot(
    scree_data,
    ggplot2::aes_string(x = "n_clusters", y = "within_cluster_inertia")
  )

  if (isTRUE(draw_path)) {
    plot <- plot + ggplot2::geom_path()
  }

  plot <- plot +
    ggplot2::geom_point(shape = 16, size = 4, alpha = 0.6, colour = "#999999") +
    ggplot2::theme_linedraw() +
    ggplot2::labs(x = "Number of clusters", y = "Within cluster inertia")

  if (!is.null(highlight_cluster)) {
    plot <- plot + ggplot2::geom_vline(xintercept = highlight_cluster)
  }
  if (!is.null(x_limits) || !is.null(y_limits)) {
    plot <- plot + ggplot2::coord_cartesian(xlim = x_limits, ylim = y_limits)
  }

  plot
}

#' Plot a Clustered Map
#'
#' @param data A data frame containing coordinates and cluster labels.
#' @param x,y Coordinate column names.
#' @param cluster_col Cluster column name.
#' @param palette Optional vector of fill colours.
#' @param point_size Point size.
#' @param point_alpha Point alpha.
#' @param show_legend Logical; keep the fill legend.
#' @param background_data Optional data frame used as a grey background layer.
#' @param background_x,background_y Background coordinate column names.
#' @param background_size Background point size.
#' @param centroid_x,centroid_y Optional centroid columns to overlay.
#' @param centroid_size Optional centroid point size.
#' @param facet_by Optional faceting column.
#' @param limits_x,limits_y Optional coordinate limits.
#' @param breaks_x,breaks_y Optional axis breaks.
#' @param scale_bar Optional named list with `x`, `y`, `length`, and `label`.
#' @param use_cartography_theme Logical; add [amrc_theme_cartography()].
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_cluster_map <- function(
  data,
  x,
  y,
  cluster_col,
  palette = NULL,
  point_size = 3,
  point_alpha = 1,
  show_legend = FALSE,
  background_data = NULL,
  background_x = x,
  background_y = y,
  background_size = 1.5,
  centroid_x = NULL,
  centroid_y = NULL,
  centroid_size = 3,
  facet_by = NULL,
  limits_x = NULL,
  limits_y = NULL,
  breaks_x = NULL,
  breaks_y = NULL,
  scale_bar = NULL,
  use_cartography_theme = TRUE
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  cluster_values <- sort(unique(data[[cluster_col]]))
  if (is.null(palette)) {
    palette <- amrc_default_cluster_palette(length(cluster_values))
  }
  names(palette) <- cluster_values

  plot <- ggplot2::ggplot(data, ggplot2::aes_string(x = x, y = y, fill = cluster_col))

  if (!is.null(background_data)) {
    plot <- plot + ggplot2::geom_point(
      data = background_data,
      mapping = ggplot2::aes_string(x = background_x, y = background_y),
      inherit.aes = FALSE,
      colour = "#999999",
      fill = "#999999",
      shape = 16,
      size = background_size,
      alpha = 0.8
    )
  }

  plot <- plot +
    ggplot2::geom_point(shape = 21, size = point_size, alpha = point_alpha, colour = "black") +
    ggplot2::theme_linedraw() +
    ggplot2::coord_fixed() +
    ggplot2::scale_fill_manual(values = palette)

  if (!is.null(centroid_x) && !is.null(centroid_y)) {
    plot <- plot + ggplot2::geom_point(
      mapping = ggplot2::aes_string(x = centroid_x, y = centroid_y, fill = cluster_col),
      shape = 21,
      size = centroid_size,
      alpha = 0.8,
      show.legend = FALSE
    )
  }

  if (!is.null(limits_x) || !is.null(breaks_x)) {
    plot <- plot + ggplot2::scale_x_continuous(limits = limits_x, breaks = breaks_x)
  }
  if (!is.null(limits_y) || !is.null(breaks_y)) {
    plot <- plot + ggplot2::scale_y_continuous(limits = limits_y, breaks = breaks_y)
  }
  if (isTRUE(use_cartography_theme)) {
    plot <- plot + amrc_theme_cartography()
  }
  if (!isTRUE(show_legend)) {
    plot <- plot + ggplot2::guides(fill = "none", colour = "none")
  }
  if (!is.null(facet_by)) {
    plot <- plot + ggplot2::facet_wrap(stats::as.formula(paste("~", facet_by)))
  }
  if (!is.null(scale_bar)) {
    plot <- plot +
      ggplot2::annotate(
        geom = "segment",
        x = scale_bar$x,
        y = scale_bar$y,
        xend = scale_bar$x + scale_bar$length,
        yend = scale_bar$y,
        linewidth = 1,
        colour = "black"
      ) +
      ggplot2::annotate(
        geom = "text",
        x = scale_bar$x + scale_bar$length / 2,
        y = scale_bar$y + ifelse(is.null(scale_bar$label_offset), 0, scale_bar$label_offset),
        label = scale_bar$label,
        colour = "black",
        size = ifelse(is.null(scale_bar$label_size), 4, scale_bar$label_size)
      )
  }

  plot
}

#' Plot Cluster-Separation Histograms
#'
#' @param hist_data Data frame containing `DistanceType` and `Distance`.
#' @param fill_values Named fill vector.
#' @param binwidth Histogram bin width.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_distance_histogram <- function(
  hist_data,
  fill_values = c("Intra-Group" = "blue", "Inter-Group" = "red"),
  binwidth = 1
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  ggplot2::ggplot(hist_data, ggplot2::aes_string(x = "Distance", fill = "DistanceType")) +
    ggplot2::geom_histogram(binwidth = binwidth, position = "identity", alpha = 0.6) +
    ggplot2::labs(x = "Pairwise Distance", y = "Count") +
    ggplot2::scale_fill_manual(values = fill_values)
}

#' Plot the Reference-Distance Relationship
#'
#' @param distance_table Data frame containing phenotype/genotype distances and
#'   a cluster column.
#' @param x_col,y_col Numeric column names to plot.
#' @param cluster_col Cluster column name.
#' @param palette Optional colour palette.
#' @param x_limits,y_limits Optional axis limits.
#' @param x_breaks,y_breaks Optional axis breaks.
#' @param xlab,ylab Axis labels.
#' @param annotation_text Optional label text placed at `annotation_x` and
#'   `annotation_y`.
#' @param annotation_x,annotation_y Optional annotation coordinates.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_reference_distance_relationship <- function(
  distance_table,
  x_col = "gen_distance",
  y_col = "phen_distance",
  cluster_col = "gen_cluster",
  palette = NULL,
  x_limits = NULL,
  y_limits = NULL,
  x_breaks = NULL,
  y_breaks = NULL,
  xlab = "Genetic distance",
  ylab = "Phenotypic distance",
  annotation_text = NULL,
  annotation_x = NULL,
  annotation_y = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  cluster_values <- sort(unique(distance_table[[cluster_col]]))
  if (is.null(palette)) {
    palette <- amrc_default_cluster_palette(length(cluster_values))
  }
  names(palette) <- cluster_values

  plot <- ggplot2::ggplot(
    distance_table,
    ggplot2::aes_string(x = x_col, y = y_col, fill = cluster_col)
  ) +
    ggplot2::geom_point(size = 4.5, shape = 21, alpha = 1) +
    ggplot2::guides(fill = "none") +
    ggplot2::theme_bw() +
    ggplot2::labs(x = xlab, y = ylab, fill = "Genetic group") +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 14),
      aspect.ratio = 1
    ) +
    ggplot2::scale_fill_manual(values = palette)

  if (!is.null(x_limits) || !is.null(x_breaks)) {
    plot <- plot + ggplot2::scale_x_continuous(limits = x_limits, breaks = x_breaks)
  }
  if (!is.null(y_limits) || !is.null(y_breaks)) {
    plot <- plot + ggplot2::scale_y_continuous(limits = y_limits, breaks = y_breaks)
  }
  if (!is.null(annotation_text) && !is.null(annotation_x) && !is.null(annotation_y)) {
    plot <- plot + ggplot2::geom_label(
      inherit.aes = FALSE,
      data = data.frame(x = annotation_x, y = annotation_y, label = annotation_text),
      ggplot2::aes_string(x = "x", y = "y", label = "label"),
      size = 4.5
    )
  }

  plot
}

#' Plot One- vs Two-Dimensional Procrustes Projection
#'
#' @param projection_data Output table from
#'   [amrc_compare_one_and_two_dimensional_maps()]$unique_phenotypes or
#'   `$comparison`.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_one_vs_two_dimensional_projection <- function(projection_data) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  line_data <- data.frame(
    x = min(projection_data$X_axis_1D_map),
    y = min(projection_data$Y_axis_1D_map),
    xend = max(projection_data$X_axis_1D_map),
    yend = max(projection_data$Y_axis_1D_map)
  )

  range_x <- c(projection_data$X_axis_1D_map, projection_data$X_axis_2D_map)
  range_y <- c(projection_data$Y_axis_1D_map, projection_data$Y_axis_2D_map)

  ggplot2::ggplot(
    projection_data,
    ggplot2::aes_string(x = "X_axis_2D_map", y = "Y_axis_2D_map", size = "spp_1D")
  ) +
    ggplot2::geom_segment(
      data = line_data,
      ggplot2::aes_string(x = "x", y = "y", xend = "xend", yend = "yend"),
      inherit.aes = FALSE,
      linewidth = 1,
      colour = "black"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes_string(xend = "X_axis_1D_map", yend = "Y_axis_1D_map"),
      linewidth = 0.3,
      colour = "black"
    ) +
    ggplot2::geom_point(shape = 21, fill = "#E41A1C", colour = "white") +
    ggplot2::theme_bw() +
    ggplot2::scale_x_continuous(
      limits = c(min(range_x, na.rm = TRUE), max(range_x, na.rm = TRUE) + 0.5)
    ) +
    ggplot2::scale_y_continuous(
      limits = c(min(range_y, na.rm = TRUE), max(range_y, na.rm = TRUE) + 0.5)
    ) +
    ggplot2::labs(title = "", x = "MDR distance", y = "MDR distance") +
    ggplot2::guides(size = "none") +
    amrc_theme_cartography() +
    ggplot2::coord_fixed()
}
