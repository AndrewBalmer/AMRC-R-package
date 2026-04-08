# App guide

This page is designed to start with phenotype MIC cartography and then, only if needed, extend into genotype or other structure-based comparison.

## Overview

The primary workflow is:

1. upload or choose a phenotype MIC table
2. clean raw MIC values and optionally apply `log2` transformation
3. fit and calibrate the phenotype map
4. inspect fit, clustering, and reports
5. optionally add a genotype / structure map for comparison

Calibration is what makes the map interpretable in MIC-style units. A 1-unit grid should only be read as one doubling dilution after calibration has been applied.

## Phenotype workflow

Choose:

- one isolate ID column
- the raw MIC columns
- any metadata columns you want available for colouring, faceting, grouping, or summaries

The app can clean unusual MIC entries such as `<`, `>`, `~`, and related variants through the package preprocessing helpers. If you choose `log2`, the transformation happens after cleaning.

The phenotype map is the primary output. If you only want phenotype cartography, you can stop there.

## Genotype map

The optional second map can be used for:

- a precomputed genotype distance matrix
- aligned numeric features
- aligned character-state features
- aligned sequence / allele tables

The app labels this as a genotype / structure map because the second map is often genetic, but the package also supports other aligned structures.

Phenotype and genotype maps have separate controls for:

- colouring
- faceting
- density overlays
- 1-unit gridlines
- rotation
- clustering

Rotation is a view choice. Dilation should follow the package calibration model instead of being set manually.

## Summary and fit

The summary section is the first place to check whether the run is believable.

Look for:

- isolate counts
- MIC variable counts
- map stress
- calibration details

The fit tables then give:

- pairwise distance correlation
- residual summaries
- stress-per-point summaries

Plausible-looking maps can still be wrong. Always check fit and data counts rather than relying on appearance alone.

## Diagnostics

Diagnostics include:

- cluster scree / elbow plots
- cluster overlays
- fit metric tables
- residual and stress summaries
- reference-distance relationship plots when the genotype map is enabled

These help catch silent failures such as unstable clustering, poor calibration, or a genotype map that is not aligned to the phenotype metadata.

## Reports and exports

The report/export section bundles the main outputs from a run:

- report in Markdown and HTML
- optional PDF
- JSON summary
- result `.rds`
- zipped bundle
- primary figures and key tables

Use the exported bundle as the reproducible record of an app run.

## Citations

Cite the software baseline as `amrcartography` `v0.2.0` unless you intentionally move to a later tagged release.

Previous AMR cartography work referenced in the app:

- Balmer AJ, Murray GGR, Lo S, Restif O, Weinert LA. *Antimicrobial Resistance Cartography: A Generalisable Framework for Studying Multivariate Drug Resistance*. Manuscript draft, 2025.
- Balmer AJ. *Multivariate methods for the study of beta-lactam resistance in streptococci*. PhD thesis, University of Cambridge, 2023.
