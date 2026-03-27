# amrcartography news

## 0.1.0.9000

First usable package-development release of `amrcartography`.

### Reproducibility and infrastructure

- Formalised the repository as an R package with `DESCRIPTION`, `NAMESPACE`, generated man pages, tests, and packaged example data.
- Captured the project environment with `renv` and added environment/bootstrap helpers under `tools/`.
- Added GitHub Actions `R-CMD-check` for hosted build/check validation.
- Added a release checklist and manuscript scaffold in `docs/`.

### Data and preprocessing

- Made phenotype preprocessing canonical with `amrc_process_spneumoniae_phenotype()`.
- Made genotype preprocessing canonical with `amrc_process_spneumoniae_genotype()`.
- Frozen external/generated data provenance in `docs/DATA_PROVENANCE.md` and `data-raw/data-provenance.csv`.
- Shortened packaged generated genotype-distance filenames to portable names and added backward-compatible path lookup helpers.
- Added bundled mini raw-input example files and packaged generated example paths.

### Analysis API

- Added reusable MDS, calibration, goodness-of-fit, robustness, clustering, dimensionality, and phenotype/genotype comparison helpers.
- Added shared plotting helpers so notebooks can call package code instead of carrying private plotting logic.
- Added packaged helpers for locating example inputs and outputs.

### Notebook migration

- Rebuilt the phenotype/genotype map-generation workflow around package helpers.
- Migrated the dimensionality, clustering, and side-by-side phenotype/genotype comparison notebooks onto the package API.
- Reduced remaining dependence on hard-coded paths and notebook-local data assembly.

### Testing and validation

- Added deterministic unit tests for map-building, robustness, and the new clustering/comparison helpers.
- Added fixture-based regression tests for preprocessing outputs, map summaries, goodness-of-fit summaries, and robustness summaries.
- Local validation now passes with `testthat::test_local(".")` and `R CMD check --no-manual --ignore-vignettes`.

### Documentation

- Rewrote the README around installation, examples, runtime expectations, provenance, and release-facing guidance.
- Added the user-facing end-to-end vignette `end-to-end-spneumoniae`.
- Added manuscript planning and release-checklist documents.
- Added `CITATION.cff`, a standard `inst/CITATION`, and README citation guidance.
