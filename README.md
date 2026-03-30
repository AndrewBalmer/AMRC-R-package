# amrcartography

> Work-in-progress notice: this repository is under active development and is provided as-is. It may change substantially, and it should not yet be treated as a stable release.
>
> This is the package/code repository only. It is not the source repository for the related manuscript, which is maintained separately.

`amrcartography` is an R package for reusable MIC cartography workflows. The
main goal of the package is to let users bring their own MIC dataset, build
phenotypic maps, compare those maps to an external distance structure when
available, and reuse the same calibration, robustness, clustering, and plotting
tools across datasets.

The repository still contains the migrated *S. pneumoniae* analysis because it
is useful as a worked example and regression target, but that case study is not
the primary purpose of the package.

The package is now at the point where it has:

- a locked package identity and reproducible environment setup
- generic MIC validation, standardisation, and distance helpers
- reusable MDS, robustness, clustering, calibration, and comparison helpers
- explicit support for precomputed, numeric-feature, and character-feature
  external data structures
- a package-backed *S. pneumoniae* case study for example and regression use
- deterministic and fixture-based regression tests

## Status

This is still a GitHub release rather than a CRAN release, and the repository
should be used as-is. The current public milestone is `0.1.0`: the generic API
is now intentionally usable, but the package is still being prepared for
manuscript-centered release and long-term API stabilisation. This repository is
also separate from the related manuscript
repository: it contains the package, migrated analysis code, and development
documentation, not the manuscript submission source itself. The long-term
package goal is a generic MIC cartography toolkit; the current
*S. pneumoniae* workflow should be read as a worked example and validation
case, not the permanent center of the public API. Any interactive app remains
explicitly deferred until the manuscript workflow and exported API stop
moving.

## Installation

For day-to-day package use, install from GitHub:

```r
install.packages("remotes")
remotes::install_github("AndrewBalmer/AMRC-R-package")
```

For repository development and exact dependency capture, use the project-local `renv` environment instead:

```r
source("renv/activate.R")
renv::restore()
```

## Quick Start

Start with the generic vignette if you want to use your own MIC table:

```r
vignette("using-your-own-mic-data", package = "amrcartography")
```

If you want help choosing and preparing the external structure that will be
compared to a phenotype map, use:

```r
vignette("external-data-structures", package = "amrcartography")
```

The *S. pneumoniae* case-study vignette is still available separately:

```r
vignette("end-to-end-spneumoniae", package = "amrcartography")
```

You can also locate the bundled *S. pneumoniae* example files directly:

```r
library(amrcartography)

amrc_spneumoniae_example_paths("mini_raw")
```

The `mini_raw` example is a tiny raw-input workflow intended for the
case-study vignette and CI. The larger notebook-scale generated outputs are not
bundled in the installed package; build them locally when you need the full
repository workflow.

The core object contracts used throughout these workflows are documented in
[docs/OBJECT_CONTRACTS.md](docs/OBJECT_CONTRACTS.md).

## Generic Workflow

This is the generic package workflow for an arbitrary MIC table:

1. Validate and standardise the MIC table with `amrc_standardise_mic_data()`.
2. Build a phenotype distance matrix with `amrc_compute_mic_distance()`.
3. Fit and diagnose a phenotype map with `amrc_compute_mds()` and `amrc_map_fit_report()`.
4. Optionally standardise an external distance structure with `amrc_compute_external_distance()` or build one from aligned feature data with `amrc_compute_external_feature_distance()`.
5. Fit an external map with `amrc_compute_mds()`.
6. Build a shared phenotype/external comparison table with `amrc_prepare_map_data()`.
7. Cluster either map with `amrc_cluster_map()` and attach labels with `amrc_add_cluster_assignments()`.
8. Summarise distances from a chosen reference entry with `amrc_compute_reference_distance_table()` and `amrc_summarise_reference_distance_table()`.

For example:

```r
library(amrcartography)

mic_data <- amrc_standardise_mic_data(
  data = my_mic_table,
  id_col = "isolate_id",
  mic_cols = c("drug_a", "drug_b", "drug_c"),
  metadata_cols = c("country", "lineage"),
  transform = "log2"
)

phenotype_distance <- amrc_compute_mic_distance(mic_data)
phenotype_map <- amrc_compute_mds(phenotype_distance)
phenotype_report <- amrc_map_fit_report(phenotype_map)

external_distance <- amrc_compute_external_feature_distance(
  data = my_external_feature_table,
  id_col = "isolate_id"
)
external_map <- amrc_compute_mds(external_distance)

comparison_bundle <- amrc_prepare_map_data(
  metadata = mic_data$metadata,
  phenotype_mds = phenotype_map,
  external_mds = external_map,
  id_col = "isolate_id",
  group_col = "lineage"
)

reference_distances <- amrc_compute_reference_distance_table(
  data = comparison_bundle$data,
  reference_value = "lineage_A",
  reference_col = "lineage",
  phenotype_distance_col = "phenotype_distance",
  external_distance_col = "external_distance"
)
```

If you only need phenotype cartography, you can stop after the MIC
standardisation, distance, and phenotype-map steps.

## External Data Formats

The package currently supports three generic ways to bring in the non-MIC
structure you want to compare against the phenotype map:

- a precomputed external distance matrix via `amrc_compute_external_distance()`
- an aligned numeric feature table via `amrc_standardise_external_data()` and
  `amrc_compute_external_feature_distance()`
- an aligned character-state feature table via
  `amrc_standardise_external_data(feature_mode = "character")` and
  `amrc_compute_external_feature_distance()`

The dedicated external-data vignette walks through those options with small
reproducible examples.

## S. pneumoniae Case Study

The organism-specific `S. pneumoniae` helpers remain in the package as
case-study infrastructure, legacy-migration support, and regression targets.
They are still useful when you want to reproduce the migrated pneumococcal
workflow or rebuild the notebook-scale example outputs from the bundled raw
example inputs.

The main case-study wrappers are:

- `amrc_process_spneumoniae_phenotype()`
- `amrc_process_spneumoniae_genotype()`
- `amrc_prepare_spneumoniae_map_data()`

Those functions remain supported for compatibility, but they should be read as
example-specific wrappers rather than the long-term primary API. In `0.1.0`
they remain documented and supported, but they are soft-deprecated as the
recommended entry points for new analyses.

For lightweight case-study runs, prefer the bundled `mini_raw` example or the
`sample_n` arguments in the case-study preprocessing wrappers rather than the
full notebook-scale dataset.

For maintainers, the current keep-vs-deprecate decisions are recorded in
[docs/API_LIFECYCLE.md](docs/API_LIFECYCLE.md).

If you want to reconstruct the larger packaged example outputs from the raw example inputs, use:

```r
out_dir <- tempfile("amrc-spneumoniae-generated-")

amrc_build_spneumoniae_example_outputs(
  raw_dir = tempfile("amrc-spneumoniae-raw-"),
  out_dir = out_dir,
  download_missing = TRUE
)

amrc_build_spneumoniae_example_maps(generated_dir = out_dir)
```

If you are working in a source checkout and want the conventional local
generated-output location used by the legacy notebooks, you can inspect it
with:

```r
amrc_spneumoniae_example_paths("generated", mustWork = FALSE)
```

## Expected Runtime

- The generic toy-data vignette workflow should run in seconds.
- The bundled `mini_raw` vignette workflow should run in seconds.
- Rebuilding the full notebook-scale *S. pneumoniae* outputs and maps from raw example inputs can take several minutes, especially on a laptop.
- The full notebook-scale case-study MDS fits are much heavier than the package examples and should not be treated as the default entry point for learning the package.
- Full notebook-style robustness and manuscript analyses are slower again and should be treated as heavier workflows.

## Data Provenance

The package now separates what ships in the repository from what is downloaded or generated locally.

- Narrative provenance policy: [docs/DATA_PROVENANCE.md](docs/DATA_PROVENANCE.md)
- Machine-readable provenance manifest: [data-raw/data-provenance.csv](data-raw/data-provenance.csv)
- Package conversion roadmap: [docs/ROADMAP.md](docs/ROADMAP.md)
- Script-by-script migration audit: [docs/SCRIPT_AUDIT.md](docs/SCRIPT_AUDIT.md)
- Release checklist: [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)
- Object contracts: [docs/OBJECT_CONTRACTS.md](docs/OBJECT_CONTRACTS.md)
- GitHub release notes draft: [docs/RELEASE_NOTES_0.1.0.md](docs/RELEASE_NOTES_0.1.0.md)
- Manuscript scaffold: [docs/MANUSCRIPT_DRAFT.md](docs/MANUSCRIPT_DRAFT.md)
- API lifecycle notes: [docs/API_LIFECYCLE.md](docs/API_LIFECYCLE.md)

## How To Cite

The repository now includes both a GitHub citation file at [CITATION.cff](CITATION.cff) and a standard package citation via `citation("amrcartography")`. For the current publication workflow, the package should be cited as the `0.1.0` software release; once the package manuscript is finalized, the citation text should be updated to cite both the software and the paper.

## Repository Layout

- `R/`: package functions
- `vignettes/`: user-facing generic and case-study worked examples
- `tests/testthat/`: deterministic and fixture-based regression tests
- `tools/`: environment/bootstrap/build helpers
- `01-Phenotype_and_map_analyses/`: legacy notebooks being migrated onto the package API

## Current Caveat

`08-Mapping-external-variables.Rmd` still depends on metadata files that are not currently in the repository, so full manuscript-level reproducibility still requires either recovering those files or rewriting that section around available inputs.
