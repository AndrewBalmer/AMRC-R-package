# Release Notes: 0.1.0

`amrcartography` 0.1.0 is the first public GitHub release of the package as a
generic MIC cartography toolkit.

## Highlights

- generic MIC preprocessing, distance construction, and map fitting for
  arbitrary datasets
- generic external-data support for precomputed distances, numeric feature
  tables, and aligned character-state tables
- reusable clustering, calibration, robustness, and phenotype-vs-external
  comparison helpers
- a retained `S. pneumoniae` case study for worked-example and regression use,
  not as the primary package identity

## What changed in 0.1.0

### Generic-first API

- Added and stabilised the generic MIC workflow around:
  - `amrc_standardise_mic_data()`
  - `amrc_compute_mic_distance()`
  - `amrc_compute_mds()`
  - `amrc_prepare_map_data()`
  - `amrc_compute_reference_distance_table()`
  - `amrc_summarise_reference_distance_table()`

### External data

- Added explicit support for:
  - precomputed external distance matrices
  - aligned numeric feature tables
  - aligned character-state feature tables

### Case-study lifecycle

- Kept the pneumococcal wrappers public for compatibility and example use:
  - `amrc_process_spneumoniae_phenotype()`
  - `amrc_process_spneumoniae_genotype()`
  - `amrc_prepare_spneumoniae_map_data()`
- Reframed them as case-study wrappers rather than the recommended API for new
  analyses

### Testing and validation

- Added stronger generic workflow coverage
- Fixed the audit issues in robustness, plotting, reference-distance, and
  weighted-MDS search code paths
- Validated locally with:
  - `testthat::test_local(".")`
  - full vignette-inclusive `R CMD build`
  - full `R CMD check --as-cran --no-manual`

## Remaining deferred items

- the interactive app
- `08-Mapping-external-variables.Rmd`, which still depends on metadata not
  bundled in the repository

## Citation

For now, cite the software release. Once the package manuscript is public, the
citation guidance should be updated to cite both the package and the paper.
