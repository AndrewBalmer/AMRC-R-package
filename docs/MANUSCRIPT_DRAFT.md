# Package Manuscript Draft

## Working title

**amrcartography: a generic toolkit for cartographic analysis of antimicrobial
susceptibility phenotypes and external genotype structure**

## Software baseline

- cite `amrcartography` `v0.2.0` as the current public software baseline
- treat later `main` improvements as post-`v0.2.0` development unless a new tag
  is deliberately cut
- build manuscript figures from package-backed code, not notebook-only logic

Primary figure builder:

- [tools/build_manuscript_figures.R](/Users/ab69/AMRC-R-package/tools/build_manuscript_figures.R)

Primary package workflows:

- [using-your-own-mic-data.Rmd](/Users/ab69/AMRC-R-package/vignettes/using-your-own-mic-data.Rmd)
- [external-data-structures.Rmd](/Users/ab69/AMRC-R-package/vignettes/external-data-structures.Rmd)
- [public-mic-examples-across-species.Rmd](/Users/ab69/AMRC-R-package/vignettes/public-mic-examples-across-species.Rmd)
- [end-to-end-spneumoniae.Rmd](/Users/ab69/AMRC-R-package/vignettes/end-to-end-spneumoniae.Rmd)

## Abstract

Antimicrobial susceptibility phenotypes measured by minimum inhibitory
concentration (MIC) assays are intrinsically multivariate, yet many analysis
workflows still reduce them to single-drug summaries, breakpoint categories, or
project-specific scripts. As phenotype and genotype datasets have grown in
scale and diversity, there has been an increasing need for reusable tools that
can map multivariate MIC structure, compare phenotype landscapes with external
genetic or epidemiological structure, and preserve those analyses in a
reproducible software form.

Here we present `amrcartography`, an open-source R package for generic MIC
cartography. The package provides a workflow for validating and standardising
MIC tables, constructing phenotype distance matrices, fitting and calibrating
multidimensional scaling maps, and comparing phenotype maps with external
structures derived from precomputed distances, numeric feature tables, aligned
character-state tables, or aligned sequence/allele tables. Beyond the core map
workflow, the package includes reusable helpers for clustering, robustness
analysis, reference-distance summaries, goodness-of-fit reporting, association
analyses, manuscript-style figure composition, and staged validation.

We retain *Streptococcus pneumoniae* as a worked validation case study, but the
package is now structured around a generic “bring your own MIC dataset”
workflow rather than a species-specific API. To show that the workflow is not
restricted to a single organism, the package also includes small public MIC
subsets spanning multiple bacterial species. Together, these components provide
a reusable and extensible framework for phenotype cartography and
genotype-to-phenotype comparison in antimicrobial resistance research.

## Author summary

Antimicrobial resistance phenotypes are often summarized one antibiotic at a
time, even though clinically meaningful resistance patterns are multivariate.
When MIC measurements are considered jointly, isolates can occupy structured
phenotype landscapes that are difficult to capture with simple tables or binary
susceptible/resistant calls. Researchers also often want to compare those
phenotype patterns with genotype structure, lineage groupings, or other
external variables, but the code used to do this is commonly distributed across
case-study scripts and is hard to reuse in new datasets.

`amrcartography` was developed to make that workflow more reusable. Users can
bring their own MIC table, clean and standardise the values, fit a phenotype
map, calibrate the map onto MIC-style units, and then compare that phenotype
structure with an external distance or feature representation using the same
software framework. The package also includes plotting, clustering, robustness,
and reporting helpers, together with a retained *S. pneumoniae* case study and
small public cross-species example datasets. Our aim is to provide a practical
toolkit for multivariate AMR phenotype analysis that is easier to reproduce,
inspect, and adapt across organisms.

## Introduction

Antimicrobial resistance research increasingly relies on datasets that pair
multidrug phenotype measurements with genomic, lineage, or epidemiological
metadata. MIC measurements are especially information-rich because they encode
graded susceptibility across multiple drugs, but this structure is not fully
captured by binary breakpoint classifications or by one-drug-at-a-time
summaries. Multivariate approaches can reveal phenotype landscapes, cluster
structure, and gradients of susceptibility that are difficult to see in
univariate analyses alone.

Despite this, reusable software for multivariate MIC cartography remains
limited. Many workflows are embedded in organism-specific notebook pipelines,
with data cleaning, distance construction, dimensionality reduction, and figure
generation tightly coupled to one historical case study. Such workflows can be
scientifically productive, but they are hard to transfer across species, hard
to validate over time, and difficult for others to reproduce without manually
reassembling the original analysis environment.

To address these limitations, we developed `amrcartography` as a generic
toolkit for cartographic analysis of MIC datasets. The package is built around
a simple user-facing sequence: validate and standardise an MIC table,
construct a phenotype distance structure, fit and calibrate a low-dimensional
map, and optionally compare that map with an external structure such as
genotype-derived distances or aligned feature tables. The original
*S. pneumoniae* analyses remain scientifically important, but they now serve as
validation and regression targets rather than as the defining identity of the
package.

In this paper, we describe the package design, the staged validation framework,
and the generic phenotype-versus-external workflow implemented in the package.
We show how the same software supports phenotype map generation, comparison
against external structure, and manuscript-style visualisation in both bundled
toy examples and a retained pneumococcal case study. We also demonstrate that
the workflow can be exercised on small public MIC subsets spanning multiple
bacterial contexts.

## Methods

### Package design principles

The package was designed around four practical principles. First, the primary
API should be generic and MIC-first: users should be able to start from a
standard tabular MIC dataset without relying on case-study-specific wrappers.
Second, map interpretation should be calibration-first: if users want one-unit
spacing to correspond to one doubling dilution, that should be achieved through
the fitted calibration model rather than arbitrary manual dilation. Third, the
workflow should preserve compatibility with the original *S. pneumoniae*
analysis path while making the underlying components reusable. Fourth,
validation should be staged throughout development rather than deferred until
the end of a project.

### Core MIC cartography workflow

The main phenotype workflow begins with `amrc_standardise_mic_data()`, which
validates identifier structure, cleans raw MIC string values, and applies the
requested transformation. From this standardized object,
`amrc_compute_mic_distance()` constructs a phenotype distance matrix, and
`amrc_compute_mds()` fits a low-dimensional map. Goodness-of-fit and
calibration are then handled through `amrc_map_fit_report()`,
`amrc_fit_distance_calibration()`, and `amrc_calibrate_mds()`. In practice,
this means that map distances can be related back to MIC-scale distances using
a model-based calibration step rather than by manually stretching the map.

### External structure integration

The package supports several routes for adding non-phenotype structure. Users
can provide a precomputed distance matrix, a numeric feature table, a
character-state table, or an aligned sequence/allele table. These are handled
through `amrc_standardise_external_data()`,
`amrc_compute_external_distance()`, `amrc_compute_external_feature_distance()`,
`amrc_compute_hamming_distance()`, and `amrc_compute_sequence_distance()`.
External maps are fitted with the same MDS and calibration machinery used for
phenotype maps, which keeps the downstream comparison layer consistent across
different kinds of external input.

### Comparison, clustering, and reporting

Once phenotype and external maps are available, `amrc_prepare_map_data()`
produces aligned coordinate tables for downstream comparison. These can be used
for clustering, group summaries, reference-distance analysis, and phenotype
versus external comparison tables. The plotting layer standardizes the visual
style across package and app outputs, with manuscript-style helpers for map
composition and panel assembly. The experimental Streamlit interface reuses the
package plotting and calibration path so that the interactive outputs remain
consistent with the manuscript workflow.

### Validation and reproducibility

The repository now includes staged validation aimed at catching silent failures
as well as obvious runtime errors. This includes schema checks for bundled
example data, count and identifier consistency checks for the retained
*S. pneumoniae* case-study bundle, Streamlit backend smoke checks, and visual
regression checks for key manuscript-style plots. Validation commands are
documented for both humans and coding agents in
[AGENT_VALIDATION_WORKFLOW.md](/Users/ab69/AMRC-R-package/AGENT_VALIDATION_WORKFLOW.md),
[VALIDATION.md](/Users/ab69/AMRC-R-package/VALIDATION.md), and
[VALIDATION_CHECKLIST.md](/Users/ab69/AMRC-R-package/VALIDATION_CHECKLIST.md).

### Example datasets

We use two classes of example data in this manuscript. The first is a compact
set of generic toy MIC and external examples that are bundled for documentation
and testing. The second is a retained *S. pneumoniae* case-study bundle that
preserves the original biological workflow in a package-backed form. To show
that the generic workflow is portable beyond a single organism, the package
also includes small public MIC subsets spanning *Salmonella enterica*,
*Campylobacter jejuni*, *Escherichia coli* O157, *Acinetobacter baumannii*,
*Pseudomonas aeruginosa*, and *Staphylococcus aureus*. These public subsets are
curated from CDC & FDA Antimicrobial Resistance Isolate Bank isolate-detail
pages and are intended for teaching, testing, and lightweight workflow
demonstration rather than standalone biological inference.

## Results

### A generic MIC workflow can be executed from a user-supplied table

The primary package workflow begins with a generic MIC table rather than a
species-specific helper. Using bundled toy data, a user can standardize raw MIC
values, compute phenotype distances, fit a two-dimensional map, and then
calibrate that map onto MIC-style units. This workflow exposes the core
cartographic idea in a small, inspectable setting and makes the calibration
step explicit: one-unit grid spacing is meaningful only after the fitted
calibration model has been applied.

### Phenotype maps can be compared against multiple forms of external structure

The same workflow can be extended to phenotype-versus-external comparison by
providing an external distance or feature representation. The package supports
numeric feature tables, character-state features, sequence/allele tables, and
precomputed distance matrices, allowing phenotype maps to be compared against
genotype-derived or user-defined external structure without changing the core
API. In the packaged examples, this yields aligned phenotype and external maps,
cluster summaries, and reference-distance plots from a single comparison layer.

### Small public MIC subsets show cross-species portability

Although the packaged public examples are intentionally tiny, they are useful
for testing whether the generic MIC-cleaning, calibration, and plotting path
behaves sensibly across different bacterial panels. Running the same compact
workflow on multiple public species subsets demonstrates that the package does
not depend on pneumococcal naming conventions or a single MIC panel layout.
These examples are deliberately modest in scope, but they are valuable for
documentation, QA, and teaching because they exercise the generic workflow on
real public MIC strings.

### The retained *S. pneumoniae* case study provides biological continuity and validation

The original *S. pneumoniae* workflow remains important because it connects the
generic package API back to the historical scientific analysis that motivated
the project. In the current repository, this case study has been refactored
into a package-backed bundle and vignette path, allowing the phenotype map,
genotype map, external-variable notebook logic, and associated figures to be
validated against tracked assets rather than only against loosely coupled
scripts. This makes the case study useful both scientifically and as a
regression target for future package development.

### Reusable plotting and reporting keep the software close to the manuscript workflow

The package now includes manuscript-style plotting defaults, panel composition
helpers, and lightweight report-generation pathways that can be reused across
the static package workflow and the Streamlit prototype. This is important in
practice because visual language was a central part of the original analysis
workflow. Standardizing these defaults in the package reduces the risk that the
interactive interface or later figure-building code will drift away from the
style and interpretive conventions used in the thesis and manuscript analyses.

## Discussion

`amrcartography` packages a workflow that was previously distributed across a
large collection of scripts and notebooks. Its main contribution is not a new
dimensionality reduction method, but the translation of a scientifically useful
cartographic workflow into a reusable, testable, and inspectable software
framework. By centering the API on generic MIC tables while retaining the
original *S. pneumoniae* case study, the package supports both reuse in new
datasets and continuity with the historical analyses that motivated it.

The package has several practical strengths. It supports multiple routes for
bringing external structure into the analysis, including genotype-derived and
user-defined formats. It makes calibration an explicit and inspectable part of
map interpretation. It includes a growing validation layer designed to catch
schema drift, identifier mismatches, empty outputs, and other silent failures.
It also provides a reusable visual and reporting surface so that package
outputs, manuscript figures, and the experimental app remain aligned.

There are also important limitations. Upstream genotype parsing remains less
generic than the downstream comparison layer, and some advanced mixed-model
workflows are still heavier and more environment-dependent than the core map
workflow. The cross-species public MIC subsets are intentionally tiny and
should not be overinterpreted biologically. The Streamlit interface is useful
as a convenience layer, but it is still a prototype rather than a polished
end-user application.

Overall, we view `amrcartography` as a reusable software foundation for
multivariate AMR phenotype analysis. Its main value lies in making a complex
analysis pattern easier to inspect, validate, and adapt across projects. Future
work can continue to broaden the public example coverage, refine the reporting
surface, and further package the remaining high-value logic from the legacy
analysis notebooks.

## Figure plan

- **Figure 1.** Generic MIC workflow example from a user-supplied table.
- **Figure 2.** Phenotype-versus-external comparison panel with a
  reference-distance plot.
- **Figure 3.** Cross-species portability panel from bundled public MIC
  examples.
- **Figure 4.** *S. pneumoniae* validation panel showing retained phenotype and
  genotype map structure.

Current figure builder:

- [tools/build_manuscript_figures.R](/Users/ab69/AMRC-R-package/tools/build_manuscript_figures.R)

Current output directory:

- [docs/manuscript-figures](/Users/ab69/AMRC-R-package/docs/manuscript-figures)

## Table plan

- **Table 1.** Generic workflow inputs and outputs.
- **Table 2.** Goodness-of-fit summary for the main phenotype and external
  examples.
- **Table 3.** Reference-distance or cluster-summary table for the comparison
  example.
- **Supplementary table.** Bundled public MIC example provenance and source
  panels.

## Remaining writing tasks

- add the full reference list and in-text citations
- decide the target journal and tune title/abstract length to its format
- refine the results narrative once the final figure set is frozen
- decide whether to cut `0.2.1` before manuscript submission or continue to
  cite `v0.2.0`
