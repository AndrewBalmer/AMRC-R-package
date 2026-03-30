# amrcartography

[![R-CMD-check](https://github.com/AndrewBalmer/AMRC-R-package/actions/workflows/r-cmd-check.yaml/badge.svg)](https://github.com/AndrewBalmer/AMRC-R-package/actions/workflows/r-cmd-check.yaml)

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
- a package-backed *S. pneumoniae* case study for example and regression use
- deterministic and fixture-based regression tests

## Status

This is still a development release rather than a CRAN release, and the
repository should be used as-is. The exported API is now usable, but some
notebook migrations, generic-first documentation changes, and release-facing
cleanup are still ongoing, so interfaces and bundled examples may still
change. This repository is also separate from the related manuscript
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

## Generic Workflow

This is the generic package workflow for an arbitrary MIC table:

1. Validate and standardise the MIC table with `amrc_standardise_mic_data()`.
2. Build a phenotype distance matrix with `amrc_compute_mic_distance()`.
3. Fit and diagnose a phenotype map with `amrc_compute_mds()` and `amrc_map_fit_report()`.
4. Optionally standardise an external distance structure with `amrc_compute_external_distance()`.
5. Fit an external map with `amrc_compute_mds()`.
6. Build a shared phenotype/external comparison table with `amrc_prepare_map_data()`.
7. Cluster either map with `amrc_cluster_map()` and attach labels with `amrc_add_cluster_assignments()`.

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

external_distance <- amrc_compute_external_distance(
  my_external_distance_matrix,
  isolate_ids = mic_data$isolate_ids
)
external_map <- amrc_compute_mds(external_distance)

comparison_bundle <- amrc_prepare_map_data(
  metadata = mic_data$metadata,
  phenotype_mds = phenotype_map,
  external_mds = external_map,
  id_col = "isolate_id",
  group_col = "lineage"
)
```

If you only need phenotype cartography, you can stop after the MIC
standardisation, distance, and phenotype-map steps.

## S. pneumoniae Case Study

The organism-specific `S. pneumoniae` helpers remain in the package as
case-study infrastructure, legacy-migration support, and regression targets.
They are still useful when you want to reproduce the migrated pneumococcal
workflow or rebuild the notebook-scale example outputs from the bundled raw
example inputs.

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
- Full notebook-style robustness and manuscript analyses are slower again and should be treated as heavier workflows.

## Data Provenance

The package now separates what ships in the repository from what is downloaded or generated locally.

- Narrative provenance policy: [docs/DATA_PROVENANCE.md](docs/DATA_PROVENANCE.md)
- Machine-readable provenance manifest: [data-raw/data-provenance.csv](data-raw/data-provenance.csv)
- Package conversion roadmap: [docs/ROADMAP.md](docs/ROADMAP.md)
- Script-by-script migration audit: [docs/SCRIPT_AUDIT.md](docs/SCRIPT_AUDIT.md)
- Release checklist: [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)
- Manuscript scaffold: [docs/MANUSCRIPT_DRAFT.md](docs/MANUSCRIPT_DRAFT.md)

## How To Cite

The repository now includes both a GitHub citation file at [CITATION.cff](CITATION.cff) and a standard package citation via `citation("amrcartography")`. For now, cite the package/software record; once the package manuscript is finalized, the README and citation text should be updated to cite both the software and the paper.

## Repository Layout

- `R/`: package functions
- `vignettes/`: user-facing generic and case-study worked examples
- `tests/testthat/`: deterministic and fixture-based regression tests
- `tools/`: environment/bootstrap/build helpers
- `01-Phenotype_and_map_analyses/`: legacy notebooks being migrated onto the package API

## Current Caveat

`08-Mapping-external-variables.Rmd` still depends on metadata files that are not currently in the repository, so full manuscript-level reproducibility still requires either recovering those files or rewriting that section around available inputs.
