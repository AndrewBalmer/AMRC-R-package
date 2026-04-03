# Manuscript Skeleton

Working title:

**amrcartography: a generic toolkit for cartographic analysis of antimicrobial susceptibility phenotypes and external genotype structure**

Software baseline for citation:

- cite `amrcartography` `v0.2.0` as the current stable release baseline
- update to a later release only if a new tagged release is deliberately chosen

## Abstract

Antimicrobial resistance datasets are often high-dimensional, heterogeneous,
and difficult to interpret using univariate summaries alone. Minimum
inhibitory concentration (MIC) measurements capture rich multivariate
phenotypes, but there are still relatively few general-purpose tools for
turning these measurements into interpretable low-dimensional maps and linking
them to external genetic or epidemiological structure. Existing analysis
workflows are often organism-specific, tightly coupled to one historical case
study, or difficult to reuse across new datasets.

To address these gaps, we developed `amrcartography`, an open-source R package
for generic MIC cartography. The package provides tools for validating and
standardising MIC tables, constructing phenotype distance matrices, fitting and
calibrating multidimensional scaling maps, and comparing phenotype maps with
external distance structures derived from genotypes, aligned character-state
tables, sequence features, or precomputed distances. The package also includes
reusable helpers for clustering, robustness analysis, reference-distance
summaries, mixed-model workflows, and manuscript-style visualisation. A
Streamlit prototype extends the core workflow into a lightweight interactive
interface.

We retain *Streptococcus pneumoniae* as a worked validation case study, but
the package is designed around a generic “bring your own MIC dataset” workflow.
To demonstrate broader portability, the package now ships small public MIC
example subsets spanning multiple bacterial species. Together, these components
provide a reproducible and extensible framework for phenotype cartography and
genotype-to-phenotype comparison in antimicrobial resistance research.

## Author Summary

Antimicrobial susceptibility data are often analysed one drug at a time, even
though clinically relevant resistance phenotypes are multivariate. When
several MIC measurements are considered together, isolates can form structured
phenotypic landscapes that are difficult to summarize with conventional tables
or single-threshold classifications. Researchers also often want to ask how
those phenotype patterns relate to genetic background, lineage structure, or
other external variables, but the available tooling is usually fragmented and
case-study specific.

Here we present `amrcartography`, a software toolkit for turning MIC datasets
into interpretable phenotype maps and comparing those maps with external
genetic or epidemiological structure. Users can bring their own MIC table,
clean and standardise the values, fit a phenotype map, and then compare that
map against a genotype-derived or user-supplied external structure using a
common workflow. The package also includes plotting, clustering, robustness,
and report-generation tools, together with a retained *S. pneumoniae* case
study and small public cross-species example datasets. Our goal is to make
multivariate AMR phenotype analysis more reusable, transparent, and easier to
adapt across organisms and projects.

## Introduction

### Suggested opening paragraph

In recent years, antimicrobial resistance research has generated increasingly
large phenotype and genotype datasets, creating new opportunities for
multivariate analysis of resistance landscapes. MIC measurements, in
particular, contain structured information across multiple drugs that is not
fully captured by binary susceptible/resistant calls or by single-drug
summaries. However, tools for analysing MIC data as multivariate phenotypes
remain comparatively limited, especially when researchers want to relate those
phenotypes to genetic background, lineage structure, or other external
variables in a reusable way.

### Suggested problem paragraph

Much of the existing work in this area has been developed within
organism-specific analysis pipelines. These workflows can be scientifically
useful, but they are often difficult to reuse because data cleaning, map
generation, comparison logic, and plotting are tightly tied to one historical
dataset. As a result, researchers working with other species or other AMR
contexts often need to rebuild similar analysis infrastructure from scratch,
even when the core methodological ideas are shared.

### Suggested solution paragraph

We therefore developed `amrcartography` as a generic toolkit for cartographic
analysis of MIC datasets. The package is built around a simple workflow:
validate and standardise an MIC table, construct a phenotype distance
structure, fit and calibrate a low-dimensional map, and optionally compare that
map with an external structure such as genotype-derived distances, aligned
feature tables, or other user-supplied metadata. The original *S. pneumoniae*
workflow is retained as a validation case study, but no longer defines the
primary user-facing API.

### End-of-introduction aims paragraph

In this paper, we describe the package design, document the generic workflow,
and show how the framework supports phenotype map generation, genotype-to-
phenotype comparison, and reproducible visualisation across multiple bacterial
contexts. We also position the *S. pneumoniae* case study as a worked example
and regression target rather than as the defining identity of the software.

## Methods

### Package design goals

- generic MIC-first workflow rather than organism-specific entry points
- reproducible validation and fixture-backed examples
- separation between generic API, case-study wrappers, and legacy notebooks
- calibration-first interpretation of MIC-style map units

### Core workflow

Suggested subsection flow:

1. MIC data ingestion and cleaning
2. Distance construction
3. MDS fitting and calibration
4. External/genotype structure integration
5. Comparison summaries and clustering
6. Plotting and manuscript-style figure composition
7. Robustness and perturbation analyses
8. Association and mixed-model extensions

### Example datasets

Suggested wording:

We illustrate the package using both bundled generic examples and retained
case-study data. The *S. pneumoniae* workflow is included as a validation and
regression target. To demonstrate broader portability, the package also ships
small public MIC subsets spanning multiple bacterial species curated from CDC
AR Isolate Bank detail pages. These public subsets are intentionally small and
are intended for documentation, testing, and teaching rather than for
standalone biological inference.

### Validation and reproducibility

Key points to include:

- staged validation during development rather than end-only checking
- fixture-based checks for bundled example data
- schema, count, and output-contract validation
- CI-based source and installed-package validation
- visual regression coverage for key manuscript-style plots

## Results

### Result 1: Generic MIC cartography workflow

Suggested focus:

- demonstrate that a user can start from a generic MIC table
- show standardisation, distance construction, MDS fitting, and calibration
- emphasize that one-unit spacing should be interpreted after model-based
  calibration, not arbitrary dilation

### Result 2: Phenotype-versus-external comparison

Suggested focus:

- show phenotype map and external/genotype map side by side
- demonstrate group summaries, clustering, and reference-distance analysis
- show that the same comparison layer can work with different external data
  formats

### Result 3: Cross-species portability

Suggested focus:

- use the bundled public multi-species MIC examples
- show that the core workflow applies across more than one bacterial context
- keep claims modest because the subsets are intentionally tiny

### Result 4: Case-study validation in *S. pneumoniae*

Suggested focus:

- preserve continuity with the original pneumococcal analysis
- show that the package-backed workflow reproduces the core map-generation and
  comparison logic
- frame this as validation and worked example, not as the only intended use

### Result 5: Reusable visualisation and reporting

Suggested focus:

- manuscript-style plotting defaults
- reusable panel composition helpers
- lightweight interactive Streamlit interface
- downloadable report and bundle outputs

## Discussion

### Suggested opening

`amrcartography` is intended to lower the practical barrier to multivariate AMR
phenotype analysis by packaging a workflow that was previously distributed
across case-study scripts and notebooks. The package does not replace domain
knowledge or organism-specific preprocessing decisions, but it does make the
core cartographic workflow more reusable, testable, and transparent.

### Suggested strengths

- generic MIC-first API
- support for multiple external-data representations
- preserved link to an established case study
- stronger validation and reproducibility layer
- reusable visualisation and reporting surface

### Suggested limitations

- raw upstream genotype parsing is still less generic than downstream map
  comparison
- some advanced workflows remain heavier and more environment-dependent
- bundled cross-species public examples are intentionally small
- interactive app is still a prototype, not a fully polished end-user product

### Suggested future directions

- broader external-data ingestion helpers
- further visual regression and figure-specific presets
- deeper interactive app support for advanced association workflows
- additional public example fixtures across organisms and use cases

## Availability and implementation

Suggested points:

- language: R
- interactive prototype: Streamlit + R backend
- repository: GitHub
- current cited release: `v0.2.0`
- license: MIT

## Figures to plan

Figure 1:
- generic workflow schematic
- MIC table -> distance -> map -> calibration -> external comparison

Figure 2:
- generic phenotype map example with calibration note
- possibly one bundled public species example

Figure 3:
- phenotype vs external/genotype side-by-side map
- reference-distance panel beneath

Figure 4:
- *S. pneumoniae* validation case-study panel

Figure 5:
- Streamlit/reporting or robustness/association extension figure

## Tables to plan

Table 1:
- major package capabilities and corresponding exported functions

Table 2:
- bundled example datasets and intended use

Table 3:
- validation and reproducibility coverage

## Immediate writing plan

1. Finalise the package/software baseline to cite in the manuscript.
2. Turn the abstract and author summary above into a polished first draft.
3. Build Figure 1 and Figure 3 directly from package-backed functions.
4. Write Introduction and Methods around the generic workflow, not the
   pneumococcal case study.
5. Use *S. pneumoniae* in Results as a validation section, not as the opening
   user story.
