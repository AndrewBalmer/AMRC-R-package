# amrcartography news

## 0.2.0 (2026-04-01)

Minor release candidate that promotes the new generic genotype-to-phenotype
postprocessing layer beyond the `0.1.x` patch line.

### Generic group-contrast analysis

- Added generic helpers for within-group metadata dispersion summaries.
- Added generic one-feature contrast discovery and summarisation helpers.
- Added generic cluster-difference feature summaries based on state-frequency
  shifts.
- Added informative-isolate selection helpers for two-cluster contrasts.

### Generic association postprocessing

- Added marker-matrix preprocessing helpers for invariant-marker filtering and
  duplicate/inverse collapse handling.
- Added model-comparison helpers for adjusted-versus-unadjusted association
  scans, including explicit full-outer-join presence tracking.
- Added long-form ranking and cross-method feature-overlap helpers.

### Generic workflow and visualisation

- Added a reusable cluster-to-feature workflow helper for the common pattern
  "subset one outer cluster, identify phenotype subclusters, then summarise
  differentiating markers".
- Added external benchmark join helpers for comparing package results against
  literature, GWAS, or laboratory-validation tables.
- Added effect-direction categorisation helpers for two-dimensional effect-size
  interpretation.
- Added generic plotting helpers for:
  - top-group faceted maps
  - within-group dispersion histograms
  - side-by-side phenotype/external map panels
  - cluster-difference feature rankings
  - adjusted-vs-unadjusted association comparisons
  - effect-direction summaries
  - cross-method overlap visualisation
  - heritability and variance-decomposition summaries

### Validation

- Fixed the critical review issues in the new helper layer:
  - missing-group validation for one-feature contrast summaries
  - explicit identifier-column inference failure in informative-isolate
    selection
  - clearer outer-join semantics in association-model comparison
- Added targeted error-path tests for the new helper functions.
- Authoritative Linux CI passed for the feature commit that introduced this
  layer: `62ef521` (`23848748302`).

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
