# Release Notes: 0.2.0

`amrcartography` 0.2.0 is the second public GitHub release of the package and
the first one that includes the broader generic genotype-to-phenotype
postprocessing and visualisation layer on top of the generic MIC cartography
core.

## Highlights

- generic MIC preprocessing, distance construction, and map fitting for
  arbitrary datasets
- generic external-data support for precomputed distances, numeric feature
  tables, aligned character-state tables, and sequence-style distance inputs
- generic genotype-to-phenotype postprocessing for:
  - within-group dispersion analysis
  - one-feature contrast summaries
  - cluster-difference feature summaries
  - informative-isolate selection
  - adjusted-versus-unadjusted association comparison
  - cross-method overlap/ranking summaries
- generic plotting helpers for faceted maps, side-by-side phenotype/external
  panels, cluster-feature rankings, effect-direction plots, and mixed-model
  summaries

## What changed in 0.2.0

### Generic contrast and comparison helpers

- Added and validated:
  - `amrc_summarise_within_group_dispersion()`
  - `amrc_identify_single_feature_pairs()`
  - `amrc_summarise_single_feature_contrasts()`
  - `amrc_find_cluster_differentiating_features()`
  - `amrc_select_informative_isolates()`
  - `amrc_run_cluster_feature_workflow()`

### Generic association postprocessing

- Added and validated:
  - `amrc_prepare_marker_matrix()`
  - `amrc_compare_association_models()`
  - `amrc_summarise_association_model_comparison()`
  - `amrc_bind_ranked_feature_tables()`
  - `amrc_compute_feature_overlap()`
  - `amrc_join_external_benchmarks()`
  - `amrc_categorise_effect_directions()`
  - `amrc_summarise_effect_directions()`

### Generic visualisation

- Added reusable plotting wrappers for:
  - top-group faceted maps
  - within-group dispersion histograms
  - side-by-side phenotype/external panels
  - cluster-difference feature-shift ranking plots
  - association-model comparison plots
  - effect-direction summaries
  - feature-overlap visualisation
  - heritability summaries
  - variance-decomposition summaries

### Validation and release gating

- Fixed the critical review issues identified in the first helper-layer audit.
- Added targeted error-path tests for the new helper layer.
- Validated the feature baseline on Linux CI:
  - `62ef521` helper-layer feature commit: passed
  - `7dc9c8a` `0.2.0` release baseline: passed

## Remaining deferred items

- the interactive app remains a post-`0.2.0` task
- `08-Mapping-external-variables.Rmd` still depends on metadata not bundled in
  the repository

## Citation

For now, cite the `v0.2.0` software release. Once the package manuscript is
public, the citation guidance should be updated to cite both the software and
the paper.
