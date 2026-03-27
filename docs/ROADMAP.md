# AMR Cartography Package Roadmap

## Planning assumptions

- The working package name is `amrcartography`.
- The first reproducible release should target the `S. pneumoniae` beta-lactam workflow already present in the repo.
- The existing scripts should be preserved as legacy references until each one has been functionally replaced.
- The first public milestone should be a GitHub-installable research package, not a CRAN submission.
- The interactive app should stay out of scope until the package API and reproducible example data are stable.

## Phase 1: Stabilise the repository base

- Remove machine-specific clutter from version control and keep `.DS_Store`, `.Rhistory`, `.RData`, and downloaded raw data out of git.
- Freeze the legacy scripts in place so they remain available for comparison during migration.
- Keep the previous manuscript artefacts in the repo, but treat them as historical reference material rather than executable analysis assets.
- Add a proper package `DESCRIPTION`, `LICENSE`, `NAMESPACE`, `R/`, `tests/`, `inst/extdata/`, `data-raw/`, and reproducibility helper scripts.
- Introduce `renv` for environment capture so the repo stops depending on one local machine.
- Add one environment-check script and one dependency-install script so a new collaborator has an obvious starting point.

## Phase 2: Make data provenance explicit

- Create a source manifest for every external file used by the analysis.
- Separate three data states: raw downloads, processed reproducible artefacts, and package-ready internal objects.
- Stop writing outputs outside the repository.
- Replace all `setwd()` usage with explicit function arguments and project-relative paths.
- Confirm the legal and practical position on redistributing example data inside the package.
- Record citation information for the example datasets in the README and package documentation.
- Identify every file that is currently assumed to exist before a script starts and replace that assumption with a build step.
- Decide which derived objects should be stored as `csv`, which as `rds`, and which should be regenerated on demand.

## Phase 3: Define the minimum viable package API

- Lock down the smallest useful first release rather than trying to package every notebook at once.
- Make the first release able to do four things well: download the example source data, clean MIC phenotype data, clean genotype sequence data, and fit basic AMR cartography MDS maps.
- Standardise function naming, argument conventions, and return objects.
- Decide which functions are specific to the `S. pneumoniae` example and which should be generalized for user-supplied MIC datasets.
- Add validation around required columns, missing values, and common data-shape mistakes.
- Create one helper for repairing spreadsheet-damaged PBP-type labels and reuse it everywhere.
- Create one helper for map rotation and one helper for map dilation/calibration instead of repeating that code across notebooks.

## Phase 4: Convert legacy preprocessing scripts first

- Fully retire the phenotype input script by moving its download, combine, clean, transform, and distance-matrix logic into package functions.
- Verify the phenotype preprocessing against the original outputs on a known dataset.
- Investigate the `add_count()` plus `colnames()` sequence in the phenotype script and decide whether it reflects a bug or an abandoned intermediate step.
- Fully retire the genotype input script by moving its download, merge, clean, exclusion, and distance-matrix logic into package functions.
- Replace ad hoc `.RData` outputs with clearly named reproducible artefacts.
- Build one scripted end-to-end example pipeline that regenerates the example processed data from scratch.

## Phase 5: Refactor map-generation logic into reusable modules

- Extract a single core MDS wrapper with sensible defaults for `ndim`, `type`, `init`, `itmax`, and `eps`.
- Add helper functions for random-start comparisons and dimensionality sweeps rather than keeping those loops inside notebooks.
- Separate exploratory optimisation experiments from package-facing functions.
- Recreate the phenotype and genotype map-generation workflows using the new package functions.
- Decide on one canonical map object structure so downstream diagnostics and plotting functions can share the same interface.
- Save only what downstream steps truly need rather than serializing large temporary workspaces.

## Phase 6: Rebuild diagnostics and robustness analyses on top of the package

- Move goodness-of-fit summaries into a dedicated diagnostics module.
- Create functions for stress-per-point summaries, residual summaries, distance-vs-map regressions, and basic Shepard-style diagnostics.
- Convert the missing-value, noise-added, mixed-input, and thresholding notebooks into reproducible analysis modules that call shared helpers instead of copying code blocks.
- Decide which robustness analyses belong inside the package and which belong in vignettes or manuscript-only analyses.
- Add deterministic seeds and explicit parallel settings wherever resampling is used.
- Store long-running simulation outputs in reproducible file formats and document how to regenerate them.

## Phase 7: Build plotting and reporting layers

- Separate plotting helpers from analysis helpers so users can reuse the computation without inheriting manuscript-specific aesthetics.
- Create plotting functions for phenotype maps, genotype maps, stress summaries, residual histograms, and cluster overlays.
- Move one-off figure tuning and manuscript annotations out of core functions.
- Reproduce the key legacy figures from package outputs as a validation milestone.
- Add at least one vignette that walks a user from raw MIC data to a phenotype map.
- Add one second vignette that compares phenotype and genotype maps using the example dataset.

## Phase 8: Add testing, validation, and quality control

- Add unit tests for small deterministic helpers first.
- Add regression tests for phenotype preprocessing and genotype preprocessing using small fixtures.
- Add snapshot or file-based tests for key summary tables where appropriate.
- Add package checks to a continuous integration workflow once the dependency stack is stable.
- Add a script that runs the minimum reproducible pipeline from scratch and fails loudly when an upstream data source has changed.
- Add performance notes for steps that are expected to take a long time on full datasets.
- Decide what package behavior should be tested on toy fixtures versus full example data.

## Phase 9: Reorganise documentation for users and maintainers

- Keep the README short and task-oriented for new users.
- Maintain a separate script-audit document for maintainers so the migration status stays explicit.
- Document the required input schema for user-supplied MIC datasets.
- Document how genotype data should be formatted if users want genotype-map support.
- Add a package website later, but only after the public API stops changing week to week.
- Write a changelog once the first tagged release is close.

## Phase 10: Prepare the first public release

- Decide on a stable package name, maintainer email, and final software license.
- Replace placeholder metadata in `DESCRIPTION`.
- Decide whether the example dataset will ship inside the package or be downloaded on demand.
- Tag a first GitHub release once the preprocessing and core map-generation API are stable.
- Create an installation section that works for both fresh users and collaborators who want to reproduce the paper.
- Write a release checklist covering package checks, example pipeline rebuild, README review, and citation metadata.

## Phase 11: Write the companion manuscript

- Do not start the package manuscript before the package API and example workflow are stable enough to cite.
- Frame the paper around the problem the package solves: reproducible cartography of MIC landscapes rather than the codebase alone.
- Include one motivating biological case study using the `S. pneumoniae` dataset already in the project.
- Explain the conceptual workflow clearly: input data, preprocessing, distance calculation, MDS map fitting, calibration, diagnostics, and interpretation.
- Include one figure that shows the end-to-end pipeline and one figure that shows a canonical phenotype map.
- Include one table that tells readers which parts of the legacy workflow are now package functions.
- Provide a reproducibility statement that points readers to the GitHub repository, installation instructions, and example-data pipeline.

## Phase 12: Decide later whether an app is worth it

- Only consider an interactive app after the package functions and processed example data are stable.
- If an app is built, keep it as a thin layer over the package rather than a second codebase with duplicated logic.
- Limit the first app scope to dataset upload, map fitting, simple overlays, and export of figures or coordinates.
- Avoid building an app until you know which package outputs real users actually need most.

## Immediate next actions

- Confirm the intended package name, license, and maintainer metadata.
- Install the missing R dependencies and capture them in `renv`.
- Run the example data build script end to end.
- Regenerate the first phenotype and genotype outputs with package functions.
- Choose the smallest set of legacy figures that must be reproduced before the first release.
- Start extracting the goodness-of-fit and plotting code into dedicated modules only after preprocessing and map generation are locked down.
