# amrcartography news

## 0.1.1 (2026-04-01)

Patch release that promotes the post-`v0.1.0` generic analysis additions to the
current validated public baseline.

### Generic MIC data handling

- Added more tolerant generic MIC cleaning for censored and irregular raw
  values, including strings such as `<`, `<=`, `>`, `>=`, `~`, and similar
  non-numeric prefixes around reported MIC values.
- Added bundled generic example datasets for MIC tables, external numeric
  features, external character-state features, and precomputed external
  distances.

### Advanced genotype-to-phenotype analysis

- Added the advanced mixed-model and prediction toolkit, including generic
  helpers for LIMIX-backed LMM/mvLMM workflows, permutation scans, epistatic
  scans, heritability estimation, variance decomposition, and kinship-based
  prediction utilities.

### Validation and CI

- Fixed the remaining Ubuntu `R-CMD-check` warnings in the release workflow.
- Tightened vignette/check workflow handling so the Linux release leg is the
  current authoritative validation baseline for this patch release.

## 0.1.0 (2026-03-30)

First public GitHub release of `amrcartography` as a generic MIC cartography
toolkit, with the `S. pneumoniae` workflow retained as a worked example and
regression target rather than the package’s primary identity.

### Generic-first API

- Added generic MIC validation, standardisation, and distance helpers for
  arbitrary isolate-by-drug MIC tables.
- Added generic external-data helpers for precomputed distance matrices,
  aligned numeric feature tables, and aligned character-state feature tables.
- Added reusable map-comparison, clustering, calibration, robustness, and
  reference-distance helpers designed to work across datasets rather than only
  the pneumococcal case study.
- Updated the robustness and dimensionality helpers so isolate identifiers are
  no longer silently hard-coded as `LABID`.

### Case-study lifecycle

- Kept `amrc_process_spneumoniae_phenotype()`,
  `amrc_process_spneumoniae_genotype()`, and
  `amrc_prepare_spneumoniae_map_data()` as supported case-study wrappers for
  compatibility.
- Clarified in the README and lifecycle docs that those pneumococcal wrappers
  are example-facing compatibility helpers rather than the long-term primary
  analysis API.
- Kept the `S. pneumoniae` example-build helpers public as permanent
  case-study infrastructure.

### Validation, testing, and CI

- Fixed the audit issues in the generic workflow, robustness, plotting, and
  reference-distance code paths.
- Expanded deterministic and fixture-based tests, including generic workflow
  coverage that now runs locally on macOS as well as in CI.
- Added stronger local and hosted validation of vignette rebuilding and
  documentation-facing workflows.
- Local validation for this release passes with:
  - `testthat::test_local(".")`
  - full vignette-inclusive `R CMD build`
  - full `R CMD check --as-cran --no-manual`

### Documentation and examples

- Rewrote the README around the generic “bring your own MIC table” story.
- Added the generic vignette `using-your-own-mic-data`.
- Added the generic vignette `external-data-structures`.
- Kept `end-to-end-spneumoniae` as a separate case-study vignette.
- Added explicit object-contract documentation for the package’s core data and
  result structures.
- Added release-facing metadata, citation cleanup, and release-note scaffolding
  for a tagged public milestone.

### Reproducibility and infrastructure

- Formalised the repository as an R package with generated man pages, tests,
  packaged example data, and a reproducible `renv` environment.
- Frozen external/generated data provenance in `docs/DATA_PROVENANCE.md` and
  `data-raw/data-provenance.csv`.
- Added release checklist, API lifecycle notes, manuscript draft scaffolding,
  and first-release GitHub notes under `docs/`.
