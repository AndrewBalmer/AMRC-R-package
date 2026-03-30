# API Lifecycle

This document records how the current public namespace should be interpreted
while `amrcartography` moves toward a generic-first package API.

## Principle

The package should be understood in two layers:

- generic analysis API for arbitrary MIC datasets
- `S. pneumoniae` case-study infrastructure retained for example,
  compatibility, and regression testing

The goal is not to remove the historical case-study helpers immediately. The
goal is to stop treating them as the primary API a new user sees first.

## Permanent example infrastructure

These functions are expected to remain public because they support the bundled
case study and reproducible example-data rebuilds:

- `amrc_spneumoniae_example_paths()`
- `amrc_spneumoniae_sources()`
- `amrc_download_spneumoniae_example_data()`
- `amrc_build_spneumoniae_example_outputs()`
- `amrc_build_spneumoniae_example_maps()`

These should stay clearly documented as example-data helpers, not core generic
analysis entry points.

## Transitional compatibility wrappers

These functions remain exported for now so the migrated notebooks and case-study
workflow still work, but they should eventually be deprecated once the generic
replacements are mature and well documented:

- `amrc_process_spneumoniae_phenotype()`
- `amrc_process_spneumoniae_genotype()`
- `amrc_prepare_spneumoniae_map_data()`

For the `0.1.0` public milestone, these wrappers are in a soft-deprecation
state:

- they remain fully supported for the case-study workflow
- they are still documented and tested
- they should not be introduced as the primary API in new user-facing docs
- new analyses should prefer the generic replacements listed below

### Generic replacement path

| Transitional wrapper | Generic replacement path |
| --- | --- |
| `amrc_process_spneumoniae_phenotype()` | `amrc_standardise_mic_data()` + `amrc_compute_mic_distance()` |
| `amrc_process_spneumoniae_genotype()` | `amrc_standardise_external_data()` + `amrc_compute_external_distance()` or `amrc_compute_external_feature_distance()` |
| `amrc_prepare_spneumoniae_map_data()` | `amrc_prepare_map_data()` |

## Case-study-specific helper functions

These functions are still useful for the pneumococcal case study, but they are
not part of the long-term generic package story:

- `amrc_clean_pbp_type()`
- `amrc_pbp_type_lookup()`
- `amrc_default_pbp_deletion_labids()`
- `amrc_default_sequence_exclusions()`

They can remain public for now if they materially simplify the case-study
pipeline, but they should not be introduced in the README or generic vignettes.

## Current generic-first replacements

The package should increasingly lead new users toward these functions instead:

- `amrc_standardise_mic_data()`
- `amrc_compute_mic_distance()`
- `amrc_standardise_external_data()`
- `amrc_compute_external_distance()`
- `amrc_compute_external_feature_distance()`
- `amrc_prepare_map_data()`
- `amrc_compute_reference_distance_table()`
- `amrc_summarise_reference_distance_table()`
- `amrc_cluster_map()`
- `amrc_add_cluster_assignments()`
- `amrc_map_fit_report()`

## Deprecation gate

Do not deprecate the transitional pneumococcal wrappers until all of the
following are true:

- the generic README workflow is stable
- the generic vignette is stable
- the generic comparison layer is stable
- the case-study vignette has a clear replacement path using generic helpers
- CI covers both generic toy workflows and the case-study regression path

## Immediate policy

- keep the case-study helpers exported
- keep them documented as compatibility/example infrastructure
- avoid adding new organism-specific public functions
- prefer adding generic helpers even when the motivating use case comes from the
  pneumococcal analysis
- do not add runtime deprecation warnings to the transitional wrappers until
  the generic replacement story is stable enough that existing notebook users
  have a clear migration path
