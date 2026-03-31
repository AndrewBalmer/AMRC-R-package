# Object Contracts

This document records the core object shapes that `amrcartography` expects and
returns in the generic-first API. These are not formal S4 classes; they are
stable list/data-frame contracts that package functions are designed to
compose with.

## `amrc_mic_data`

Returned by:

- `amrc_standardise_mic_data()`

Required elements:

- `isolate_ids`: character vector of isolate identifiers
- `mic`: numeric data frame with one row per isolate and one column per drug
- `metadata`: data frame aligned row-for-row with `mic`
- `drug_columns`: character vector naming the MIC columns
- `id_column`: name of the isolate identifier column
- `transform`: preprocessing transform used, currently `"none"` or `"log2"`
- `excluded_rows`: integer vector of dropped input-row indices

Usage notes:

- row names of `mic` and `metadata` should match `isolate_ids`
- `amrc_compute_mic_distance()` accepts this object directly

## `amrc_external_data`

Returned by:

- `amrc_standardise_external_data()`

Required elements:

- `isolate_ids`: character vector of isolate identifiers
- `features`: aligned feature table with one row per isolate
- `metadata`: data frame aligned row-for-row with `features`
- `feature_columns`: character vector naming the feature columns
- `id_column`: name of the isolate identifier column
- `feature_mode`: `"numeric"` or `"character"`
- `excluded_rows`: integer vector of dropped input-row indices

Usage notes:

- use `amrc_compute_external_feature_distance()` to convert this object into a
  distance structure
- use `amrc_compute_sequence_distance()` when the aligned feature table should
  be treated as sequence or allele states and passed through
  `ape::dist.gene()`
- use `amrc_compute_external_distance()` when you already have a precomputed
  distance matrix instead of raw features
- for organism-specific raw genotype inputs, the parsing/alignment step still
  happens upstream; the generic package API begins once you have an aligned
  table or a distance matrix

## Distance bundle

Returned by:

- `amrc_distance_bundle()`

Required elements:

- `isolate_ids`: character vector used to align all bundled structures
- `phenotype_distance`: `dist` object over those isolate IDs

Optional elements:

- `external_distance`: optional aligned `dist` object

Usage notes:

- bundled distances should all share the same isolate ordering
- the bundle is the cleanest hand-off point before phenotype-vs-external map
  fitting

## Map fit outputs

Primary fit object:

- `amrc_compute_mds()` returns a `smacof` fit object

Important elements used throughout the package:

- `delta`: input dissimilarities
- `conf`: fitted coordinates
- `confdist`: pairwise distances in map space
- `stress`: overall fit stress
- `spp`: stress-per-point contribution

Downstream report object:

- `amrc_map_fit_report()` returns a list with:
  - `calibration`
  - `distances`
  - `residual_summary`
  - `stress_summary`

Usage notes:

- the fit object is the main input for calibration, map comparison, and
  plotting helpers
- the report object is the preferred summary object for user-facing
  diagnostics

## Robustness study outputs

Returned by:

- `amrc_missing_value_study()`
- `amrc_noise_added_study()`
- `amrc_disc_diffusion_study()`
- `amrc_threshold_effect_study()`
- `amrc_cross_validate_robustness()`

Shared structural expectations:

- study-specific perturbed samples or perturbation tables
- fitted MDS objects
- fitted configurations
- stress summaries
- cross-validation outputs where applicable
- identifier columns preserved using the supplied `id_col`

Cross-validation object:

- `reference_fits`
- `reference_configurations`
- `sample_fits`
- `pairwise`
- `sample_summary`
- `dimension_summary`
- `id_col`

Usage notes:

- long-form outputs from the robustness studies should be safe to merge with
  user metadata because they preserve the chosen identifier column

## Comparison outputs

Returned by:

- `amrc_prepare_map_data()`

Required elements:

- `data`: isolate-level comparison table with phenotype and external map
  coordinates aligned to the same isolate IDs
- `group_data`: optional one-row-per-group table when `group_col` is supplied
- `phenotype_calibration`
- `external_calibration`

Usage notes:

- `data` is the standard input to clustering, plotting, and reference-distance
  helpers
- `group_data` is the standard input when clustering distinct lineages, PBP
  types, or other grouped structures
- use `amrc_compute_group_centroids()` when you need a reusable grouped summary
  table for arbitrary metadata classifications
- use `amrc_compute_group_distance_summary()` when you need sample-level
  within-group or between-group phenotype/external summaries rather than
  centroid-only summaries

## Reference-distance summary outputs

Returned by:

- `amrc_compute_reference_distance_table()`
- `amrc_summarise_reference_distance_table()`

Distance-table expectations:

- identifier column if supplied
- reference column
- optional cluster column
- phenotype distance column
- external distance column

Summary object elements:

- `distance_table`
- `summary`
- `overall_summary`
- `average_row`
- `sd_row`
- `summary_with_overall`
- `fit`
- `correlation`

Usage notes:

- `summary` contains the grouped rows only
- `overall_summary`, `average_row`, and `sd_row` are now broken out explicitly
- `summary_with_overall` is retained as a compatibility table for notebook-era
  reporting code
- `amrc_compute_group_pairwise_distances()` and
  `amrc_summarise_nested_group_pairwise_distances()` extend this grouped
  comparison story to arbitrary metadata groups and nested subgroup structures
- `amrc_compare_cluster_assignments()` provides a reusable cross-tabulation and
  purity summary for phenotype-cluster versus genotype/external-cluster
  comparisons

## Feature-association outputs

Returned by:

- `amrc_fit_multivariate_linear_model()`
- `amrc_scan_single_feature_associations()`
- `amrc_fit_linear_mixed_model()`
- `amrc_scan_single_feature_mixed_models()`
- `amrc_write_limix_mvlmm_inputs()`
- `amrc_run_limix_lmm_scan()`
- `amrc_run_limix_mvlmm()`
- `amrc_run_limix_heritability()`
- `amrc_run_limix_variance_decomposition()`
- `amrc_generate_epistatic_markers()`
- `amrc_run_limix_epistatic_scan()`
- `amrc_run_limix_permutation_scan()`
- `amrc_fit_kinship_blup()`
- `amrc_cross_validate_kinship_blup()`

Association object expectations:

- response columns must be numeric
- scanned feature columns are currently expected to be binary
- multivariate fits use `lm(cbind(...))` plus MANOVA-style summaries
- mixed-model fits use `lme4::lmer()` with a random intercept
- optional LIMIX scans use a staged CSV-input contract plus an external Python
  environment with `limix`
- BLUP helpers use a kinship matrix plus explicit train/test or CV structure

Summary object elements:

- `feature_summary`: one row per scanned feature with absent/present counts and
  multivariate p-values
- `response_summary`: one row per feature-response pair with mean and median
  shifts plus univariate p-values
- `response_path`, `marker_path`, `covariate_path`, `kinship_path`: staged CSV
  inputs for LIMIX-backed scans
- `stats_path`, `effects_path`, `args`: prepared outputs and command metadata
  for LIMIX-backed scans
- `epistatic_markers`: generated interaction-marker table for epistatic scans
- `predictions`, `predictive_sd`, `fold_summary`, `overall`: prediction and
  cross-validation outputs for BLUP-style helpers

Usage notes:

- these helpers are intended for generic single-feature scans such as gene
  presence/absence or single substitution indicators
- they are designed to sit downstream of the generic external-data preparation
  helpers rather than replace organism-specific raw variant calling
- the R-native helpers cover the simple fixed-effect and random-intercept use
  cases directly inside the package
- the LIMIX helpers are the optional route when users want the manuscript-style
  multivariate mixed-model workflow on generic inputs
- the epistatic, permutation, heritability, variance-decomposition, and
  kinship-BLUP helpers extend that advanced layer into the other reusable parts
  of the original Python workflow
