# amrcartography

`amrcartography` is the start of a reproducible R package for the AMR cartography project. The long-term goal is to turn the current analysis scripts into a reusable toolkit for importing MIC data, building phenotype and genotype distance structures, generating AMR cartography maps, and reproducing the core analyses behind the project manuscript.

The repository currently contains two things in parallel:

- the original legacy analysis scripts in `01-Phenotype_and_map_analyses/`
- a new package-oriented scaffold that makes the project easier to install, document, test, and extend

## Current status

This repository is now set up as an R package development project, but it is not yet a complete replacement for every legacy notebook. The package scaffold, environment scripts, migration roadmap, and initial reusable functions are in place. The existing scripts remain the source of truth for the published workflow and should be treated as legacy references while we extract stable functions into `R/`.

## Package identity

- Package name: `amrcartography`
- Maintainer: Andrew Balmer
- Maintainer email: `ab69@sanger.ac.uk`
- License: MIT

## What is in the repo

- `R/`: early package functions for data download, phenotype preprocessing, genotype preprocessing, and MDS helpers
- `docs/ROADMAP.md`: ordered package-conversion to-do list
- `docs/ROADMAP.pdf`: shareable PDF version of the roadmap
- `docs/SCRIPT_AUDIT.md`: script-by-script migration audit
- `docs/PACKAGE_IDENTITY.md`: frozen package identity decisions
- `docs/DATA_PROVENANCE.md`: provenance rules for what ships with the repo and what stays external
- `tools/check_environment.R`: checks whether the local R environment has the packages needed for package work and legacy script execution
- `tools/install_packages.R`: installs the package-development and legacy-analysis dependencies used in this repository
- `tools/bootstrap_renv.R`: creates or refreshes a project-local `renv` environment and lockfile
- `tools/build_spneumoniae_example_data.R`: reproducible helper script for downloading and processing the example S. pneumoniae source files
- `inst/extdata/spneumoniae_source_manifest.csv`: manifest of the external example data files referenced by the legacy scripts
- `data-raw/data-provenance.csv`: frozen manifest of external and generated data assets referenced in the workflow
- `01-Phenotype_and_map_analyses/`: original scripts and notebooks, preserved for migration
- `Previous_AMRC_manuscript/`: previous manuscript artefacts and supporting files

## Key reproducibility issues found in the legacy workflow

- most scripts use hard-coded absolute paths under `/Users/ajb306/...`
- intermediate outputs are written outside the repository
- the analysis depends on many packages, but the environment was not previously captured
- several scripts assume prior `.RData` objects already exist
- script `08-Mapping-external-variables.Rmd` references additional metadata files that are not present in the repository
- several notebooks mix reusable transformations with figure-specific code, making them hard to package directly

## Quick start

1. Open the project in R from the repository root.
2. Run `Rscript tools/check_environment.R` to see what is already installed.
3. For a project-local reproducible environment, run `Rscript tools/bootstrap_renv.R`.
4. Once `renv.lock` exists, collaborators can restore the same environment with `Rscript -e 'renv::restore()'`.
5. If you prefer to install into your usual R library instead, run `Rscript tools/install_packages.R`.
6. Use `Rscript tools/build_spneumoniae_example_data.R` to download and process the bundled example source data into a reproducible local folder structure.
7. Treat the files in `R/` as the package API under active development, and the files in `01-Phenotype_and_map_analyses/` as migration references.

## Recommended migration strategy

- freeze the legacy scripts as historical inputs
- extract repeated transformations into tested functions
- replace all `setwd()` usage with explicit paths and function arguments
- standardise data objects and file formats
- reproduce each analysis figure from package functions before retiring the corresponding notebook

The detailed ordered plan lives in [docs/ROADMAP.md](docs/ROADMAP.md), and the script-by-script breakdown lives in [docs/SCRIPT_AUDIT.md](docs/SCRIPT_AUDIT.md).

## Notes

- The interactive app idea is intentionally deferred until the package API and reproducible data flow are stable.
- The notebook that depends on the missing extra metadata files has been deferred for now and is explicitly called out in the provenance documentation.
