# Streamlit Prototype

This directory contains an experimental Streamlit front end for the generic
`amrcartography` workflow.

The app intentionally renders package-backed plots using the manuscript-aligned
cartography style, so the visual language stays consistent across the original
analysis scripts, package helpers, and app outputs.

Current scope:

- upload a phenotype MIC CSV
- choose ID, MIC, and metadata columns
- clean and standardise MIC values
- compute a phenotype distance matrix and MDS map
- optionally cluster the phenotype map with configurable `k` and join-key
  controls
- cluster scree/elbow diagnostics for phenotype and external map clustering
- scree tables surfaced alongside the elbow plots in the UI
- optionally upload an external/genotype structure as:
  - a precomputed distance matrix
  - a numeric feature table
  - a character-state feature table
  - an aligned sequence/allele table
- fit an external map
- generate a side-by-side phenotype/external map comparison
- optionally cluster the external map with the same controls
- optionally compute reference-distance summaries against a selected metadata
  group or isolate
- filter reference-distance summaries by a chosen metadata column/value set
- adjust reference-distance plot axis limits
- adjust reference-distance plot break spacing
- add optional annotation text/coordinates to the reference-distance plot
- download the raw output tables plus a bundled `.rds` result object

Deliberately not in v1:

- mixed-model scans
- epistasis/permutation workflows
- notebook-specific figure layouts
- full clustering/association orchestration

## Run

Python environment:

```bash
pip install -r streamlit_app/requirements.txt
```

R environment:

- `Rscript` must be available
- either install `amrcartography`, or have `pkgload` available so the backend
  can load the package from the repo checkout
- `jsonlite` and `ggplot2` must be installed in the R library

Start the app from the repo root:

```bash
streamlit run streamlit_app/app.py
```

## Known limitation

This repo still has a local macOS/OpenMP shared-memory issue in some R runs on
this machine. The app files parse cleanly, but full backend execution should be
treated as authoritative only once it is validated in a Linux environment or in
an R setup that does not hit the existing `OMP: Error #179` problem.

## Expected external input shapes

`precomputed_distance`:

- CSV with one ID column
- remaining columns form a square symmetric distance matrix

`numeric_features`, `character_features`, `sequence_alleles`:

- one row per isolate
- one ID column
- one or more selected feature columns

## Next logical app steps

- advanced association tabs
- downloadable report exports once the UI is stable enough to define them
- broader UI polish once the workflow surface stabilises
