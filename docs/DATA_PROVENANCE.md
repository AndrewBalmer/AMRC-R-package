# Data Provenance

This file freezes the current data-provenance policy for the AMR cartography
repository.

## Scope

The goal is to make it unambiguous which data assets:

- ship in the repository
- may eventually ship in the package
- are generated locally from reproducible scripts
- must be downloaded on demand
- are currently missing and need source clarification

## Provenance policy

### Ships in the repository

- code, package metadata, and documentation
- historical manuscript artefacts already committed under `Previous_AMRC_manuscript/`
- manifests and provenance tables
- small generated example fixtures and compact public teaching/demo subsets

### Does not ship in the repository by default

- raw externally hosted supplementary CSV files downloaded from Springer
- large generated distance matrices and `.RData` workspaces
- locally rendered analysis outputs and figure caches

### Does not ship in the package for now

- raw phenotype and genotype source files
- large derived matrices
- manuscript-era exploratory `.RData` objects

### Ships in the package now

- generic toy MIC/external examples under `inst/extdata/examples/generic/`
- the compact `mapping_08` pneumococcal case-study bundle under
  `inst/extdata/examples/spneumoniae-08/`
- tiny public cross-species MIC subsets under `inst/extdata/examples/public-mic/`
  now spanning enteric, non-fermenter, and staphylococcal examples
  with source citation notes in `docs/PUBLIC_MIC_EXAMPLE_CITATIONS.md`

### Generated on demand

- processed phenotype MIC tables
- processed phenotype metadata tables
- phenotype distance matrices
- processed genotype sequence matrices
- genotype distance matrices

### Currently unresolved

- full public redistribution of the larger non-mini notebook-scale source data
- whether future public example bundles should remain tiny curated subsets or
  expand further beyond the current small multi-species teaching collection

## Working rules

- Treat `data-raw/data-provenance.csv` as the source-of-truth manifest.
- Add every newly referenced external input to that manifest before writing more analysis code.
- Prefer download-on-demand plus a manifest over committing third-party raw data unless redistribution has been checked.
- Keep generated artefacts reproducible from scripts rather than treating them as hand-managed inputs.
