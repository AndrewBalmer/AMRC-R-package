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
    amrc_theme_manuscript_bw() +
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

  ggplot2::ggplot(data, ggplot2::aes(x = .data[[x_ref]], y = .data[[y_ref]])) +
    ggplot2::geom_segment(
      ggplot2::aes(xend = .data[[x_alt]], yend = .data[[y_alt]]),
      colour = "grey",
      linewidth = 0.5
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = .data[[x_alt]], y = .data[[y_alt]]),
      shape = 21,
      size = 2,
      fill = "black",
      colour = "white"
    ) +
    ggplot2::geom_point(shape = 21, size = 2, fill = fill, colour = "black") +
    amrc_theme_manuscript_bw() +
    ggplot2::coord_fixed()
}

amrc_default_cluster_palette <- function(n) {
  palette <- c(
    "#4DAF4A", "#377EB8", "#E41A1C", "#F781BF", "#FF7F00", "#000000",
    "#FFFFFF", "#7570B3", "#E7298A", "#FFFF33", "#A65628", "#00FFFF",
    "#999999", "#FF0000", "#FF00FF", "#800080", "#8B4513", "#008000",
    "#FFFF00", "#EE82EE"
  )

  rep(palette, length.out = n)
}

amrc_default_named_palette <- function(values) {
  values <- unique(as.character(values[!is.na(values)]))
  palette <- amrc_default_cluster_palette(length(values))
  stats::setNames(palette, values)
}

amrc_theme_manuscript_base <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  ggplot2::theme(
    axis.text = ggplot2::element_text(size = 10, colour = "black"),
    axis.title = ggplot2::element_text(size = 12, colour = "black"),
    legend.text = ggplot2::element_text(size = 10, colour = "black"),
    legend.title = ggplot2::element_text(size = 12, colour = "black"),
    strip.text = ggplot2::element_text(size = 11, colour = "black")
  )
}

amrc_theme_manuscript_bw <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  ggplot2::theme_bw() + amrc_theme_manuscript_base()
}

amrc_theme_manuscript_linedraw <- function() {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  ggplot2::theme_linedraw() + amrc_theme_manuscript_base()
}

amrc_apply_manuscript_scales <- function(plot, data, fill_col = NULL, colour_col = NULL) {
  if (!is.null(fill_col) && fill_col %in% colnames(data)) {
    fill_values <- data[[fill_col]]
    if (is.numeric(fill_values)) {
      plot <- plot + ggplot2::scale_fill_gradient(low = "yellow", high = "red")
    } else {
      plot <- plot + ggplot2::scale_fill_manual(
        values = amrc_default_named_palette(fill_values),
        drop = FALSE
      )
    }
  }

  if (!is.null(colour_col) && colour_col %in% colnames(data)) {
    colour_values <- data[[colour_col]]
    if (is.numeric(colour_values)) {
      plot <- plot + ggplot2::scale_colour_gradient(low = "yellow", high = "red")
    } else {
      plot <- plot + ggplot2::scale_colour_manual(
        values = amrc_default_named_palette(colour_values),
        drop = FALSE
      )
    }
  }

  plot
}

amrc_grid_breaks <- function(values, spacing) {
  if (!is.numeric(spacing) || length(spacing) != 1L || is.na(spacing) || spacing <= 0) {
    stop("grid_spacing must be a single positive numeric value.", call. = FALSE)
  }

  value_range <- range(values, na.rm = TRUE)
  seq(
    from = floor(value_range[[1]] / spacing) * spacing,
    to = ceiling(value_range[[2]] / spacing) * spacing,
    by = spacing
  )
}

amrc_group_polygon_layer <- function(
  data,
  x,
  y,
  group_col,
  level,
  alpha,
  fill_by_group,
  colour_by_group,
  fill,
  colour,
  linewidth,
  linetype,
  ellipse_type
) {
  complete <- stats::complete.cases(data[, c(x, y, group_col), drop = FALSE])
  data <- data[complete, , drop = FALSE]
  group_sizes <- table(data[[group_col]])
  keep_groups <- names(group_sizes[group_sizes >= 3L])
  data <- data[as.character(data[[group_col]]) %in% keep_groups, , drop = FALSE]

  if (nrow(data) == 0) {
    stop(
      "At least one group with three or more complete points is required to draw group envelopes.",
      call. = FALSE
    )
  }

  base_mapping <- if (isTRUE(fill_by_group) && isTRUE(colour_by_group)) {
    ggplot2::aes(
      x = .data[[x]],
      y = .data[[y]],
      group = .data[[group_col]],
      fill = .data[[group_col]],
      colour = .data[[group_col]]
    )
  } else if (isTRUE(fill_by_group)) {
    ggplot2::aes(
      x = .data[[x]],
      y = .data[[y]],
      group = .data[[group_col]],
      fill = .data[[group_col]]
    )
  } else if (isTRUE(colour_by_group)) {
    ggplot2::aes(
      x = .data[[x]],
      y = .data[[y]],
      group = .data[[group_col]],
      colour = .data[[group_col]]
    )
  } else {
    ggplot2::aes(
      x = .data[[x]],
      y = .data[[y]],
      group = .data[[group_col]]
    )
  }

  split_groups <- split(data, as.character(data[[group_col]]))
  hull_groups <- split_groups[vapply(split_groups, nrow, integer(1)) < 4L]
  ellipse_groups <- split_groups[vapply(split_groups, nrow, integer(1)) >= 4L]

  layers <- list()

  if (length(hull_groups) > 0) {
    hull_data <- do.call(rbind, lapply(hull_groups, function(group_data) {
      hull_index <- grDevices::chull(group_data[[x]], group_data[[y]])
      hull_index <- c(hull_index, hull_index[[1]])
      group_data[hull_index, , drop = FALSE]
    }))

    hull_args <- list(
      data = hull_data,
      mapping = base_mapping,
      inherit.aes = FALSE,
      alpha = alpha,
      linewidth = linewidth,
      linetype = linetype
    )
    if (!isTRUE(fill_by_group)) {
      hull_args$fill <- fill
    }
    if (!isTRUE(colour_by_group)) {
      hull_args$colour <- colour
    }

    layers[[length(layers) + 1L]] <- do.call(ggplot2::geom_polygon, hull_args)
  }

  if (length(ellipse_groups) > 0) {
    ellipse_data <- do.call(rbind, ellipse_groups)
    ellipse_args <- list(
      data = ellipse_data,
      mapping = base_mapping,
      inherit.aes = FALSE,
      geom = "polygon",
      type = ellipse_type,
      level = level,
      alpha = alpha,
      linewidth = linewidth,
      linetype = linetype
    )
    if (!isTRUE(fill_by_group)) {
      ellipse_args$fill <- fill
    }
    if (!isTRUE(colour_by_group)) {
      ellipse_args$colour <- colour
    }

    layers[[length(layers) + 1L]] <- do.call(ggplot2::stat_ellipse, ellipse_args)
  }

  layers
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
    axis.ticks.y = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(size = 10, colour = "black"),
    axis.title = ggplot2::element_text(size = 12, colour = "black"),
    legend.text = ggplot2::element_text(size = 10, colour = "black"),
    legend.title = ggplot2::element_text(size = 12, colour = "black")
  )
}

#' Plot a Generic Map with Optional Metadata Colouring and MIC-Style Gridlines
#'
#' @param data A data frame containing map coordinates and optional metadata.
#' @param x,y Coordinate column names.
#' @param fill_col Optional column mapped to point fill.
#' @param colour_col Optional column mapped to point colour.
#' @param size_col Optional column mapped to point size.
#' @param point_size Constant point size when `size_col` is not supplied.
#' @param point_alpha Point alpha. The default keeps some overlap visibility in
#'   the same way as the manuscript-era map plots.
#' @param point_shape Optional point shape. When `NULL`, the function chooses a
#'   filled point for `fill_col` plots and a solid point otherwise.
#' @param outline_colour Outline colour used when `fill_col` is mapped.
#' @param point_fill Constant fill colour when neither `fill_col` nor
#'   `colour_col` is supplied. Defaults to the manuscript-era blue map point.
#' @param grid_spacing Optional major-grid spacing. When the coordinates have
#'   already been calibrated to MIC units, setting `grid_spacing = 1` gives a
#'   one-doubling-dilution grid.
#' @param density Optional density overlay: `"none"` or `"contour"`.
#' @param density_bins Number of contour bands when `density = "contour"`.
#' @param density_colour Contour colour.
#' @param facet_by Optional faceting column.
#' @param facet_ncol,facet_nrow Optional facet layout controls.
#' @param facet_scales Facet scale behaviour passed to
#'   [ggplot2::facet_wrap()].
#' @param limits_x,limits_y Optional axis limits.
#' @param breaks_x,breaks_y Optional axis breaks. When `grid_spacing` is set and
#'   breaks are omitted, the breaks are inferred automatically from the data
#'   range.
#' @param coord_fixed Logical; keep a 1:1 aspect ratio.
#' @param use_cartography_theme Logical; apply [amrc_theme_cartography()] to
#'   hide axis labels and leave only the grid.
#' @param show_legend Logical; keep the mapped legend.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_map <- function(
  data,
  x,
  y,
  fill_col = NULL,
  colour_col = NULL,
  size_col = NULL,
  point_size = 3,
  point_alpha = 0.6,
  point_shape = NULL,
  outline_colour = "black",
  point_fill = "#377EB8",
  grid_spacing = NULL,
  density = c("none", "contour"),
  density_bins = 6,
  density_colour = "grey40",
  facet_by = NULL,
  facet_ncol = NULL,
  facet_nrow = NULL,
  facet_scales = "fixed",
  limits_x = NULL,
  limits_y = NULL,
  breaks_x = NULL,
  breaks_y = NULL,
  coord_fixed = TRUE,
  use_cartography_theme = FALSE,
  show_legend = TRUE
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  density <- match.arg(density)
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(x, data, arg_name = "x")
  amrc_assert_single_column_name(y, data, arg_name = "y")

  optional_cols <- c(fill_col, colour_col, size_col, facet_by)
  optional_cols <- optional_cols[!vapply(optional_cols, is.null, logical(1))]
  if (length(optional_cols) > 0) {
    amrc_assert_column_set(optional_cols, data, arg_name = "optional plotting columns")
  }

  if (is.null(point_shape)) {
    point_shape <- if (!is.null(fill_col)) 21 else 19
  }

  if (!is.null(grid_spacing)) {
    if (is.null(breaks_x)) {
      breaks_x <- amrc_grid_breaks(data[[x]], grid_spacing)
    }
    if (is.null(breaks_y)) {
      breaks_y <- amrc_grid_breaks(data[[y]], grid_spacing)
    }
  }

  plot_data <- data
  if (!is.null(fill_col)) {
    plot_data$.amrc_fill <- plot_data[[fill_col]]
  }
  if (!is.null(colour_col)) {
    plot_data$.amrc_colour <- plot_data[[colour_col]]
  }
  if (!is.null(size_col)) {
    plot_data$.amrc_size <- plot_data[[size_col]]
  }

  plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data[[x]], y = .data[[y]]))

  if (identical(density, "contour")) {
    plot <- plot + ggplot2::geom_density_2d(
      colour = density_colour,
      bins = density_bins,
      inherit.aes = TRUE
    )
  }

  if (!is.null(fill_col) && !is.null(colour_col) && !is.null(size_col)) {
    point_layer <- ggplot2::geom_point(
      ggplot2::aes(fill = .data[[".amrc_fill"]], colour = .data[[".amrc_colour"]], size = .data[[".amrc_size"]]),
      shape = point_shape,
      alpha = point_alpha,
      stroke = if (point_shape %in% c(21:25)) 0.4 else 0
    )
  } else if (!is.null(fill_col) && !is.null(colour_col)) {
    point_layer <- ggplot2::geom_point(
      ggplot2::aes(fill = .data[[".amrc_fill"]], colour = .data[[".amrc_colour"]]),
      shape = point_shape,
      size = point_size,
      alpha = point_alpha,
      stroke = if (point_shape %in% c(21:25)) 0.4 else 0
    )
  } else if (!is.null(fill_col) && !is.null(size_col)) {
    point_layer <- ggplot2::geom_point(
      ggplot2::aes(fill = .data[[".amrc_fill"]], size = .data[[".amrc_size"]]),
      shape = point_shape,
      alpha = point_alpha,
      colour = outline_colour,
      stroke = if (point_shape %in% c(21:25)) 0.4 else 0
    )
  } else if (!is.null(colour_col) && !is.null(size_col)) {
    point_layer <- ggplot2::geom_point(
      ggplot2::aes(colour = .data[[".amrc_colour"]], size = .data[[".amrc_size"]]),
      shape = point_shape,
      alpha = point_alpha
    )
  } else if (!is.null(fill_col)) {
    point_layer <- ggplot2::geom_point(
      ggplot2::aes(fill = .data[[".amrc_fill"]]),
      shape = point_shape,
      size = point_size,
      alpha = point_alpha,
      colour = outline_colour,
      stroke = if (point_shape %in% c(21:25)) 0.4 else 0
    )
  } else if (!is.null(colour_col)) {
    point_layer <- ggplot2::geom_point(
      ggplot2::aes(colour = .data[[".amrc_colour"]]),
      shape = point_shape,
      size = point_size,
      alpha = point_alpha
    )
  } else if (!is.null(size_col)) {
    point_layer <- ggplot2::geom_point(
      ggplot2::aes(size = .data[[".amrc_size"]]),
      shape = point_shape,
      alpha = point_alpha,
      fill = point_fill,
      colour = if (point_shape %in% c(21:25)) outline_colour else NULL,
      stroke = if (point_shape %in% c(21:25)) 0.4 else 0
    )
  } else {
    point_layer <- ggplot2::geom_point(
      shape = point_shape,
      size = point_size,
      alpha = point_alpha,
      fill = point_fill,
      colour = if (point_shape %in% c(21:25)) outline_colour else NULL
    )
  }

  plot <- plot + point_layer + amrc_theme_manuscript_bw()
  plot <- amrc_apply_manuscript_scales(
    plot = plot,
    data = plot_data,
    fill_col = fill_col,
    colour_col = colour_col
  )

  if (!is.null(breaks_x) || !is.null(limits_x)) {
    plot <- plot + ggplot2::scale_x_continuous(breaks = breaks_x, limits = limits_x)
  }
  if (!is.null(breaks_y) || !is.null(limits_y)) {
    plot <- plot + ggplot2::scale_y_continuous(breaks = breaks_y, limits = limits_y)
  }
  if (isTRUE(coord_fixed)) {
    plot <- plot + ggplot2::coord_fixed()
  }
  if (!is.null(facet_by)) {
    plot <- plot + ggplot2::facet_wrap(
      stats::as.formula(paste("~", facet_by)),
      ncol = facet_ncol,
      nrow = facet_nrow,
      scales = facet_scales
    )
  }
  if (isTRUE(use_cartography_theme)) {
    plot <- plot + amrc_theme_cartography()
  }
  if (!isTRUE(show_legend)) {
    plot <- plot + ggplot2::guides(fill = "none", colour = "none", size = "none")
  }

  plot
}

#' Add Group Envelopes to an Existing Map Plot
#'
#' @param plot A `ggplot` object, typically from [amrc_plot_map()].
#' @param data A data frame containing coordinates and the grouping column.
#' @param x,y Coordinate column names.
#' @param group_col Grouping column used to define the envelopes.
#' @param level Confidence level passed to [ggplot2::stat_ellipse()].
#' @param alpha Polygon alpha.
#' @param fill_by_group Logical; map fills by group.
#' @param colour_by_group Logical; map outline colours by group.
#' @param fill Constant fill colour used when `fill_by_group = FALSE`.
#' @param colour Constant outline colour used when `colour_by_group = FALSE`.
#' @param linewidth Envelope outline width.
#' @param linetype Envelope outline linetype.
#' @param ellipse_type Ellipse type passed to [ggplot2::stat_ellipse()].
#'
#' @return A `ggplot` object with group envelopes.
#' @export
amrc_add_group_envelopes <- function(
  plot,
  data,
  x,
  y,
  group_col,
  level = 0.95,
  alpha = 0.15,
  fill_by_group = TRUE,
  colour_by_group = FALSE,
  fill = "grey80",
  colour = "black",
  linewidth = 0.4,
  linetype = "solid",
  ellipse_type = "norm"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(x, data, arg_name = "x")
  amrc_assert_single_column_name(y, data, arg_name = "y")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")

  plot + amrc_group_polygon_layer(
    data = data,
    x = x,
    y = y,
    group_col = group_col,
    level = level,
    alpha = alpha,
    fill_by_group = fill_by_group,
    colour_by_group = colour_by_group,
    fill = fill,
    colour = colour,
    linewidth = linewidth,
    linetype = linetype,
    ellipse_type = ellipse_type
  )
}

#' Add Marginal Histograms or Density Curves to a Map Plot
#'
#' @param plot A `ggplot` scatterplot, typically from [amrc_plot_map()].
#' @param type Marginal display type passed to `ggExtra::ggMarginal()`.
#' @param size Relative marginal size.
#' @param fill Fill colour for non-grouped marginals.
#' @param alpha Alpha for non-grouped marginals.
#' @param group_fill Logical; use mapped group fills when present.
#' @param group_colour Logical; use mapped group colours when present.
#' @param ... Additional arguments passed to `ggExtra::ggMarginal()`.
#'
#' @return A plot object produced by `ggExtra::ggMarginal()`.
#' @export
amrc_add_marginal_distribution <- function(
  plot,
  type = c("histogram", "density", "boxplot"),
  size = 8,
  fill = "#E41A1C",
  alpha = 0.75,
  group_fill = FALSE,
  group_colour = FALSE,
  ...
) {
  if (!requireNamespace("ggExtra", quietly = TRUE)) {
    stop("Package 'ggExtra' is required for marginal distributions.", call. = FALSE)
  }

  type <- match.arg(type)

  if (isTRUE(group_fill)) {
    fill <- NULL
  }

  suppressWarnings(
    ggExtra::ggMarginal(
      p = plot,
      type = type,
      size = size,
      fill = fill,
      alpha = alpha,
      groupFill = group_fill,
      groupColour = group_colour,
      ...
    )
  )
}

#' Compute Biplot-Style Vectors for Numeric Metadata Variables
#'
#' @param data A data frame containing map coordinates and numeric variables.
#' @param x,y Coordinate column names.
#' @param variable_cols Character vector naming numeric metadata variables.
#' @param centre Optional length-2 numeric vector giving the arrow origin. When
#'   `NULL`, the centroid of the plotted coordinates is used.
#' @param scale Proportion of the smaller map axis range used for the longest
#'   arrow.
#' @param min_complete Minimum number of complete observations required per
#'   variable.
#'
#' @return A data frame of arrow start/end coordinates and fit summaries.
#' @export
amrc_compute_biplot_vectors <- function(
  data,
  x,
  y,
  variable_cols,
  centre = NULL,
  scale = 0.25,
  min_complete = 3
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(x, data, arg_name = "x")
  amrc_assert_single_column_name(y, data, arg_name = "y")
  amrc_assert_column_set(variable_cols, data, arg_name = "variable_cols")

  x_vals <- as.numeric(data[[x]])
  y_vals <- as.numeric(data[[y]])

  if (is.null(centre)) {
    centre <- c(mean(x_vals, na.rm = TRUE), mean(y_vals, na.rm = TRUE))
  }

  map_span <- min(diff(range(x_vals, na.rm = TRUE)), diff(range(y_vals, na.rm = TRUE)))
  if (!is.finite(map_span) || map_span <= 0) {
    stop("Could not compute a positive plotting range for the supplied coordinates.", call. = FALSE)
  }

  vector_rows <- lapply(variable_cols, function(variable) {
    values <- amrc_numeric_coercion(data[[variable]], variable)
    complete <- stats::complete.cases(x_vals, y_vals, values)
    if (sum(complete) < min_complete) {
      return(NULL)
    }

    fitted <- stats::lm(
      scale(values[complete]) ~ scale(x_vals[complete]) + scale(y_vals[complete])
    )
    direction <- unname(stats::coef(fitted)[2:3])
    direction[is.na(direction)] <- 0

    norm <- sqrt(sum(direction^2))
    if (!is.finite(norm) || norm == 0) {
      direction[] <- 0
    } else {
      direction <- direction / norm
    }

    r_squared <- summary(fitted)$r.squared
    arrow_length <- map_span * scale * sqrt(max(r_squared, 0))

    data.frame(
      variable = variable,
      x = centre[[1]],
      y = centre[[2]],
      xend = centre[[1]] + direction[[1]] * arrow_length,
      yend = centre[[2]] + direction[[2]] * arrow_length,
      r_squared = r_squared,
      stringsAsFactors = FALSE
    )
  })

  vector_rows <- Filter(Negate(is.null), vector_rows)
  if (length(vector_rows) == 0) {
    stop("No variables had enough complete numeric observations for biplot vectors.", call. = FALSE)
  }

  do.call(rbind, vector_rows)
}

#' Add Biplot-Style Vectors to an Existing Plot
#'
#' @param plot A `ggplot` object, typically from [amrc_plot_map()].
#' @param vectors Output from [amrc_compute_biplot_vectors()].
#' @param label Logical; label each vector.
#' @param label_col Column used for labels.
#' @param label_nudge_x,label_nudge_y Numeric offsets applied to the labels.
#' @param colour Arrow and label colour.
#' @param linewidth Arrow line width.
#' @param label_size Label size.
#'
#' @return A `ggplot` object with vector overlays.
#' @export
amrc_add_biplot_vectors <- function(
  plot,
  vectors,
  label = TRUE,
  label_col = "variable",
  label_nudge_x = 0,
  label_nudge_y = 0,
  colour = "black",
  linewidth = 0.6,
  label_size = 3.5
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  amrc_assert_is_data_frame(vectors, arg_name = "vectors")
  amrc_assert_column_set(c("x", "y", "xend", "yend", label_col), vectors, arg_name = "vectors")

  plot <- plot + ggplot2::geom_segment(
    data = vectors,
    ggplot2::aes(
      x = .data[["x"]],
      y = .data[["y"]],
      xend = .data[["xend"]],
      yend = .data[["yend"]]
    ),
    inherit.aes = FALSE,
    linewidth = linewidth,
    colour = colour,
    arrow = grid::arrow(length = grid::unit(0.2, "cm"))
  )

  if (isTRUE(label)) {
    plot <- plot + ggplot2::geom_label(
      data = vectors,
      ggplot2::aes(
        x = .data[["xend"]] + label_nudge_x,
        y = .data[["yend"]] + label_nudge_y,
        label = .data[[label_col]]
      ),
      inherit.aes = FALSE,
      size = label_size,
      colour = colour
    )
  }

  plot
}

#' Compute Calibrated Biplot Axes with Tick Marks
#'
#' Fits simple linear calibrations for numeric metadata variables against map
#' coordinates, then converts those fits into drawable axis segments with tick
#' marks and labels. This is the generic package-backed version of the
#' manuscript notebook's calibrated biplot-axis styling.
#'
#' @param data A data frame containing map coordinates and numeric variables.
#' @param x,y Coordinate column names.
#' @param variable_cols Character vector naming numeric metadata variables.
#' @param tick_values Optional numeric vector applied to every variable, or a
#'   named list giving per-variable tick values. When `NULL`, pretty breaks are
#'   computed from the observed variable range.
#' @param centre Optional length-2 numeric vector giving the axis origin. When
#'   `NULL`, the centroid of the plotted coordinates is used.
#' @param tick_length Optional tick-mark length in plot units.
#' @param axis_padding Proportion of the smaller map span used to extend the
#'   axis beyond the outermost tick.
#' @param min_complete Minimum number of complete observations required per
#'   variable.
#'
#' @return A list with `axes`, `ticks`, and fitted linear models in `fits`.
#' @export
amrc_compute_calibrated_biplot_axes <- function(
  data,
  x,
  y,
  variable_cols,
  tick_values = NULL,
  centre = NULL,
  tick_length = NULL,
  axis_padding = 0.05,
  min_complete = 3
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(x, data, arg_name = "x")
  amrc_assert_single_column_name(y, data, arg_name = "y")
  amrc_assert_column_set(variable_cols, data, arg_name = "variable_cols")

  x_vals <- as.numeric(data[[x]])
  y_vals <- as.numeric(data[[y]])
  if (is.null(centre)) {
    centre <- c(mean(x_vals, na.rm = TRUE), mean(y_vals, na.rm = TRUE))
  }

  map_span <- min(diff(range(x_vals, na.rm = TRUE)), diff(range(y_vals, na.rm = TRUE)))
  if (!is.finite(map_span) || map_span <= 0) {
    stop("Could not compute a positive plotting range for the supplied coordinates.", call. = FALSE)
  }
  if (is.null(tick_length)) {
    tick_length <- map_span * 0.04
  }

  axis_rows <- list()
  tick_rows <- list()
  fit_list <- list()

  for (variable in variable_cols) {
    values <- amrc_numeric_coercion(data[[variable]], variable)
    complete <- stats::complete.cases(x_vals, y_vals, values)
    if (sum(complete) < min_complete) {
      next
    }

    fit <- stats::lm(values[complete] ~ x_vals[complete] + y_vals[complete])
    coefficients <- stats::coef(fit)
    direction <- unname(coefficients[2:3])
    direction[is.na(direction)] <- 0

    norm <- sqrt(sum(direction^2))
    if (!is.finite(norm) || norm == 0) {
      next
    }

    unit_direction <- direction / norm
    unit_perp <- c(-unit_direction[2], unit_direction[1])
    centre_value <- unname(coefficients[[1]] + sum(direction * centre))

    ticks <- tick_values
    if (is.list(ticks)) {
      ticks <- ticks[[variable]]
    }
    if (is.null(ticks)) {
      ticks <- pretty(values[complete], n = 5)
    }
    ticks <- sort(unique(as.numeric(ticks[is.finite(ticks)])))
    if (length(ticks) == 0) {
      next
    }

    tick_offsets <- (ticks - centre_value) / norm
    axis_half_length <- max(abs(tick_offsets), na.rm = TRUE) + map_span * axis_padding

    axis_start <- centre - unit_direction * axis_half_length
    axis_end <- centre + unit_direction * axis_half_length
    label_position <- axis_end + unit_direction * (map_span * 0.03)

    axis_rows[[variable]] <- data.frame(
      variable = variable,
      x = axis_start[[1]],
      y = axis_start[[2]],
      xend = axis_end[[1]],
      yend = axis_end[[2]],
      label_x = label_position[[1]],
      label_y = label_position[[2]],
      r_squared = summary(fit)$r.squared,
      stringsAsFactors = FALSE
    )

    tick_rows[[variable]] <- do.call(rbind, lapply(seq_along(ticks), function(i) {
      tick_centre <- centre + unit_direction * tick_offsets[[i]]
      tick_start <- tick_centre - unit_perp * (tick_length / 2)
      tick_end <- tick_centre + unit_perp * (tick_length / 2)
      tick_label <- tick_end + unit_perp * (tick_length * 0.6)

      data.frame(
        variable = variable,
        tick_value = ticks[[i]],
        x = tick_start[[1]],
        y = tick_start[[2]],
        xend = tick_end[[1]],
        yend = tick_end[[2]],
        label_x = tick_label[[1]],
        label_y = tick_label[[2]],
        stringsAsFactors = FALSE
      )
    }))

    fit_list[[variable]] <- fit
  }

  axis_rows <- Filter(Negate(is.null), axis_rows)
  if (length(axis_rows) == 0) {
    stop("No variables had enough complete numeric observations for calibrated axes.", call. = FALSE)
  }

  tick_rows <- Filter(Negate(is.null), tick_rows)

  list(
    axes = do.call(rbind, axis_rows),
    ticks = if (length(tick_rows) == 0) NULL else do.call(rbind, tick_rows),
    fits = fit_list
  )
}

#' Add Calibrated Biplot Axes to an Existing Plot
#'
#' @param plot A `ggplot` object, typically from [amrc_plot_map()].
#' @param axis_data Output from [amrc_compute_calibrated_biplot_axes()].
#' @param show_axis_labels Logical; label each axis by variable name.
#' @param show_tick_labels Logical; label the tick marks.
#' @param axis_label_col Column in `axis_data$axes` used for axis labels.
#' @param tick_label_col Column in `axis_data$ticks` used for tick labels.
#' @param colour Axis and tick colour.
#' @param axis_linewidth Line width for axis segments.
#' @param tick_linewidth Line width for tick segments.
#' @param axis_label_size Label size for axis labels.
#' @param tick_label_size Label size for tick labels.
#'
#' @return A `ggplot` object with calibrated axis overlays.
#' @export
amrc_add_calibrated_biplot_axes <- function(
  plot,
  axis_data,
  show_axis_labels = TRUE,
  show_tick_labels = TRUE,
  axis_label_col = "variable",
  tick_label_col = "tick_value",
  colour = "black",
  axis_linewidth = 0.6,
  tick_linewidth = 0.4,
  axis_label_size = 3.5,
  tick_label_size = 3
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  if (!is.list(axis_data) || is.null(axis_data$axes)) {
    stop("axis_data must be the output from amrc_compute_calibrated_biplot_axes().", call. = FALSE)
  }

  amrc_assert_is_data_frame(axis_data$axes, arg_name = "axis_data$axes")
  amrc_assert_column_set(
    c("x", "y", "xend", "yend", "label_x", "label_y", axis_label_col),
    axis_data$axes,
    arg_name = "axis_data$axes"
  )

  plot <- plot + ggplot2::geom_segment(
    data = axis_data$axes,
    ggplot2::aes(
      x = .data[["x"]],
      y = .data[["y"]],
      xend = .data[["xend"]],
      yend = .data[["yend"]]
    ),
    inherit.aes = FALSE,
    linewidth = axis_linewidth,
    colour = colour,
    arrow = grid::arrow(length = grid::unit(0.2, "cm"))
  )

  if (!is.null(axis_data$ticks)) {
    plot <- plot + ggplot2::geom_segment(
      data = axis_data$ticks,
      ggplot2::aes(
        x = .data[["x"]],
        y = .data[["y"]],
        xend = .data[["xend"]],
        yend = .data[["yend"]]
      ),
      inherit.aes = FALSE,
      linewidth = tick_linewidth,
      colour = colour
    )
  }

  if (isTRUE(show_axis_labels)) {
    plot <- plot + ggplot2::geom_label(
      data = axis_data$axes,
      ggplot2::aes(
        x = .data[["label_x"]],
        y = .data[["label_y"]],
        label = .data[[axis_label_col]]
      ),
      inherit.aes = FALSE,
      size = axis_label_size,
      colour = colour
    )
  }

  if (isTRUE(show_tick_labels) && !is.null(axis_data$ticks)) {
    plot <- plot + ggplot2::geom_text(
      data = axis_data$ticks,
      ggplot2::aes(
        x = .data[["label_x"]],
        y = .data[["label_y"]],
        label = .data[[tick_label_col]]
      ),
      inherit.aes = FALSE,
      size = tick_label_size,
      colour = colour
    )
  }

  plot
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
    ggplot2::aes(x = .data[["n_clusters"]], y = .data[["within_cluster_inertia"]])
  )

  if (isTRUE(draw_path)) {
    plot <- plot + ggplot2::geom_path()
  }

  plot <- plot +
    ggplot2::geom_point(shape = 16, size = 4, alpha = 0.6, colour = "#999999") +
    amrc_theme_manuscript_linedraw() +
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

  plot_data <- data
  plot_data[[cluster_col]] <- as.factor(plot_data[[cluster_col]])
  if (!is.null(background_data) && cluster_col %in% colnames(background_data)) {
    background_data[[cluster_col]] <- as.factor(background_data[[cluster_col]])
  }

  cluster_values <- sort(unique(plot_data[[cluster_col]]))
  if (is.null(palette)) {
    palette <- amrc_default_cluster_palette(length(cluster_values))
  }
  names(palette) <- as.character(cluster_values)

  plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data[[x]], y = .data[[y]], fill = .data[[cluster_col]]))

  if (!is.null(background_data)) {
    plot <- plot + ggplot2::geom_point(
      data = background_data,
      mapping = ggplot2::aes(x = .data[[background_x]], y = .data[[background_y]]),
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
    amrc_theme_manuscript_linedraw() +
    ggplot2::coord_fixed() +
    ggplot2::scale_fill_manual(values = palette)

  if (!is.null(centroid_x) && !is.null(centroid_y)) {
    plot <- plot + ggplot2::geom_point(
      mapping = ggplot2::aes(x = .data[[centroid_x]], y = .data[[centroid_y]], fill = .data[[cluster_col]]),
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
  fill_values = c("Intra-Group" = "#377EB8", "Inter-Group" = "#E41A1C"),
  binwidth = 1
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  ggplot2::ggplot(hist_data, ggplot2::aes(x = .data[["Distance"]], fill = .data[["DistanceType"]])) +
    ggplot2::geom_histogram(binwidth = binwidth, position = "identity", alpha = 0.6) +
    ggplot2::labs(x = "Pairwise Distance", y = "Count") +
    ggplot2::scale_fill_manual(values = fill_values) +
    amrc_theme_manuscript_bw()
}

#' Plot the Reference-Distance Relationship
#'
#' @param distance_table Data frame containing phenotype/external distances and
#'   optionally a cluster column.
#' @param x_col,y_col Numeric column names to plot. When omitted, the function
#'   falls back to generic names (`external_distance`, `phenotype_distance`) and
#'   then the legacy pneumococcal names (`gen_distance`, `phen_distance`).
#' @param cluster_col Optional cluster column name. Use `FALSE` to suppress
#'   cluster colouring even when a cluster column is present.
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
  x_col = NULL,
  y_col = NULL,
  cluster_col = NULL,
  palette = NULL,
  x_limits = NULL,
  y_limits = NULL,
  x_breaks = NULL,
  y_breaks = NULL,
  xlab = NULL,
  ylab = NULL,
  annotation_text = NULL,
  annotation_x = NULL,
  annotation_y = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  x_col <- amrc_resolve_distance_column(
    data = distance_table,
    explicit = x_col,
    candidates = c("external_distance", "gen_distance"),
    arg_name = "x_col"
  )
  y_col <- amrc_resolve_distance_column(
    data = distance_table,
    explicit = y_col,
    candidates = c("phenotype_distance", "phen_distance"),
    arg_name = "y_col"
  )
  if (identical(cluster_col, FALSE)) {
    cluster_col <- NULL
  } else if (is.null(cluster_col)) {
    cluster_col <- amrc_default_existing_column(
      distance_table,
      c("external_cluster", "gen_cluster", "cluster")
    )
  }

  if (is.null(xlab)) {
    xlab <- if (identical(x_col, "gen_distance")) "Genetic distance" else "External distance"
  }
  if (is.null(ylab)) {
    ylab <- if (identical(y_col, "phen_distance")) "Phenotypic distance" else "Phenotype distance"
  }

  plot_data <- distance_table
  plot_data$.amrc_x <- plot_data[[x_col]]
  plot_data$.amrc_y <- plot_data[[y_col]]
  if (!is.null(cluster_col)) {
    plot_data$.amrc_cluster <- as.factor(plot_data[[cluster_col]])

    cluster_values <- sort(unique(plot_data$.amrc_cluster))
    if (is.null(palette)) {
      palette <- amrc_default_cluster_palette(length(cluster_values))
    }
    names(palette) <- as.character(cluster_values)

    plot <- ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = .amrc_x, y = .amrc_y, fill = .amrc_cluster)
    ) +
      ggplot2::geom_point(size = 4.5, shape = 21, alpha = 1, colour = "black") +
      ggplot2::guides(fill = "none") +
      ggplot2::scale_fill_manual(values = palette) +
      ggplot2::labs(x = xlab, y = ylab, fill = "Cluster")
  } else {
    plot <- ggplot2::ggplot(
      plot_data,
      ggplot2::aes(x = .amrc_x, y = .amrc_y)
    ) +
      ggplot2::geom_point(size = 4.5, shape = 21, alpha = 1, fill = "#999999", colour = "black") +
      ggplot2::labs(x = xlab, y = ylab)
  }

  plot <- plot +
    amrc_theme_manuscript_bw() +
    ggplot2::theme(
      aspect.ratio = 1
    )

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
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]], label = .data[["label"]]),
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
    ggplot2::aes(
      x = .data[["X_axis_2D_map"]],
      y = .data[["Y_axis_2D_map"]],
      size = .data[["spp_1D"]]
    )
  ) +
    ggplot2::geom_segment(
      data = line_data,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]], xend = .data[["xend"]], yend = .data[["yend"]]),
      inherit.aes = FALSE,
      linewidth = 1,
      colour = "black"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(xend = .data[["X_axis_1D_map"]], yend = .data[["Y_axis_1D_map"]]),
      linewidth = 0.3,
      colour = "black"
    ) +
    ggplot2::geom_point(shape = 21, fill = "#E41A1C", colour = "black") +
    amrc_theme_manuscript_bw() +
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

amrc_infer_column <- function(data, explicit, candidates, arg_name) {
  if (!is.null(explicit)) {
    if (!(explicit %in% colnames(data))) {
      stop(arg_name, " was not found in data.", call. = FALSE)
    }
    return(explicit)
  }

  matched <- candidates[candidates %in% colnames(data)]
  if (length(matched) == 0L) {
    stop(
      "Could not infer ", arg_name, ". Tried: ",
      paste(candidates, collapse = ", "),
      call. = FALSE
    )
  }
  matched[[1]]
}

#' Plot the Top Metadata Groups as Faceted Maps
#'
#' Filters a map to the most frequent metadata groups and facets the result so
#' the same plotting logic can be reused for any grouping variable.
#'
#' @param data A data frame containing map coordinates and a grouping column.
#' @param group_col Grouping column to rank and facet.
#' @param x,y Coordinate column names.
#' @param top_n Number of groups to retain.
#' @param count_col Optional precomputed count column. When `NULL`, counts are
#'   computed from row frequencies.
#' @param fill_col Optional fill column passed to [amrc_plot_map()]. Defaults to
#'   `group_col`.
#' @param facet_ncol Optional number of facet columns.
#' @param label_with_counts Logical; append sample counts to the facet labels.
#'
#' @return A faceted `ggplot` object.
#' @export
amrc_plot_top_group_facets <- function(
  data,
  group_col,
  x = "D1",
  y = "D2",
  top_n = 10,
  count_col = NULL,
  fill_col = NULL,
  facet_ncol = NULL,
  label_with_counts = TRUE
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(group_col, data, arg_name = "group_col")
  amrc_require_coordinate_columns(data, c(x, y))
  if (!is.null(count_col)) {
    amrc_assert_single_column_name(count_col, data, arg_name = "count_col")
  }

  if (is.null(count_col)) {
    counts <- as.data.frame(table(data[[group_col]]), stringsAsFactors = FALSE)
    colnames(counts) <- c(group_col, ".amrc_n")
  } else {
    counts <- data[!duplicated(data[[group_col]]), c(group_col, count_col), drop = FALSE]
    colnames(counts) <- c(group_col, ".amrc_n")
  }

  counts <- counts[order(-counts$.amrc_n, counts[[group_col]]), , drop = FALSE]
  keep_groups <- utils::head(as.character(counts[[group_col]]), top_n)
  plot_data <- data[as.character(data[[group_col]]) %in% keep_groups, , drop = FALSE]
  plot_data <- merge(plot_data, counts, by = group_col, all.x = TRUE, sort = FALSE)

  plot_data$.amrc_group_label <- if (isTRUE(label_with_counts)) {
    paste0(plot_data[[group_col]], " (n = ", plot_data$.amrc_n, ")")
  } else {
    as.character(plot_data[[group_col]])
  }

  amrc_plot_map(
    data = plot_data,
    x = x,
    y = y,
    fill_col = if (is.null(fill_col)) group_col else fill_col,
    facet_by = ".amrc_group_label",
    facet_ncol = facet_ncol,
    use_cartography_theme = TRUE
  )
}

#' Plot a Histogram of Within-Group Dispersion Summaries
#'
#' @param summary_table Output from [amrc_summarise_within_group_dispersion()]
#'   or another one-row-per-group table.
#' @param value_col Numeric summary column to plot.
#' @param bins Number of histogram bins.
#' @param fill Histogram fill colour.
#' @param reference_line Optional vertical reference line.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_within_group_dispersion_histogram <- function(
  summary_table,
  value_col = "phenotype_distance_median",
  bins = 30,
  fill = "#E41A1C",
  reference_line = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  amrc_assert_is_data_frame(summary_table, arg_name = "summary_table")
  amrc_assert_single_column_name(value_col, summary_table, arg_name = "value_col")

  plot <- ggplot2::ggplot(summary_table, ggplot2::aes(x = .data[[value_col]])) +
    ggplot2::geom_histogram(fill = fill, colour = "black", bins = bins, alpha = 0.8) +
    amrc_theme_manuscript_bw() +
    ggplot2::labs(x = value_col, y = "Count")

  if (!is.null(reference_line)) {
    plot <- plot + ggplot2::geom_vline(xintercept = reference_line, colour = "black")
  }

  plot
}

#' Plot Phenotype and External Maps Side by Side
#'
#' Builds one faceted plot with a phenotype panel and an external panel using a
#' shared metadata layer.
#'
#' @param data A data frame containing phenotype and external coordinates.
#' @param phenotype_cols Length-2 character vector naming phenotype columns.
#' @param external_cols Length-2 character vector naming external columns.
#' @param fill_col Optional fill column passed through to [amrc_plot_map()].
#' @param panel_col Output panel column name used internally.
#' @param panel_labels Length-2 character vector naming the two panels.
#' @param grid_spacing Optional grid spacing passed through to [amrc_plot_map()].
#'
#' @return A faceted `ggplot` object.
#' @export
amrc_plot_side_by_side_maps <- function(
  data,
  phenotype_cols = c("D1", "D2"),
  external_cols = c("E1", "E2"),
  fill_col = NULL,
  panel_col = ".amrc_panel",
  panel_labels = c("Phenotype", "External"),
  grid_spacing = NULL
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_require_coordinate_columns(data, phenotype_cols)
  amrc_require_coordinate_columns(data, external_cols)

  phenotype_data <- data
  phenotype_data$.amrc_x <- phenotype_data[[phenotype_cols[[1]]]]
  phenotype_data$.amrc_y <- phenotype_data[[phenotype_cols[[2]]]]
  phenotype_data[[panel_col]] <- panel_labels[[1]]

  external_data <- data
  external_data$.amrc_x <- external_data[[external_cols[[1]]]]
  external_data$.amrc_y <- external_data[[external_cols[[2]]]]
  external_data[[panel_col]] <- panel_labels[[2]]

  combined <- rbind(phenotype_data, external_data)

  amrc_plot_map(
    data = combined,
    x = ".amrc_x",
    y = ".amrc_y",
    fill_col = fill_col,
    facet_by = panel_col,
    grid_spacing = grid_spacing,
    use_cartography_theme = TRUE
  )
}

amrc_require_patchwork <- function() {
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    stop(
      "Package 'patchwork' is required for manuscript panel composition. ",
      "Install it to use the panel composer helpers.",
      call. = FALSE
    )
  }
}

#' Compose Multiple Plots into a Manuscript-Style Panel Grid
#'
#' Provides a lightweight, reusable wrapper around `patchwork::wrap_plots()`
#' using the package's manuscript-style defaults. This is intended as the
#' generic replacement for the ad hoc panel assembly used throughout the
#' manuscript and thesis notebooks.
#'
#' @param plots A list of `ggplot` objects.
#' @param ncol,nrow Optional grid dimensions.
#' @param widths,heights Optional panel layout controls passed to
#'   `patchwork::wrap_plots()`.
#' @param collect_guides Logical; collect shared legends.
#' @param tag_levels Tag style passed to `patchwork::plot_annotation()`.
#'
#' @return A patchwork-composed plot object.
#' @export
amrc_compose_manuscript_panel_grid <- function(
  plots,
  ncol = NULL,
  nrow = NULL,
  widths = NULL,
  heights = NULL,
  collect_guides = TRUE,
  tag_levels = "A"
) {
  amrc_require_patchwork()

  if (!is.list(plots) || length(plots) == 0L) {
    stop("plots must be a non-empty list of ggplot objects.", call. = FALSE)
  }

  patchwork::wrap_plots(
    plots,
    ncol = ncol,
    nrow = nrow,
    widths = widths,
    heights = heights,
    guides = if (isTRUE(collect_guides)) "collect" else "keep"
  ) +
    patchwork::plot_annotation(tag_levels = tag_levels)
}

#' Compose a Map and Reference Plot as a Manuscript-Style Figure Panel
#'
#' @param map_plot A phenotype or external map plot.
#' @param reference_plot A reference-distance relationship plot.
#' @param widths Relative panel widths.
#' @param collect_guides Logical; collect shared legends.
#' @param tag_levels Tag style passed to `patchwork::plot_annotation()`.
#'
#' @return A patchwork-composed plot object.
#' @export
amrc_compose_map_reference_panel <- function(
  map_plot,
  reference_plot,
  widths = c(1, 1),
  collect_guides = TRUE,
  tag_levels = "A"
) {
  amrc_compose_manuscript_panel_grid(
    plots = list(map_plot, reference_plot),
    ncol = 2,
    widths = widths,
    collect_guides = collect_guides,
    tag_levels = tag_levels
  )
}

#' Compose Phenotype, External, and Reference Panels in the Manuscript Layout
#'
#' Builds the most common manuscript comparison layout: phenotype map and
#' external map on the top row, with an optional full-width reference-distance
#' panel below them.
#'
#' @param phenotype_plot A phenotype map plot.
#' @param external_plot An external or genotype map plot.
#' @param reference_plot Optional reference-distance relationship plot.
#' @param top_widths Relative widths of the top-row map panels.
#' @param bottom_height Relative height of the optional bottom panel.
#' @param collect_guides Logical; collect shared legends.
#' @param tag_levels Tag style passed to `patchwork::plot_annotation()`.
#'
#' @return A patchwork-composed plot object.
#' @export
amrc_compose_phenotype_external_reference_panel <- function(
  phenotype_plot,
  external_plot,
  reference_plot = NULL,
  top_widths = c(1, 1),
  bottom_height = 1,
  collect_guides = TRUE,
  tag_levels = "A"
) {
  amrc_require_patchwork()

  top_row <- patchwork::wrap_plots(
    list(phenotype_plot, external_plot),
    ncol = 2,
    widths = top_widths,
    guides = if (isTRUE(collect_guides)) "collect" else "keep"
  )

  combined <- if (is.null(reference_plot)) {
    top_row
  } else {
    top_row / reference_plot + patchwork::plot_layout(heights = c(1, bottom_height))
  }

  combined + patchwork::plot_annotation(tag_levels = tag_levels)
}

#' Compose a Recurring Manuscript Side-by-Side Comparison Panel
#'
#' Mirrors the repeated two-panel `ggarrange(..., nrow = 1, ncol = 2)` layouts
#' used throughout the manuscript and thesis notebooks.
#'
#' @param left_plot,right_plot `ggplot` objects.
#' @param widths Relative panel widths.
#' @param collect_guides Logical; collect shared legends.
#' @param tag_levels Tag style passed to `patchwork::plot_annotation()`.
#'
#' @return A patchwork-composed plot object.
#' @export
amrc_compose_manuscript_side_by_side_panel <- function(
  left_plot,
  right_plot,
  widths = c(1, 1),
  collect_guides = TRUE,
  tag_levels = "A"
) {
  amrc_compose_manuscript_panel_grid(
    plots = list(left_plot, right_plot),
    ncol = 2,
    widths = widths,
    collect_guides = collect_guides,
    tag_levels = tag_levels
  )
}

#' Compose a Recurring Manuscript Triptych Row
#'
#' Mirrors the common one-row, three-panel arrangement used for multi-drug map
#' comparisons in the notebooks.
#'
#' @param plot_a,plot_b,plot_c `ggplot` objects.
#' @param widths Relative panel widths.
#' @param collect_guides Logical; collect shared legends.
#' @param tag_levels Tag style passed to `patchwork::plot_annotation()`.
#'
#' @return A patchwork-composed plot object.
#' @export
amrc_compose_manuscript_triptych_panel <- function(
  plot_a,
  plot_b,
  plot_c,
  widths = c(1, 1, 1),
  collect_guides = TRUE,
  tag_levels = "A"
) {
  amrc_compose_manuscript_panel_grid(
    plots = list(plot_a, plot_b, plot_c),
    ncol = 3,
    widths = widths,
    collect_guides = collect_guides,
    tag_levels = tag_levels
  )
}

#' Compose a Recurring Thesis-Style Storyboard Panel
#'
#' Mirrors the repeated notebook layout with two smaller top-row panels and one
#' wider bottom panel carrying the main interpretive graphic.
#'
#' @param top_left,top_right,bottom_plot `ggplot` objects.
#' @param top_widths Relative widths of the top-row panels.
#' @param bottom_height Relative height of the bottom panel.
#' @param collect_guides Logical; collect shared legends.
#' @param tag_levels Tag style passed to `patchwork::plot_annotation()`.
#'
#' @return A patchwork-composed plot object.
#' @export
amrc_compose_thesis_storyboard_panel <- function(
  top_left,
  top_right,
  bottom_plot,
  top_widths = c(1, 1),
  bottom_height = 1.15,
  collect_guides = TRUE,
  tag_levels = "A"
) {
  amrc_require_patchwork()

  top_row <- patchwork::wrap_plots(
    list(top_left, top_right),
    ncol = 2,
    widths = top_widths,
    guides = if (isTRUE(collect_guides)) "collect" else "keep"
  )

  (top_row / bottom_plot + patchwork::plot_layout(heights = c(1, bottom_height))) +
    patchwork::plot_annotation(tag_levels = tag_levels)
}

#' Compose a Cluster-Story Figure in the Recurring Thesis Layout
#'
#' Convenience wrapper for the common phenotype/external-plus-feature-shift
#' figure used in the clustering notebooks.
#'
#' @param phenotype_plot A phenotype map plot.
#' @param external_plot An external or genotype map plot.
#' @param feature_plot A differentiating-feature or effect-summary plot.
#' @param top_widths Relative widths of the top-row panels.
#' @param bottom_height Relative height of the bottom panel.
#' @param collect_guides Logical; collect shared legends.
#' @param tag_levels Tag style passed to `patchwork::plot_annotation()`.
#'
#' @return A patchwork-composed plot object.
#' @export
amrc_compose_manuscript_cluster_story_panel <- function(
  phenotype_plot,
  external_plot,
  feature_plot,
  top_widths = c(1, 1),
  bottom_height = 1.15,
  collect_guides = TRUE,
  tag_levels = "A"
) {
  amrc_compose_thesis_storyboard_panel(
    top_left = phenotype_plot,
    top_right = external_plot,
    bottom_plot = feature_plot,
    top_widths = top_widths,
    bottom_height = bottom_height,
    collect_guides = collect_guides,
    tag_levels = tag_levels
  )
}

#' Plot Ranked Cluster-Difference Features
#'
#' @param feature_summary Output from
#'   [amrc_find_cluster_differentiating_features()].
#' @param cluster_pair Optional length-2 character vector selecting one cluster
#'   pair.
#' @param top_n Number of features to plot.
#' @param feature_col Feature column.
#' @param shift_col Frequency-shift column.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_cluster_feature_shifts <- function(
  feature_summary,
  cluster_pair = NULL,
  top_n = 20,
  feature_col = "feature",
  shift_col = "max_state_frequency_shift"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  amrc_assert_is_data_frame(feature_summary, arg_name = "feature_summary")
  amrc_assert_column_set(c("cluster_1", "cluster_2", feature_col, shift_col), feature_summary, arg_name = "feature_summary")

  plot_data <- feature_summary
  if (!is.null(cluster_pair)) {
    if (length(cluster_pair) != 2L) {
      stop("cluster_pair must contain exactly two cluster labels.", call. = FALSE)
    }
    plot_data <- plot_data[
      plot_data$cluster_1 == cluster_pair[[1]] & plot_data$cluster_2 == cluster_pair[[2]],
      ,
      drop = FALSE
    ]
  }
  plot_data <- plot_data[order(-plot_data[[shift_col]], plot_data[[feature_col]]), , drop = FALSE]
  plot_data <- utils::head(plot_data, top_n)
  plot_data$.amrc_pair <- paste(plot_data$cluster_1, plot_data$cluster_2, sep = " vs ")

  ggplot2::ggplot(plot_data, ggplot2::aes(x = stats::reorder(.data[[feature_col]], .data[[shift_col]]), y = .data[[shift_col]])) +
    ggplot2::geom_col(fill = "#377EB8", colour = "black", alpha = 0.8) +
    ggplot2::coord_flip() +
    amrc_theme_manuscript_bw() +
    ggplot2::labs(x = "Feature", y = "Frequency shift") +
    ggplot2::facet_wrap(~ .amrc_pair, scales = "free_y")
}

#' Plot an Association-Model Comparison
#'
#' @param comparison_table Output from [amrc_compare_association_models()].
#' @param mode Plot type: `"change_counts"`, `"p_values"`, or
#'   `"effect_sizes"`.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_association_model_comparison <- function(
  comparison_table,
  mode = c("change_counts", "p_values", "effect_sizes")
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  mode <- match.arg(mode)
  amrc_assert_is_data_frame(comparison_table, arg_name = "comparison_table")

  if (identical(mode, "change_counts")) {
    counts <- as.data.frame(table(comparison_table$significance_change), stringsAsFactors = FALSE)
    colnames(counts) <- c("change", "n")
    return(
      ggplot2::ggplot(counts, ggplot2::aes(x = .data[["change"]], y = .data[["n"]], fill = .data[["change"]])) +
        ggplot2::geom_col(show.legend = FALSE) +
        ggplot2::scale_fill_manual(values = amrc_default_named_palette(counts$change), drop = FALSE) +
        amrc_theme_manuscript_bw() +
        ggplot2::labs(x = "Change category", y = "Features")
    )
  }

  if (identical(mode, "p_values")) {
    amrc_assert_column_set(c("p_value_1", "p_value_2"), comparison_table, arg_name = "comparison_table")
    return(
      ggplot2::ggplot(comparison_table, ggplot2::aes(x = .data[["p_value_1"]], y = .data[["p_value_2"]], colour = .data[["presence_status"]])) +
        ggplot2::geom_point(size = 2.5, alpha = 0.8) +
        ggplot2::scale_colour_manual(values = amrc_default_named_palette(comparison_table$presence_status), drop = FALSE) +
        amrc_theme_manuscript_bw() +
        ggplot2::labs(x = "Model 1 p-value", y = "Model 2 p-value", colour = "Presence")
    )
  }

  amrc_assert_column_set(c("effect_size_1", "effect_size_2"), comparison_table, arg_name = "comparison_table")
  ggplot2::ggplot(comparison_table, ggplot2::aes(x = .data[["effect_size_1"]], y = .data[["effect_size_2"]], colour = .data[["presence_status"]])) +
    ggplot2::geom_point(size = 2.5, alpha = 0.8) +
    ggplot2::scale_colour_manual(values = amrc_default_named_palette(comparison_table$presence_status), drop = FALSE) +
    amrc_theme_manuscript_bw() +
    ggplot2::labs(x = "Model 1 effect", y = "Model 2 effect", colour = "Presence")
}

#' Plot Effect-Direction Summaries
#'
#' @param data A data frame containing two effect columns.
#' @param effect_x_col,effect_y_col Numeric effect columns.
#' @param category_col Direction-category column. When absent, the function
#'   creates it with [amrc_categorise_effect_directions()].
#' @param x_threshold,y_threshold Thresholds passed to
#'   [amrc_categorise_effect_directions()] when needed.
#' @param show_counts Logical; annotate quadrant counts.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_effect_direction_summary <- function(
  data,
  effect_x_col,
  effect_y_col,
  category_col = "effect_direction",
  x_threshold = 0,
  y_threshold = 0,
  show_counts = TRUE
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  amrc_assert_is_data_frame(data, arg_name = "data")
  if (!(category_col %in% colnames(data))) {
    data <- amrc_categorise_effect_directions(
      data = data,
      effect_x_col = effect_x_col,
      effect_y_col = effect_y_col,
      x_threshold = x_threshold,
      y_threshold = y_threshold,
      category_col = category_col
    )
  }

  plot <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[effect_x_col]], y = .data[[effect_y_col]], colour = .data[[category_col]])) +
    ggplot2::geom_hline(yintercept = c(-y_threshold, y_threshold), linetype = "dashed", colour = "grey50") +
    ggplot2::geom_vline(xintercept = c(-x_threshold, x_threshold), linetype = "dashed", colour = "grey50") +
    ggplot2::geom_point(size = 2.5, alpha = 0.8) +
    ggplot2::scale_colour_manual(values = amrc_default_named_palette(data[[category_col]]), drop = FALSE) +
    amrc_theme_manuscript_bw() +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = effect_x_col, y = effect_y_col, colour = "Direction")

  if (isTRUE(show_counts)) {
    counts <- amrc_summarise_effect_directions(data, category_col = category_col)
    annotation <- merge(
      counts,
      data.frame(
        direction = c("positive_positive", "negative_positive", "negative_negative", "positive_negative"),
        x = c(1, -1, -1, 1),
        y = c(1, 1, -1, -1),
        stringsAsFactors = FALSE
      ),
      by = "direction",
      all.x = TRUE,
      sort = FALSE
    )
    annotation <- annotation[stats::complete.cases(annotation[, c("x", "y"), drop = FALSE]), , drop = FALSE]
    if (nrow(annotation) > 0L) {
      plot <- plot + ggplot2::geom_text(
        data = annotation,
        mapping = ggplot2::aes(
          x = .data[["x"]] * max(abs(data[[effect_x_col]]), na.rm = TRUE),
          y = .data[["y"]] * max(abs(data[[effect_y_col]]), na.rm = TRUE),
          label = paste0(.data[["n"]], " (", round(.data[["proportion"]] * 100, 1), "%)")
        ),
        inherit.aes = FALSE
      )
    }
  }

  plot
}

#' Plot Cross-Method Feature Overlap
#'
#' @param overlap_result Output from [amrc_compute_feature_overlap()].
#' @param mode Plot type: `"pairwise"` or `"membership"`.
#' @param top_n Number of features to show in membership mode.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_feature_overlap <- function(
  overlap_result,
  mode = c("pairwise", "membership"),
  top_n = 25
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  mode <- match.arg(mode)
  if (!is.list(overlap_result) || is.null(overlap_result$pairwise_overlap)) {
    stop("overlap_result must be the output of amrc_compute_feature_overlap().", call. = FALSE)
  }

  if (identical(mode, "pairwise")) {
    plot_data <- overlap_result$pairwise_overlap
    plot_data$.amrc_pair <- paste(plot_data$method_1, plot_data$method_2, sep = " vs ")
    return(
      ggplot2::ggplot(plot_data, ggplot2::aes(x = .data[[".amrc_pair"]], y = .data[["jaccard"]], fill = .data[[".amrc_pair"]])) +
        ggplot2::geom_col(show.legend = FALSE) +
        ggplot2::scale_fill_manual(values = amrc_default_named_palette(plot_data$.amrc_pair), drop = FALSE) +
        amrc_theme_manuscript_bw() +
        ggplot2::labs(x = "Method pair", y = "Jaccard overlap")
    )
  }

  membership <- overlap_result$membership_matrix
  method_cols <- setdiff(colnames(membership), c("feature", "n_methods", "method_list"))
  membership <- membership[order(-membership$n_methods, membership$feature), , drop = FALSE]
  membership <- utils::head(membership, top_n)
  long_data <- do.call(rbind, lapply(method_cols, function(method) {
    data.frame(
      feature = membership$feature,
      method = method,
      present = membership[[method]],
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }))

  ggplot2::ggplot(long_data, ggplot2::aes(x = .data[["method"]], y = stats::reorder(.data[["feature"]], .data[["feature"]]), fill = .data[["present"]])) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_manual(values = c("FALSE" = "grey90", "TRUE" = "#377EB8")) +
    amrc_theme_manuscript_bw() +
    ggplot2::labs(x = "Method", y = "Feature", fill = "Present")
}

#' Plot Heritability Summaries
#'
#' @param heritability_table Table containing one row per response.
#' @param trait_col Response/trait column.
#' @param value_col Heritability column.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_heritability_summary <- function(
  heritability_table,
  trait_col = NULL,
  value_col = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  amrc_assert_is_data_frame(heritability_table, arg_name = "heritability_table")
  trait_col <- amrc_infer_column(heritability_table, trait_col, c("response", "trait", "trait_name"), "trait_col")
  value_col <- amrc_infer_column(heritability_table, value_col, c("heritability", "h2"), "value_col")

  ggplot2::ggplot(heritability_table, ggplot2::aes(x = stats::reorder(.data[[trait_col]], .data[[value_col]]), y = .data[[value_col]])) +
    ggplot2::geom_col(fill = "#4DAF4A", colour = "black") +
    ggplot2::coord_flip() +
    amrc_theme_manuscript_bw() +
    ggplot2::labs(x = "Trait", y = "Heritability")
}

#' Plot Variance-Decomposition Summaries
#'
#' @param variance_table Table containing response/component/proportion columns.
#' @param trait_col Response/trait column.
#' @param component_col Variance-component column.
#' @param value_col Numeric proportion column.
#'
#' @return A `ggplot` object.
#' @export
amrc_plot_variance_decomposition <- function(
  variance_table,
  trait_col = NULL,
  component_col = NULL,
  value_col = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for plotting.", call. = FALSE)
  }

  amrc_assert_is_data_frame(variance_table, arg_name = "variance_table")
  trait_col <- amrc_infer_column(variance_table, trait_col, c("response", "trait", "trait_name"), "trait_col")
  component_col <- amrc_infer_column(variance_table, component_col, c("component", "label"), "component_col")
  value_col <- amrc_infer_column(variance_table, value_col, c("proportion", "variance_proportion", "value"), "value_col")

  ggplot2::ggplot(variance_table, ggplot2::aes(x = .data[[trait_col]], y = .data[[value_col]], fill = .data[[component_col]])) +
    ggplot2::geom_col(position = "stack", colour = "black") +
    ggplot2::scale_fill_manual(values = amrc_default_named_palette(variance_table[[component_col]]), drop = FALSE) +
    amrc_theme_manuscript_bw() +
    ggplot2::labs(x = "Trait", y = "Variance proportion", fill = "Component")
}
