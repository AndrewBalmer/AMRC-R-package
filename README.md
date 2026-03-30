# amrcartography

[![R-CMD-check](https://github.com/AndrewBalmer/AMRC-R-package/actions/workflows/r-cmd-check.yaml/badge.svg)](https://github.com/AndrewBalmer/AMRC-R-package/actions/workflows/r-cmd-check.yaml)

> Work-in-progress notice: this repository is under active development and is provided as-is. It may change substantially, and it should not yet be treated as a stable release.
>
> This is the package/code repository only. It is not the source repository for the related manuscript, which is maintained separately.

`amrcartography` is an R package for reproducible AMR cartography workflows. It is being extracted from the legacy AMR cartography analysis repository so that other users can preprocess MIC data, build phenotype and genotype maps, and reproduce the comparison analyses without relying on project-specific paths or manually created `.RData` files.

The package is now at the point where it has:

- a locked package identity and reproducible environment setup
- canonical phenotype and genotype preprocessing functions
- reusable MDS, robustness, clustering, and comparison helpers
- package-backed versions of the main phenotype/genotype notebooks
- deterministic and fixture-based regression tests

## Status

This is still a development release rather than a CRAN release, and the repository should be used as-is. The exported API is now usable, but some notebook migrations and release-facing cleanup are still ongoing, so interfaces and bundled examples may still change. This repository is also separate from the related manuscript repository: it contains the package, migrated analysis code, and development documentation, not the manuscript submission source itself. The long-term package goal is a generic MIC cartography toolkit; the current `S. pneumoniae` workflow should be read as a worked example and validation case, not the permanent center of the public API. Any interactive app remains explicitly deferred until the manuscript workflow and exported API stop moving.

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

The fastest way to see the API is the end-to-end vignette:

```r
vignette("end-to-end-spneumoniae", package = "amrcartography")
```

You can also locate the bundled example files directly:

```r
library(amrcartography)

amrc_spneumoniae_example_paths("mini_raw")
```

The `mini_raw` example is a tiny raw-input workflow intended for quick learning and CI. The larger notebook-scale generated outputs are not bundled in the installed package; build them locally when you need the full repository workflow.

## Example Workflow

This is the typical package workflow:

1. Preprocess phenotype inputs with `amrc_process_spneumoniae_phenotype()`.
2. Preprocess genotype inputs with `amrc_process_spneumoniae_genotype()`.
3. Fit phenotype and genotype maps with `amrc_compute_mds()`.
4. Build a shared phenotype/genotype comparison table with `amrc_prepare_spneumoniae_map_data()`.
5. Cluster the genotype map with `amrc_cluster_map()` and attach cluster labels with `amrc_add_cluster_assignments()`.
6. Summarise phenotype-vs-genotype relationships with `amrc_compute_reference_distance_table()` and `amrc_summarise_reference_distance_table()`.

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

If you are working in a source checkout and want the conventional local generated-output location used by the legacy notebooks, you can inspect it with:

```r
amrc_spneumoniae_example_paths("generated", mustWork = FALSE)
```

## Expected Runtime

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
- `vignettes/`: user-facing worked examples
- `tests/testthat/`: deterministic and fixture-based regression tests
- `tools/`: environment/bootstrap/build helpers
- `01-Phenotype_and_map_analyses/`: legacy notebooks being migrated onto the package API

## Current Caveat

`08-Mapping-external-variables.Rmd` still depends on metadata files that are not currently in the repository, so full manuscript-level reproducibility still requires either recovering those files or rewriting that section around available inputs.
