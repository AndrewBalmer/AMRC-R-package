# Generalisation Strategy for `amrcartography`

## Purpose

This document sets the direction for the next major phase of the package:
`amrcartography` should become a general toolkit for cartographic analysis of
MIC datasets, not a package whose primary identity is reproducing the
`S. pneumoniae` workflow from the earlier AMR cartography work.

The `S. pneumoniae` analysis should remain in the repository only as:

- a worked example
- a validation dataset
- a case-study vignette
- a regression target for package-backed migration

It should not define the public package API, the package naming conventions, or
the main user story.

## Plain-language goal

The package should let a user bring their own MIC dataset and do the following
without touching `S. pneumoniae`-specific code:

1. validate and preprocess a MIC table
2. build a phenotypic distance matrix
3. fit one- or two-dimensional cartography maps
4. calibrate and diagnose map fit
5. run robustness analyses
6. cluster map structure
7. compare phenotype maps with an external distance structure if available
8. generate reusable summary tables and plots

The `S. pneumoniae` example should simply demonstrate that workflow on one real
dataset.

## Current state

The package already contains a reusable computational backend in several areas:

- general MDS wrappers
- map calibration and goodness-of-fit helpers
- clustering helpers
- robustness helpers
- plotting helpers

However, the main end-to-end path is still too organism-specific:

- preprocessing is currently exported as `amrc_process_spneumoniae_phenotype()`
  and `amrc_process_spneumoniae_genotype()`
- map comparison is currently exported as
  `amrc_prepare_spneumoniae_map_data()`
- example data helpers, data download helpers, and build helpers are centered on
  `S. pneumoniae`
- the user-facing vignette is an `S. pneumoniae` vignette
- the README still naturally reads as "this package reproduces the pneumococcal
  analysis"

So the package has a partly general engine, but not yet a truly generic public
API.

## Strategic decision

The package should adopt a two-layer architecture:

### Layer 1: generic public API

This is the main package surface and should be the default user entry point.

It must:

- use organism-agnostic names
- accept arbitrary MIC datasets
- define explicit input schemas
- return standard object structures
- avoid assumptions about PBP types, beta-lactams, or `S. pneumoniae`

### Layer 2: example-specific wrappers and case studies

This layer should support:

- the `S. pneumoniae` reference workflow
- backwards-compatible migration from the old scripts
- reproducible example data generation
- regression testing against the legacy outputs

This layer should not define the package identity.

## Design principles

### 1. Public functions must be generic

No primary user-facing function should be named after `S. pneumoniae`.

`S. pneumoniae`-specific functions may still exist temporarily during
migration, but they should be treated as:

- wrappers
- legacy compatibility helpers
- example-build tools

They should not be the functions that the README introduces first.

### 2. Input schemas must be explicit

The package should document clearly what a valid MIC dataset looks like.

At minimum, the package should support:

- a wide-format MIC table with one row per isolate and one column per drug
- an isolate identifier column
- optional metadata columns
- optional grouping, cluster, or reference columns
- optional external distance matrices

The package must stop relying on hard-coded column names that only make sense
for the pneumococcal workflow.

### 3. Standard object shapes must replace ad hoc lists

Generic workflows are hard to compose when every step returns a slightly
different object.

The package should define stable object contracts for:

- preprocessed MIC data
- distance bundles
- map fits
- calibrated map reports
- robustness study outputs
- comparison tables
- clustering results

These can remain lists internally, but they must have standard names and
documented required components.

### 4. Example pipelines should wrap the generic engine

The `S. pneumoniae` workflow should call the same generic functions that outside
users call.

That means the example pipeline should be evidence that the generic API works,
not a parallel one-off code path.

### 5. Plotting and reporting should stay downstream of computation

The package should let users run the full analysis without inheriting the
manuscript's labels, themes, or assumptions.

Plots should consume generic result objects.

## Target package architecture

## A. Data ingestion and validation

Create generic functions for validating and standardising MIC inputs.

### Required new public functions

- `amrc_validate_mic_data()`
- `amrc_standardise_mic_data()`
- `amrc_extract_mic_matrix()`
- `amrc_extract_isolate_metadata()`

### Responsibilities

- confirm the isolate ID column exists
- confirm drug columns are numeric or coercible to numeric
- separate MIC columns from metadata columns
- optionally apply log2 transformation rules
- optionally drop or flag incomplete rows
- return a standardised MIC-data object

### Proposed return object

`amrc_standardise_mic_data()` should return a list with:

- `isolate_ids`
- `mic`
- `metadata`
- `drug_columns`
- `id_column`
- `transform`
- `excluded_rows`

## B. Distance construction

Create generic distance builders that do not depend on a specific organism.

### Required new public functions

- `amrc_compute_mic_distance()`
- `amrc_compute_external_distance()`
- `amrc_subset_distance()`
- `amrc_distance_bundle()`

### Responsibilities

- compute phenotype distance matrices from MIC tables
- accept user-supplied external distance matrices
- keep isolate ordering explicit
- verify that distances and metadata refer to the same isolate IDs

### Notes

This is the place where the package becomes reusable for "any MIC dataset".
Users should be able to stop after this phase and still get value from the
package.

## C. Map fitting and calibration

This layer is already partly generic and should become the package center.

### Existing functions that can remain central

- `amrc_compute_mds()`
- `amrc_run_dimensionality_sweep()`
- `amrc_fit_mds_transformations()`
- `amrc_run_random_start_search()`
- `amrc_run_weighted_mds_search()`
- `amrc_calibrate_mds()`
- `amrc_fit_distance_calibration()`
- `amrc_map_fit_report()`

### Work still needed

- document these as generic first-class APIs
- make sure examples and docs show arbitrary MIC input, not just the example
  dataset
- define a stable "map fit" object contract

## D. Generic clustering and comparison

Much of this already exists, but the public API should stop assuming PBP types.

### Required new or renamed public functions

- `amrc_prepare_map_data()`
- `amrc_attach_cluster_assignments()`
- `amrc_compute_reference_distance_table()`
- `amrc_summarise_reference_distance_table()`
- `amrc_cluster_map()`

### What must change

- `amrc_prepare_spneumoniae_map_data()` should become a generic
  `amrc_prepare_map_data()`
- the concept of a key column should not assume `PBP_type`
- phenotype/genotype comparison should be reframed as comparison between:
  - a phenotype map
  - an external map or distance structure

## E. Generic robustness workflows

The robustness layer is already close to generic, but its inputs and docs need
to become more obviously reusable.

### Functions that should remain but be reframed

- `amrc_missing_value_study()`
- `amrc_noise_added_study()`
- `amrc_threshold_effect_study()`
- `amrc_cross_validate_robustness()`

### Work still needed

- document required generic input objects
- remove any implicit dependence on `S. pneumoniae` metadata conventions
- make the outputs easier to use across arbitrary datasets

## F. Plotting layer

Plotting should be generic and consume standard result objects.

### Existing generic plots that should remain

- `amrc_plot_cluster_map()`
- `amrc_plot_cluster_elbow()`
- `amrc_plot_distance_histogram()`
- `amrc_plot_reference_distance_relationship()`
- `amrc_plot_one_vs_two_dimensional_projection()`

### Work still needed

- make documentation generic
- stop describing these plots primarily through the pneumococcal example
- add one generic example for each key plot class

## Naming policy

The package should adopt the following naming rule immediately:

- public generic functions: no organism names
- example-build helpers: organism names allowed
- legacy compatibility wrappers: organism names allowed temporarily

### Current names to replace

| Current exported function | Target direction |
| --- | --- |
| `amrc_process_spneumoniae_phenotype()` | replace with generic `amrc_process_mic_data()` or split into validation + transformation + distance helpers |
| `amrc_process_spneumoniae_genotype()` | replace with generic external-sequence/distance preparation helpers, then keep a pneumococcal wrapper only for the example |
| `amrc_prepare_spneumoniae_map_data()` | replace with `amrc_prepare_map_data()` |
| `amrc_build_spneumoniae_example_outputs()` | keep, but mark clearly as example-build infrastructure |
| `amrc_build_spneumoniae_example_maps()` | keep, but mark clearly as example-build infrastructure |
| `amrc_spneumoniae_example_paths()` | keep as example-data helper, not core analysis API |
| `amrc_download_spneumoniae_example_data()` | keep as example-data helper, not core analysis API |

## Public API plan

The package should end up with a top-level user workflow that looks more like
this:

```r
mic_data <- amrc_standardise_mic_data(
  data = my_data,
  id_col = "isolate_id",
  mic_cols = c("drug_a", "drug_b", "drug_c"),
  metadata_cols = c("country", "year", "lineage"),
  transform = "log2"
)

phen_dist <- amrc_compute_mic_distance(mic_data$mic)
phen_map <- amrc_compute_mds(phen_dist)
phen_report <- amrc_map_fit_report(phen_map)

cluster_fit <- amrc_cluster_map(
  data = as.data.frame(phen_map$conf),
  coord_cols = c("D1", "D2"),
  n_clusters = 4
)
```

If the user also has an external distance matrix:

```r
comparison <- amrc_prepare_map_data(
  metadata = mic_data$metadata,
  phenotype_mds = phen_map,
  external_mds = external_map,
  key_col = "isolate_id"
)
```

This is the kind of workflow the README should eventually lead with.

## Migration plan

## Phase 1: freeze the current generic core

Goal: identify what is already generic and keep it stable.

### Deliverables

- confirm the generic map, goodness-of-fit, robustness, clustering, and plotting
  functions that remain part of the core API
- mark `S. pneumoniae` helpers in documentation as example-specific
- avoid further growth of organism-specific public API

## Phase 2: build the generic MIC preprocessing layer

Goal: create the real generic entry point for arbitrary MIC datasets.

### Deliverables

- generic MIC schema validator
- generic MIC transformer/standardiser
- generic phenotype distance builder
- documentation for accepted input layouts
- tests using toy non-pneumococcal MIC datasets

### Exit criterion

A user can start from an arbitrary MIC table and produce a phenotype distance
matrix without touching `S. pneumoniae` functions.

## Phase 3: build the generic comparison layer

Goal: make phenotype-vs-external comparison generic.

### Deliverables

- `amrc_prepare_map_data()`
- generic key-column handling
- external-distance integration docs
- tests that do not mention PBP types

### Exit criterion

A user can compare a phenotype map to any aligned external distance structure or
external map.

## Phase 4: turn `S. pneumoniae` into a worked example

Goal: reframe the organism-specific code as example infrastructure.

### Deliverables

- keep `amrc_build_spneumoniae_example_outputs()` and related helpers, but move
  their documentation into an example-data section
- create a dedicated case-study vignette for `S. pneumoniae`
- stop using `S. pneumoniae` wrappers as the first functions shown in the
  README

### Exit criterion

The example is clearly a case study, not the package identity.

## Phase 5: deprecate species-specific public names where possible

Goal: clean the public namespace.

### Deliverables

- add generic replacement functions
- add deprecation warnings or lifecycle notes for the exported
  `S. pneumoniae`-named analysis functions
- keep example-build helpers if still useful, but clearly label them as
  example-specific

### Exit criterion

The public API a new user sees is generic first.

## Phase 6: rewrite documentation around the generic story

Goal: make the README, vignettes, and manuscript reflect the real package goal.

### Deliverables

- README starts with generic MIC workflow
- add a generic vignette, for example:
  - "Using amrcartography with your own MIC table"
- keep `S. pneumoniae` vignette as a second case-study vignette
- update manuscript framing so the package contribution is generic and the case
  study is illustrative

### Exit criterion

A new user reading the repo understands immediately that the package is for
arbitrary MIC datasets.

## Testing strategy for generalisation

The package should no longer rely on one organism-specific example as the main
proof that the API works.

### Add three test tiers

#### Tier 1: generic toy fixtures

Use tiny synthetic MIC datasets that are clearly not tied to `S. pneumoniae`.

These should test:

- MIC validation
- transformation
- distance construction
- map fitting
- clustering
- comparison table assembly

#### Tier 2: organism-specific reference fixtures

Keep the `S. pneumoniae` fixtures as regression tests for the example pipeline.

These should prove:

- the example workflow still reproduces the intended case study
- refactors to generic functions do not silently break the example

#### Tier 3: documentation tests

Make sure:

- the generic vignette builds
- the `S. pneumoniae` case-study vignette builds
- the README code paths remain valid

## Documentation strategy

The package should have two clearly separated documentation stories.

### Story 1: general users

Main docs should answer:

- What shape should my MIC data be in?
- How do I build a map from my own data?
- How do I diagnose fit quality?
- How do I cluster and compare structures?

### Story 2: example and validation

Secondary docs should answer:

- How does the `S. pneumoniae` case study work?
- How does it relate to the earlier AMR cartography analyses?
- How do I rebuild the example outputs used in the repo?

## Release criteria for the "generic-first" milestone

Do not call the package genuinely general-purpose until all of the following are
true:

- the primary README workflow uses generic function names only
- the first vignette is generic, not `S. pneumoniae`-specific
- a user can start from an arbitrary MIC table without calling an
  organism-specific function
- a user can compute and diagnose a phenotype map without touching legacy
  notebook code
- comparison helpers no longer assume `PBP_type`
- the `S. pneumoniae` analysis is documented as an example/case study
- CI includes tests for generic toy data as well as the example dataset

## Immediate next actions

1. Write and export the generic MIC preprocessing layer.
2. Rename or replace `amrc_prepare_spneumoniae_map_data()` with a generic map
   preparation function.
3. Add a generic vignette using a small synthetic or anonymised MIC table.
4. Rewrite the README so the first workflow is generic and the pneumococcal
   example comes second.
5. Move `S. pneumoniae`-specific functions into an "example data and case-study"
   section of the docs.
6. Add lifecycle notes for organism-specific wrappers that should not define the
   long-term public API.

## Bottom line

The package should evolve from:

"a package-backed reproduction of the pneumococcal AMR cartography workflow"

to:

"a general R toolkit for MIC cartography, with `S. pneumoniae` retained as a
worked case study and validation example."
