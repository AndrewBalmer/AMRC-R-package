# Package Manuscript Draft

## Working Title

`amrcartography`: an R package for reproducible antimicrobial resistance cartography from MIC data

## Positioning

The manuscript should be a software/application paper centered on the package
as a generic toolkit for MIC cartography, with one concrete case study used to
demonstrate that generic workflow on real data.

The main user-facing workflow should now be the generic vignette:

[using-your-own-mic-data.Rmd](/Users/ab69/AMRC-R-package/vignettes/using-your-own-mic-data.Rmd)

The supporting generic external-data story should now be the second vignette:

[external-data-structures.Rmd](/Users/ab69/AMRC-R-package/vignettes/external-data-structures.Rmd)

The `S. pneumoniae` workflow remains important, but it should be framed as the
secondary case-study/validation path rather than the package identity:

[end-to-end-spneumoniae.Rmd](/Users/ab69/AMRC-R-package/vignettes/end-to-end-spneumoniae.Rmd)

The manuscript should explain the package around this generic sequence:

1. preprocess MIC phenotype data
2. optionally prepare or import an external distance structure
3. fit phenotype and external maps
4. compare map structure and cluster-level relationships
5. demonstrate the approach on the `S. pneumoniae` case study

The manuscript should now move away from citing an intermediate development
commit and instead cite the first tagged public package release. The current
release target is:

- target software release: `v0.1.0`
- package version in the release-prep tree: `0.1.0`
- citation policy: cite the first green tagged release rather than an older
  development commit

Keep the manuscript drafting centered on the vignette structure, and update the
final software citation to the validated release tag once the GitHub release is
cut.

## Draft Abstract

Antimicrobial resistance phenotypes measured by minimum inhibitory concentration
(MIC) assays are intrinsically multivariate, but many analysis workflows remain
tied to univariate summaries or project-specific scripts. We present
`amrcartography`, an R package for reproducible antimicrobial resistance
cartography workflows that transform arbitrary MIC datasets into phenotype maps,
optionally integrate aligned external distance structures, and support
downstream clustering and phenotype-versus-external comparison analyses. The
package formalizes data preprocessing, multidimensional scaling, map
calibration, robustness analyses, and reusable comparison summaries that were
previously distributed across notebook-style analysis scripts. We demonstrate
the workflow using a packaged *Streptococcus pneumoniae* case study and provide
bundled examples, regression tests, and a reproducible environment for reuse
and extension. `amrcartography` is intended both as a practical toolkit for
MIC-based analysis and as a reproducible software companion to AMR cartography
studies.

## Draft Outline

### 1. Introduction

- Why MIC datasets benefit from multivariate analysis
- Why cartography-style phenotype mapping is useful
- The reproducibility problem with analysis-script workflows
- Aim of the package paper

### 2. Package Design

- Reproducible input handling and provenance
- Generic MIC preprocessing
- Generic external-data preparation and distance handling
- MDS fitting, calibration, and goodness-of-fit helpers
- Robustness, clustering, and phenotype-vs-external comparison helpers

### 3. Example Workflow

- Use the generic vignette workflow as the manuscript’s conceptual main path
- Show the `S. pneumoniae` vignette as the biological case-study validation
- Show phenotype preprocessing output
- Show optional external-data integration
- Show phenotype and external maps
- Show clustering/comparison summary

### 4. Reproducibility and Validation

- `renv` environment capture
- deterministic tests
- fixture/regression tests
- package-backed migration of legacy notebooks

### 5. Availability

- GitHub repository
- license
- installation
- packaged examples

## Figures to Build from the Package

- phenotype map example
- external map example
- side-by-side phenotype/external comparison
- possibly one robustness/clustering summary figure if space allows

## Tables to Build from the Package

- preprocessing outputs summary
- map fit / goodness-of-fit summary
- phenotype-vs-external cluster comparison summary

## Writing Tasks

- tighten the abstract once the target journal is chosen
- add references for MDS, MIC analysis, and AMR cartography framing
- decide whether to position this as a methods/software paper or as a companion software note to the main AMR cartography manuscript
- add citation/repository/version text for the first tagged package release
