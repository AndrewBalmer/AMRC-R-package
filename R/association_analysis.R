amrc_binary_feature_info <- function(x, feature_name = "feature") {
  original <- x

  if (is.logical(x)) {
    values <- ifelse(is.na(x), NA_integer_, ifelse(x, 1L, 0L))
    return(list(
      values = values,
      absent_label = "FALSE",
      present_label = "TRUE"
    ))
  }

  if (is.factor(x)) {
    x <- as.character(x)
  }

  if (is.numeric(x)) {
    observed <- sort(unique(stats::na.omit(x)))
    if (all(observed %in% c(0, 1))) {
      values <- ifelse(is.na(x), NA_integer_, as.integer(x))
      return(list(
        values = values,
        absent_label = "0",
        present_label = "1"
      ))
    }
  }

  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  observed <- unique(stats::na.omit(x))

  if (length(observed) != 2L) {
    stop(
      feature_name,
      " must be binary (two non-missing states) for single-feature association scans.",
      call. = FALSE
    )
  }

  observed_lower <- tolower(observed)
  present_map <- c("1", "true", "t", "yes", "y", "present", "detected", "+")
  absent_map <- c("0", "false", "f", "no", "n", "absent", "undetected", "-")

  if (all(observed_lower %in% c(present_map, absent_map))) {
    present_label <- observed[observed_lower %in% present_map][1]
    absent_label <- observed[observed_lower %in% absent_map][1]
  } else {
    sorted <- sort(observed)
    absent_label <- sorted[[1]]
    present_label <- sorted[[2]]
  }

  values <- ifelse(
    is.na(x),
    NA_integer_,
    ifelse(x == present_label, 1L, 0L)
  )

  list(
    values = values,
    absent_label = absent_label,
    present_label = present_label,
    original = original
  )
}

amrc_extract_manova_p <- function(summary_object, predictor_name) {
  stats_table <- summary_object$stats
  if (is.null(stats_table) || !(predictor_name %in% rownames(stats_table))) {
    return(NA_real_)
  }

  stats_table[predictor_name, "Pr(>F)"]
}

amrc_build_lmm_formula <- function(response_col, fixed_effect_cols, random_effect_col) {
  fixed_string <- paste(fixed_effect_cols, collapse = " + ")
  stats::as.formula(
    paste0(response_col, " ~ ", fixed_string, " + (1 | ", random_effect_col, ")")
  )
}

amrc_numeric_response_frame <- function(data, cols, arg_name = "response_cols") {
  as.data.frame(
    Map(
      function(column, name) amrc_numeric_coercion(column, name),
      data[, cols, drop = FALSE],
      cols
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

amrc_marker_design_frame <- function(data, cols, arg_name = "marker_cols") {
  out <- lapply(cols, function(col) {
    values <- data[[col]]

    if (is.logical(values)) {
      return(ifelse(is.na(values), NA_real_, ifelse(values, 1, 0)))
    }

    if (is.numeric(values)) {
      return(as.numeric(values))
    }

    parsed <- tryCatch(
      amrc_binary_feature_info(values, feature_name = col),
      error = function(e) NULL
    )
    if (!is.null(parsed)) {
      return(as.numeric(parsed$values))
    }

    amrc_numeric_coercion(values, col)
  })

  names(out) <- cols
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

amrc_covariate_design_frame <- function(data, cols = NULL) {
  if (is.null(cols) || length(cols) == 0L) {
    return(NULL)
  }

  covariate_data <- data[, cols, drop = FALSE]
  design <- stats::model.matrix(~ . - 1, data = covariate_data)
  as.data.frame(design, stringsAsFactors = FALSE, check.names = FALSE)
}

amrc_align_kinship_matrix <- function(kinship_matrix, isolate_ids) {
  kinship_matrix <- as.matrix(kinship_matrix)

  if (nrow(kinship_matrix) != ncol(kinship_matrix)) {
    stop("kinship_matrix must be square.", call. = FALSE)
  }

  if (!is.null(rownames(kinship_matrix)) && !is.null(colnames(kinship_matrix))) {
    missing_ids <- setdiff(isolate_ids, rownames(kinship_matrix))
    if (length(missing_ids) > 0L) {
      stop(
        "kinship_matrix row names are missing isolate IDs: ",
        paste(utils::head(missing_ids, 10), collapse = ", "),
        call. = FALSE
      )
    }
    kinship_matrix <- kinship_matrix[isolate_ids, isolate_ids, drop = FALSE]
    return(kinship_matrix)
  }

  if (nrow(kinship_matrix) != length(isolate_ids)) {
    stop(
      "kinship_matrix must be square and aligned to the retained rows.",
      call. = FALSE
    )
  }

  rownames(kinship_matrix) <- isolate_ids
  colnames(kinship_matrix) <- isolate_ids
  kinship_matrix
}

amrc_build_limix_command <- function(
  script_path,
  inputs,
  stats_path,
  effects_path,
  mode = c("multivariate", "univariate", "heritability", "variance-decomposition"),
  trait_covariance = c("empirical", "identity")
) {
  mode <- match.arg(mode)
  trait_covariance <- match.arg(trait_covariance)

  args <- c(
    script_path,
    "--mode", mode,
    "--responses", inputs$response_path,
    "--out-stats", stats_path
  )

  if (mode %in% c("multivariate", "univariate")) {
    args <- c(args, "--trait-covariance", trait_covariance)
  }
  if (!is.null(inputs$marker_path)) {
    args <- c(args, "--markers", inputs$marker_path)
  }
  if (!is.null(effects_path)) {
    args <- c(args, "--out-effects", effects_path)
  }

  if (!is.null(inputs$covariate_path)) {
    args <- c(args, "--covariates", inputs$covariate_path)
  }
  if (!is.null(inputs$kinship_path)) {
    args <- c(args, "--kinship", inputs$kinship_path)
  }
  if (!is.null(inputs$component_manifest_path)) {
    args <- c(args, "--component-manifest", inputs$component_manifest_path)
  }

  args
}

amrc_prepare_limix_response_inputs <- function(
  data,
  response_cols,
  id_col = NULL,
  extra_cols = NULL,
  drop_incomplete = TRUE
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(response_cols, data, arg_name = "response_cols")
  if (!is.null(id_col)) {
    amrc_assert_single_column_name(id_col, data, arg_name = "id_col")
  }
  if (!is.null(extra_cols)) {
    amrc_assert_column_set(extra_cols, data, arg_name = "extra_cols")
  }

  keep_cols <- unique(c(id_col, response_cols, extra_cols))
  model_data <- data[, keep_cols, drop = FALSE]
  if (isTRUE(drop_incomplete)) {
    model_data <- stats::na.omit(model_data)
  }

  ids <- if (is.null(id_col)) {
    sprintf("row_%03d", seq_len(nrow(model_data)))
  } else {
    as.character(model_data[[id_col]])
  }

  response_frame <- amrc_numeric_response_frame(model_data, response_cols, arg_name = "response_cols")
  extra_frame <- if (!is.null(extra_cols)) model_data[, extra_cols, drop = FALSE] else NULL

  list(
    isolate_ids = ids,
    response_frame = response_frame,
    extra_frame = extra_frame
  )
}

amrc_binary_feature_matrix <- function(data, feature_cols) {
  out <- lapply(feature_cols, function(feature) {
    parsed <- amrc_binary_feature_info(data[[feature]], feature_name = feature)
    as.numeric(parsed$values)
  })
  names(out) <- feature_cols
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

amrc_write_labeled_matrix_csv <- function(ids, matrix_data, path) {
  out <- data.frame(isolate_id = ids, as.data.frame(matrix_data, check.names = FALSE), check.names = FALSE)
  utils::write.csv(out, path, row.names = FALSE)
  path
}

amrc_limix_script_path <- function(script = NULL) {
  if (!is.null(script)) {
    return(script)
  }

  installed <- system.file("python", "amrc_limix_mvlmm_scan.py", package = "amrcartography")
  if (nzchar(installed)) {
    return(installed)
  }

  local <- file.path("inst", "python", "amrc_limix_mvlmm_scan.py")
  if (file.exists(local)) {
    return(local)
  }

  stop("Could not locate amrc_limix_mvlmm_scan.py.", call. = FALSE)
}

#' Fit a Multivariate Linear Model
#'
#' Fits a multivariate linear model using `lm(cbind(...))` and returns both the
#' fitted model and a MANOVA-style summary. This provides a generic
#' multi-response association layer for phenotype-vs-genotype or
#' phenotype-vs-metadata analyses.
#'
#' @param data A data frame containing response and predictor columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param predictor_cols Character vector naming predictor columns.
#' @param covariate_cols Optional character vector naming additional covariates.
#' @param drop_incomplete Logical; drop incomplete rows before fitting.
#'
#' @return A list containing the fitted `lm`, the `manova` object, the Pillai
#'   MANOVA summary, the model formula, and the data used for fitting.
#' @export
amrc_fit_multivariate_linear_model <- function(
  data,
  response_cols,
  predictor_cols,
  covariate_cols = NULL,
  drop_incomplete = TRUE
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(response_cols, data, arg_name = "response_cols")
  amrc_assert_column_set(predictor_cols, data, arg_name = "predictor_cols")
  if (!is.null(covariate_cols)) {
    amrc_assert_column_set(covariate_cols, data, arg_name = "covariate_cols")
  }

  model_cols <- unique(c(response_cols, predictor_cols, covariate_cols))
  model_data <- data[, model_cols, drop = FALSE]

  if (isTRUE(drop_incomplete)) {
    model_data <- stats::na.omit(model_data)
  }

  if (nrow(model_data) < 3) {
    stop("Not enough complete rows to fit the multivariate model.", call. = FALSE)
  }

  response_string <- paste(response_cols, collapse = ", ")
  predictor_string <- paste(c(predictor_cols, covariate_cols), collapse = " + ")
  formula <- stats::as.formula(
    paste0("cbind(", response_string, ") ~ ", predictor_string)
  )

  fit <- stats::lm(formula, data = model_data)
  manova_fit <- stats::manova(formula, data = model_data)
  pillai <- summary(manova_fit, test = "Pillai")

  list(
    fit = fit,
    manova = manova_fit,
    pillai = pillai,
    formula = formula,
    model_data = model_data
  )
}

#' Fit a Linear Mixed Model
#'
#' Fits a Gaussian linear mixed model with a random intercept, using
#' [lme4::lmer()]. This is the generic mixed-effects option for users who want
#' to account for grouped structure such as lineage, ST, host, or batch while
#' testing phenotype-genotype relationships.
#'
#' @param data A data frame containing the response, fixed effects, and random
#'   effect.
#' @param response_col Name of the numeric response column.
#' @param fixed_effect_cols Character vector naming the fixed-effect columns.
#' @param random_effect_col Name of the random-intercept grouping column.
#' @param drop_incomplete Logical; drop incomplete rows before fitting.
#' @param reml Logical; fit with REML when `TRUE`.
#'
#' @return A list containing the fitted `lmerMod`, the model formula, and the
#'   data used for fitting.
#' @export
amrc_fit_linear_mixed_model <- function(
  data,
  response_col,
  fixed_effect_cols,
  random_effect_col,
  drop_incomplete = TRUE,
  reml = FALSE
) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop(
      "Package 'lme4' is required for linear mixed models.",
      call. = FALSE
    )
  }

  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_single_column_name(response_col, data, arg_name = "response_col")
  amrc_assert_column_set(fixed_effect_cols, data, arg_name = "fixed_effect_cols")
  amrc_assert_single_column_name(random_effect_col, data, arg_name = "random_effect_col")

  model_cols <- unique(c(response_col, fixed_effect_cols, random_effect_col))
  model_data <- data[, model_cols, drop = FALSE]
  if (isTRUE(drop_incomplete)) {
    model_data <- stats::na.omit(model_data)
  }

  if (nrow(model_data) < 3) {
    stop("Not enough complete rows to fit the mixed model.", call. = FALSE)
  }

  formula <- amrc_build_lmm_formula(
    response_col = response_col,
    fixed_effect_cols = fixed_effect_cols,
    random_effect_col = random_effect_col
  )

  fit <- lme4::lmer(formula, data = model_data, REML = reml)

  list(
    fit = fit,
    formula = formula,
    model_data = model_data
  )
}

#' Write Inputs for a LIMIX Multivariate Mixed-Model Scan
#'
#' Writes response, marker, optional covariate, and optional kinship matrices to
#' CSV files so they can be consumed by the generic LIMIX-based Python mvLMM
#' script bundled with the package.
#'
#' @param data A data frame containing responses, markers, and optional
#'   covariates.
#' @param response_cols Character vector naming numeric response columns.
#' @param marker_cols Character vector naming marker or feature columns. Binary
#'   logical/character markers are automatically encoded to `0/1`.
#' @param covariate_cols Optional character vector naming covariate columns.
#'   Categorical covariates are expanded to a model matrix before writing.
#' @param id_col Optional identifier column to carry into the written CSVs.
#' @param kinship_matrix Optional precomputed kinship/relatedness matrix.
#' @param out_dir Output directory for the written CSV files.
#' @param prefix File-name prefix.
#' @param drop_incomplete Logical; drop incomplete rows before writing.
#'
#' @return A list of file paths plus the retained isolate IDs.
#' @export
amrc_write_limix_mvlmm_inputs <- function(
  data,
  response_cols,
  marker_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  drop_incomplete = TRUE
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(response_cols, data, arg_name = "response_cols")
  amrc_assert_column_set(marker_cols, data, arg_name = "marker_cols")
  if (!is.null(covariate_cols)) {
    amrc_assert_column_set(covariate_cols, data, arg_name = "covariate_cols")
  }
  if (!is.null(id_col)) {
    amrc_assert_single_column_name(id_col, data, arg_name = "id_col")
  }

  keep_cols <- unique(c(id_col, response_cols, marker_cols, covariate_cols))
  model_data <- data[, keep_cols, drop = FALSE]
  if (isTRUE(drop_incomplete)) {
    model_data <- stats::na.omit(model_data)
  }

  ids <- if (is.null(id_col)) {
    sprintf("row_%03d", seq_len(nrow(model_data)))
  } else {
    as.character(model_data[[id_col]])
  }

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  response_path <- file.path(out_dir, paste0(prefix, "_responses.csv"))
  marker_path <- file.path(out_dir, paste0(prefix, "_markers.csv"))
  covariate_path <- if (!is.null(covariate_cols)) file.path(out_dir, paste0(prefix, "_covariates.csv")) else NULL
  kinship_path <- if (!is.null(kinship_matrix)) file.path(out_dir, paste0(prefix, "_kinship.csv")) else NULL

  response_frame <- amrc_numeric_response_frame(model_data, response_cols, arg_name = "response_cols")
  marker_frame <- amrc_marker_design_frame(model_data, marker_cols, arg_name = "marker_cols")

  response_data <- data.frame(isolate_id = ids, response_frame, check.names = FALSE)
  marker_data <- data.frame(isolate_id = ids, marker_frame, check.names = FALSE)
  utils::write.csv(response_data, response_path, row.names = FALSE)
  utils::write.csv(marker_data, marker_path, row.names = FALSE)

  if (!is.null(covariate_cols)) {
    covariate_frame <- amrc_covariate_design_frame(model_data, covariate_cols)
    covariate_data <- data.frame(isolate_id = ids, covariate_frame, check.names = FALSE)
    utils::write.csv(covariate_data, covariate_path, row.names = FALSE)
  }

  if (!is.null(kinship_matrix)) {
    kinship_matrix <- amrc_align_kinship_matrix(kinship_matrix, isolate_ids = ids)
    kinship_data <- data.frame(
      isolate_id = ids,
      as.data.frame(kinship_matrix, check.names = FALSE),
      check.names = FALSE
    )
    utils::write.csv(kinship_data, kinship_path, row.names = FALSE)
  }

  list(
    response_path = response_path,
    marker_path = marker_path,
    covariate_path = covariate_path,
    kinship_path = kinship_path,
    isolate_ids = ids,
    response_cols = response_cols,
    marker_cols = marker_cols,
    covariate_cols = covariate_cols
  )
}

#' Run a LIMIX Multivariate Mixed-Model Scan
#'
#' Writes generic response/marker inputs, builds the bundled Python/LIMIX mvLMM
#' command, and optionally executes it. This packages the same kind of
#' multivariate mixed-model workflow as the manuscript-era Python script, but in
#' a reusable generic form.
#'
#' @param data A data frame containing responses, markers, and optional
#'   covariates.
#' @param response_cols Character vector naming numeric response columns.
#' @param marker_cols Character vector naming marker or feature columns.
#' @param covariate_cols Optional character vector naming covariate columns.
#' @param id_col Optional isolate identifier column.
#' @param kinship_matrix Optional precomputed kinship/relatedness matrix. When
#'   omitted, the Python script recomputes kinship from the marker matrix with
#'   the tested marker removed at each iteration.
#' @param out_dir Output directory for the intermediate and result files.
#' @param prefix File-name prefix.
#' @param python Command used to invoke Python.
#' @param script Optional path to the Python mvLMM script. By default the
#'   packaged script is used.
#' @param trait_covariance Trait-covariance model used in the multivariate
#'   LIMIX scan. `"empirical"` uses the empirical covariance of the response
#'   matrix, whereas `"identity"` uses an identity matrix.
#' @param execute Logical; run the Python command when `TRUE`, otherwise return
#'   the prepared command and file paths without executing it.
#' @param drop_incomplete Logical; drop incomplete rows before writing inputs.
#'
#' @return A list with input paths, output paths, and the constructed command.
#'
#' @details This is the optional advanced route for users who want the same
#'   general style of multivariate mixed-model scan used in the manuscript-era
#'   Python analysis, but on generic package inputs. It requires a working
#'   Python environment with `limix`, `numpy`, and `pandas`.
#' @export
amrc_run_limix_mvlmm <- function(
  data,
  response_cols,
  marker_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  python = "python3",
  script = NULL,
  trait_covariance = c("empirical", "identity"),
  execute = FALSE,
  drop_incomplete = TRUE
) {
  trait_covariance <- match.arg(trait_covariance)

  inputs <- amrc_write_limix_mvlmm_inputs(
    data = data,
    response_cols = response_cols,
    marker_cols = marker_cols,
    covariate_cols = covariate_cols,
    id_col = id_col,
    kinship_matrix = kinship_matrix,
    out_dir = out_dir,
    prefix = prefix,
    drop_incomplete = drop_incomplete
  )

  script_path <- amrc_limix_script_path(script = script)
  stats_path <- file.path(out_dir, paste0(prefix, "_stats.csv"))
  effects_path <- file.path(out_dir, paste0(prefix, "_effects.csv"))

  args <- amrc_build_limix_command(
    script_path = script_path,
    inputs = inputs,
    stats_path = stats_path,
    effects_path = effects_path,
    mode = "multivariate",
    trait_covariance = trait_covariance
  )

  exit_status <- NULL
  if (isTRUE(execute)) {
    exit_status <- system2(python, args = args)
  }

  list(
    inputs = inputs,
    stats_path = stats_path,
    effects_path = effects_path,
    python = python,
    script = script_path,
    args = args,
    exit_status = exit_status
  )
}

#' Run a LIMIX Univariate Mixed-Model Scan
#'
#' Writes generic response/marker inputs, builds the bundled Python/LIMIX
#' univariate LMM command, and optionally executes it. This mirrors the
#' manuscript-era single-trait mixed-model scans in a reusable generic form.
#'
#' @inheritParams amrc_run_limix_mvlmm
#'
#' @return A list with input paths, output paths, and the constructed command.
#'
#' @details This is the optional advanced route for users who want a
#'   LIMIX-backed univariate mixed-model scan across one or more phenotype
#'   responses. It requires a working Python environment with `limix`, `numpy`,
#'   and `pandas`.
#' @export
amrc_run_limix_lmm_scan <- function(
  data,
  response_cols,
  marker_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
) {
  inputs <- amrc_write_limix_mvlmm_inputs(
    data = data,
    response_cols = response_cols,
    marker_cols = marker_cols,
    covariate_cols = covariate_cols,
    id_col = id_col,
    kinship_matrix = kinship_matrix,
    out_dir = out_dir,
    prefix = prefix,
    drop_incomplete = drop_incomplete
  )

  script_path <- amrc_limix_script_path(script = script)
  stats_path <- file.path(out_dir, paste0(prefix, "_stats.csv"))
  effects_path <- file.path(out_dir, paste0(prefix, "_effects.csv"))

  args <- amrc_build_limix_command(
    script_path = script_path,
    inputs = inputs,
    stats_path = stats_path,
    effects_path = effects_path,
    mode = "univariate",
    trait_covariance = "identity"
  )

  exit_status <- NULL
  if (isTRUE(execute)) {
    exit_status <- system2(python, args = args)
  }

  list(
    inputs = inputs,
    stats_path = stats_path,
    effects_path = effects_path,
    python = python,
    script = script_path,
    args = args,
    exit_status = exit_status
  )
}

#' Write Inputs for a LIMIX Heritability Analysis
#'
#' Writes generic response and kinship inputs for a LIMIX heritability run.
#'
#' @param data A data frame containing numeric response columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param kinship_matrix Square kinship/relatedness matrix aligned to the
#'   retained isolates.
#' @param id_col Optional isolate identifier column.
#' @param out_dir Output directory for the written CSV files.
#' @param prefix File-name prefix.
#' @param drop_incomplete Logical; drop incomplete rows before writing inputs.
#'
#' @return A list with written input paths and retained isolate IDs.
#' @export
amrc_write_limix_heritability_inputs <- function(
  data,
  response_cols,
  kinship_matrix,
  id_col = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  drop_incomplete = TRUE
) {
  prepared <- amrc_prepare_limix_response_inputs(
    data = data,
    response_cols = response_cols,
    id_col = id_col,
    drop_incomplete = drop_incomplete
  )

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  response_path <- file.path(out_dir, paste0(prefix, "_responses.csv"))
  kinship_path <- file.path(out_dir, paste0(prefix, "_kinship.csv"))

  kinship_matrix <- amrc_align_kinship_matrix(
    kinship_matrix,
    isolate_ids = prepared$isolate_ids
  )

  amrc_write_labeled_matrix_csv(prepared$isolate_ids, prepared$response_frame, response_path)
  amrc_write_labeled_matrix_csv(prepared$isolate_ids, kinship_matrix, kinship_path)

  list(
    response_path = response_path,
    kinship_path = kinship_path,
    isolate_ids = prepared$isolate_ids,
    response_cols = response_cols
  )
}

#' Run a LIMIX Heritability Analysis
#'
#' Builds and optionally executes a generic LIMIX heritability analysis for one
#' or more numeric responses against a supplied kinship matrix.
#'
#' @param data A data frame containing numeric response columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param kinship_matrix Square kinship/relatedness matrix aligned to the
#'   retained isolates.
#' @param id_col Optional isolate identifier column.
#' @param out_dir Output directory for the intermediate and result files.
#' @param prefix File-name prefix.
#' @param python Command used to invoke Python.
#' @param script Optional path to the Python LIMIX helper script. By default
#'   the packaged script is used.
#' @param execute Logical; run the Python command when `TRUE`, otherwise return
#'   the prepared command and file paths without executing it.
#' @param drop_incomplete Logical; drop incomplete rows before writing inputs.
#'
#' @return A list with input paths, output paths, and the constructed command.
#' @export
amrc_run_limix_heritability <- function(
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
) {
  inputs <- amrc_write_limix_heritability_inputs(
    data = data,
    response_cols = response_cols,
    kinship_matrix = kinship_matrix,
    id_col = id_col,
    out_dir = out_dir,
    prefix = prefix,
    drop_incomplete = drop_incomplete
  )

  script_path <- amrc_limix_script_path(script = script)
  stats_path <- file.path(out_dir, paste0(prefix, "_heritability.csv"))

  args <- amrc_build_limix_command(
    script_path = script_path,
    inputs = c(inputs, list(marker_path = NULL, covariate_path = NULL, component_manifest_path = NULL)),
    stats_path = stats_path,
    effects_path = NULL,
    mode = "heritability",
    trait_covariance = "identity"
  )

  exit_status <- NULL
  if (isTRUE(execute)) {
    exit_status <- system2(python, args = args)
  }

  list(
    inputs = inputs,
    stats_path = stats_path,
    python = python,
    script = script_path,
    args = args,
    exit_status = exit_status
  )
}

#' Write Inputs for a LIMIX Variance-Decomposition Analysis
#'
#' Writes generic response inputs and a manifest of named kinship components for
#' a LIMIX variance-decomposition run.
#'
#' @param data A data frame containing numeric response columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param kinship_components Named list of square kinship/relatedness matrices.
#' @param id_col Optional isolate identifier column.
#' @param out_dir Output directory for the written CSV files.
#' @param prefix File-name prefix.
#' @param drop_incomplete Logical; drop incomplete rows before writing inputs.
#'
#' @return A list with written input paths, manifest path, and retained isolate
#'   IDs.
#' @export
amrc_write_limix_variance_decomposition_inputs <- function(
  data,
  response_cols,
  kinship_components,
  id_col = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix",
  drop_incomplete = TRUE
) {
  if (!is.list(kinship_components) || length(kinship_components) == 0L) {
    stop("kinship_components must be a non-empty named list of matrices.", call. = FALSE)
  }
  if (is.null(names(kinship_components)) || any(names(kinship_components) == "")) {
    stop("kinship_components must be a named list of matrices.", call. = FALSE)
  }

  prepared <- amrc_prepare_limix_response_inputs(
    data = data,
    response_cols = response_cols,
    id_col = id_col,
    drop_incomplete = drop_incomplete
  )

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  response_path <- file.path(out_dir, paste0(prefix, "_responses.csv"))
  manifest_path <- file.path(out_dir, paste0(prefix, "_component_manifest.csv"))

  amrc_write_labeled_matrix_csv(prepared$isolate_ids, prepared$response_frame, response_path)

  component_rows <- lapply(seq_along(kinship_components), function(i) {
    label <- names(kinship_components)[[i]]
    path <- file.path(out_dir, paste0(prefix, "_component_", i, ".csv"))
    component_matrix <- amrc_align_kinship_matrix(
      kinship_components[[i]],
      isolate_ids = prepared$isolate_ids
    )
    amrc_write_labeled_matrix_csv(prepared$isolate_ids, component_matrix, path)
    data.frame(label = label, path = path, stringsAsFactors = FALSE, check.names = FALSE)
  })

  manifest <- do.call(rbind, component_rows)
  utils::write.csv(manifest, manifest_path, row.names = FALSE)

  list(
    response_path = response_path,
    component_manifest_path = manifest_path,
    isolate_ids = prepared$isolate_ids,
    response_cols = response_cols,
    component_labels = names(kinship_components)
  )
}

#' Run a LIMIX Variance-Decomposition Analysis
#'
#' Builds and optionally executes a generic LIMIX variance-decomposition
#' analysis for one or more numeric responses against multiple kinship
#' components.
#'
#' @param data A data frame containing numeric response columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param kinship_components Named list of square kinship/relatedness matrices.
#' @param id_col Optional isolate identifier column.
#' @param out_dir Output directory for the intermediate and result files.
#' @param prefix File-name prefix.
#' @param python Command used to invoke Python.
#' @param script Optional path to the Python LIMIX helper script. By default
#'   the packaged script is used.
#' @param execute Logical; run the Python command when `TRUE`, otherwise return
#'   the prepared command and file paths without executing it.
#' @param drop_incomplete Logical; drop incomplete rows before writing inputs.
#'
#' @return A list with input paths, output paths, and the constructed command.
#' @export
amrc_run_limix_variance_decomposition <- function(
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
) {
  inputs <- amrc_write_limix_variance_decomposition_inputs(
    data = data,
    response_cols = response_cols,
    kinship_components = kinship_components,
    id_col = id_col,
    out_dir = out_dir,
    prefix = prefix,
    drop_incomplete = drop_incomplete
  )

  script_path <- amrc_limix_script_path(script = script)
  stats_path <- file.path(out_dir, paste0(prefix, "_variance_decomposition.csv"))

  args <- amrc_build_limix_command(
    script_path = script_path,
    inputs = c(inputs, list(marker_path = NULL, covariate_path = NULL, kinship_path = NULL)),
    stats_path = stats_path,
    effects_path = NULL,
    mode = "variance-decomposition",
    trait_covariance = "identity"
  )

  exit_status <- NULL
  if (isTRUE(execute)) {
    exit_status <- system2(python, args = args)
  }

  list(
    inputs = inputs,
    stats_path = stats_path,
    python = python,
    script = script_path,
    args = args,
    exit_status = exit_status
  )
}

#' Generate Epistatic Interaction Markers
#'
#' Builds pairwise interaction markers from binary feature columns, returning a
#' generic isolate-by-interaction design matrix that can be used in the package
#' association or LIMIX scan helpers.
#'
#' @param data A data frame containing binary feature columns.
#' @param feature_cols Character vector naming the binary feature columns.
#' @param id_col Optional isolate identifier column to carry through.
#' @param separator String used when naming interaction columns.
#' @param min_present Minimum number of present observations required for an
#'   interaction column to be retained.
#'
#' @return A data frame containing the optional identifier column and one column
#'   per retained interaction marker.
#' @export
amrc_generate_epistatic_markers <- function(
  data,
  feature_cols,
  id_col = NULL,
  separator = ":",
  min_present = 1
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(feature_cols, data, arg_name = "feature_cols")
  if (!is.null(id_col)) {
    amrc_assert_single_column_name(id_col, data, arg_name = "id_col")
  }

  if (length(feature_cols) < 2L) {
    stop("At least two feature columns are required to generate epistatic markers.", call. = FALSE)
  }

  feature_matrix <- amrc_binary_feature_matrix(data, feature_cols)
  combos <- utils::combn(feature_cols, 2, simplify = FALSE)

  interaction_list <- lapply(combos, function(pair) {
    values <- feature_matrix[[pair[[1]]]] * feature_matrix[[pair[[2]]]]
    if (sum(values == 1, na.rm = TRUE) < min_present) {
      return(NULL)
    }
    out <- data.frame(values, stringsAsFactors = FALSE, check.names = FALSE)
    names(out) <- paste(pair, collapse = separator)
    out
  })

  interaction_list <- Filter(Negate(is.null), interaction_list)
  if (length(interaction_list) == 0L) {
    out <- if (!is.null(id_col)) data.frame(data[[id_col]], check.names = FALSE) else data.frame()
    if (!is.null(id_col)) names(out) <- id_col
    return(out)
  }

  interactions <- do.call(cbind, interaction_list)
  out <- if (!is.null(id_col)) data.frame(data[[id_col]], interactions, check.names = FALSE) else interactions
  if (!is.null(id_col)) names(out)[1] <- id_col
  out
}

#' Run a LIMIX Epistatic Scan
#'
#' Generates pairwise interaction markers from binary features and then stages
#' or runs either a multivariate or univariate LIMIX scan on those interaction
#' markers.
#'
#' @param data A data frame containing responses and binary feature columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param feature_cols Character vector naming binary feature columns to combine
#'   into pairwise interactions.
#' @param covariate_cols Optional covariate columns to include.
#' @param id_col Optional isolate identifier column.
#' @param kinship_matrix Optional precomputed kinship/relatedness matrix.
#' @param mode Either `"multivariate"` or `"univariate"`.
#' @param include_main_effects Logical; append the original binary feature
#'   columns to `covariate_cols` before running the scan.
#' @param min_present Minimum present count required for an interaction to be
#'   retained.
#' @param out_dir Output directory for staged inputs and outputs.
#' @param prefix File-name prefix.
#' @param python Command used to invoke Python.
#' @param script Optional path to the Python LIMIX helper script.
#' @param execute Logical; run the Python command when `TRUE`.
#' @param drop_incomplete Logical; drop incomplete rows before writing inputs.
#'
#' @return A list containing the generated epistatic marker table plus the
#'   prepared or executed LIMIX scan metadata.
#' @export
amrc_run_limix_epistatic_scan <- function(
  data,
  response_cols,
  feature_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  mode = c("multivariate", "univariate"),
  include_main_effects = TRUE,
  min_present = 1,
  out_dir = tempdir(),
  prefix = "amrc_limix_epi",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
) {
  mode <- match.arg(mode)
  epi_markers <- amrc_generate_epistatic_markers(
    data = data,
    feature_cols = feature_cols,
    id_col = id_col,
    min_present = min_present
  )

  epi_cols <- setdiff(names(epi_markers), id_col)
  if (length(epi_cols) == 0L) {
    stop("No epistatic interaction markers passed the min_present filter.", call. = FALSE)
  }

  analysis_data <- data
  analysis_data[, epi_cols] <- epi_markers[, epi_cols, drop = FALSE]
  analysis_covariates <- covariate_cols
  if (isTRUE(include_main_effects)) {
    analysis_covariates <- unique(c(covariate_cols, feature_cols))
  }

  run <- if (identical(mode, "multivariate")) {
    amrc_run_limix_mvlmm(
      data = analysis_data,
      response_cols = response_cols,
      marker_cols = epi_cols,
      covariate_cols = analysis_covariates,
      id_col = id_col,
      kinship_matrix = kinship_matrix,
      out_dir = out_dir,
      prefix = prefix,
      python = python,
      script = script,
      execute = execute,
      drop_incomplete = drop_incomplete
    )
  } else {
    amrc_run_limix_lmm_scan(
      data = analysis_data,
      response_cols = response_cols,
      marker_cols = epi_cols,
      covariate_cols = analysis_covariates,
      id_col = id_col,
      kinship_matrix = kinship_matrix,
      out_dir = out_dir,
      prefix = prefix,
      python = python,
      script = script,
      execute = execute,
      drop_incomplete = drop_incomplete
    )
  }

  run$epistatic_markers <- epi_markers
  run
}

#' Run a Permutation LIMIX Scan
#'
#' Repeats a LIMIX scan after jointly permuting the response rows, preserving
#' the correlation structure among multiple responses while breaking the link to
#' the marker matrix.
#'
#' @param data A data frame containing response, marker, and optional covariate
#'   columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param marker_cols Character vector naming marker columns.
#' @param covariate_cols Optional covariate columns.
#' @param id_col Optional isolate identifier column.
#' @param kinship_matrix Optional precomputed kinship/relatedness matrix.
#' @param n_permutations Number of phenotype permutations to stage or run.
#' @param mode Either `"multivariate"` or `"univariate"`.
#' @param seed Optional random seed.
#' @param out_dir Output directory for staged inputs and outputs.
#' @param prefix File-name prefix.
#' @param python Command used to invoke Python.
#' @param script Optional path to the Python LIMIX helper script.
#' @param execute Logical; run each Python command when `TRUE`.
#' @param drop_incomplete Logical; drop incomplete rows before writing inputs.
#'
#' @return A list with one scan entry per permutation.
#' @export
amrc_run_limix_permutation_scan <- function(
  data,
  response_cols,
  marker_cols,
  covariate_cols = NULL,
  id_col = NULL,
  kinship_matrix = NULL,
  n_permutations = 100,
  mode = c("multivariate", "univariate"),
  marker_sample_size = NULL,
  marker_sample_replace = FALSE,
  seed = NULL,
  out_dir = tempdir(),
  prefix = "amrc_limix_perm",
  python = "python3",
  script = NULL,
  execute = FALSE,
  drop_incomplete = TRUE
) {
  mode <- match.arg(mode)
  if (!is.null(seed)) {
    set.seed(seed)
  }

  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(response_cols, data, arg_name = "response_cols")
  amrc_assert_column_set(marker_cols, data, arg_name = "marker_cols")
  if (!is.null(covariate_cols)) {
    amrc_assert_column_set(covariate_cols, data, arg_name = "covariate_cols")
  }
  if (!is.null(id_col)) {
    amrc_assert_single_column_name(id_col, data, arg_name = "id_col")
  }
  if (!is.null(marker_sample_size)) {
    if (marker_sample_size < 1L) {
      stop("marker_sample_size must be at least 1 when provided.", call. = FALSE)
    }
    if (!isTRUE(marker_sample_replace) && marker_sample_size > length(marker_cols)) {
      stop("marker_sample_size cannot exceed the number of marker_cols when sampling without replacement.", call. = FALSE)
    }
  }

  scans <- vector("list", n_permutations)
  n <- nrow(data)

  for (i in seq_len(n_permutations)) {
    permuted <- data
    index <- sample.int(n, size = n, replace = FALSE)
    permuted[, response_cols] <- data[index, response_cols, drop = FALSE]
    marker_cols_used <- if (is.null(marker_sample_size)) {
      marker_cols
    } else {
      sample(marker_cols, size = marker_sample_size, replace = marker_sample_replace)
    }

    run <- if (identical(mode, "multivariate")) {
      amrc_run_limix_mvlmm(
        data = permuted,
        response_cols = response_cols,
        marker_cols = marker_cols_used,
        covariate_cols = covariate_cols,
        id_col = id_col,
        kinship_matrix = kinship_matrix,
        out_dir = out_dir,
        prefix = paste0(prefix, "_perm_", i),
        python = python,
        script = script,
        execute = execute,
        drop_incomplete = drop_incomplete
      )
    } else {
      amrc_run_limix_lmm_scan(
        data = permuted,
        response_cols = response_cols,
        marker_cols = marker_cols_used,
        covariate_cols = covariate_cols,
        id_col = id_col,
        kinship_matrix = kinship_matrix,
        out_dir = out_dir,
        prefix = paste0(prefix, "_perm_", i),
        python = python,
        script = script,
        execute = execute,
        drop_incomplete = drop_incomplete
      )
    }

    run$permutation <- i
    run$permuted_index <- index
    run$marker_cols_used <- marker_cols_used
    scans[[i]] <- run
  }

  scans
}

amrc_read_limix_table <- function(path, table_name = "table") {
  if (is.null(path) || !file.exists(path)) {
    stop(table_name, " file does not exist: ", path, call. = FALSE)
  }
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

#' Read LIMIX Scan Results
#'
#' Reads staged or executed LIMIX result files back into R.
#'
#' @param scan_result A scan result list returned by one of the LIMIX helper
#'   functions.
#' @param include_effects Logical; include the effects table when available.
#'
#' @return A list with `stats` and, when available, `effects`.
#' @export
amrc_read_limix_scan_results <- function(scan_result, include_effects = TRUE) {
  if (!is.list(scan_result) || is.null(scan_result$stats_path)) {
    stop("scan_result must be a LIMIX helper result containing stats_path.", call. = FALSE)
  }

  out <- list(
    stats = amrc_read_limix_table(scan_result$stats_path, table_name = "stats")
  )

  if (isTRUE(include_effects) && !is.null(scan_result$effects_path) && file.exists(scan_result$effects_path)) {
    out$effects <- amrc_read_limix_table(scan_result$effects_path, table_name = "effects")
  }

  out
}

#' Summarise an Epistatic LIMIX Scan
#'
#' Reads the result of an epistatic LIMIX scan and returns a cleaned summary
#' table with interaction partners split into separate columns.
#'
#' @param scan_result A result list returned by [amrc_run_limix_epistatic_scan()]
#'   or another LIMIX scan helper with epistatic marker names.
#' @param p_col Name of the p-value column in the stats table.
#' @param separator Separator used in epistatic marker names.
#' @param p_adjust_method Multiple-testing correction method passed to
#'   [stats::p.adjust()].
#'
#' @return A list with the raw result tables plus a parsed `summary` table.
#' @export
amrc_summarise_limix_epistatic_scan <- function(
  scan_result,
  p_col = "pv20",
  separator = ":",
  p_adjust_method = "BH"
) {
  results <- amrc_read_limix_scan_results(scan_result, include_effects = TRUE)
  stats <- results$stats

  marker_col <- if ("marker" %in% names(stats)) "marker" else if ("test" %in% names(stats)) "test" else NULL
  if (is.null(marker_col)) {
    stop("Could not find a marker/test column in the LIMIX stats table.", call. = FALSE)
  }
  if (!(p_col %in% names(stats))) {
    stop("p_col was not found in the LIMIX stats table.", call. = FALSE)
  }

  parts <- strsplit(as.character(stats[[marker_col]]), separator, fixed = TRUE)
  feature_1 <- vapply(parts, function(x) if (length(x) >= 1L) x[[1]] else NA_character_, character(1))
  feature_2 <- vapply(parts, function(x) if (length(x) >= 2L) x[[2]] else NA_character_, character(1))

  summary <- stats
  summary$feature_1 <- feature_1
  summary$feature_2 <- feature_2
  summary$p_value <- suppressWarnings(as.numeric(summary[[p_col]]))
  summary$p_adjusted <- stats::p.adjust(summary$p_value, method = p_adjust_method)
  summary <- summary[order(summary$p_value, na.last = TRUE), , drop = FALSE]
  rownames(summary) <- NULL

  list(
    stats = stats,
    effects = results$effects,
    summary = summary
  )
}

#' Summarise a Permutation LIMIX Scan
#'
#' Reads a list of permutation LIMIX scan runs and returns combined summary
#' tables, including the minimum p-value observed within each permutation.
#'
#' @param scan_results A list returned by [amrc_run_limix_permutation_scan()].
#' @param p_col Name of the p-value column in each stats table.
#'
#' @return A list with combined `stats`, combined `effects` when available, and
#'   a `permutation_summary` table.
#' @export
amrc_summarise_limix_permutation_scan <- function(
  scan_results,
  p_col = "pv20"
) {
  if (!is.list(scan_results) || length(scan_results) == 0L) {
    stop("scan_results must be a non-empty list of LIMIX scan results.", call. = FALSE)
  }

  stats_parts <- list()
  effects_parts <- list()
  summary_rows <- list()

  for (i in seq_along(scan_results)) {
    run <- scan_results[[i]]
    results <- amrc_read_limix_scan_results(run, include_effects = TRUE)
    stats <- results$stats
    if (!(p_col %in% names(stats))) {
      stop("p_col was not found in one of the LIMIX stats tables.", call. = FALSE)
    }

    permutation_id <- if (!is.null(run$permutation)) run$permutation else i
    stats$permutation <- permutation_id
    stats_parts[[i]] <- stats

    if (!is.null(results$effects)) {
      effects <- results$effects
      effects$permutation <- permutation_id
      effects_parts[[i]] <- effects
    }

    p_values <- suppressWarnings(as.numeric(stats[[p_col]]))
    summary_rows[[i]] <- data.frame(
      permutation = permutation_id,
      n_tests = nrow(stats),
      min_p_value = min(p_values, na.rm = TRUE),
      median_p_value = stats::median(p_values, na.rm = TRUE),
      marker_sample_size = if (!is.null(run$marker_cols_used)) length(run$marker_cols_used) else nrow(stats),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  combined_stats <- do.call(rbind, stats_parts)
  combined_effects <- if (length(effects_parts) > 0L) do.call(rbind, effects_parts) else NULL
  permutation_summary <- do.call(rbind, summary_rows)

  list(
    stats = combined_stats,
    effects = combined_effects,
    permutation_summary = permutation_summary,
    overall = data.frame(
      n_permutations = nrow(permutation_summary),
      min_of_min_p = min(permutation_summary$min_p_value, na.rm = TRUE),
      median_min_p = stats::median(permutation_summary$min_p_value, na.rm = TRUE),
      mean_min_p = mean(permutation_summary$min_p_value, na.rm = TRUE),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
}

#' Create a Train/Test Split
#'
#' Creates a reproducible logical train/test split for generic prediction
#' workflows such as kinship-BLUP analyses.
#'
#' @param n Number of observations.
#' @param proportion Proportion assigned to the training set.
#' @param seed Optional random seed.
#'
#' @return A list with logical `train` and `test` vectors.
#' @export
amrc_make_train_test_split <- function(n, proportion = 0.8, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  n_train <- floor(n * proportion)
  selected <- c(rep(TRUE, n_train), rep(FALSE, n - n_train))
  selected <- sample(selected, length(selected), replace = FALSE)

  list(
    train = selected,
    test = !selected
  )
}

#' Create Cross-Validation Fold Assignments
#'
#' Creates reproducible fold assignments for generic prediction workflows.
#'
#' @param n Number of observations.
#' @param n_folds Number of folds.
#' @param seed Optional random seed.
#'
#' @return An integer vector of fold assignments.
#' @export
amrc_make_cv_folds <- function(n, n_folds = 5, seed = NULL) {
  if (!is.null(seed)) {
    set.seed(seed)
  }

  sample(rep(seq_len(n_folds), length.out = n), n, replace = FALSE)
}

#' Fit a Kinship-BLUP Predictor
#'
#' Fits a simple kinship-based BLUP/ridge predictor and returns predictions for
#' a test set defined by logical train/test vectors.
#'
#' @param response Numeric response vector.
#' @param kinship_matrix Square kinship/relatedness matrix.
#' @param train Optional logical vector indicating training rows.
#' @param test Optional logical vector indicating test rows.
#' @param lambda Ridge/noise penalty added to the training kernel diagonal.
#' @param center Logical; center the training response before prediction.
#' @param return_sd Logical; return predictive standard deviations based on the
#'   Gaussian-process posterior covariance.
#'
#' @return A list with predictions, the train/test masks, and optionally
#'   predictive standard deviations.
#' @export
amrc_fit_kinship_blup <- function(
  response,
  kinship_matrix,
  train = NULL,
  test = NULL,
  lambda = 1,
  center = TRUE,
  return_sd = FALSE
) {
  y <- as.numeric(response)
  k <- as.matrix(kinship_matrix)

  if (length(y) != nrow(k) || nrow(k) != ncol(k)) {
    stop("response and kinship_matrix must have compatible dimensions.", call. = FALSE)
  }

  if (is.null(train) && is.null(test)) {
    train <- rep(TRUE, length(y))
    test <- rep(TRUE, length(y))
  } else if (is.null(train)) {
    train <- !test
  } else if (is.null(test)) {
    test <- !train
  }

  train <- as.logical(train)
  test <- as.logical(test)
  if (sum(train) < 2L || sum(test) < 1L) {
    stop("Need at least two training rows and one test row.", call. = FALSE)
  }

  y_train <- y[train]
  mu <- if (isTRUE(center)) mean(y_train, na.rm = TRUE) else 0
  y_centered <- y_train - mu

  k_tt <- k[train, train, drop = FALSE]
  k_vt <- k[test, train, drop = FALSE]
  penalty <- diag(lambda, nrow = nrow(k_tt), ncol = ncol(k_tt))
  alpha <- solve(k_tt + penalty, y_centered)
  predictions <- as.numeric(mu + k_vt %*% alpha)

  out <- list(
    predictions = predictions,
    train = train,
    test = test,
    lambda = lambda,
    mean = mu
  )

  if (isTRUE(return_sd)) {
    k_vv <- k[test, test, drop = FALSE]
    predictive_cov <- k_vv - k_vt %*% solve(k_tt + penalty, t(k_vt))
    predictive_var <- pmax(diag(predictive_cov), 0)
    out$predictive_sd <- sqrt(predictive_var)
  }

  out
}

#' Cross-Validate Kinship-BLUP Prediction
#'
#' Runs a simple cross-validated kinship-BLUP workflow and summarises prediction
#' accuracy across folds.
#'
#' @param response Numeric response vector.
#' @param kinship_matrix Square kinship/relatedness matrix.
#' @param n_folds Number of cross-validation folds.
#' @param seed Optional random seed.
#' @param lambda Ridge/noise penalty added to the training kernel diagonal.
#'
#' @return A list with fold-level metrics and combined predictions.
#' @export
amrc_cross_validate_kinship_blup <- function(
  response,
  kinship_matrix,
  n_folds = 5,
  seed = NULL,
  lambda = 1
) {
  y <- as.numeric(response)
  folds <- amrc_make_cv_folds(length(y), n_folds = n_folds, seed = seed)
  fold_rows <- vector("list", n_folds)
  prediction_rows <- vector("list", n_folds)

  for (fold in seq_len(n_folds)) {
    test <- folds == fold
    train <- !test
    fit <- amrc_fit_kinship_blup(
      response = y,
      kinship_matrix = kinship_matrix,
      train = train,
      test = test,
      lambda = lambda,
      return_sd = FALSE
    )

    observed <- y[test]
    predicted <- fit$predictions
    rmse <- sqrt(mean((observed - predicted)^2, na.rm = TRUE))
    correlation <- if (length(observed) < 2L) NA_real_ else stats::cor(observed, predicted)

    fold_rows[[fold]] <- data.frame(
      fold = fold,
      n_test = sum(test),
      rmse = rmse,
      correlation = correlation,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    prediction_rows[[fold]] <- data.frame(
      index = which(test),
      fold = fold,
      observed = observed,
      predicted = predicted,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  fold_summary <- do.call(rbind, fold_rows)
  predictions <- do.call(rbind, prediction_rows)

  list(
    fold_summary = fold_summary,
    predictions = predictions,
    overall = data.frame(
      mean_rmse = mean(fold_summary$rmse, na.rm = TRUE),
      mean_correlation = mean(fold_summary$correlation, na.rm = TRUE),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
}

#' Scan Binary Feature Associations Across Multiple Responses
#'
#' Runs a generic single-feature association scan for binary features such as
#' gene presence/absence markers or single amino-acid substitutions against one
#' or more numeric phenotype or map-response variables.
#'
#' For each feature the function reports:
#'
#' - absent/present sample counts
#' - a multivariate linear-model p-value across all responses
#' - per-response mean and median shifts
#' - per-response linear-model coefficients and adjusted p-values
#'
#' @param data A data frame containing response and feature columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param feature_cols Character vector naming binary feature columns.
#' @param covariate_cols Optional character vector naming additional covariates.
#' @param min_group_size Minimum number of absent and present observations
#'   required for a feature to be tested.
#' @param p_adjust_method Multiple-testing correction method passed to
#'   [stats::p.adjust()].
#'
#' @return A list with `feature_summary` and `response_summary` tables.
#' @export
amrc_scan_single_feature_associations <- function(
  data,
  response_cols,
  feature_cols,
  covariate_cols = NULL,
  min_group_size = 3,
  p_adjust_method = "BH"
) {
  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(response_cols, data, arg_name = "response_cols")
  amrc_assert_column_set(feature_cols, data, arg_name = "feature_cols")
  if (!is.null(covariate_cols)) {
    amrc_assert_column_set(covariate_cols, data, arg_name = "covariate_cols")
  }

  feature_rows <- vector("list", length(feature_cols))
  response_rows <- list()

  for (i in seq_along(feature_cols)) {
    feature <- feature_cols[[i]]
    parsed <- amrc_binary_feature_info(data[[feature]], feature_name = feature)
    model_data <- data.frame(
      data[, unique(c(response_cols, covariate_cols)), drop = FALSE],
      .amrc_feature = parsed$values,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    model_data <- stats::na.omit(model_data)

    absent_n <- sum(model_data$.amrc_feature == 0L)
    present_n <- sum(model_data$.amrc_feature == 1L)

    status <- "ok"
    mv_p <- NA_real_
    if (absent_n < min_group_size || present_n < min_group_size) {
      status <- "insufficient_group_size"
    } else {
      mv_fit <- amrc_fit_multivariate_linear_model(
        data = model_data,
        response_cols = response_cols,
        predictor_cols = ".amrc_feature",
        covariate_cols = covariate_cols
      )
      mv_p <- amrc_extract_manova_p(mv_fit$pillai, ".amrc_feature")
    }

    feature_rows[[i]] <- data.frame(
      feature = feature,
      absent_label = parsed$absent_label,
      present_label = parsed$present_label,
      n_absent = absent_n,
      n_present = present_n,
      multivariate_p = mv_p,
      status = status,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )

    for (response in response_cols) {
      absent_values <- model_data[model_data$.amrc_feature == 0L, response]
      present_values <- model_data[model_data$.amrc_feature == 1L, response]

      coefficient <- NA_real_
      p_value <- NA_real_
      if (identical(status, "ok")) {
        formula <- stats::as.formula(
          paste(response, "~ .amrc_feature", if (!is.null(covariate_cols)) paste("+", paste(covariate_cols, collapse = " + ")) else "")
        )
        fit <- stats::lm(formula, data = model_data)
        coefficient <- stats::coef(fit)[[".amrc_feature"]]
        p_value <- summary(fit)$coefficients[".amrc_feature", "Pr(>|t|)"]
      }

      response_rows[[length(response_rows) + 1L]] <- data.frame(
        feature = feature,
        response = response,
        absent_mean = if (length(absent_values) == 0) NA_real_ else mean(absent_values, na.rm = TRUE),
        present_mean = if (length(present_values) == 0) NA_real_ else mean(present_values, na.rm = TRUE),
        mean_difference = if (length(absent_values) == 0 || length(present_values) == 0) NA_real_ else mean(present_values, na.rm = TRUE) - mean(absent_values, na.rm = TRUE),
        absent_median = if (length(absent_values) == 0) NA_real_ else stats::median(absent_values, na.rm = TRUE),
        present_median = if (length(present_values) == 0) NA_real_ else stats::median(present_values, na.rm = TRUE),
        median_difference = if (length(absent_values) == 0 || length(present_values) == 0) NA_real_ else stats::median(present_values, na.rm = TRUE) - stats::median(absent_values, na.rm = TRUE),
        coefficient = coefficient,
        p_value = p_value,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    }
  }

  feature_summary <- do.call(rbind, feature_rows)
  response_summary <- do.call(rbind, response_rows)

  feature_summary$multivariate_p_adjusted <- stats::p.adjust(
    feature_summary$multivariate_p,
    method = p_adjust_method
  )
  response_summary$p_adjusted <- stats::p.adjust(
    response_summary$p_value,
    method = p_adjust_method
  )

  list(
    feature_summary = feature_summary,
    response_summary = response_summary
  )
}

#' Scan Binary Feature Associations with Linear Mixed Models
#'
#' Fits one mixed model per feature-response pair, using a random intercept to
#' absorb grouped structure such as lineage or batch. This is the generic LMM
#' option for single-gene or single-substitution scans.
#'
#' @param data A data frame containing response, feature, and random-effect
#'   columns.
#' @param response_cols Character vector naming numeric response columns.
#' @param feature_cols Character vector naming binary feature columns.
#' @param random_effect_col Grouping column used for the random intercept.
#' @param covariate_cols Optional fixed-effect covariates.
#' @param min_group_size Minimum absent/present size required for a feature to
#'   be tested.
#' @param p_adjust_method Multiple-testing correction method passed to
#'   [stats::p.adjust()].
#'
#' @return A list with `feature_summary` and `response_summary` tables.
#' @export
amrc_scan_single_feature_mixed_models <- function(
  data,
  response_cols,
  feature_cols,
  random_effect_col,
  covariate_cols = NULL,
  min_group_size = 3,
  p_adjust_method = "BH"
) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop(
      "Package 'lme4' is required for linear mixed-model scans.",
      call. = FALSE
    )
  }

  amrc_assert_is_data_frame(data, arg_name = "data")
  amrc_assert_column_set(response_cols, data, arg_name = "response_cols")
  amrc_assert_column_set(feature_cols, data, arg_name = "feature_cols")
  amrc_assert_single_column_name(random_effect_col, data, arg_name = "random_effect_col")
  if (!is.null(covariate_cols)) {
    amrc_assert_column_set(covariate_cols, data, arg_name = "covariate_cols")
  }

  feature_rows <- vector("list", length(feature_cols))
  response_rows <- list()

  for (i in seq_along(feature_cols)) {
    feature <- feature_cols[[i]]
    parsed <- amrc_binary_feature_info(data[[feature]], feature_name = feature)
    common_data <- data.frame(
      data[, unique(c(response_cols, covariate_cols, random_effect_col)), drop = FALSE],
      .amrc_feature = parsed$values,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
    common_data <- stats::na.omit(common_data)

    absent_n <- sum(common_data$.amrc_feature == 0L)
    present_n <- sum(common_data$.amrc_feature == 1L)
    status <- if (absent_n < min_group_size || present_n < min_group_size) "insufficient_group_size" else "ok"

    feature_p_values <- numeric(0)

    for (response in response_cols) {
      model_data <- common_data[, unique(c(response, covariate_cols, random_effect_col, ".amrc_feature")), drop = FALSE]
      absent_values <- model_data[model_data$.amrc_feature == 0L, response]
      present_values <- model_data[model_data$.amrc_feature == 1L, response]

      coefficient <- NA_real_
      p_value <- NA_real_

      if (identical(status, "ok")) {
        null_formula <- amrc_build_lmm_formula(
          response_col = response,
          fixed_effect_cols = if (is.null(covariate_cols)) "1" else covariate_cols,
          random_effect_col = random_effect_col
        )
        full_formula <- amrc_build_lmm_formula(
          response_col = response,
          fixed_effect_cols = c(".amrc_feature", covariate_cols),
          random_effect_col = random_effect_col
        )

        null_fit <- lme4::lmer(null_formula, data = model_data, REML = FALSE)
        full_fit <- lme4::lmer(full_formula, data = model_data, REML = FALSE)
        model_compare <- stats::anova(null_fit, full_fit)
        p_value <- model_compare[["Pr(>Chisq)"]][2]
        coefficient <- lme4::fixef(full_fit)[[".amrc_feature"]]
        feature_p_values <- c(feature_p_values, p_value)
      }

      response_rows[[length(response_rows) + 1L]] <- data.frame(
        feature = feature,
        response = response,
        random_effect = random_effect_col,
        absent_mean = if (length(absent_values) == 0) NA_real_ else mean(absent_values, na.rm = TRUE),
        present_mean = if (length(present_values) == 0) NA_real_ else mean(present_values, na.rm = TRUE),
        mean_difference = if (length(absent_values) == 0 || length(present_values) == 0) NA_real_ else mean(present_values, na.rm = TRUE) - mean(absent_values, na.rm = TRUE),
        absent_median = if (length(absent_values) == 0) NA_real_ else stats::median(absent_values, na.rm = TRUE),
        present_median = if (length(present_values) == 0) NA_real_ else stats::median(present_values, na.rm = TRUE),
        median_difference = if (length(absent_values) == 0 || length(present_values) == 0) NA_real_ else stats::median(present_values, na.rm = TRUE) - stats::median(absent_values, na.rm = TRUE),
        coefficient = coefficient,
        p_value = p_value,
        status = status,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
    }

    feature_rows[[i]] <- data.frame(
      feature = feature,
      absent_label = parsed$absent_label,
      present_label = parsed$present_label,
      n_absent = absent_n,
      n_present = present_n,
      min_response_p = if (length(feature_p_values) == 0) NA_real_ else min(feature_p_values, na.rm = TRUE),
      median_response_p = if (length(feature_p_values) == 0) NA_real_ else stats::median(feature_p_values, na.rm = TRUE),
      status = status,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  feature_summary <- do.call(rbind, feature_rows)
  response_summary <- do.call(rbind, response_rows)

  feature_summary$min_response_p_adjusted <- stats::p.adjust(
    feature_summary$min_response_p,
    method = p_adjust_method
  )
  response_summary$p_adjusted <- stats::p.adjust(
    response_summary$p_value,
    method = p_adjust_method
  )

  list(
    feature_summary = feature_summary,
    response_summary = response_summary
  )
}
