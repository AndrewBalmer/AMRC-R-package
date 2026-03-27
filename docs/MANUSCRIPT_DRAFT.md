# Package Manuscript Draft

## Working Title

`amrcartography`: an R package for reproducible antimicrobial resistance cartography from MIC data

## Positioning

The manuscript should be a software/application paper centered on one core example workflow:

1. preprocess MIC phenotype data
2. preprocess genotype sequence data
3. fit phenotype and genotype maps
4. compare map structure and cluster-level relationships

That workflow now exists in a user-facing form in the vignette:
[end-to-end-spneumoniae.Rmd](/Users/ab69/AMRC-R-package/vignettes/end-to-end-spneumoniae.Rmd)

The software version referenced in the manuscript should be frozen at the first
GitHub Actions `R-CMD-check` green commit that includes the end-to-end vignette
workflow. Until that green baseline is fixed, keep the manuscript drafting
centered on the vignette structure rather than on moving notebook details.

## Draft Abstract

Antimicrobial resistance phenotypes measured by minimum inhibitory concentration (MIC) assays are intrinsically multivariate, but many analysis workflows remain tied to univariate summaries or project-specific scripts. We present `amrcartography`, an R package for reproducible antimicrobial resistance cartography workflows that transform MIC datasets into phenotype maps, integrate genotype-derived distance structures, and support downstream clustering and phenotype-versus-genotype comparison analyses. The package formalizes data preprocessing, multidimensional scaling, map calibration, robustness analyses, and reusable comparison summaries that were previously distributed across notebook-style analysis scripts. We demonstrate the workflow using a packaged *Streptococcus pneumoniae* example and provide bundled examples, regression tests, and a reproducible environment for reuse and extension. `amrcartography` is intended both as a practical toolkit for MIC-based analysis and as a reproducible software companion to AMR cartography studies.

## Draft Outline

### 1. Introduction

- Why MIC datasets benefit from multivariate analysis
- Why cartography-style phenotype mapping is useful
- The reproducibility problem with analysis-script workflows
- Aim of the package paper

### 2. Package Design

- Reproducible input handling and provenance
- Canonical phenotype preprocessing
- Canonical genotype preprocessing
- MDS fitting, calibration, and goodness-of-fit helpers
- Robustness, clustering, and phenotype-genotype comparison helpers

### 3. Example Workflow

- Use the vignette workflow as the manuscript’s main worked example
- Show phenotype preprocessing output
- Show genotype preprocessing output
- Show phenotype and genotype maps
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
- genotype map example
- side-by-side phenotype/genotype comparison
- possibly one robustness/clustering summary figure if space allows

## Tables to Build from the Package

- preprocessing outputs summary
- map fit / goodness-of-fit summary
- phenotype-vs-genotype cluster comparison summary

## Writing Tasks

- tighten the abstract once the target journal is chosen
- add references for MDS, MIC analysis, and AMR cartography framing
- decide whether to position this as a methods/software paper or as a companion software note to the main AMR cartography manuscript
- add citation/repository/version text once the green release-basis commit is fixed
