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
