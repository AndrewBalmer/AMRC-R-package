args <- commandArgs(trailingOnly = TRUE)

stage <- "smoke"
include_preprocessing <- FALSE

if (length(args) > 0) {
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]

    if (startsWith(arg, "--stage=")) {
      stage <- sub("^--stage=", "", arg)
    } else if (identical(arg, "--stage")) {
      if (i == length(args)) {
        stop("Expected a stage name after --stage.", call. = FALSE)
      }
      i <- i + 1L
      stage <- args[[i]]
    } else if (identical(arg, "--include-preprocessing")) {
      include_preprocessing <- TRUE
    } else if (identical(arg, "--help")) {
      cat(
        "Usage: Rscript tools/run_validation.R [--stage smoke|ci|release] [--include-preprocessing]\n"
      )
      quit(save = "no", status = 0)
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }

    i <- i + 1L
  }
}

stage <- match.arg(stage, c("smoke", "ci", "release"))

Sys.setenv(
  KMP_USE_SHM = "0",
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1"
)

full_args <- commandArgs(trailingOnly = FALSE)
script_flag <- "--file="
script_path <- sub(script_flag, "", full_args[grep(script_flag, full_args)])

if (length(script_path) == 0L) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

script_dir <- dirname(normalizePath(script_path))
repo_root <- normalizePath(file.path(script_dir, ".."))
manifest_path <- file.path(repo_root, "inst", "extdata", "validation", "expected_metrics.json")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop(
    "Package 'jsonlite' is required for staged validation. ",
    "Install it and rerun this script.",
    call. = FALSE
  )
}

amrc_load_package <- function(repo_root, prefer_installed = FALSE) {
  if (isTRUE(prefer_installed) && requireNamespace("amrcartography", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  if (!isTRUE(prefer_installed) && requireNamespace("pkgload", quietly = TRUE)) {
    pkgload::load_all(
      path = repo_root,
      export_all = FALSE,
      helpers = FALSE,
      attach_testthat = FALSE,
      quiet = TRUE
    )
    return(invisible(TRUE))
  }

  if (isTRUE(prefer_installed) && requireNamespace("amrcartography", quietly = TRUE)) {
    return(invisible(TRUE))
  }

  stop(
    if (isTRUE(prefer_installed)) {
      "An installed copy of amrcartography is required for installed-package validation."
    } else {
      "pkgload is required for source-checkout validation."
    },
    call. = FALSE
  )
}

prefer_installed_package <- identical(Sys.getenv("AMRC_PACKAGE_LOAD_MODE"), "installed") ||
  {
    load_mode <- Sys.getenv("AMRC_PACKAGE_LOAD_MODE", unset = "")
    if (identical(load_mode, "installed")) {
      TRUE
    } else if (identical(load_mode, "source")) {
      FALSE
    } else {
      identical(Sys.getenv("CI"), "true") && !identical(stage, "smoke")
    }
  }

amrc_load_package(repo_root, prefer_installed = prefer_installed_package)
amrc_fn <- function(name) getExportedValue("amrcartography", name)

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

failures <- character()
notes <- character()

report_ok <- function(label) {
  message("[OK] ", label)
}

report_note <- function(label, msg) {
  notes <<- c(notes, paste0(label, ": ", msg))
  message("[NOTE] ", label, " - ", msg)
}

report_fail <- function(label, msg) {
  failures <<- c(failures, paste0(label, ": ", msg))
  message("[FAIL] ", label, " - ", msg)
}

report_runtime_context <- function() {
  report_note("Validation stage", stage)
  report_note(
    "Package load mode",
    if (isTRUE(prefer_installed_package)) "installed" else "source"
  )
  report_note("CI environment", Sys.getenv("CI", unset = "false"))
  report_note(".libPaths()", paste(.libPaths(), collapse = " | "))
  report_note(
    "Namespace availability",
    paste(
      sprintf("amrcartography=%s", requireNamespace("amrcartography", quietly = TRUE)),
      sprintf("pkgload=%s", requireNamespace("pkgload", quietly = TRUE)),
      collapse = ", "
    )
  )
}

run_check <- function(label, expr) {
  tryCatch(
    {
      force(expr)
      report_ok(label)
    },
    error = function(e) {
      report_fail(label, conditionMessage(e))
    }
  )
}

assert_true <- function(condition, msg) {
  if (!isTRUE(condition)) {
    stop(msg, call. = FALSE)
  }
}

assert_identical_scalar <- function(actual, expected, msg) {
  if (!identical(actual, expected)) {
    stop(
      sprintf("%s (expected %s, got %s)", msg, expected, actual),
      call. = FALSE
    )
  }
}

assert_has_columns <- function(data, required, label) {
  missing <- setdiff(required, colnames(data))
  if (length(missing) > 0L) {
    stop(label, " is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

assert_unique_ids <- function(data, id_col, label) {
  assert_true(id_col %in% colnames(data), paste0(label, " is missing ID column '", id_col, "'"))
  duplicated_ids <- unique(as.character(data[[id_col]][duplicated(data[[id_col]])]))
  if (length(duplicated_ids) > 0L) {
    stop(
      label,
      " contains duplicated IDs: ",
      paste(utils::head(duplicated_ids, 10), collapse = ", "),
      call. = FALSE
    )
  }
}

assert_non_empty_file <- function(path, label) {
  assert_true(file.exists(path), paste0(label, " does not exist: ", path))
  assert_true(file.info(path)$size > 0, paste0(label, " is empty: ", path))
}

assert_numeric_columns <- function(data, cols, label) {
  for (col in cols) {
    assert_true(col %in% colnames(data), paste0(label, " is missing numeric column '", col, "'"))
    values <- suppressWarnings(as.numeric(data[[col]]))
    assert_true(!all(is.na(values)), paste0(label, " column '", col, "' is all NA"))
    assert_true(all(is.finite(values[!is.na(values)])), paste0(label, " column '", col, "' contains non-finite values"))
    assert_true(stats::var(values, na.rm = TRUE) > 0, paste0(label, " column '", col, "' has zero variance"))
  }
}

read_csv_keep_names <- function(path) {
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
}

run_rscript <- function(script_path, script_args = character(), label = basename(script_path)) {
  output <- system2(
    command = file.path(R.home("bin"), "Rscript"),
    args = c(script_path, script_args),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status") %||% 0L
  if (!identical(status, 0L)) {
    stop(
      paste(
        c(
          sprintf("%s failed with status %s", label, status),
          output
        ),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }
  invisible(output)
}

metrics <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
report_runtime_context()

validate_generic_examples <- function() {
  paths <- amrc_fn("amrc_example_data_paths")()

  for (name in names(paths)[names(paths) != "root"]) {
    assert_non_empty_file(paths[[name]], paste("Bundled generic example", name))
  }

  mic_raw <- amrc_fn("amrc_example_data")("mic_raw")
  ext_numeric <- amrc_fn("amrc_example_data")("external_numeric")
  ext_character <- amrc_fn("amrc_example_data")("external_character")
  ext_distance <- amrc_fn("amrc_example_data")("external_distance")

  assert_identical_scalar(
    nrow(mic_raw),
    metrics$generic_examples$mic_raw$rows,
    "Bundled generic MIC row count changed"
  )
  assert_has_columns(
    mic_raw,
    metrics$generic_examples$mic_raw$required_columns,
    "Bundled generic MIC data"
  )
  assert_unique_ids(mic_raw, "isolate_id", "Bundled generic MIC data")
  assert_true(
    !any(vapply(mic_raw[c("drug_a", "drug_b", "drug_c")], function(x) all(is.na(x)), logical(1))),
    "Bundled generic MIC data contains an all-NA MIC column"
  )

  assert_identical_scalar(
    nrow(ext_numeric),
    metrics$generic_examples$external_numeric$rows,
    "Bundled generic numeric external row count changed"
  )
  assert_has_columns(
    ext_numeric,
    metrics$generic_examples$external_numeric$required_columns,
    "Bundled numeric external data"
  )
  assert_unique_ids(ext_numeric, "isolate_id", "Bundled numeric external data")

  assert_identical_scalar(
    nrow(ext_character),
    metrics$generic_examples$external_character$rows,
    "Bundled generic character external row count changed"
  )
  assert_has_columns(
    ext_character,
    metrics$generic_examples$external_character$required_columns,
    "Bundled character external data"
  )
  assert_unique_ids(ext_character, "isolate_id", "Bundled character external data")

  assert_identical_scalar(
    nrow(ext_distance),
    metrics$generic_examples$external_distance$rows,
    "Bundled external distance row count changed"
  )
  assert_identical_scalar(
    ncol(ext_distance),
    metrics$generic_examples$external_distance$cols,
    "Bundled external distance column count changed"
  )
  assert_true(isTRUE(all.equal(ext_distance, t(ext_distance))), "Bundled external distance matrix is not symmetric")
  assert_true(all(diag(ext_distance) == 0), "Bundled external distance matrix diagonal is not zero")
  assert_true(all(is.finite(ext_distance)), "Bundled external distance matrix contains non-finite values")

  mic_data <- amrc_fn("amrc_standardise_mic_data")(
    data = mic_raw,
    id_col = "isolate_id",
    mic_cols = c("drug_a", "drug_b", "drug_c"),
    metadata_cols = c("lineage", "source"),
    transform = "log2",
    less_than = "numeric",
    greater_than = "numeric"
  )
  phenotype_distance <- amrc_fn("amrc_compute_mic_distance")(mic_data)

  assert_identical_scalar(
    nrow(mic_data$mic),
    metrics$generic_examples$mic_raw$rows,
    "Standardised generic MIC data row count changed"
  )
  assert_identical_scalar(ncol(mic_data$mic), 3L, "Standardised MIC data drug count changed")
  assert_true(inherits(phenotype_distance, "dist"), "Phenotype distance is not a dist object")
  assert_identical_scalar(length(attr(phenotype_distance, "Labels")), 6L, "Phenotype distance labels changed")
}

validate_mapping_08_bundle <- function() {
  paths <- amrc_fn("amrc_spneumoniae_example_paths")("mapping_08")
  required <- unlist(paths[names(paths) != "root"], use.names = TRUE)

  for (name in names(required)) {
    assert_non_empty_file(required[[name]], paste("mapping_08 file", name))
  }

  phenotype_meta <- read_csv_keep_names(paths$mic_metadata)
  phenotype_map <- read_csv_keep_names(paths$phenotype_map)
  genotype_map <- read_csv_keep_names(paths$genotype_map)
  mlst_metadata <- read_csv_keep_names(paths$mlst_metadata)
  post2015_metadata <- read_csv_keep_names(paths$post2015_metadata)
  map_bundle <- readRDS(paths$map_bundle)

  assert_identical_scalar(
    nrow(phenotype_meta),
    metrics$spneumoniae_08$phenotype_metadata_rows,
    "mapping_08 phenotype metadata row count changed"
  )
  assert_identical_scalar(
    nrow(phenotype_map),
    metrics$spneumoniae_08$phenotype_map_rows,
    "mapping_08 phenotype map row count changed"
  )
  assert_identical_scalar(
    nrow(genotype_map),
    metrics$spneumoniae_08$genotype_map_rows,
    "mapping_08 genotype map row count changed"
  )
  assert_identical_scalar(
    nrow(mlst_metadata),
    metrics$spneumoniae_08$mlst_metadata_rows,
    "mapping_08 MLST metadata row count changed"
  )
  assert_identical_scalar(
    nrow(post2015_metadata),
    metrics$spneumoniae_08$post2015_metadata_rows,
    "mapping_08 post-2015 metadata row count changed"
  )

  assert_has_columns(
    phenotype_meta,
    metrics$spneumoniae_08$phenotype_metadata_required_columns,
    "mapping_08 phenotype metadata"
  )
  assert_has_columns(
    phenotype_map,
    metrics$spneumoniae_08$phenotype_map_required_columns,
    "mapping_08 phenotype map"
  )
  assert_has_columns(
    genotype_map,
    metrics$spneumoniae_08$genotype_map_required_columns,
    "mapping_08 genotype map"
  )
  assert_has_columns(
    mlst_metadata,
    metrics$spneumoniae_08$mlst_metadata_required_columns,
    "mapping_08 MLST metadata"
  )
  assert_has_columns(
    post2015_metadata,
    metrics$spneumoniae_08$post2015_metadata_required_columns,
    "mapping_08 post-2015 metadata"
  )

  assert_unique_ids(phenotype_meta, "LABID", "mapping_08 phenotype metadata")
  assert_unique_ids(phenotype_map, "LABID", "mapping_08 phenotype map")
  assert_unique_ids(genotype_map, "LABID", "mapping_08 genotype map")

  assert_true(
    setequal(phenotype_meta$LABID, phenotype_map$LABID),
    "mapping_08 phenotype metadata and phenotype map LABIDs differ"
  )
  assert_true(
    all(genotype_map$LABID %in% phenotype_meta$LABID),
    "mapping_08 genotype map contains LABIDs missing from phenotype metadata"
  )

  phenotype_only_ids <- setdiff(phenotype_meta$LABID, genotype_map$LABID)
  assert_identical_scalar(
    length(phenotype_only_ids),
    metrics$spneumoniae_08$phenotype_minus_genotype_rows,
    "mapping_08 phenotype-vs-genotype ID difference changed"
  )
  assert_true(
    all(phenotype_only_ids %in% map_bundle$deleted_labids),
    "mapping_08 bundle deleted_labids no longer covers phenotype-only LABIDs"
  )
  assert_identical_scalar(
    length(map_bundle$deleted_labids),
    metrics$spneumoniae_08$deleted_labids_bundle_count,
    "mapping_08 bundle deleted_labids count changed"
  )

  assert_numeric_columns(phenotype_map, c("D1", "D2"), "mapping_08 phenotype map")
  assert_numeric_columns(genotype_map, c("G1", "G2"), "mapping_08 genotype map")

  assert_true(is.list(map_bundle), "mapping_08 map bundle is not a list")
  assert_true(
    all(c("phenotype_map", "genotype_map", "deleted_labids") %in% names(map_bundle)),
    "mapping_08 map bundle is missing required components"
  )
}

validate_suis_demo_bundle <- function() {
  paths <- amrc_fn("amrc_suis_example_paths")()

  phenotype <- read_csv_keep_names(paths$phenotype)
  metadata <- read_csv_keep_names(paths$metadata)
  distance <- read_csv_keep_names(paths$pbp_distance)

  assert_identical_scalar(
    nrow(phenotype),
    metrics$suis_demo$phenotype_rows,
    "Bundled S. suis phenotype row count changed"
  )
  assert_identical_scalar(
    nrow(metadata),
    metrics$suis_demo$metadata_rows,
    "Bundled S. suis metadata row count changed"
  )
  assert_identical_scalar(
    nrow(distance),
    metrics$suis_demo$distance_rows,
    "Bundled S. suis distance row count changed"
  )
  assert_identical_scalar(
    ncol(distance) - 1L,
    metrics$suis_demo$distance_cols,
    "Bundled S. suis distance column count changed"
  )

  assert_has_columns(
    phenotype,
    metrics$suis_demo$phenotype_required_columns,
    "Bundled S. suis phenotype input"
  )
  assert_has_columns(
    metadata,
    metrics$suis_demo$metadata_required_columns,
    "Bundled S. suis metadata"
  )
  assert_true("LABID" %in% colnames(distance), "Bundled S. suis distance matrix is missing 'LABID'")

  assert_unique_ids(phenotype, "LABID", "Bundled S. suis phenotype input")
  assert_unique_ids(metadata, "LABID", "Bundled S. suis metadata")
  assert_unique_ids(distance, "LABID", "Bundled S. suis distance matrix rows")

  distance_row_ids <- as.character(distance$LABID)
  distance_col_ids <- colnames(distance)[colnames(distance) != "LABID"]

  assert_true(
    setequal(distance_row_ids, distance_col_ids),
    "Bundled S. suis distance matrix row and column identifiers no longer match"
  )
  assert_true(
    all(as.character(phenotype$LABID) %in% distance_row_ids),
    "Bundled S. suis phenotype IDs are no longer all present in the distance matrix"
  )
  assert_true(
    all(as.character(phenotype$LABID) %in% as.character(metadata$LABID)),
    "Bundled S. suis phenotype IDs are no longer all present in the metadata table"
  )
}

validate_public_mic_examples <- function() {
  paths <- amrc_fn("amrc_example_data_paths")()
  manifest <- amrc_fn("amrc_public_mic_example_specs")()

  assert_identical_scalar(
    nrow(manifest),
    metrics$public_mic_examples$public_mic_manifest$rows,
    "Public MIC manifest row count changed"
  )
  assert_has_columns(
    manifest,
    metrics$public_mic_examples$public_mic_manifest$required_columns,
    "Public MIC manifest"
  )

  dataset_names <- as.character(manifest$dataset_name)

  for (name in dataset_names) {
    assert_non_empty_file(paths[[name]], paste("Bundled public MIC example", name))
    data <- amrc_fn("amrc_example_data")(name)

    assert_identical_scalar(
      nrow(data),
      metrics$public_mic_examples[[name]]$rows,
      paste("Bundled public MIC row count changed for", name)
    )
    assert_has_columns(
      data,
      metrics$public_mic_examples[[name]]$required_columns,
      paste("Bundled public MIC data", name)
    )
    assert_unique_ids(data, "ar_bank_id", paste("Bundled public MIC data", name))

    suggested_cols <- strsplit(
      manifest$suggested_mic_cols[manifest$dataset_name == name],
      ",",
      fixed = TRUE
    )[[1]]
    assert_true(
      all(suggested_cols %in% colnames(data)),
      paste("Public MIC manifest suggested_mic_cols no longer match dataset columns for", name)
    )
  }
}

validate_source_generated_artifacts <- function() {
  generated_root <- file.path(repo_root, "inst", "extdata", "generated", "spneumoniae")
  required_paths <- file.path(generated_root, metrics$source_generated$required_files)

  for (path in required_paths) {
    assert_non_empty_file(path, "Source-checkout generated example artifact")
  }

  phenotype_mic <- read_csv_keep_names(file.path(generated_root, "MIC_table_Spneumoniae.csv"))
  phenotype_meta <- read_csv_keep_names(file.path(generated_root, "meta_data_Spneumoniae.csv"))

  assert_identical_scalar(
    nrow(phenotype_mic),
    metrics$source_generated$phenotype_rows,
    "Tracked generated MIC table row count changed"
  )
  assert_identical_scalar(
    nrow(phenotype_meta),
    metrics$source_generated$metadata_rows,
    "Tracked generated metadata row count changed"
  )
  assert_has_columns(
    phenotype_meta,
    c("LABID", "PT"),
    "Tracked generated phenotype metadata"
  )
  assert_unique_ids(phenotype_meta, "LABID", "Tracked generated phenotype metadata")
}

validate_streamlit_backend <- function() {
  backend_script <- file.path(repo_root, "streamlit_app", "amrc_streamlit_backend.R")
  assert_non_empty_file(backend_script, "Streamlit backend script")

  example_paths <- amrc_fn("amrc_example_data_paths")()
  output_dir <- file.path(tempdir(), paste0("amrc-validation-", as.integer(Sys.time())))
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  config_path <- file.path(output_dir, "config.json")

  config <- list(
    repo_root = repo_root,
    output_dir = output_dir,
    phenotype = list(
      path = example_paths$mic_raw,
      id_col = "isolate_id",
      mic_cols = c("drug_a", "drug_b", "drug_c"),
      metadata_cols = c("lineage", "source"),
      transform = "log2",
      drop_incomplete = TRUE,
      less_than = "numeric",
      greater_than = "numeric"
    ),
    plot = list(
      fill_col = "lineage",
      facet_by = "",
      grid_spacing_one = TRUE,
      density = FALSE,
      phenotype_rotation_degrees = 15,
      external_rotation_degrees = -20
    ),
    comparison = list(
      group_col = "lineage"
    ),
    report = list(
      zip_bundle = TRUE,
      pdf_export = TRUE
    ),
    clustering = list(
      enabled = TRUE,
      n_clusters = 2L,
      distinct_col = "lineage"
    ),
    reference = list(
      enabled = TRUE,
      reference_col = "lineage",
      reference_value = "L1",
      x_break_step = 1,
      y_break_step = 1,
      annotation_text = "Example",
      annotation_x = 1,
      annotation_y = 1
    ),
    external = list(
      enabled = TRUE,
      mode = "numeric_features",
      path = example_paths$external_numeric,
      id_col = "isolate_id",
      feature_cols = c("axis1", "axis2")
    )
  )

  jsonlite::write_json(config, path = config_path, auto_unbox = TRUE, pretty = TRUE)

  output <- system2(
    command = file.path(R.home("bin"), "Rscript"),
    args = c(backend_script, config_path),
    env = c(
      sprintf(
        "AMRC_PACKAGE_LOAD_MODE=%s",
        if (isTRUE(prefer_installed_package)) "installed" else "source"
      ),
      sprintf("CI=%s", Sys.getenv("CI", unset = "false"))
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status") %||% 0L
  if (!identical(status, 0L)) {
    stop(
      paste(
        c("Streamlit backend smoke run failed:", output),
        collapse = "\n"
      ),
      call. = FALSE
    )
  }

  required_files <- file.path(output_dir, metrics$streamlit_smoke$required_files)
  for (path in required_files) {
    assert_non_empty_file(path, "Streamlit backend output")
  }

  summary <- jsonlite::read_json(file.path(output_dir, "summary.json"), simplifyVector = TRUE)
  assert_identical_scalar(
    summary$phenotype$n_isolates,
    metrics$streamlit_smoke$phenotype_n_isolates,
    "Streamlit backend phenotype isolate count changed"
  )
  assert_identical_scalar(
    summary$phenotype$n_drugs,
    metrics$streamlit_smoke$phenotype_n_drugs,
    "Streamlit backend phenotype drug count changed"
  )
  assert_identical_scalar(
    summary$phenotype$calibration$mode,
    "model_based_1mic",
    "Streamlit backend phenotype calibration mode changed"
  )
  assert_true(
    is.numeric(summary$phenotype$calibration$dilation),
    "Streamlit backend phenotype calibration dilation is not numeric"
  )
  assert_true(
    isTRUE(all.equal(as.numeric(summary$phenotype$calibration$rotation_degrees), 15)),
    "Streamlit backend phenotype rotation changed"
  )
  assert_true(
    !is.null(summary$external$reference$n_rows),
    "Streamlit backend summary is missing external reference row count"
  )
  assert_identical_scalar(
    summary$external$calibration$mode,
    "model_based_1mic",
    "Streamlit backend external calibration mode changed"
  )
  assert_true(
    isTRUE(all.equal(as.numeric(summary$external$calibration$rotation_degrees), -20)),
    "Streamlit backend external rotation changed"
  )
  assert_true(
    isTRUE(all.equal(as.numeric(summary$external$reference$x_break_step), 1)),
    "Streamlit backend reference x break step changed"
  )
  assert_true(
    isTRUE(all.equal(as.numeric(summary$external$reference$y_break_step), 1)),
    "Streamlit backend reference y break step changed"
  )
  assert_identical_scalar(
    summary$external$reference$annotation_text,
    "Example",
    "Streamlit backend annotation text changed"
  )
  assert_true(
    summary$external$reference$n_rows >= metrics$streamlit_smoke$reference_rows_min,
    "Streamlit backend reference summary is unexpectedly empty"
  )

  phenotype_map_data <- read_csv_keep_names(file.path(output_dir, "phenotype_map_data.csv"))
  phenotype_fit_metrics <- read_csv_keep_names(file.path(output_dir, "phenotype_fit_metrics.csv"))
  phenotype_residual_summary <- read_csv_keep_names(file.path(output_dir, "phenotype_residual_summary.csv"))
  phenotype_stress_summary <- read_csv_keep_names(file.path(output_dir, "phenotype_stress_summary.csv"))
  comparison_data <- read_csv_keep_names(file.path(output_dir, "comparison_data.csv"))
  external_fit_metrics <- read_csv_keep_names(file.path(output_dir, "external_fit_metrics.csv"))
  external_residual_summary <- read_csv_keep_names(file.path(output_dir, "external_residual_summary.csv"))
  external_stress_summary <- read_csv_keep_names(file.path(output_dir, "external_stress_summary.csv"))
  reference_table <- read_csv_keep_names(file.path(output_dir, "reference_distance_table.csv"))

  assert_has_columns(
    phenotype_map_data,
    c("isolate_id", "D1", "D2"),
    "Streamlit phenotype map data"
  )
  assert_has_columns(
    phenotype_fit_metrics,
    c("stress", "r_squared", "dilation", "correlation_estimate", "correlation_p_value"),
    "Streamlit phenotype fit metrics"
  )
  assert_has_columns(
    phenotype_residual_summary,
    c("mean_abs_residual", "sd_abs_residual"),
    "Streamlit phenotype residual summary"
  )
  assert_has_columns(
    phenotype_stress_summary,
    c("mean_spp", "sd_spp", "max_spp"),
    "Streamlit phenotype stress summary"
  )
  assert_has_columns(
    comparison_data,
    c("isolate_id", "D1", "D2", "E1", "E2"),
    "Streamlit comparison data"
  )
  assert_has_columns(
    external_fit_metrics,
    c("stress", "r_squared", "dilation", "correlation_estimate", "correlation_p_value"),
    "Streamlit external fit metrics"
  )
  assert_has_columns(
    external_residual_summary,
    c("mean_abs_residual", "sd_abs_residual"),
    "Streamlit external residual summary"
  )
  assert_has_columns(
    external_stress_summary,
    c("mean_spp", "sd_spp", "max_spp"),
    "Streamlit external stress summary"
  )
  assert_true(
    isTRUE(phenotype_fit_metrics$r_squared[[1]] >= 0 && phenotype_fit_metrics$r_squared[[1]] <= 1),
    "Streamlit phenotype fit R-squared is outside [0, 1]"
  )
  assert_true(
    isTRUE(external_fit_metrics$r_squared[[1]] >= 0 && external_fit_metrics$r_squared[[1]] <= 1),
    "Streamlit external fit R-squared is outside [0, 1]"
  )
  assert_true(
    "isolate_id" %in% colnames(reference_table),
    "Streamlit reference-distance table is missing 'isolate_id'"
  )
  has_distance_pair <- (
    all(c("phen_distance", "gen_distance") %in% colnames(reference_table)) ||
      all(c("phenotype_distance", "external_distance") %in% colnames(reference_table))
  )
  assert_true(
    has_distance_pair,
    paste(
      "Streamlit reference-distance table is missing the expected distance columns.",
      "Expected either phen_distance/gen_distance or phenotype_distance/external_distance."
    )
  )
  assert_true(nrow(reference_table) > 0L, "Streamlit reference-distance table is empty")
}

run_smoke_stage <- function() {
  run_check("Validation metrics manifest is available", {
    assert_non_empty_file(manifest_path, "Validation metrics manifest")
    assert_true(is.list(metrics), "Validation metrics manifest did not parse into a list")
  })

  run_check("Bundled generic examples remain valid", validate_generic_examples())
  run_check("Bundled public MIC examples remain valid", validate_public_mic_examples())
  run_check("Packaged mapping_08 bundle remains internally consistent", validate_mapping_08_bundle())
  run_check("Packaged S. suis bundle remains internally consistent", validate_suis_demo_bundle())
  run_check("Tracked generated source artifacts remain present", validate_source_generated_artifacts())
  run_check("Streamlit backend contract smoke check passes", validate_streamlit_backend())
}

run_release_stage <- function() {
  run_check("README example workflow still runs", {
    run_rscript(file.path(repo_root, "tools", "check_readme_examples.R"), label = "README example workflow")
  })
  run_check("Vignettes still render explicitly", {
    run_rscript(file.path(repo_root, "tools", "render_vignettes.R"), label = "Vignette render")
  })

  if (isTRUE(include_preprocessing)) {
    run_check("Legacy preprocessing outputs still verify", {
      run_rscript(
        file.path(repo_root, "tools", "verify_preprocessing_outputs.R"),
        label = "Legacy preprocessing verification"
      )
    })
  } else {
    report_note(
      "Legacy preprocessing verification",
      "Skipped by default. Re-run with --include-preprocessing when you need the deeper case-study parity check."
    )
  }
}

message("Running validation stage: ", stage)
run_smoke_stage()

if (identical(stage, "release")) {
  run_release_stage()
}

if (length(failures) > 0L) {
  message("\nValidation failed with ", length(failures), " problem(s):")
  for (failure in failures) {
    message("- ", failure)
  }
  quit(save = "no", status = 1)
}

message("\nValidation stage '", stage, "' completed successfully.")

if (length(notes) > 0L) {
  message("\nNotes:")
  for (note in notes) {
    message("- ", note)
  }
}
