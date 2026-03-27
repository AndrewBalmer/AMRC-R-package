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
- small generated example fixtures if added later for tests

### Does not ship in the repository by default

- raw externally hosted supplementary CSV files downloaded from Springer
- large generated distance matrices and `.RData` workspaces
- locally rendered analysis outputs and figure caches

### Does not ship in the package for now

- raw phenotype and genotype source files
- large derived matrices
- manuscript-era exploratory `.RData` objects

### Generated on demand

- processed phenotype MIC tables
- processed phenotype metadata tables
- phenotype distance matrices
- processed genotype sequence matrices
- genotype distance matrices

### Currently unresolved

- `MIC_S.Pneumo_metadata.csv`
- `Meta_data_spneumoniae_isolates_post_2015.csv`

These two files are referenced by the deferred external-variable notebook and
are not currently available in the repository. That notebook is intentionally
out of scope until the source and redistribution status of those files are clear.

## Working rules

- Treat `data-raw/data-provenance.csv` as the source-of-truth manifest.
- Add every newly referenced external input to that manifest before writing more analysis code.
- Prefer download-on-demand plus a manifest over committing third-party raw data unless redistribution has been checked.
- Keep generated artefacts reproducible from scripts rather than treating them as hand-managed inputs.
