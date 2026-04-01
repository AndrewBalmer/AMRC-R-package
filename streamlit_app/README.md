# Streamlit Prototype

This directory contains an experimental Streamlit front end for the generic
`amrcartography` workflow.

Current scope:

- upload a phenotype MIC CSV
- choose ID, MIC, and metadata columns
- clean and standardise MIC values
- compute a phenotype distance matrix and MDS map
- optionally upload an external/genotype structure as:
  - a precomputed distance matrix
  - a numeric feature table
  - a character-state feature table
  - an aligned sequence/allele table
- fit an external map
- generate a side-by-side phenotype/external map comparison

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

- cluster controls and cluster overlays
- reference-distance summaries
- download bundles for comparison tables and fit summaries
- advanced association tabs once the package-side mixed-model layer is more
  stable in app form
