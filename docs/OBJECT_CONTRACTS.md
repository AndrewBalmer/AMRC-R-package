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
- use `amrc_compute_external_distance()` when you already have a precomputed
  distance matrix instead of raw features

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
