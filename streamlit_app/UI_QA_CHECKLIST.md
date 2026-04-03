# Streamlit UI QA Checklist

Use this checklist when doing browser-level QA on the Streamlit prototype.

## Scope

This is a lightweight manual QA pass for the app shell and the stable
phenotype/external workflow. It is not meant to validate the full scientific
correctness of results.

## Before starting

- install Python requirements from `streamlit_app/requirements.txt`
- make sure `Rscript` is available
- make sure the package can be loaded by the backend
- use the bundled generic example CSVs first before trying ad hoc data

## Basic app load

- app opens without a Python traceback
- title shows `amrcartography`
- quick demo buttons render in the sidebar
- sidebar renders the phenotype upload area
- no empty white screen or immediately broken widgets

## Bundled demo workflow

- `MIC only` loads the bundled generic MIC example without uploading a file
- `Numeric ext.` loads the bundled generic MIC + numeric external example
- `Character ext.` loads the bundled generic MIC + character external example
- `Clear demo selection` resets the app back to upload mode
- demo mode still allows a successful run

## Phenotype-only workflow

- upload a phenotype MIC CSV
- ID column selector populates correctly
- MIC column selector populates correctly
- metadata selectors populate correctly
- phenotype rotation control accepts values without breaking the run
- phenotype rotation preset buttons update the numeric control sensibly
- if `Use 1-unit grid spacing` is enabled, remember this should be interpreted
  as one doubling dilution only because the backend applies model-based
  calibration
- clicking `Run analysis` produces:
  - phenotype map
  - summary JSON block
  - output tables
  - downloadable `summary.json`
  - downloadable `.rds` bundle
  - downloadable report files

## External workflow

- enable external structure
- upload a valid external CSV
- external rotation control accepts values without breaking the run
- external rotation preset buttons update the numeric control sensibly
- external mode selector behaves correctly for:
  - numeric features
  - character features
  - sequence alleles
  - precomputed distance
- clicking `Run analysis` produces:
  - external map
  - side-by-side map
  - comparison table

## Clustering workflow

- enable cluster overlays
- cluster maps appear for phenotype and external workflows
- scree plots appear
- scree tables download successfully
- changing `n_clusters` changes the highlighted cluster in the scree output

## Reference-distance workflow

- enable reference summary
- choose a reference column and value
- optional filtering works without emptying the app unexpectedly
- reference-distance plot appears
- reference summary table appears
- x/y max controls behave sensibly
- x/y break controls behave sensibly
- annotation text and coordinates appear when supplied

## Visual fidelity checks

- map points use the manuscript-style palette and black outlines
- calibration note is visible in the app copy and report summary
- cluster plots look consistent with package outputs
- reference-distance plot styling matches package defaults
- app shell does not visually clash with the package plot style

## Export/report checks

- `amrc_report.md` downloads
- `amrc_report.html` downloads
- optional `amrc_report.pdf` downloads when enabled
- `amrc_output_bundle.zip` downloads
- report contents match the visible summary
- CSV downloads are non-empty and open normally
- `.rds` bundle is non-empty

## Failure-mode checks

- invalid external schema gives a readable error
- missing required MIC columns gives a readable error
- reference filtering to zero rows gives a readable error
- app does not silently claim success after backend failure
