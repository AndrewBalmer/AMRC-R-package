# amrcartography: a generic toolkit for cartographic analysis of antimicrobial susceptibility phenotypes

Article type: software, methods, or resource article.

Author list: Andrew J. Balmer and collaborators to be finalized.

Software baseline for the manuscript: `amrcartography` `v0.2.0`.

Maintenance/app release available after baseline: `v0.2.1`.

Primary repository: <https://github.com/AndrewBalmer/AMRC-R-package>

Primary figure builder: [tools/build_manuscript_figures.R](/Users/ab69/AMRC-R-package/tools/build_manuscript_figures.R)

Primary table builder: [tools/build_manuscript_tables.R](/Users/ab69/AMRC-R-package/tools/build_manuscript_tables.R)

Current figure directory: [docs/manuscript-figures](/Users/ab69/AMRC-R-package/docs/manuscript-figures)

Current table directory: [docs/manuscript-tables](/Users/ab69/AMRC-R-package/docs/manuscript-tables)

## Abstract

Minimum inhibitory concentration (MIC) measurements capture graded antimicrobial susceptibility across multiple drugs, but these measurements are often analysed one drug at a time or reduced to breakpoint categories before multivariate structure is examined. As antimicrobial resistance (AMR) datasets increasingly combine MIC panels with genomic, lineage, and epidemiological metadata, there is a need for reusable software that can map multivariate phenotype structure and compare those maps with external biological structure in a reproducible way.

Here we present `amrcartography`, an open-source R package for cartographic analysis of AMR phenotype data. The package provides a generic workflow for validating and cleaning MIC tables, constructing phenotype distance matrices, fitting multidimensional scaling maps, calibrating map distances onto MIC-style units, and comparing phenotype maps with external distance or feature structures. External inputs can be supplied as precomputed distances, numeric features, character-state profiles, aligned allele or sequence tables, or package-derived genotype structures. The package also includes helpers for clustering, map-fit diagnostics, dimensionality sweeps, robustness studies, group summaries, reference-distance modelling, manuscript-style visualisation, and staged validation.

The software was developed from an earlier *Streptococcus pneumoniae* cartography workflow, but the current package is organized around a generic "bring your own MIC data" interface. We retain the pneumococcal analysis as a worked validation case study and regression target, and include small public MIC example subsets across multiple bacterial species for documentation and testing. A lightweight Streamlit prototype exposes the core phenotype-first workflow with optional genotype or structure maps, while advanced mixed-model, LIMIX, epistatic, heritability, and BLUP workflows remain documented as provenance and expert extensions rather than default app workflows. `amrcartography` provides a reusable foundation for multivariate AMR phenotype cartography, genotype-to-phenotype comparison, and publication-ready AMR visualisation.

## Importance

AMR software increasingly supports the systematic integration of genotypes and phenotypes, including tools such as AMRgen for marker-based genotype-phenotype analysis. `amrcartography` addresses a complementary problem: how to represent quantitative, multidrug MIC phenotypes as interpretable landscapes and how to compare those landscapes with genotype, lineage, or other external structure. This makes it useful when the biological question is not only "which marker predicts resistance?", but also "how are isolates arranged in multivariate resistance space, and how does that arrangement relate to genetic or epidemiological structure?" The package turns a historically notebook-based cartography workflow into a reusable R toolkit with validation checks, reproducible figures, and an optional interactive app.

## Introduction

Whole-genome sequencing and high-throughput antimicrobial susceptibility testing have made it possible to analyse AMR across increasingly large matched genotype and phenotype datasets. These datasets are scientifically rich, but they are also awkward to summarize. MIC measurements are quantitative and often censored by assay design; panels contain multiple drugs; and resistance mechanisms may produce gradients of susceptibility rather than clean binary categories. Breakpoint-based susceptible, intermediate, and resistant calls remain essential for clinical and surveillance interpretation, but they do not exhaust the information contained in a multidrug MIC panel.

This creates a practical gap between the structure present in AMR phenotype data and the tools commonly used to analyse it. Many workflows still begin by reducing each drug to a separate univariate summary or by fitting marker-specific models one phenotype at a time. These approaches are useful, but they can miss relationships that only become visible when MIC measurements are considered jointly. In particular, they are not designed to represent isolates as positions in a continuous multivariate resistance landscape, nor to ask how that phenotype landscape relates to genotype maps, lineage structure, sequence-derived distances, or other external variables.

Recent AMR software has made important progress in related areas. The AMR R package provides a widely used foundation for antimicrobial and microorganism standardisation, breakpoint interpretation, and reproducible AMR analytics. AMRgen extends the R ecosystem toward systematic AMR genotype-phenotype analysis, with data import, harmonisation, concordance analysis, logistic modelling, and visualisation of marker combinations. These tools address crucial phenotype interpretation and genotype-phenotype association tasks. `amrcartography` is designed to sit beside them rather than replace them. Its focus is the cartographic representation of multivariate MIC phenotypes and the comparison of that representation with external biological structure.

The original AMR cartography workflow was developed in the context of beta-lactam resistance in streptococci. That work used phenotype distances, genotype distances, low-dimensional maps, calibration, and manuscript-specific visualisation to understand how multidrug resistance phenotypes were arranged and how they related to genetic structure. The scientific workflow was useful, but the implementation was spread across scripts, notebooks, local data paths, and case-study assumptions. This made it difficult to reuse in new organisms, difficult to validate in stages, and difficult for future users to distinguish generic methods from pneumococcus-specific analysis code.

We developed `amrcartography` to make this workflow reusable. The package is organized around a phenotype-first sequence: clean and standardise MIC data, compute phenotype distances, fit and calibrate a map, inspect goodness of fit, and optionally compare the phenotype map with external genotype or structure maps. The *S. pneumoniae* analysis remains part of the package as a worked example and validation target, but it no longer defines the public API. The package also includes small public MIC examples, a staged validation framework, manuscript-style plotting helpers, and a prototype app that exposes the core workflow to users who prefer an interactive interface.

In this paper, we describe the design and implementation of `amrcartography`, demonstrate its core workflows, and position it within the AMR software ecosystem. We show how the package supports generic MIC cartography, phenotype-versus-external comparison, cross-species example execution, and package-backed reconstruction of the retained pneumococcal case study. We also define the boundary of the current software: mixed models, LIMIX, epistasis, heritability, and BLUP remain available as documented expert/provenance workflows, but the main product is a reproducible and extensible cartography toolkit for multivariate AMR phenotypes.

## Implementation

### Design goals

`amrcartography` was built around five design goals. First, the primary workflow should be generic and MIC-first, so that users can begin with a tabular MIC dataset rather than an organism-specific analysis script. Second, map interpretation should be calibration-first: a one-unit grid should be read as one doubling dilution only after a model-based calibration step, not after arbitrary manual dilation. Third, phenotype and genotype or structure maps should have separate controls, because rotating a phenotype map for interpretation is not the same operation as rotating a genotype map. Fourth, plotting defaults should preserve the visual language of the original thesis and manuscript workflows rather than drifting toward generic dashboard styling. Fifth, validation should be staged and reusable, because a pipeline can run without necessarily producing biologically valid or correctly aligned outputs.

### Package architecture

The package exposes functions for MIC validation, MIC cleaning, distance construction, map fitting, calibration, plotting, comparison, clustering, robustness, and reporting. The core data flow is:

1. A user supplies a phenotype table with one isolate identifier column, one or more MIC columns, and optional metadata columns.
2. MIC values are validated and cleaned, including censored or non-standard values such as `<`, `<=`, `>`, and `>=`.
3. The cleaned MIC matrix is transformed, usually with a log2 transformation for raw MIC values.
4. Pairwise phenotype distances are computed across isolates.
5. A low-dimensional map is fitted using multidimensional scaling.
6. Map distances are calibrated against phenotype distances and summarised with stress, residual, and distance-correlation diagnostics.
7. Optional external data are aligned to the same isolate identifiers and represented as a second distance or map structure.
8. Phenotype and external maps are compared through joined coordinate tables, group summaries, reference-distance relationships, and manuscript-style plots.

This architecture deliberately separates input standardisation, map fitting, plotting, and comparison. That separation is important because silent bugs in AMR analysis often occur at joins, identifier matching, transformation choices, and figure-building boundaries rather than inside a single statistical function.

### MIC cleaning and phenotype distances

Raw MIC data are handled through functions including `amrc_validate_mic_data()`, `amrc_clean_mic_values()`, `amrc_standardise_mic_data()`, and `amrc_compute_mic_distance()`. The cleaning layer preserves common AMR-specific details, including censored MIC values and odd string formats. In the default workflow, raw MIC values are log2-transformed after cleaning because MIC dilution series are naturally multiplicative. Users can switch the transformation off if the submitted data have already been log2-transformed.

The result of standardisation is a cleaned MIC matrix and aligned metadata. Pairwise phenotype distances are then computed from the MIC matrix. These distances provide the target structure for downstream cartography: isolates that have similar multidrug susceptibility profiles should be close in phenotype space, while isolates with larger differences across the MIC panel should be further apart.

### Map fitting, rotation, and calibration

Maps are fitted with `amrc_compute_mds()` and summarised with `amrc_map_fit_report()`. The package returns low-dimensional coordinates, stress summaries, stress-per-point summaries, residual summaries, distance correlations, and calibration parameters. Rotation is exposed through `amrc_rotate_configuration()` and through plotting/app controls as a visual orientation step. It does not change the underlying pairwise distances.

Calibration is handled separately through `amrc_fit_distance_calibration()` and `amrc_calibrate_mds()`. This distinction matters. Manual dilation can make a map look larger or smaller, but it does not establish that a map unit corresponds to a MIC-scale distance. In `amrcartography`, calibration is the manuscript-consistent route for interpreting map units. App and package documentation therefore state that one-unit gridlines should be interpreted as one doubling dilution only after calibration has been applied.

### External and genotype structure

The external-data layer accepts several input types. Users can import a precomputed distance matrix, numeric feature table, character-state table, aligned allele or sequence table, or package-prepared genotype structure. The relevant functions include `amrc_standardise_external_data()`, `amrc_compute_external_distance()`, `amrc_compute_external_feature_distance()`, `amrc_compute_hamming_distance()`, and `amrc_compute_sequence_distance()`. These routes are intended to make the downstream comparison layer generic, even when upstream genotype parsing remains project-specific.

Once external distances or external maps are available, `amrc_prepare_map_data()` aligns phenotype coordinates, external coordinates, and metadata by isolate identifier. This produces a joined map table used for side-by-side plotting, clustering, group summaries, reference-distance modelling, and app reporting.

### Comparison summaries and visualisation

The package includes functions for comparing phenotype and external structure at several levels. Reference-distance summaries can be computed with `amrc_compute_reference_distance_table()` and visualised with `amrc_plot_reference_distance_relationship()`. Group centroids, pairwise group distances, and within-group dispersion can be computed with `amrc_compute_group_centroids()`, `amrc_compute_group_pairwise_distances()`, `amrc_compute_group_distance_summary()`, and `amrc_summarise_within_group_dispersion()`. Cluster overlays and scree plots are supported through functions such as `amrc_cluster_map()` and `amrc_plot_cluster_elbow()`.

The plotting surface is built around `ggplot2` and `patchwork`, with manuscript-specific defaults in `amrc_theme_cartography()` and panel-composition helpers such as `amrc_compose_manuscript_side_by_side_panel()` and `amrc_compose_phenotype_external_reference_panel()`. This package-level visual layer is intentional. The visual style was part of the original AMR cartography work, so figure construction is treated as a reusable method rather than an afterthought.

### Advanced and provenance workflows

The package includes additional helpers for single-feature contrasts, cluster-difference feature workflows, association postprocessing, mixed models, LIMIX input staging, heritability, epistatic scans, permutation scans, and BLUP prediction. These functions document and preserve useful logic from the original project and thesis workflows. However, they are not presented as the first-line app workflow and should not be interpreted as the core claim of this manuscript. In particular, LIMIX and epistatic workflows require more assumptions, more dependencies, and more domain review than the phenotype-first cartography path.

This separation is important for scope control. The paper is about a generic cartography package for AMR phenotype landscapes and phenotype-versus-external comparison. Advanced association modelling is included as provenance and extension, not as the main reason to trust or use the package.

### Streamlit prototype

The repository includes a lightweight Streamlit prototype with an R backend. The app is phenotype-first: users start from MIC data, choose cleaning and transformation options, fit a phenotype map, inspect goodness-of-fit outputs, and then optionally add a genotype or structure map. The app exposes separate controls for phenotype and genotype map rotation, colouring, gridlines, clustering, and reporting. It also includes bundled demos, deterministic preview subsets for larger case studies, downloadable HTML reports, and zipped result bundles.

The app should be viewed as a convenience and QA surface rather than the scientific core of the manuscript. It is useful for demonstration, teaching, and exploratory analysis, but the package API remains the primary reproducible interface.

### Validation and reproducibility

Validation is documented in `AGENT_VALIDATION_WORKFLOW.md`, `VALIDATION.md`, `VALIDATION_CHECKLIST.md`, and `VALIDATION_IMPLEMENTATION_SUMMARY.md`. The validation layer checks more than whether code runs. It looks for missing files, malformed example data, identifier mismatches, empty outputs, schema drift, broken report generation, and reproducibility gaps.

The release workflow includes local staged validation, Streamlit backend contract checks, browser-level app QA, manuscript figure generation, table generation, vignette rendering, and GitHub Actions R-CMD-check on Ubuntu release and devel. For `v0.2.1`, CI passed on the release head before the tag and GitHub Release were created.

## Example datasets

The manuscript uses four categories of example data. The first is a synthetic generic MIC fixture bundled for tests, vignettes, and documentation. The second is a set of small public MIC subsets from the CDC & FDA Antimicrobial Resistance Isolate Bank, covering *Salmonella enterica*, *Campylobacter jejuni*, *Escherichia coli* O157, *Acinetobacter baumannii*, *Pseudomonas aeruginosa*, and *Staphylococcus aureus*. These subsets are intentionally tiny and are used to exercise the generic workflow on real public MIC strings, not to make new organism-specific biological claims. The third is a retained *S. pneumoniae* case-study bundle used for continuity with the original AMR cartography work. The fourth is an *S. suis* app/demo bundle used to test larger phenotype-plus-structure app workflows.

Dataset counts and sources are generated by [tools/build_manuscript_tables.R](/Users/ab69/AMRC-R-package/tools/build_manuscript_tables.R) and written to [docs/manuscript-tables/table02_example_datasets.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table02_example_datasets.csv).

## Results

### Generic MIC cartography can be executed from a user-supplied table

The generic workflow begins from a simple MIC table rather than a species-specific object. In the bundled example, raw MIC values are standardised, log2-transformed, converted to pairwise phenotype distances, and mapped into two dimensions. The map is then summarized with residual and stress diagnostics (Figure 1). This small example is intentionally minimal: its purpose is to show the shape of the workflow and make each transformation inspectable. The same functions are used by the larger case-study and app pathways.

This workflow supports the central user story of the package. A user can bring a table of isolate identifiers, MIC columns, and metadata columns; run a defined cleaning and distance workflow; and obtain a phenotype map with fit diagnostics. The calibration step means that visual gridlines can be interpreted in MIC-like units only when calibration supports that interpretation.

### Phenotype maps can be compared with external genotype or structure maps

`amrcartography` can align a phenotype map with an external map derived from numeric features, character states, aligned sequences, or precomputed distances. In the generic comparison example, phenotype coordinates and external coordinates are joined by isolate identifier, plotted side by side, and used to compute a reference-distance relationship (Figure 2). This illustrates the package's main comparative workflow: phenotype structure and external structure are not forced into one model, but are mapped, aligned, and compared through interpretable summaries.

This design is deliberately flexible. A user might supply a genotype distance matrix, a PBP profile distance matrix, a lineage-derived feature table, or another externally computed structure. As long as isolate identifiers can be aligned, the downstream comparison functions are shared.

### Public MIC subsets demonstrate cross-species portability without overclaiming biological inference

The public MIC examples show that the package is not hard-coded to pneumococcal column names or beta-lactam panels. The same MIC-cleaning and map-fitting path runs on small public subsets from six bacterial contexts (Figure 3). These examples include censored MIC strings and variable drug panels, allowing the cleaning and transformation layer to be tested against realistic public values.

The biological claims from these subsets are intentionally limited. Each subset contains only four isolates and is designed for demonstration, documentation, and automated validation. Their value is therefore methodological: they show that the package workflow is portable across table layouts and organism labels, not that the resulting maps describe complete species-level resistance structure.

### The retained *S. pneumoniae* case study preserves biological continuity and provides regression targets

The original pneumococcal analysis motivated much of the package. In the current repository, that workflow is represented by package-backed example data, calibrated phenotype and genotype map files, and figure-building code. The retained case-study figure shows phenotype and genotype map structure side by side using the same visual conventions as the generic package figures (Figure 4).

This case study plays two roles. Scientifically, it preserves continuity with the beta-lactam resistance work from which the package emerged. Technically, it provides a regression target. If future changes break the pneumococcal map bundle, the validation layer and manuscript figure builder should reveal that drift.

### Validation and app QA catch failure modes that ordinary package tests can miss

During development, several failures were not simple syntax errors. Examples included missing generated artefacts in CI, local-only paths in legacy notebooks, visual regression checks that were too brittle for CI, and case-study app subsets that contained phenotype identifiers missing from the genotype-map input. These are exactly the kinds of silent or semi-silent failures that staged validation is intended to catch.

The current validation layer includes package tests, smoke validation, vignette rendering, README example checks, manuscript figure generation, Streamlit backend contract checks, and browser-level QA. The app QA now covers phenotype-only, phenotype-plus-genotype, *S. pneumoniae*, *S. suis*, report download, and zipped bundle workflows. The validation gates are summarized in Table 3.

## Discussion

`amrcartography` translates a historically bespoke AMR cartography workflow into a reusable R package. The main contribution is not a new dimensionality-reduction algorithm. It is the packaging of a practical, end-to-end workflow for turning multivariate MIC data into calibrated phenotype maps, comparing those maps with external structure, and producing manuscript-consistent figures and reports.

The package complements rather than competes with tools such as AMR and AMRgen. AMR provides robust antimicrobial and organism standardisation and breakpoint interpretation. AMRgen focuses on systematic genotype-phenotype analysis, marker combinations, concordance, logistic models, and UpSet-style genotype summaries. `amrcartography` focuses on continuous multivariate phenotype landscapes and phenotype-versus-structure comparison. In practice, these tools could be used in the same broader project: AMR or AMRgen for phenotype interpretation and genotype-phenotype marker analysis, and `amrcartography` for mapping and comparing multidrug phenotype structure.

The strongest feature of `amrcartography` is the explicit separation between the generic workflow and case-study provenance. Many research software projects begin as analysis code for a single paper. That is not a weakness, but it becomes a problem when case-study assumptions remain hidden inside public functions. Here, the pneumococcal workflow is retained, but generic MIC ingestion, external-distance integration, map fitting, calibration, plotting, and validation have been promoted into package-level functions. This makes the software easier to reuse and easier to review.

The package also treats visualisation as part of the method. For AMR cartography, map interpretation depends on calibration, orientation, grouping, and visual consistency. The package therefore includes manuscript-style plotting defaults and panel composers, and the app reuses the same plotting conventions. This reduces the risk that interactive outputs and static manuscript figures silently diverge.

Several limitations remain. First, raw upstream genotype parsing is still less generic than downstream map comparison. The package can compare phenotype maps with many external structures, but it does not yet claim to be a universal importer for every genotype-calling pipeline. Second, advanced mixed-model, LIMIX, epistatic, heritability, and full BLUP workflows are heavier and require more assumptions than the default map workflow. They are documented as provenance and expert methods, not as default app features. Third, the public cross-species MIC examples are intentionally small and should not be treated as biological benchmark datasets. Fourth, the Streamlit app is a useful prototype, but not yet a polished clinical or surveillance product.

Future work should prioritize broader example datasets, figure-by-figure visual parity with the original manuscript panels, additional app reporting polish, and careful integration with complementary AMR software. If advanced association workflows are brought further into the app, they should be introduced as separate expert modules with clear input assumptions, validation checks, and warnings about interpretation.

## Conclusions

`amrcartography` provides a reusable software foundation for multivariate AMR phenotype cartography. It enables users to clean MIC data, build phenotype distance structures, fit and calibrate phenotype maps, compare those maps with genotype or other external structures, and generate reproducible manuscript-style outputs. By separating the generic package API from retained case-study provenance, the software makes an existing AMR cartography workflow easier to inspect, validate, and adapt across organisms.

## Availability and requirements

Project name: `amrcartography`

Version used for manuscript baseline: `v0.2.0`

Current maintenance/app release: `v0.2.1`

Operating systems: Linux, macOS, and Windows where R package dependencies are available; CI validation is run on Ubuntu.

Programming language: R, with an optional Python Streamlit interface.

Main dependencies: R, `ggplot2`, `smacof`, `ape`; suggested packages include `patchwork`, `jsonlite`, `knitr`, `rmarkdown`, `testthat`, `lme4`, and Streamlit app Python dependencies.

License: MIT.

Repository: <https://github.com/AndrewBalmer/AMRC-R-package>

Release: <https://github.com/AndrewBalmer/AMRC-R-package/releases/tag/v0.2.1>

## Data availability

The repository includes generic example fixtures, compact public MIC subsets derived from the CDC & FDA Antimicrobial Resistance Isolate Bank, a package-backed *S. pneumoniae* mapping bundle, and an *S. suis* demonstration bundle. Public MIC example provenance is documented in [docs/PUBLIC_MIC_EXAMPLE_CITATIONS.md](/Users/ab69/AMRC-R-package/docs/PUBLIC_MIC_EXAMPLE_CITATIONS.md). The public subsets are intended for documentation and testing rather than biological inference. Larger original data sources and any third-party data not suitable for redistribution should be cited and retrieved according to their source policies.

## Code availability

Source code is available at <https://github.com/AndrewBalmer/AMRC-R-package>. The manuscript baseline is `v0.2.0`; the maintenance/app release `v0.2.1` includes additional validation, app, and documentation hardening. Reproducible manuscript figures can be rebuilt with:

```sh
Rscript tools/build_manuscript_figures.R
```

Reproducible manuscript tables can be rebuilt with:

```sh
Rscript tools/build_manuscript_tables.R
```

Core validation can be run with:

```sh
Rscript tools/run_validation.R --stage smoke
```

## Author contributions

Conceptualization: Andrew J. Balmer and collaborators to be finalized.

Software: Andrew J. Balmer, with package migration and validation contributions to be finalized.

Validation: Andrew J. Balmer and collaborators to be finalized.

Writing, original draft: Andrew J. Balmer.

Writing, review and editing: all authors to be finalized.

## Competing interests

The authors declare no competing interests, unless updated before submission.

## Funding

Funding statements to be completed before submission. Include PhD, institutional, Wellcome, UKRI, MRC, NIHR, or other funder acknowledgements as appropriate.

## Acknowledgements

We thank the researchers and data providers whose public AMR datasets made the teaching and validation examples possible. We also acknowledge the development of complementary AMR software, including AMR and AMRgen, which has helped define expectations for reproducible AMR analysis in R.

## Figure captions

Figure 1. Generic MIC cartography workflow. A bundled example MIC table is cleaned, transformed, converted to phenotype distances, fitted as a two-dimensional map, and summarized with goodness-of-fit diagnostics. The figure illustrates the package's primary user-facing workflow from raw MIC table to calibrated phenotype map.

Figure 2. Phenotype-versus-external structure comparison. A phenotype map and external feature map are fitted from aligned isolate data and displayed side by side with a reference-distance relationship. The panel illustrates how `amrcartography` compares MIC phenotype landscapes with genotype or other external structure.

Figure 3. Cross-species public MIC examples. Small public MIC subsets from multiple bacterial species are processed through the same generic MIC cartography workflow. These examples are intended for portability checks, documentation, and teaching rather than species-level biological inference.

Figure 4. Retained *Streptococcus pneumoniae* validation case study. Package-backed phenotype and genotype maps preserve the original pneumococcal cartography workflow as a worked example and regression target while the public API remains generic.

## Tables

Table 1. Main workflow components and representative package functions. Source file: [docs/manuscript-tables/table01_workflow_components.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table01_workflow_components.csv).

Table 2. Example datasets used for documentation, app QA, and manuscript figures. Source file: [docs/manuscript-tables/table02_example_datasets.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table02_example_datasets.csv).

Table 3. Validation gates used before tagging `v0.2.1`. Source file: [docs/manuscript-tables/table03_validation_gates.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table03_validation_gates.csv).

## References

1. Balmer AJ, Murray GGR, Lo SW, Restif O, Weinert LA. Antimicrobial Resistance Cartography: A generalisable framework for studying multivariate drug resistance. Manuscript/preprint from the original AMR cartography project. Final bibliographic details to verify before submission.
2. Balmer AJ, Lee C, Pearson RD, Ariani CV, Almagro Garcia J. Pf-PeptideFilter: An interactive catalogue of peptide vaccine candidates for *Plasmodium falciparum*. bioRxiv. 2025. doi:10.64898/2025.12.15.694343.
3. Holt KE, Argimon S, Chaput DL, Couto N, Dyson ZA, Foster-Nyarko E, et al. AMRgen: an R package for antimicrobial resistance genotype-phenotype analysis. bioRxiv. 2026. doi:10.64898/2026.05.01.722195.
4. Berends MS, Luz CF, Friedrich AW, Sinha BNM, Albers CJ, Glasner C. AMR: An R package for working with antimicrobial resistance data. Journal of Statistical Software. 2022;104:1-31.
5. Lutgring JD, Machado MJ, Benahmed FH, et al. FDA-CDC Antimicrobial Resistance Isolate Bank: a publicly available resource to support research, development, and regulatory requirements. Journal of Clinical Microbiology. 2018;56:e01415-17. doi:10.1128/JCM.01415-17.
6. Feldgarden M, Brover V, Gonzalez-Escalona N, et al. AMRFinderPlus and the Reference Gene Catalog facilitate examination of the genomic links among antimicrobial resistance, stress response, and virulence. Scientific Reports. 2021;11:12728.
7. Bortolaia V, Kaas RS, Ruppe E, et al. ResFinder 4.0 for predictions of phenotypes from genotypes. Journal of Antimicrobial Chemotherapy. 2020;75:3491-3500.
8. Ellington MJ, Ekelund O, Aarestrup FM, et al. The role of whole genome sequencing in antimicrobial susceptibility testing of bacteria: report from the EUCAST Subcommittee. Clinical Microbiology and Infection. 2017;23:2-22.
9. Kahlmeter G, Turnidge J. How to: ECOFFs, the why, the how, and the don'ts of EUCAST epidemiological cutoff values. Clinical Microbiology and Infection. 2022;28:952-954.
10. World Health Organization. WHO bacterial priority pathogens list, 2024: bacterial pathogens of public health importance to guide research, development and strategies to prevent and control antimicrobial resistance. 2024.
11. Wickham H. ggplot2: Elegant graphics for data analysis. Springer-Verlag New York. 2016.
12. Wickham H, Averick M, Bryan J, et al. Welcome to the tidyverse. Journal of Open Source Software. 2019;4:1686.
13. De Leeuw J, Mair P. Multidimensional scaling using majorization: SMACOF in R. Journal of Statistical Software. 2009;31:1-30.
14. R Core Team. R: A language and environment for statistical computing. R Foundation for Statistical Computing. 2026.
15. Lex A, Gehlenborg N, Strobelt H, Vuillemot R, Pfister H. UpSet: visualization of intersecting sets. IEEE Transactions on Visualization and Computer Graphics. 2014;20:1983-1992.

Reference list note: final submission should verify all author lists, article status, journal names, page ranges, and DOIs before journal upload.
