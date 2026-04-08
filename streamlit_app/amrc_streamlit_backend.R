`%||%` <- function(x, y) {
  if (is.null(x) || identical(x, "")) y else x
}

amrc_scalar_or_null <- function(x) {
  if (is.null(x) || length(x) == 0L || identical(x, "")) {
    return(NULL)
  }
  if (is.atomic(x) && length(x) == 1L) {
    return(as.character(x))
  }
  x
}

amrc_vector_or_null <- function(x) {
  if (is.null(x) || length(x) == 0L) {
    return(NULL)
  }
  x <- as.character(x)
  x <- x[nzchar(x)]
  if (length(x) == 0L) {
    return(NULL)
  }
  unique(x)
}

amrc_numeric_or_null <- function(x) {
  x <- amrc_scalar_or_null(x)
  if (is.null(x)) {
    return(NULL)
  }
  value <- suppressWarnings(as.numeric(x))
  if (length(value) != 1L || is.na(value) || !is.finite(value)) {
    return(NULL)
  }
  value
}

amrc_resolve_package_load_mode <- function(default = "source") {
  mode <- Sys.getenv("AMRC_PACKAGE_LOAD_MODE", unset = "")
  if (identical(mode, "")) {
    return(default)
  }
  if (!(mode %in% c("source", "installed"))) {
    stop(
      "AMRC_PACKAGE_LOAD_MODE must be either 'source' or 'installed'.",
      call. = FALSE
    )
  }
  mode
}

amrc_positive_limit_or_null <- function(x) {
  value <- amrc_numeric_or_null(x)
  if (is.null(value) || !isTRUE(value > 0)) {
    return(NULL)
  }
  c(0, value)
}

amrc_breaks_from_step <- function(values, step, limits = NULL) {
  step <- amrc_numeric_or_null(step)
  if (is.null(step) || !isTRUE(step > 0)) {
    return(NULL)
  }

  if (!is.null(limits)) {
    lower <- limits[[1]]
    upper <- limits[[2]]
  } else {
    finite_values <- values[is.finite(values)]
    if (length(finite_values) == 0L) {
      return(NULL)
    }
    lower <- min(finite_values, na.rm = TRUE)
    upper <- max(finite_values, na.rm = TRUE)
  }

  if (!is.finite(lower) || !is.finite(upper) || upper < lower) {
    return(NULL)
  }

  seq(
    from = floor(lower / step) * step,
    to = ceiling(upper / step) * step,
    by = step
  )
}

amrc_first_existing_column <- function(data, candidates) {
  hits <- candidates[candidates %in% colnames(data)]
  if (length(hits) == 0L) {
    return(NULL)
  }
  hits[[1]]
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1L) {
  stop("Usage: Rscript streamlit_app/amrc_streamlit_backend.R <config.json>", call. = FALSE)
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required for the Streamlit backend.", call. = FALSE)
}

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required for the Streamlit backend.", call. = FALSE)
}

config <- jsonlite::fromJSON(args[[1]], simplifyVector = TRUE)
repo_root <- normalizePath(config$repo_root, mustWork = TRUE)
output_dir <- normalizePath(config$output_dir, winslash = "/", mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

amrc_load_package <- function(repo_root, load_mode = c("source", "installed")) {
  load_mode <- match.arg(load_mode)
  prefer_installed <- identical(load_mode, "installed")

  if (isTRUE(prefer_installed) && requireNamespace("amrcartography", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  if (identical(load_mode, "source") && requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(
      path = repo_root,
      export_all = FALSE,
      helpers = FALSE,
      attach_testthat = FALSE,
      quiet = TRUE
    )

    return(invisible(TRUE))
  }

  if (identical(load_mode, "installed") && requireNamespace("amrcartography", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  stop(
    if (identical(load_mode, "source")) {
      "pkgload is required to run the Streamlit app directly from the repo checkout."
    } else {
      "An installed copy of amrcartography is required for installed-package mode."
    },
    call. = FALSE
  )

  invisible(TRUE)
}

package_load_mode <- amrc_resolve_package_load_mode(default = "source")
amrc_load_package(repo_root, load_mode = package_load_mode)

amrc_fn <- function(name) getExportedValue("amrcartography", name)

read_csv_keep_names <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_plot <- function(plot, path, width = 7, height = 6) {
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = width,
    height = height,
    dpi = 300
  )
}

`%fmt_or_na%` <- function(x, digits = 3) {
  if (is.null(x) || length(x) == 0L || is.na(x) || !is.finite(x)) {
    return("NA")
  }
  format(round(as.numeric(x), digits = digits), nsmall = min(digits, 3), trim = TRUE)
}

amrc_escape_html <- function(text) {
  text <- gsub("&", "&amp;", text, fixed = TRUE)
  text <- gsub("<", "&lt;", text, fixed = TRUE)
  text <- gsub(">", "&gt;", text, fixed = TRUE)
  text
}

amrc_html_list <- function(items) {
  items <- items[!is.na(items) & nzchar(items)]
  if (length(items) == 0L) {
    return("<p>None.</p>")
  }
  items <- sub("^[-*]\\s+", "", items)
  paste0(
    "<ul>",
    paste0("<li>", vapply(items, amrc_escape_html, character(1)), "</li>", collapse = ""),
    "</ul>"
  )
}

amrc_markdown_list <- function(items) {
  items <- items[!is.na(items) & nzchar(items)]
  if (length(items) == 0L) {
    return("None.")
  }
  paste0("- ", sub("^[-*]\\s+", "", items))
}

amrc_collect_report_figures <- function(output_dir, summary) {
  comparison_summary <- summary$genotype %||% summary$external
  candidates <- list(
    list(
      file = "phenotype_map.png",
      title = "Phenotype map",
      caption = "Primary phenotype map calibrated to MIC-style units."
    ),
    list(
      file = "phenotype_cluster_map.png",
      title = "Phenotype cluster overlay",
      caption = "Phenotype map with cluster assignments overlaid."
    ),
    list(
      file = "phenotype_cluster_elbow.png",
      title = "Phenotype scree diagnostic",
      caption = "Cluster scree / elbow diagnostic for the phenotype map."
    )
  )

  if (!is.null(comparison_summary)) {
    candidates <- c(
      candidates,
      list(
        list(
          file = "external_map.png",
          title = "Genotype / structure map",
          caption = "Genotype or structure map rendered with the same manuscript-style visual language."
        ),
        list(
          file = "side_by_side_maps.png",
          title = "Phenotype versus genotype panel",
          caption = "Side-by-side phenotype and genotype / structure maps."
        ),
        list(
          file = "external_cluster_map.png",
          title = "Genotype cluster overlay",
          caption = "Genotype / structure map with cluster assignments overlaid."
        ),
        list(
          file = "external_cluster_elbow.png",
          title = "Genotype scree diagnostic",
          caption = "Cluster scree / elbow diagnostic for the genotype / structure map."
        )
      )
    )
  }

  if (!is.null(comparison_summary$reference)) {
    candidates <- c(
      candidates,
      list(
        list(
          file = "reference_distance_relationship.png",
          title = "Reference-distance relationship",
          caption = "Phenotype versus genotype / structure distance from the selected reference group."
        )
      )
    )
  }

  figures <- Filter(
    f = function(x) file.exists(file.path(output_dir, x$file)),
    x = candidates
  )

  if (length(figures) == 0L) {
    return(figures)
  }

  for (i in seq_along(figures)) {
    figures[[i]]$path <- file.path(output_dir, figures[[i]]$file)
  }
  figures
}

amrc_markdown_figure_section <- function(figures) {
  if (length(figures) == 0L) {
    return(character())
  }

  lines <- c("## Figures", "")
  for (figure in figures) {
    lines <- c(
      lines,
      sprintf("### %s", figure$title),
      "",
      sprintf("![%s](%s)", figure$title, figure$file),
      "",
      figure$caption,
      ""
    )
  }
  lines
}

amrc_html_figure_section <- function(figures) {
  if (length(figures) == 0L) {
    return("")
  }

  cards <- vapply(
    figures,
    function(figure) {
      paste0(
        "<div class=\"figure-card\">",
        "<h3>", amrc_escape_html(figure$title), "</h3>",
        "<img src=\"", amrc_escape_html(figure$file), "\" alt=\"", amrc_escape_html(figure$title), "\" />",
        "<p class=\"figure-caption\">", amrc_escape_html(figure$caption), "</p>",
        "</div>"
      )
    },
    character(1)
  )

  paste0(
    "<h2>Figures</h2>",
    "<div class=\"figure-grid\">",
    paste(cards, collapse = ""),
    "</div>"
  )
}

write_report_pdf <- function(markdown, output_dir) {
  pdf_path <- file.path(output_dir, "amrc_report.pdf")
  grDevices::pdf(pdf_path, width = 8.27, height = 11.69, family = "Helvetica")
  on.exit(grDevices::dev.off(), add = TRUE)
  grid::grid.newpage()
  grid::grid.text(
    markdown,
    x = grid::unit(0.03, "npc"),
    y = grid::unit(0.97, "npc"),
    just = c("left", "top"),
    gp = grid::gpar(fontfamily = "Helvetica", cex = 0.72)
  )
  pdf_path
}

write_output_archive <- function(output_dir, archive_name = "amrc_output_bundle.zip") {
  archive_path <- file.path(output_dir, archive_name)
  files <- list.files(output_dir, full.names = TRUE)
  files <- files[basename(files) != archive_name]
  if (length(files) == 0L) {
    return(NULL)
  }

  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(output_dir)

  tryCatch(
    {
      utils::zip(zipfile = archive_name, files = basename(files), flags = "-rq")
      archive_path
    },
    error = function(...) NULL,
    warning = function(...) NULL
  )
}

fit_report_metrics_frame <- function(fit_report, stress_value = NA_real_) {
  data.frame(
    stress = unname(stress_value %||% NA_real_),
    r_squared = unname(fit_report$r_squared %||% NA_real_),
    dilation = unname(fit_report$dilation %||% NA_real_),
    correlation_estimate = unname(fit_report$correlation$estimate %||% NA_real_),
    correlation_p_value = unname(fit_report$correlation$p.value %||% NA_real_),
    correlation_method = fit_report$correlation$method %||% NA_character_,
    n_distance_pairs = nrow(fit_report$distances %||% data.frame()),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

write_fit_report_outputs <- function(fit_report, output_dir, prefix, stress_value = NA_real_) {
  metrics <- fit_report_metrics_frame(fit_report, stress_value = stress_value)
  residual_summary_path <- file.path(output_dir, paste0(prefix, "_residual_summary.csv"))
  stress_summary_path <- file.path(output_dir, paste0(prefix, "_stress_summary.csv"))
  fit_metrics_path <- file.path(output_dir, paste0(prefix, "_fit_metrics.csv"))
  fit_distances_path <- file.path(output_dir, paste0(prefix, "_fit_distances.csv"))

  utils::write.csv(
    fit_report$residual_summary,
    file = residual_summary_path,
    row.names = FALSE
  )
  utils::write.csv(
    fit_report$stress_summary,
    file = stress_summary_path,
    row.names = FALSE
  )
  utils::write.csv(
    metrics,
    file = fit_metrics_path,
    row.names = FALSE
  )
  utils::write.csv(
    fit_report$distances,
    file = fit_distances_path,
    row.names = FALSE
  )

  list(
    metrics = metrics,
    residual_summary = fit_report$residual_summary,
    stress_summary = fit_report$stress_summary,
    distances = fit_report$distances,
    paths = list(
      residual_summary = residual_summary_path,
      stress_summary = stress_summary_path,
      fit_metrics = fit_metrics_path,
      fit_distances = fit_distances_path
    )
  )
}

write_run_report <- function(summary, output_dir, config) {
  comparison_summary <- summary$genotype %||% summary$external

  phenotype_lines <- c(
    sprintf("Isolates: %s", summary$phenotype$n_isolates %||% "NA"),
    sprintf("MIC variables: %s", summary$phenotype$n_drugs %||% "NA"),
    sprintf("Stress: %s", summary$phenotype$stress %fmt_or_na% 4)
  )

  if (!is.null(summary$phenotype$clustering)) {
    phenotype_lines <- c(
      phenotype_lines,
      sprintf("Phenotype clusters: %s", summary$phenotype$clustering$n_clusters %||% "NA"),
      sprintf(
        "Phenotype selected inertia: %s",
        summary$phenotype$clustering$selected_inertia %fmt_or_na% 4
      )
    )
  }

  if (!is.null(summary$phenotype$calibration)) {
    phenotype_lines <- c(
      phenotype_lines,
      sprintf(
        "Calibration: %s",
        summary$phenotype$calibration$note %||% "model-based MIC calibration"
      ),
      sprintf(
        "Phenotype dilation: %s",
        summary$phenotype$calibration$dilation %fmt_or_na% 4
      ),
      sprintf(
        "Phenotype rotation (degrees): %s",
        summary$phenotype$calibration$rotation_degrees %fmt_or_na% 1
      )
    )
  }
  if (!is.null(summary$phenotype$fit)) {
    phenotype_lines <- c(
      phenotype_lines,
      sprintf("Goodness-of-fit R squared: %s", summary$phenotype$fit$r_squared %fmt_or_na% 4),
      sprintf(
        "Pairwise distance correlation: %s",
        summary$phenotype$fit$correlation_estimate %fmt_or_na% 4
      ),
      sprintf(
        "Mean absolute residual: %s",
        summary$phenotype$fit$mean_abs_residual %fmt_or_na% 4
      )
    )
  }

  genotype_lines <- c("Genotype / structure workflow disabled")
  if (!is.null(comparison_summary)) {
    genotype_lines <- c(
      sprintf("Mode: %s", comparison_summary$mode %||% "NA"),
      sprintf("Isolates in comparison: %s", comparison_summary$n_isolates %||% "NA"),
      sprintf("Stress: %s", comparison_summary$stress %fmt_or_na% 4)
    )

    if (!is.null(comparison_summary$clustering)) {
      genotype_lines <- c(
        genotype_lines,
        sprintf("Genotype clusters: %s", comparison_summary$clustering$n_clusters %||% "NA"),
        sprintf(
          "Genotype selected inertia: %s",
          comparison_summary$clustering$selected_inertia %fmt_or_na% 4
        )
      )
    }

    if (!is.null(comparison_summary$reference)) {
      genotype_lines <- c(
        genotype_lines,
        sprintf("Reference column: %s", comparison_summary$reference$reference_col %||% "NA"),
        sprintf("Reference value: %s", comparison_summary$reference$reference_value %||% "NA"),
        sprintf("Reference rows: %s", comparison_summary$reference$n_rows %||% "NA"),
        sprintf("Reference mode: %s", comparison_summary$reference$cluster_mode %||% "NA")
      )
    }

    if (!is.null(comparison_summary$calibration)) {
      genotype_lines <- c(
        genotype_lines,
        sprintf(
          "Calibration: %s",
          comparison_summary$calibration$note %||% "model-based MIC calibration"
        ),
        sprintf(
          "Genotype dilation: %s",
          comparison_summary$calibration$dilation %fmt_or_na% 4
        ),
        sprintf(
          "Genotype rotation (degrees): %s",
          comparison_summary$calibration$rotation_degrees %fmt_or_na% 1
        )
      )
    }
    if (!is.null(comparison_summary$fit)) {
      genotype_lines <- c(
        genotype_lines,
        sprintf("Goodness-of-fit R squared: %s", comparison_summary$fit$r_squared %fmt_or_na% 4),
        sprintf(
          "Pairwise distance correlation: %s",
          comparison_summary$fit$correlation_estimate %fmt_or_na% 4
        ),
        sprintf(
          "Mean absolute residual: %s",
          comparison_summary$fit$mean_abs_residual %fmt_or_na% 4
        )
      )
    }
  }

  output_items <- c(
    "`phenotype_map.png`",
    if (!is.null(comparison_summary)) c("`external_map.png`", "`side_by_side_maps.png`") else NULL,
    if (!is.null(comparison_summary$reference)) "`reference_distance_relationship.png`" else NULL,
    "`phenotype_fit_metrics.csv`",
    "`phenotype_residual_summary.csv`",
    "`phenotype_stress_summary.csv`",
    "`phenotype_fit_distances.csv`",
    if (!is.null(comparison_summary)) c(
      "`external_fit_metrics.csv`",
      "`external_residual_summary.csv`",
      "`external_stress_summary.csv`",
      "`external_fit_distances.csv`"
    ) else NULL,
    "`summary.json`",
    "`amrc_result_bundle.rds`"
  )
  figures <- amrc_collect_report_figures(output_dir = output_dir, summary = summary)

  report_lines <- c(
    "# amrcartography analysis report",
    "",
    amrc_markdown_list(c(
      sprintf("Package release target: `%s`", summary$package_release_target %||% "unknown"),
      sprintf("Phenotype source: `%s`", basename(config$phenotype$path %||% "unknown"))
    )),
    "",
    "## Phenotype workflow",
    amrc_markdown_list(phenotype_lines),
    "",
    "## Genotype / structure workflow",
    amrc_markdown_list(genotype_lines),
    "",
    "## Output files",
    amrc_markdown_list(output_items),
    "",
    amrc_markdown_figure_section(figures)
  )

  markdown <- paste(report_lines, collapse = "\n")
  output_files <- c(
    "phenotype_map.png",
    if (!is.null(comparison_summary)) c("external_map.png", "side_by_side_maps.png") else NULL,
    if (!is.null(comparison_summary$reference)) "reference_distance_relationship.png" else NULL,
    "phenotype_fit_metrics.csv",
    "phenotype_residual_summary.csv",
    "phenotype_stress_summary.csv",
    "phenotype_fit_distances.csv",
    if (!is.null(comparison_summary)) c(
      "external_fit_metrics.csv",
      "external_residual_summary.csv",
      "external_stress_summary.csv",
      "external_fit_distances.csv"
    ) else NULL,
    "summary.json",
    if (isTRUE(config$report$pdf_export)) "amrc_report.pdf" else NULL,
    if (isTRUE(config$report$zip_bundle)) "amrc_output_bundle.zip" else NULL,
    "amrc_result_bundle.rds"
  )
  html <- paste0(
    "<html><head><meta charset=\"utf-8\"><title>amrcartography analysis report</title>",
    "<style>",
    "body{font-family:Helvetica,Arial,sans-serif;margin:2rem;line-height:1.55;color:#111;background:#fff;}",
    "h1,h2{color:#111;margin-bottom:0.4rem;} h1{letter-spacing:0.01em;}",
    "h3{color:#111;margin:0 0 0.6rem 0;}",
    "code{background:#f3f3f3;padding:0.1rem 0.25rem;border-radius:2px;}",
    ".lede{border-left:4px solid #377EB8;background:#f7fbff;padding:0.85rem 1rem;margin:1rem 0 1.25rem 0;}",
    ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:1rem;margin:1rem 0;}",
    ".card{border:1px solid #d9d9d9;padding:1rem;border-radius:6px;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,0.03);}",
    ".metric{font-size:1.4rem;font-weight:700;color:#202020;}",
    ".caption{color:#555;font-size:0.95rem;}",
    "ul{margin-top:0.5rem;padding-left:1.1rem;}",
    ".figure-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:1rem;margin:1rem 0;}",
    ".figure-card{border:1px solid #d9d9d9;padding:0.9rem;border-radius:6px;background:#fff;box-shadow:0 1px 2px rgba(0,0,0,0.03);}",
    ".figure-card img{width:100%;height:auto;border:1px solid #ececec;border-radius:4px;background:#fff;}",
    ".figure-caption{margin:0.75rem 0 0 0;color:#444;font-size:0.95rem;}",
    "</style></head><body>",
    "<h1>amrcartography analysis report</h1>",
    "<div class=\"lede\">",
    "<strong>Calibration note.</strong> One-unit grid spacing should be interpreted as one doubling dilution only after the package calibration model has been applied.",
    "</div>",
    "<div class=\"grid\">",
    "<div class=\"card\"><div class=\"caption\">Release target</div><div class=\"metric\">",
    amrc_escape_html(summary$package_release_target %||% "unknown"),
    "</div></div>",
    "<div class=\"card\"><div class=\"caption\">Phenotype isolates</div><div class=\"metric\">",
    amrc_escape_html(as.character(summary$phenotype$n_isolates %||% "NA")),
    "</div></div>",
    "<div class=\"card\"><div class=\"caption\">MIC variables</div><div class=\"metric\">",
    amrc_escape_html(as.character(summary$phenotype$n_drugs %||% "NA")),
    "</div></div>",
    "<div class=\"card\"><div class=\"caption\">Phenotype stress</div><div class=\"metric\">",
    amrc_escape_html(summary$phenotype$stress %fmt_or_na% 4),
    "</div></div>",
    "</div>",
    "<h2>Phenotype workflow</h2>",
    amrc_html_list(phenotype_lines),
    "<h2>Genotype / structure workflow</h2>",
    amrc_html_list(genotype_lines),
    amrc_html_figure_section(figures),
    "<h2>Output files</h2>",
    amrc_html_list(output_files),
    "</body></html>"
  )

  writeLines(markdown, con = file.path(output_dir, "amrc_report.md"), useBytes = TRUE)
  writeLines(html, con = file.path(output_dir, "amrc_report.html"), useBytes = TRUE)
  if (isTRUE(config$report$pdf_export)) {
    write_report_pdf(markdown, output_dir = output_dir)
  }
}

prepare_map_frame <- function(mds_result, metadata, id_col, prefix = "D") {
  coords <- as.data.frame(mds_result$conf, stringsAsFactors = FALSE, check.names = FALSE)
  colnames(coords) <- paste0(prefix, seq_len(ncol(coords)))
  prepare_configuration_frame(coords, metadata = metadata, id_col = id_col)
}

prepare_configuration_frame <- function(configuration, metadata, id_col, prefix = NULL) {
  coords <- as.data.frame(configuration, stringsAsFactors = FALSE, check.names = FALSE)
  if (!is.null(prefix)) {
    colnames(coords) <- paste0(prefix, seq_len(ncol(coords)))
  }

  ids <- rownames(coords)
  if (is.null(ids) || any(!nzchar(ids))) {
    ids <- as.character(metadata[[id_col]])
  }

  coords[[id_col]] <- ids
  metadata_aligned <- metadata[match(ids, metadata[[id_col]]), , drop = FALSE]
  cbind(
    coords[, c(id_col, setdiff(colnames(coords), id_col)), drop = FALSE],
    metadata_aligned[, setdiff(colnames(metadata_aligned), id_col), drop = FALSE]
  )
}

parse_precomputed_distance <- function(path, id_col) {
  raw <- read_csv_keep_names(path)

  if (!(id_col %in% colnames(raw))) {
    stop("The external distance file is missing the selected ID column.", call. = FALSE)
  }

  row_ids <- as.character(raw[[id_col]])
  matrix_df <- raw[, setdiff(colnames(raw), id_col), drop = FALSE]
  distance_matrix <- as.matrix(matrix_df)
  storage.mode(distance_matrix) <- "double"
  rownames(distance_matrix) <- row_ids

  if (nrow(distance_matrix) != ncol(distance_matrix)) {
    stop(
      "Precomputed external distance matrices must be square after removing the ID column.",
      call. = FALSE
    )
  }

  if (is.null(colnames(distance_matrix)) || any(!nzchar(colnames(distance_matrix)))) {
    colnames(distance_matrix) <- row_ids
  }

  amrc_fn("amrc_compute_external_distance")(
    distance_matrix,
    isolate_ids = row_ids
  )
}

amrc_section <- function(config, primary, fallback = NULL) {
  section <- config[[primary]]
  if (!is.null(section)) {
    return(section)
  }
  if (!is.null(fallback)) {
    return(config[[fallback]] %||% list())
  }
  list()
}

phenotype_plot_cfg <- amrc_section(config, "phenotype_plot", fallback = "plot")
genotype_plot_cfg <- amrc_section(config, "genotype_plot", fallback = "plot")
phenotype_cluster_cfg <- amrc_section(config, "phenotype_clustering", fallback = "clustering")
genotype_cluster_cfg <- amrc_section(config, "genotype_clustering", fallback = "clustering")
genotype_cfg <- amrc_section(config, "genotype", fallback = "external")

id_col <- config$phenotype$id_col
metadata_cols <- config$phenotype$metadata_cols %||% character()
group_col <- amrc_scalar_or_null(config$comparison$group_col)
phenotype_fill_col <- amrc_scalar_or_null(phenotype_plot_cfg$fill_col)
phenotype_facet_by <- amrc_scalar_or_null(phenotype_plot_cfg$facet_by)
phenotype_grid_spacing <- if (isTRUE(phenotype_plot_cfg$grid_spacing_one)) 1 else NULL
phenotype_density_mode <- if (isTRUE(phenotype_plot_cfg$density)) "contour" else "none"
phenotype_rotation_degrees <- amrc_numeric_or_null(
  phenotype_plot_cfg$rotation_degrees %||% phenotype_plot_cfg$phenotype_rotation_degrees
)
genotype_fill_col <- amrc_scalar_or_null(genotype_plot_cfg$fill_col)
genotype_facet_by <- amrc_scalar_or_null(genotype_plot_cfg$facet_by)
genotype_grid_spacing <- if (isTRUE(genotype_plot_cfg$grid_spacing_one)) 1 else NULL
genotype_density_mode <- if (isTRUE(genotype_plot_cfg$density)) "contour" else "none"
external_rotation_degrees <- amrc_numeric_or_null(
  genotype_plot_cfg$rotation_degrees %||% genotype_plot_cfg$external_rotation_degrees
)
phenotype_cluster_enabled <- isTRUE(phenotype_cluster_cfg$enabled)
phenotype_cluster_n <- as.integer(phenotype_cluster_cfg$n_clusters %||% 4L)
phenotype_cluster_max_k <- as.integer(phenotype_cluster_cfg$max_k %||% max(phenotype_cluster_n + 2L, 10L))
phenotype_cluster_distinct_col <- amrc_scalar_or_null(phenotype_cluster_cfg$distinct_col) %||% id_col
genotype_cluster_enabled <- isTRUE(genotype_cluster_cfg$enabled)
genotype_cluster_n <- as.integer(genotype_cluster_cfg$n_clusters %||% phenotype_cluster_n)
genotype_cluster_max_k <- as.integer(genotype_cluster_cfg$max_k %||% max(genotype_cluster_n + 2L, 10L))
genotype_cluster_distinct_col <- amrc_scalar_or_null(genotype_cluster_cfg$distinct_col) %||% id_col
reference_enabled <- isTRUE(config$reference$enabled)
reference_col <- amrc_scalar_or_null(config$reference$reference_col)
reference_value <- amrc_scalar_or_null(config$reference$reference_value)
reference_filter_col <- amrc_scalar_or_null(config$reference$filter_col)
reference_filter_values <- amrc_vector_or_null(config$reference$filter_values)
reference_cluster_mode <- amrc_scalar_or_null(config$reference$cluster_mode) %||% "auto"
reference_x_max <- amrc_numeric_or_null(config$reference$x_max)
reference_y_max <- amrc_numeric_or_null(config$reference$y_max)
reference_x_break_step <- amrc_numeric_or_null(config$reference$x_break_step)
reference_y_break_step <- amrc_numeric_or_null(config$reference$y_break_step)
reference_annotation_text <- amrc_scalar_or_null(config$reference$annotation_text)
reference_annotation_x <- amrc_numeric_or_null(config$reference$annotation_x)
reference_annotation_y <- amrc_numeric_or_null(config$reference$annotation_y)

phenotype_data <- read_csv_keep_names(config$phenotype$path)

mic_data <- amrc_fn("amrc_standardise_mic_data")(
  data = phenotype_data,
  id_col = id_col,
  mic_cols = config$phenotype$mic_cols,
  metadata_cols = metadata_cols,
  transform = config$phenotype$transform,
  drop_incomplete = isTRUE(config$phenotype$drop_incomplete),
  less_than = config$phenotype$less_than,
  greater_than = config$phenotype$greater_than
)

phenotype_distance <- amrc_fn("amrc_compute_mic_distance")(mic_data)
phenotype_map <- amrc_fn("amrc_compute_mds")(phenotype_distance)
phenotype_fit_report <- amrc_fn("amrc_map_fit_report")(
  phenotype_map,
  rotation_degrees = phenotype_rotation_degrees
)
phenotype_calibration <- amrc_fn("amrc_calibrate_mds")(
  phenotype_map,
  rotation_degrees = phenotype_rotation_degrees
)
phenotype_fit_outputs <- write_fit_report_outputs(
  fit_report = phenotype_fit_report,
  output_dir = output_dir,
  prefix = "phenotype",
  stress_value = phenotype_map$stress
)
phenotype_plot_data <- prepare_configuration_frame(
  configuration = phenotype_calibration$configuration,
  metadata = mic_data$metadata,
  id_col = id_col,
  prefix = "D"
)

phenotype_plot <- amrc_fn("amrc_plot_map")(
  data = phenotype_plot_data,
  x = "D1",
  y = "D2",
  fill_col = phenotype_fill_col,
  facet_by = phenotype_facet_by,
  grid_spacing = phenotype_grid_spacing,
  density = phenotype_density_mode,
  use_cartography_theme = TRUE
)

write_plot(phenotype_plot, file.path(output_dir, "phenotype_map.png"))
utils::write.csv(
  phenotype_plot_data,
  file = file.path(output_dir, "phenotype_map_data.csv"),
  row.names = FALSE
)

phenotype_cluster <- NULL
phenotype_cluster_data <- phenotype_plot_data
if (isTRUE(phenotype_cluster_enabled)) {
  phenotype_cluster <- amrc_fn("amrc_cluster_map")(
    data = phenotype_plot_data,
    coord_cols = c("D1", "D2"),
    n_clusters = phenotype_cluster_n,
    distinct_col = phenotype_cluster_distinct_col,
    max_k = phenotype_cluster_max_k
  )
  phenotype_cluster_data <- amrc_fn("amrc_add_cluster_assignments")(
    data = phenotype_plot_data,
    assignments = phenotype_cluster$assignments,
    key_col = phenotype_cluster_distinct_col,
    cluster_col = "phen_cluster"
  )
  phenotype_cluster_plot <- amrc_fn("amrc_plot_cluster_map")(
    data = phenotype_cluster_data,
    x = "D1",
    y = "D2",
    cluster_col = "phen_cluster",
    facet_by = phenotype_facet_by,
    show_legend = TRUE
  )
  write_plot(phenotype_cluster_plot, file.path(output_dir, "phenotype_cluster_map.png"))
  phenotype_elbow_plot <- amrc_fn("amrc_plot_cluster_elbow")(
    scree_data = phenotype_cluster$scree,
    highlight_cluster = phenotype_cluster_n,
    draw_path = TRUE
  )
  write_plot(
    phenotype_elbow_plot,
    file.path(output_dir, "phenotype_cluster_elbow.png"),
    width = 7,
    height = 5
  )
  utils::write.csv(
    phenotype_cluster_data,
    file = file.path(output_dir, "phenotype_cluster_data.csv"),
    row.names = FALSE
  )
  utils::write.csv(
    phenotype_cluster$scree,
    file = file.path(output_dir, "phenotype_cluster_scree.csv"),
    row.names = FALSE
  )
}

summary <- list(
  package_release_target = "v0.2.0",
  phenotype = list(
    n_isolates = nrow(phenotype_plot_data),
    n_drugs = ncol(mic_data$mic),
    stress = unname(phenotype_map$stress %||% NA_real_),
    calibration = list(
      mode = "model_based_1mic",
      note = "Use calibration to place map coordinates on MIC-style units; one-unit grid spacing corresponds to one doubling dilution only after calibration.",
      dilation = unname(phenotype_calibration$dilation %||% NA_real_),
      rotation_degrees = phenotype_calibration$rotation_degrees %||% 0
    ),
    fit = list(
      r_squared = unname(phenotype_fit_report$r_squared %||% NA_real_),
      correlation_estimate = unname(phenotype_fit_report$correlation$estimate %||% NA_real_),
      correlation_p_value = unname(phenotype_fit_report$correlation$p.value %||% NA_real_),
      correlation_method = phenotype_fit_report$correlation$method %||% NA_character_,
      mean_abs_residual = phenotype_fit_report$residual_summary$mean_abs_residual[[1]] %||% NA_real_,
      sd_abs_residual = phenotype_fit_report$residual_summary$sd_abs_residual[[1]] %||% NA_real_,
      mean_spp = phenotype_fit_report$stress_summary$mean_spp[[1]] %||% NA_real_,
      max_spp = phenotype_fit_report$stress_summary$max_spp[[1]] %||% NA_real_
    ),
    clustering = if (isTRUE(phenotype_cluster_enabled)) {
      list(
        n_clusters = phenotype_cluster_n,
        distinct_col = phenotype_cluster_distinct_col,
        max_k = phenotype_cluster_max_k,
        selected_inertia = if (!is.null(phenotype_cluster)) {
          phenotype_cluster$scree$within_cluster_inertia[
            phenotype_cluster$scree$n_clusters == phenotype_cluster_n
          ][1]
        } else {
          NULL
        }
      )
    } else {
      NULL
    }
  ),
  genotype = NULL,
  external = NULL
)

result_bundle <- list(
  summary = summary,
  mic_data = mic_data,
  phenotype_distance = phenotype_distance,
  phenotype_map = phenotype_map,
  phenotype_fit_report = phenotype_fit_report,
  phenotype_fit_outputs = phenotype_fit_outputs,
  phenotype_calibration = phenotype_calibration,
  phenotype_plot_data = phenotype_plot_data,
  phenotype_cluster = phenotype_cluster,
  phenotype_cluster_data = phenotype_cluster_data
)

if (isTRUE(genotype_cfg$enabled)) {
  mode <- genotype_cfg$mode
  external_path <- genotype_cfg$path
  external_id_col <- genotype_cfg$id_col
  external_feature_cols <- genotype_cfg$feature_cols %||% character()

  if (identical(mode, "precomputed_distance")) {
    external_distance <- parse_precomputed_distance(
      path = external_path,
      id_col = external_id_col
    )
  } else if (identical(mode, "numeric_features")) {
    external_raw <- read_csv_keep_names(external_path)
    external_standardised <- amrc_fn("amrc_standardise_external_data")(
      data = external_raw,
      id_col = external_id_col,
      feature_cols = external_feature_cols,
      feature_mode = "numeric",
      drop_incomplete = TRUE
    )
    external_distance <- amrc_fn("amrc_compute_external_feature_distance")(external_standardised)
  } else if (identical(mode, "character_features")) {
    external_raw <- read_csv_keep_names(external_path)
    external_standardised <- amrc_fn("amrc_standardise_external_data")(
      data = external_raw,
      id_col = external_id_col,
      feature_cols = external_feature_cols,
      feature_mode = "character",
      drop_incomplete = TRUE
    )
    external_distance <- amrc_fn("amrc_compute_external_feature_distance")(external_standardised)
  } else if (identical(mode, "sequence_alleles")) {
    external_raw <- read_csv_keep_names(external_path)
    external_distance <- amrc_fn("amrc_compute_sequence_distance")(
      data = external_raw,
      id_col = external_id_col,
      sequence_cols = external_feature_cols
    )
  } else {
    stop("Unsupported external mode: ", mode, call. = FALSE)
  }

  external_map <- amrc_fn("amrc_compute_mds")(external_distance)
  external_fit_report <- amrc_fn("amrc_map_fit_report")(
    external_map,
    rotation_degrees = external_rotation_degrees
  )
  external_calibration <- amrc_fn("amrc_calibrate_mds")(
    external_map,
    rotation_degrees = external_rotation_degrees
  )
  external_fit_outputs <- write_fit_report_outputs(
    fit_report = external_fit_report,
    output_dir = output_dir,
    prefix = "external",
    stress_value = external_map$stress
  )
  comparison_bundle <- amrc_fn("amrc_prepare_map_data")(
    metadata = mic_data$metadata,
    phenotype_mds = phenotype_map,
    external_mds = external_map,
    id_col = id_col,
    group_col = group_col,
    phenotype_rotation_degrees = phenotype_rotation_degrees,
    external_rotation_degrees = external_rotation_degrees
  )

  external_plot <- amrc_fn("amrc_plot_map")(
    data = comparison_bundle$data,
    x = "E1",
    y = "E2",
    fill_col = genotype_fill_col,
    facet_by = genotype_facet_by,
    grid_spacing = genotype_grid_spacing,
    density = genotype_density_mode,
    use_cartography_theme = TRUE
  )
  side_plot <- if (requireNamespace("patchwork", quietly = TRUE)) {
    amrc_fn("amrc_compose_manuscript_side_by_side_panel")(
      left_plot = phenotype_plot,
      right_plot = external_plot,
      collect_guides = identical(phenotype_fill_col, genotype_fill_col) &&
        identical(phenotype_facet_by, genotype_facet_by)
    )
  } else {
    amrc_fn("amrc_plot_side_by_side_maps")(
      data = comparison_bundle$data,
      fill_col = phenotype_fill_col %||% genotype_fill_col,
      grid_spacing = phenotype_grid_spacing %||% genotype_grid_spacing
    )
  }

  write_plot(external_plot, file.path(output_dir, "external_map.png"))
  write_plot(side_plot, file.path(output_dir, "side_by_side_maps.png"), width = 10, height = 5)
  utils::write.csv(
    comparison_bundle$data,
    file = file.path(output_dir, "comparison_data.csv"),
    row.names = FALSE
  )

  external_cluster <- NULL
  external_cluster_data <- comparison_bundle$data
  if (isTRUE(genotype_cluster_enabled)) {
    join_key <- genotype_cluster_distinct_col
    if (!(join_key %in% colnames(external_cluster_data))) {
      join_key <- id_col
    }
    external_cluster <- amrc_fn("amrc_cluster_map")(
      data = external_cluster_data,
      coord_cols = c("E1", "E2"),
      n_clusters = genotype_cluster_n,
      distinct_col = join_key,
      max_k = genotype_cluster_max_k
    )
    external_cluster_data <- amrc_fn("amrc_add_cluster_assignments")(
      data = external_cluster_data,
      assignments = external_cluster$assignments,
      key_col = join_key,
      cluster_col = "external_cluster"
    )
    external_cluster_plot <- amrc_fn("amrc_plot_cluster_map")(
      data = external_cluster_data,
      x = "E1",
      y = "E2",
      cluster_col = "external_cluster",
      facet_by = genotype_facet_by,
      show_legend = TRUE
    )
    write_plot(external_cluster_plot, file.path(output_dir, "external_cluster_map.png"))
    external_elbow_plot <- amrc_fn("amrc_plot_cluster_elbow")(
      scree_data = external_cluster$scree,
      highlight_cluster = genotype_cluster_n,
      draw_path = TRUE
    )
    write_plot(
      external_elbow_plot,
      file.path(output_dir, "external_cluster_elbow.png"),
      width = 7,
      height = 5
    )
    utils::write.csv(
      external_cluster_data,
      file = file.path(output_dir, "external_cluster_data.csv"),
      row.names = FALSE
    )
    utils::write.csv(
      external_cluster$scree,
      file = file.path(output_dir, "external_cluster_scree.csv"),
      row.names = FALSE
    )
  }

  reference_outputs <- NULL
  if (isTRUE(reference_enabled) && !is.null(reference_col) && !is.null(reference_value)) {
    ref_cluster_col <- switch(
      reference_cluster_mode,
      "overall" = FALSE,
      "clustered" = if ("external_cluster" %in% colnames(external_cluster_data)) "external_cluster" else FALSE,
      if ("external_cluster" %in% colnames(external_cluster_data)) "external_cluster" else FALSE
    )
    reference_table <- amrc_fn("amrc_compute_reference_distance_table")(
      data = external_cluster_data,
      reference_value = reference_value,
      reference_col = reference_col,
      phenotype_cols = c("D1", "D2"),
      external_cols = c("E1", "E2"),
      id_col = id_col,
      cluster_col = ref_cluster_col,
      keep_cols = unique(stats::na.omit(c(phenotype_fill_col, genotype_fill_col, group_col, reference_filter_col)))
    )
    if (!is.null(reference_filter_col)) {
      if (!(reference_filter_col %in% colnames(reference_table))) {
        stop("reference filter column was not found in the reference-distance table.", call. = FALSE)
      }
      if (!is.null(reference_filter_values)) {
        reference_table <- reference_table[
          as.character(reference_table[[reference_filter_col]]) %in% reference_filter_values,
          ,
          drop = FALSE
        ]
      }
      if (nrow(reference_table) == 0L) {
        stop("Reference-distance filtering removed all rows.", call. = FALSE)
      }
    }
    reference_summary <- amrc_fn("amrc_summarise_reference_distance_table")(
      distance_table = reference_table,
      cluster_col = ref_cluster_col
    )
    reference_x_limits <- amrc_positive_limit_or_null(reference_x_max)
    reference_y_limits <- amrc_positive_limit_or_null(reference_y_max)
    reference_x_col <- amrc_first_existing_column(reference_table, c("external_distance", "gen_distance"))
    reference_y_col <- amrc_first_existing_column(reference_table, c("phenotype_distance", "phen_distance"))
    reference_plot <- amrc_fn("amrc_plot_reference_distance_relationship")(
      distance_table = reference_table,
      cluster_col = ref_cluster_col,
      x_limits = reference_x_limits,
      y_limits = reference_y_limits,
      x_breaks = if (!is.null(reference_x_col)) {
        amrc_breaks_from_step(reference_table[[reference_x_col]], reference_x_break_step, reference_x_limits)
      } else {
        NULL
      },
      y_breaks = if (!is.null(reference_y_col)) {
        amrc_breaks_from_step(reference_table[[reference_y_col]], reference_y_break_step, reference_y_limits)
      } else {
        NULL
      },
      annotation_text = reference_annotation_text,
      annotation_x = reference_annotation_x,
      annotation_y = reference_annotation_y
    )
    write_plot(
      reference_plot,
      file.path(output_dir, "reference_distance_relationship.png"),
      width = 7,
      height = 6
    )
    utils::write.csv(
      reference_table,
      file = file.path(output_dir, "reference_distance_table.csv"),
      row.names = FALSE
    )
    utils::write.csv(
      reference_summary$summary,
      file = file.path(output_dir, "reference_distance_summary.csv"),
      row.names = FALSE
    )
    reference_outputs <- list(
      table = reference_table,
      summary = reference_summary
    )
  }

  genotype_summary <- list(
    mode = mode,
    n_isolates = nrow(comparison_bundle$data),
    stress = unname(external_map$stress %||% NA_real_),
    calibration = list(
      mode = "model_based_1mic",
      note = "Use calibration to place map coordinates on MIC-style units; one-unit grid spacing corresponds to one doubling dilution only after calibration.",
      dilation = unname(external_calibration$dilation %||% NA_real_),
      rotation_degrees = external_calibration$rotation_degrees %||% 0
    ),
    fit = list(
      r_squared = unname(external_fit_report$r_squared %||% NA_real_),
      correlation_estimate = unname(external_fit_report$correlation$estimate %||% NA_real_),
      correlation_p_value = unname(external_fit_report$correlation$p.value %||% NA_real_),
      correlation_method = external_fit_report$correlation$method %||% NA_character_,
      mean_abs_residual = external_fit_report$residual_summary$mean_abs_residual[[1]] %||% NA_real_,
      sd_abs_residual = external_fit_report$residual_summary$sd_abs_residual[[1]] %||% NA_real_,
      mean_spp = external_fit_report$stress_summary$mean_spp[[1]] %||% NA_real_,
      max_spp = external_fit_report$stress_summary$max_spp[[1]] %||% NA_real_
    ),
    clustering = if (isTRUE(genotype_cluster_enabled)) {
      list(
        n_clusters = genotype_cluster_n,
        distinct_col = genotype_cluster_distinct_col,
        max_k = genotype_cluster_max_k,
        selected_inertia = if (!is.null(external_cluster)) {
          external_cluster$scree$within_cluster_inertia[
            external_cluster$scree$n_clusters == genotype_cluster_n
          ][1]
        } else {
          NULL
        }
      )
    } else {
      NULL
    },
    reference = if (!is.null(reference_outputs)) {
      list(
        reference_col = reference_col,
        reference_value = reference_value,
        n_rows = nrow(reference_outputs$table),
        cluster_mode = reference_cluster_mode,
        filter_col = reference_filter_col,
        filter_values = reference_filter_values,
        x_break_step = reference_x_break_step,
        y_break_step = reference_y_break_step,
        annotation_text = reference_annotation_text
      )
    } else {
      NULL
    }
  )

  summary$genotype <- genotype_summary
  summary$external <- genotype_summary

  result_bundle$summary <- summary
  result_bundle$external_distance <- external_distance
  result_bundle$external_map <- external_map
  result_bundle$external_fit_report <- external_fit_report
  result_bundle$external_fit_outputs <- external_fit_outputs
  result_bundle$external_calibration <- external_calibration
  result_bundle$comparison_bundle <- comparison_bundle
  result_bundle$external_cluster <- external_cluster
  result_bundle$external_cluster_data <- external_cluster_data
  result_bundle$reference_outputs <- reference_outputs
}

jsonlite::write_json(
  summary,
  path = file.path(output_dir, "summary.json"),
  auto_unbox = TRUE,
  pretty = TRUE
)

write_run_report(
  summary = summary,
  output_dir = output_dir,
  config = config
)

saveRDS(
  result_bundle,
  file = file.path(output_dir, "amrc_result_bundle.rds")
)

if (isTRUE(config$report$zip_bundle)) {
  write_output_archive(output_dir = output_dir)
}
