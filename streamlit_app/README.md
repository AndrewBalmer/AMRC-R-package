# Streamlit Prototype

This directory contains an experimental Streamlit front end for the generic
`amrcartography` workflow.

The app intentionally renders package-backed plots using the manuscript-aligned
cartography style, so the visual language stays consistent across the original
analysis scripts, package helpers, and app outputs.

Current scope:

- load a bundled generic example dataset with one click for QA/demo runs
- upload a phenotype MIC CSV
- choose ID, MIC, and metadata columns
- clean and standardise MIC values
- compute a phenotype distance matrix and MDS map
- calibrate maps onto MIC-style units using the package calibration model
- optional post-calibration rotation controls for phenotype and external maps
  plus quick preset buttons for common manuscript/thesis orientations
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
- download a zipped output bundle for each run
- export Markdown/HTML analysis reports from each run
- optionally export a lightweight PDF report

Deliberately not in v1:

- mixed-model scans
- epistasis/permutation workflows
- browser-polished manuscript figure presets beyond the current package-backed
  plot compositions
- full clustering/association orchestration
- a free-form manual dilation slider: the intended route to 1-MIC spacing is
  the package calibration model, not arbitrary rescaling

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

## Calibration note

If you want one-unit grid spacing to mean one doubling dilution, follow the
package calibration step. The app exposes post-calibration rotation controls,
but the dilation itself comes from `amrc_fit_distance_calibration()` /
`amrc_calibrate_mds()` so the scaling stays consistent with the manuscript and
thesis figures.

## Bundled demo mode

The sidebar includes quick demo buttons for:

- generic MIC only
- generic MIC plus numeric external features
- generic MIC plus character external features

These are intended for QA, screenshots, and style checks without having to
prepare upload files first.

## Lightweight UI QA

If `streamlit` is installed with testing support, you can run the app shell
contract check:

```bash
python3 streamlit_app/check_ui_contract.py
```

For manual browser-level QA, use:

- [streamlit_app/UI_QA_CHECKLIST.md](UI_QA_CHECKLIST.md)

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
- broader UI polish once the workflow surface stabilises
