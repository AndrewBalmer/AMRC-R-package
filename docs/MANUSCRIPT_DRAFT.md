# amrcartography: cartographic analysis of antimicrobial susceptibility phenotypes

## Abstract

Minimum inhibitory concentration (MIC) measurements provide a quantitative description of antimicrobial susceptibility, but the structure present across multi-drug panels is often compressed into single-drug summaries or breakpoint categories. These reductions are clinically and epidemiologically useful, yet they can obscure the continuous, multivariate phenotype landscapes that emerge when isolates are compared across several antimicrobials simultaneously. We developed `amrcartography`, an open-source R package for constructing, calibrating, visualising and comparing cartographic representations of AMR phenotype data.

`amrcartography` standardises raw MIC tables, handles censored and non-standard MIC values, constructs pairwise phenotype distances, fits low-dimensional maps, and calibrates map distances against MIC-derived phenotype distances. The package also supports comparison between phenotype maps and external structures, including precomputed distance matrices, numeric feature tables, character-state profiles and aligned allele or sequence tables. The resulting maps can be interrogated using goodness-of-fit summaries, group centroids, reference-distance relationships, clustering diagnostics and manuscript-style visualisations.

The package generalises a previously bespoke AMR cartography analysis into a reusable software framework. We demonstrate the package using generic MIC examples, small public MIC subsets spanning multiple bacterial species, and a retained *Streptococcus pneumoniae* case study that preserves continuity with the original biological analysis. The current software also includes a lightweight phenotype-first Streamlit prototype for interactive exploration, while more specialised mixed-model and epistatic analyses are retained as expert extensions rather than the central user interface. `amrcartography` provides a reproducible framework for studying multidrug susceptibility as a structured phenotype landscape and for comparing that landscape with genetic or epidemiological structure.

## Importance

AMR phenotypes are frequently interpreted one antimicrobial at a time. This is appropriate for many clinical and surveillance questions, but it does not capture how isolates are arranged in a multidrug resistance space. `amrcartography` addresses this problem by converting MIC panels into calibrated phenotype maps that can be compared with genotype, lineage or other external structure. The package is intended for researchers who need to inspect quantitative AMR phenotype structure without rebuilding project-specific cartography code for each organism or dataset.

## Introduction

Antimicrobial resistance research increasingly relies on datasets that combine antimicrobial susceptibility measurements with genome sequences, lineage assignments and epidemiological metadata. MIC measurements are particularly informative because they provide graded phenotypic data rather than only categorical susceptibility calls. However, this quantitative information is not straightforward to analyse when several drugs are measured for the same collection of isolates. Single-drug summaries remain indispensable, but they cannot describe how isolates relate to one another across an entire susceptibility panel.

Multivariate representations offer a complementary view. If isolates are compared using distances derived from multiple MIC measurements, they can be arranged as a phenotype landscape in which proximity reflects similarity of susceptibility profiles. Such maps can reveal gradients, clusters and outlying phenotypes that may be difficult to recognise in tables of individual drug results. They can also be compared with external structures, such as genotype distances, lineage groups, sequence features or epidemiological classes, to ask whether phenotypic resistance structure follows the same organisation as genetic or population structure.

Despite this potential, MIC cartography has often remained tied to bespoke analysis scripts. The original AMR cartography workflow was developed for beta-lactam resistance in streptococci and combined MIC cleaning, phenotype distances, genotype distances, multidimensional scaling, calibration and manuscript-specific plotting. That analysis established a useful way to study multidrug resistance phenotypes, but its implementation was distributed across notebooks, local data files and case-study assumptions. This made the approach difficult to reuse and difficult to validate outside the original project.

`amrcartography` was developed to turn that analysis pattern into a generic R package. The package begins with ordinary tabular MIC data, standardises the phenotype measurements, constructs distance matrices, fits and calibrates low-dimensional maps, and provides tools for comparing those maps with external structure. The *S. pneumoniae* analysis remains available as a worked case study and regression target, but the package interface is no longer specific to pneumococcus. This distinction is important: the purpose of the software is to make AMR cartography portable, while preserving the biological analysis that motivated it.

Here we describe the design and implementation of `amrcartography`, demonstrate the core phenotype cartography and phenotype-versus-external comparison workflows, and document the validation layer used to guard against silent failures in data alignment, map generation and reporting. We frame the package as a multivariate phenotype analysis tool, not as a universal AMR genotype importer or a replacement for marker-based association methods.

## Implementation

### MIC processing and phenotype distances

The primary input to `amrcartography` is a phenotype table containing isolate identifiers, MIC measurements and optional metadata. MIC values may be supplied as numeric values or as common laboratory strings, including censored values such as `<`, `<=`, `>` and `>=`. The package validates the identifier structure, cleans MIC values, applies a user-specified transformation and returns a cleaned MIC matrix aligned to metadata. For raw MIC data, the default transformation is log2, reflecting the doubling-dilution structure of MIC assays. If a user has already transformed the data before import, the transformation can be disabled.

Pairwise phenotype distances are computed from the cleaned MIC matrix. These distances define the target structure for cartography: isolates with similar multidrug susceptibility profiles should be close together, whereas isolates that differ across the MIC panel should be further apart. This distance-based formulation allows the downstream map-fitting step to be applied consistently across different organisms and drug panels.

### Map fitting and calibration

Low-dimensional maps are fitted using multidimensional scaling. The package reports map coordinates together with stress, stress-per-point, residual and distance-correlation summaries. These diagnostics are included because visually plausible maps can still distort important pairwise relationships, particularly when high-dimensional phenotype distances are projected into two dimensions.

The package treats rotation and calibration as separate operations. Rotation changes the visual orientation of a map but does not alter pairwise distances. Calibration estimates the relationship between distances in the fitted map and distances in the original phenotype space. This distinction is central to the interpretation of AMR cartography. A one-unit grid on a map should only be interpreted as one MIC dilution after calibration supports that scale; it should not be produced by manually stretching the map until it appears convenient.

### External structure and map comparison

`amrcartography` can compare phenotype maps with external structures supplied by the user or generated by upstream analysis. External inputs may be precomputed distance matrices, numeric feature tables, character-state tables, aligned allele profiles or aligned sequence data. These inputs are standardised and converted into external distance matrices or external maps, then aligned to the phenotype map by isolate identifier.

The joined map table allows phenotype and external structure to be compared without forcing them into a single model. Users can inspect side-by-side maps, compute reference-distance relationships, summarize group centroids, compare within-group dispersion, overlay clusters and generate manuscript-style panels. This design makes the package useful for genotype-to-phenotype comparison while keeping the cartographic representation of the phenotype as the primary analysis object.

### Visualisation and reporting

The visualisation layer uses `ggplot2` and `patchwork`, with package-level defaults designed to preserve the style of the original AMR cartography figures. This matters because map interpretation depends on orientation, scale, group colour, density, calibration and panel composition. The package therefore exposes plotting helpers and panel composers rather than treating figures as disposable notebook output.

The repository also contains a lightweight Streamlit prototype built around the package backend. The app is phenotype-first: users select or upload MIC data, choose cleaning and transformation options, fit a phenotype map, inspect diagnostics and optionally add a genotype or structure map. Phenotype and genotype maps have separate controls for rotation, colouring, faceting, gridlines and clustering. The app is useful for demonstration and exploratory analysis, but the R package remains the primary reproducible interface.

### Validation

The package includes staged validation aimed at detecting failures that ordinary function-level tests may miss. These include missing files, malformed example data, duplicate or mismatched identifiers, empty outputs, app/backend contract failures and report-generation failures. Validation is run locally and in GitHub Actions using smoke checks, package tests, vignette rendering, figure generation, table generation, browser-level app QA and R-CMD-check on Ubuntu release and devel. This validation layer is a methodological component of the project because cartographic analyses can produce plausible-looking figures even when upstream joins or transformations are wrong.

### Advanced extensions

The repository retains additional functions for association postprocessing, single-feature contrasts, cluster-difference summaries, mixed models, LIMIX wrappers, heritability estimation, epistatic scans, permutation scans and BLUP prediction. These functions preserve useful logic from the original project and thesis work, but they are not the central claim of this manuscript and are not exposed as default app workflows. They should be treated as expert extensions that require clearer assumptions and stronger context-specific validation before routine use.

## Example data

The manuscript uses three categories of example data. Generic synthetic fixtures are used to demonstrate and test the core package workflow. Small public MIC subsets from the CDC & FDA Antimicrobial Resistance Isolate Bank provide real MIC strings across multiple bacterial species, including *Salmonella enterica*, *Campylobacter jejuni*, *Escherichia coli* O157, *Acinetobacter baumannii*, *Pseudomonas aeruginosa* and *Staphylococcus aureus*. These public subsets are intentionally small and are used for portability checks, documentation and validation rather than biological inference. Finally, a retained *S. pneumoniae* bundle preserves the original cartography case study as a worked example and regression target. An additional *S. suis* bundle is used for app and phenotype-plus-structure testing.

## Results

### A generic MIC table can be converted into a calibrated phenotype map

The generic example demonstrates the minimal cartography path from MIC table to phenotype map. Raw MIC values are cleaned, log2-transformed, converted into pairwise phenotype distances and embedded in two dimensions (Figure 1). The resulting map is accompanied by residual and stress summaries, allowing the user to assess whether the fitted map preserves the original phenotype distance structure. Although the example is small, it is deliberately transparent and uses the same functions as the larger case-study and app workflows.

This result establishes the core behaviour of the package. The user does not need a pneumococcus-specific object, a bespoke notebook or a precomputed map. The input is an ordinary MIC table, and the output is a calibrated map with diagnostics. The calibration step is explicit, which prevents visual gridlines from being mistaken for MIC-scale units before the map has been related back to the original phenotype distances.

### Phenotype maps can be compared with external biological structure

The package supports comparison between a phenotype map and an external map fitted from aligned non-phenotype data (Figure 2). In the generic example, a phenotype map and a numeric-feature-derived external map are joined by isolate identifier, plotted side by side and summarized using a reference-distance relationship. The same comparison machinery can be applied to genotype distances, aligned character profiles, sequence-derived distances or other user-supplied structures.

This design separates representation from interpretation. The phenotype map captures multidrug susceptibility structure; the external map captures another structure measured on the same isolates. Their relationship can then be examined through visual comparison, group summaries, cluster overlays and reference-distance statistics. This is especially useful in AMR studies where phenotype structure may partially, but not completely, follow lineage or genotype structure.

### Public MIC examples exercise the package across multiple bacterial contexts

The public MIC examples demonstrate that the package workflow is not tied to the original pneumococcal column names or beta-lactam panel (Figure 3). Each example uses a small subset of public MIC data, preserving the raw MIC string formats that users are likely to encounter in practice. The examples therefore test the generality of MIC cleaning, transformation, distance construction and plotting across different organism labels and drug panels.

These examples should not be overinterpreted biologically. Each subset contains only a small number of isolates and was curated for documentation and testing. Their purpose is to show that the software workflow is portable and robust to different input schemas, not to estimate species-level resistance structure.

### The pneumococcal case study preserves continuity with the original analysis

The retained *S. pneumoniae* case study links the package back to the scientific analysis that motivated it (Figure 4). The package includes calibrated phenotype and genotype map assets and uses them to reproduce the central map-comparison structure in a package-backed form. This case study is important because it tests whether the generalized package still supports the original biological workflow.

The case study also functions as a regression target. Changes to MIC cleaning, map fitting, plotting or identifier alignment can be evaluated against a known analysis path. This is a practical advantage of retaining the historical analysis within the package while separating it from the generic public API.

### Staged validation identified failures that simple execution would not catch

During development, several important problems were not ordinary syntax errors. Examples included local-only data paths, missing generated artifacts in CI, overly brittle visual regression checks and bundled app examples in which phenotype identifiers were not fully shared with genotype-map inputs. These failures illustrate why validation must include data, identifiers, outputs and reports rather than only checking whether functions execute.

The current validation layer includes repository smoke validation, package tests, vignette rendering, manuscript figure and table generation, Streamlit backend contract checks, browser-level app QA and Ubuntu R-CMD-check. The app QA now exercises phenotype-only analysis, phenotype-plus-structure analysis, the retained *S. pneumoniae* case-study preview, the *S. suis* preview, report rendering and zipped output bundles. These checks do not prove biological correctness, but they substantially reduce the risk of silent workflow regression.

## Discussion

`amrcartography` packages a multivariate AMR phenotype analysis workflow that was previously embedded in organism-specific scripts. Its contribution is the formalisation of AMR cartography as reusable software: MIC processing, phenotype distance construction, map fitting, calibration, external-structure comparison, visualisation and validation are exposed as package components rather than notebook fragments.

The package is most useful when a researcher wants to understand the shape of multidrug susceptibility variation across isolates. It does not replace breakpoint interpretation, marker association testing or organism-specific biological reasoning. Instead, it provides a complementary view: isolates are arranged in a continuous phenotype landscape, and that landscape can then be compared with genotype, lineage or other external structure. This framing is particularly relevant when resistance is gradual, multidimensional or only partially explained by known genetic groupings.

The separation between generic cartography and case-study provenance is a central feature of the package. Many research software projects begin as code written for a single analysis. That origin is not a problem by itself; indeed, it grounds the software in a real biological question. The problem arises when assumptions from the original analysis remain hidden inside functions that appear generic. In `amrcartography`, the pneumococcal workflow is retained as a case study and validation target, while the reusable components have been promoted into a general API.

The package also treats figure construction as part of the method. In cartographic analysis, the interpretability of a result depends on scale, orientation, grouping, colour and panel composition. Standardizing these choices in package functions helps keep static manuscript figures, reproducible scripts and interactive app outputs aligned. This is especially important for a method whose scientific output is often visual.

There are several limitations. The package does not yet provide universal importers for every upstream genotype-calling workflow. It can compare phenotype maps with many external structures, but users remain responsible for domain-appropriate genotype processing and interpretation. The public cross-species examples are deliberately small and are not biological benchmark datasets. The Streamlit interface is useful for exploration and demonstration but should not be presented as a mature end-user product. Finally, the advanced association and mixed-model functions require more context-specific validation than the core cartography workflow and are therefore best treated as expert extensions.

Future work should expand the package-backed example collection, strengthen figure-by-figure parity with the original manuscript panels, improve report generation, and refine the interactive app only where it supports the phenotype-first analysis. More advanced association workflows could be surfaced later, but only with clear assumptions, stronger validation and dedicated examples.

## Conclusions

`amrcartography` provides a reusable framework for analysing antimicrobial susceptibility as a multivariate phenotype landscape. By converting MIC panels into calibrated maps and comparing those maps with external biological structure, the package supports a form of AMR analysis that is not captured by single-drug summaries alone. The current release turns a previously bespoke cartography workflow into a validated, package-backed toolkit while preserving the original pneumococcal analysis as a worked example and regression target.

## Availability

`amrcartography` is an R package distributed under the MIT license. The manuscript baseline is version `v0.2.0`, and a subsequent maintenance/app release is available as `v0.2.1`. Source code is available at <https://github.com/AndrewBalmer/AMRC-R-package>. The `v0.2.1` release is available at <https://github.com/AndrewBalmer/AMRC-R-package/releases/tag/v0.2.1>. The package is validated on Ubuntu through GitHub Actions and can be run on platforms where the R dependencies are available.

## Data availability

The repository includes generic example fixtures, compact public MIC subsets derived from the CDC & FDA Antimicrobial Resistance Isolate Bank, a package-backed *S. pneumoniae* mapping bundle and an *S. suis* demonstration bundle. Public MIC example provenance is documented in the repository. The public subsets are provided for documentation and validation rather than biological inference. Larger original data sources and third-party data not suitable for redistribution should be retrieved and cited according to their source policies.

## Code availability

Source code, figure-building scripts, table-building scripts, validation scripts and app code are available in the project repository. Manuscript figures are generated from package-backed code, and manuscript tables are generated from repository data and package metadata. The main validation entry point is the staged repository validation script, which is also exercised in continuous integration.

## Author contributions

Andrew J. Balmer conceived the package, developed the software, migrated the original cartography workflow into reusable package functions, prepared the validation framework and drafted the manuscript. Additional author contributions, affiliations and review roles should be finalized before submission.

## Competing interests

The authors declare no competing interests, unless updated before submission.

## Funding

Funding statements should be completed before submission.

## Acknowledgements

We thank the researchers and data providers whose public AMR data resources made the teaching and validation examples possible. We also acknowledge the maintainers of the broader open-source R and AMR software ecosystem on which this package depends.

## Figure captions

Figure 1. Generic MIC cartography workflow. A bundled MIC table is cleaned, transformed, converted to phenotype distances, embedded in two dimensions and summarized with goodness-of-fit diagnostics. The figure illustrates the core package workflow from raw MIC table to calibrated phenotype map.

Figure 2. Phenotype-versus-external structure comparison. Phenotype and external feature maps are fitted from aligned isolate data and displayed with a reference-distance relationship. The panel illustrates how `amrcartography` compares MIC phenotype landscapes with genotype or other external structure.

Figure 3. Cross-species public MIC examples. Small public MIC subsets from multiple bacterial species are processed through the same MIC cartography workflow. These examples are intended for portability checks and documentation rather than species-level biological inference.

Figure 4. Retained *Streptococcus pneumoniae* validation case study. Package-backed phenotype and genotype maps preserve the original pneumococcal cartography workflow as a worked example and regression target while the public API remains generic.

## Table captions

Table 1. Main workflow components and representative package functions.

Table 2. Example datasets used for documentation, app QA and manuscript figures.

Table 3. Validation gates used before tagging `v0.2.1`.

## References

1. Balmer AJ, Murray GGR, Lo SW, Restif O, Weinert LA. Antimicrobial Resistance Cartography: A generalisable framework for studying multivariate drug resistance. Manuscript/preprint from the original AMR cartography project. Final bibliographic details to verify before submission.
2. Berends MS, Luz CF, Friedrich AW, Sinha BNM, Albers CJ, Glasner C. AMR: An R package for working with antimicrobial resistance data. Journal of Statistical Software. 2022;104:1-31.
3. Lutgring JD, Machado MJ, Benahmed FH, et al. FDA-CDC Antimicrobial Resistance Isolate Bank: a publicly available resource to support research, development, and regulatory requirements. Journal of Clinical Microbiology. 2018;56:e01415-17. doi:10.1128/JCM.01415-17.
4. Feldgarden M, Brover V, Gonzalez-Escalona N, et al. AMRFinderPlus and the Reference Gene Catalog facilitate examination of the genomic links among antimicrobial resistance, stress response, and virulence. Scientific Reports. 2021;11:12728.
5. Bortolaia V, Kaas RS, Ruppe E, et al. ResFinder 4.0 for predictions of phenotypes from genotypes. Journal of Antimicrobial Chemotherapy. 2020;75:3491-3500.
6. Ellington MJ, Ekelund O, Aarestrup FM, et al. The role of whole genome sequencing in antimicrobial susceptibility testing of bacteria: report from the EUCAST Subcommittee. Clinical Microbiology and Infection. 2017;23:2-22.
7. Kahlmeter G, Turnidge J. How to: ECOFFs, the why, the how, and the don'ts of EUCAST epidemiological cutoff values. Clinical Microbiology and Infection. 2022;28:952-954.
8. World Health Organization. WHO bacterial priority pathogens list, 2024: bacterial pathogens of public health importance to guide research, development and strategies to prevent and control antimicrobial resistance. 2024.
9. Wickham H. ggplot2: Elegant graphics for data analysis. Springer-Verlag New York. 2016.
10. Wickham H, Averick M, Bryan J, et al. Welcome to the tidyverse. Journal of Open Source Software. 2019;4:1686.
11. De Leeuw J, Mair P. Multidimensional scaling using majorization: SMACOF in R. Journal of Statistical Software. 2009;31:1-30.
12. R Core Team. R: A language and environment for statistical computing. R Foundation for Statistical Computing. 2026.

Reference list note: final submission should verify all author lists, article status, journal names, page ranges and DOIs before journal upload.
