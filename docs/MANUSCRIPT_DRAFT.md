# amrcartography: reusable cartographic analysis of multidrug antimicrobial susceptibility phenotypes

Andrew J. Balmer

## Abstract

### Background

Minimum inhibitory concentration (MIC) measurements are central to antimicrobial resistance (AMR) research because they retain quantitative information about susceptibility. In multi-drug panels, however, this information is commonly reduced to single-drug summaries, breakpoint categories or marker-specific contrasts. These summaries are necessary for many clinical and surveillance questions, but they do not directly describe how isolates are arranged in a multidrug phenotype space. The original AMR cartography workflow showed that MIC profiles can be represented as calibrated phenotype maps, but the implementation was tied to case-study scripts and organism-specific assumptions.

### Results

We developed `amrcartography`, an open-source R package that generalises AMR phenotype cartography into reusable software. The package validates and cleans raw MIC tables, handles common censored values, applies MIC-appropriate transformations, constructs pairwise phenotype distances, fits low-dimensional maps, calibrates map distances against MIC-derived distances and compares phenotype maps with external biological structure. It also provides manuscript-style visualisation functions, summary tables, staged validation scripts and a lightweight phenotype-first Streamlit prototype. We demonstrate the software using four evidence layers: a generic MIC workflow, phenotype-versus-external structure comparison, small public MIC examples spanning multiple bacterial species and a retained *Streptococcus pneumoniae* case study that acts as provenance and regression validation for the original analysis. A larger *Streptococcus suis* bundle is used as an integration example for phenotype-first analysis with matched metadata and external penicillin-binding protein structure.

### Conclusions

`amrcartography` converts a bespoke AMR cartography analysis into a validated package-backed workflow for studying multidrug susceptibility as a structured phenotype landscape. The software is intended to complement, rather than replace, breakpoint interpretation and genotype-specific association analysis. Its main contribution is a reproducible cartographic layer for MIC data that can be reused across organisms, drug panels and external comparison structures.

**Keywords:** antimicrobial resistance; minimum inhibitory concentration; multidimensional scaling; phenotype cartography; R package; reproducible research.

## Background

Antimicrobial resistance research increasingly combines quantitative susceptibility measurements, whole-genome sequence data, lineage assignments and epidemiological metadata. MIC measurements are especially valuable because they preserve graded phenotypic variation. A one-dilution change in MIC may be meaningful even when both isolates remain on the same side of a clinical breakpoint, and correlated MIC shifts across several drugs can reveal multidrug resistance structure that is difficult to see from single-drug tables alone.

Most routine analyses necessarily simplify this structure. Breakpoints, epidemiological cut-off values and susceptibility categories are essential for clinical reporting, surveillance and communication. Marker-based genotype-phenotype analyses are also essential when the objective is to estimate the effect of specific resistance determinants. Yet these approaches answer different questions from phenotype cartography. They do not directly ask how isolates relate to one another across a panel of antimicrobials, whether multidrug susceptibility varies along continuous gradients, or how a phenotype landscape compares with lineage, genotype or other external structure.

Cartographic analysis addresses this gap by treating an MIC panel as a multivariate phenotype. Isolates are compared using distances derived from cleaned MIC profiles, and those distances are represented in a low-dimensional map. If the map preserves the original phenotype distances well, nearby isolates have similar multidrug susceptibility profiles and distant isolates have more divergent profiles. The resulting map can then be calibrated, inspected for distortion, annotated by metadata and compared with external biological structure.

The AMR cartography framework was originally developed for beta-lactam resistance in streptococci and was applied to *Streptococcus pneumoniae* as a proof of concept. That analysis combined MIC cleaning, phenotype distance construction, genotype-distance comparison, multidimensional scaling, calibration and manuscript-specific figure construction. It established the scientific value of phenotype cartography, but much of the implementation remained embedded in notebooks, local files and analysis-specific conventions. This created the common research-software problem in which a useful method exists, but its assumptions are difficult to audit and its workflow is difficult to reuse.

`amrcartography` was developed to separate the reusable method from the original case study. The package retains the pneumococcal workflow as a worked example and regression target, but the public interface is generic: users provide MIC data, metadata and optional external structure; the package returns cleaned inputs, distances, maps, diagnostics, comparison tables and figures. This manuscript therefore does not re-present the pneumococcal analysis as the main new biological result. Instead, it describes the software layer that makes AMR phenotype cartography reusable, validates that layer across several example contexts and documents how the original biological analysis is preserved as provenance.

## Implementation

### Package design

`amrcartography` is implemented as an R package. The central workflow begins with a tabular MIC dataset containing one isolate identifier column and one or more MIC columns. Optional metadata columns can be retained for plotting, grouping, faceting, clustering and report generation. The package validates identifier uniqueness, checks that required columns are present, cleans MIC values and returns an aligned data structure containing a numeric MIC matrix and metadata table.

The MIC-cleaning layer is deliberately conservative. Laboratory MIC values are commonly supplied as numeric values, text strings or censored values such as `<`, `<=`, `>` and `>=`. The package converts these values into analysis-ready numeric form using explicit user settings. For raw MIC data, the standard default is `log2`, reflecting the doubling-dilution structure of MIC assays. If users supply MICs that have already been log2-transformed, the transformation can be disabled. The app exposes this distinction directly: raw MIC data should normally use log2 transformation, whereas already transformed inputs should use no additional transformation.

Pairwise phenotype distances are computed from the cleaned MIC matrix. These distances define the target structure for map fitting. Low-dimensional maps are fitted using multidimensional scaling, and the package reports stress, stress-per-point, residual summaries and distance-correlation diagnostics. These diagnostics are part of the method rather than optional decoration, because a visually plausible two-dimensional map may still distort important pairwise relationships from the original MIC space.

### Calibration, rotation and map interpretation

`amrcartography` treats rotation and calibration as separate operations. Rotation changes the visual orientation of the map but does not alter pairwise map distances. Calibration estimates the relationship between distances in the fitted map and distances in the original phenotype distance matrix. This separation is important for interpretation: a one-unit map grid should not be treated as one MIC dilution merely because the figure has been stretched or manually dilated. Map units become interpretable only through the calibration model.

The package therefore supports manuscript-consistent calibration rather than a free-form manual dilation workflow. Users may rotate maps for visual alignment and presentation, but MIC-scale interpretation should follow the calibration relationship. This design preserves the distinction between graphical layout and quantitative scale.

### Comparison with external structure

The package can compare phenotype maps with external structures supplied by the user or produced by upstream analysis. External inputs can be provided as precomputed distance matrices, numeric feature tables, character-state tables, aligned allele profiles or aligned sequence tables. These inputs are validated, converted into external distances or maps and aligned to the phenotype map by isolate identifier.

The comparison workflow is intentionally modular. The phenotype map remains the primary object, while genotype, lineage, sequence or other structures are treated as external comparators. The package can join maps, compute reference-distance relationships, summarise centroids by metadata group, estimate within-group dispersion, compare clusters and generate side-by-side manuscript panels. This allows users to ask whether phenotype structure follows external biological structure without forcing the two into a single model.

### Visualisation and interactive prototype

The plotting layer uses `ggplot2` and `patchwork` with package-level cartography defaults. Visual fidelity is important in this project because map interpretation depends on scale, orientation, group colour, gridlines, density, legends and panel composition. The package therefore provides reusable plotting helpers and panel composers rather than leaving all figures as notebook-specific output.

The repository also includes a lightweight Streamlit prototype built around the R package backend. The app is phenotype-first: users select bundled examples or upload MIC data, choose cleaning and transformation settings, fit a phenotype map, inspect diagnostics and optionally add a genotype or structure map. Phenotype and genotype maps have separate controls for rotation, colouring, clustering, density overlays, faceting and gridlines. The app is useful for demonstration, teaching and exploratory QA, but the R package remains the primary reproducible interface.

### Validation and reproducibility

The validation layer is staged because cartographic analyses can fail silently. A map can be generated even when identifiers were mismatched, MIC columns were over-filtered, external structures were misaligned or output files were missing. The repository therefore checks data manifests, example datasets, sample identifiers, generated figures, generated tables, app/backend contracts, report generation and installed-package behaviour.

Validation is run locally and in GitHub Actions. The core validation entry point is `Rscript tools/run_validation.R --stage smoke`; additional checks rebuild manuscript figures and tables, exercise the Streamlit backend contract and run browser-level app QA on representative examples. Ubuntu R-CMD-check is treated as the authoritative release gate.

### Advanced provenance methods

The repository retains advanced association and mixed-model code inherited from the original project and thesis work, including single-feature scans, LIMIX wrappers, heritability and variance-decomposition helpers, permutation summaries, epistatic scan helpers and BLUP-related utilities. These methods are documented as provenance and expert extensions. They are not part of the default app workflow and are not the central claim of this manuscript, because their assumptions and validation requirements are more context-specific than the core MIC cartography layer.

## Example data

The manuscript uses four categories of example data. First, deterministic generic fixtures demonstrate the complete MIC-to-map workflow in a small transparent setting. Second, small public MIC subsets from the CDC & FDA Antimicrobial Resistance Isolate Bank test portability across organism names, drug panels and raw MIC string formats. These subsets include examples labelled as *Salmonella enterica*, *Campylobacter jejuni*, *Escherichia coli* O157, *Acinetobacter baumannii*, *Pseudomonas aeruginosa* and *Staphylococcus aureus*. They are intentionally small and are used for documentation and validation rather than biological inference.

Third, a larger *Streptococcus suis* demonstration bundle contains 633 isolates with raw MICs for amoxicillin, cefquinome, ceftiofur and penicillin, matched metadata and an external penicillin-binding protein distance structure. This bundle is derived from the sibling *S. suis* cartography workflow and is linked to the large-scale *S. suis* AMR dataset described by Hadjirin and colleagues. In this manuscript it is used as an integration example rather than a new biological analysis.

Fourth, a retained *S. pneumoniae* bundle preserves the pneumococcal beta-lactam case-study workflow associated with the original AMR cartography analysis. The MIC and penicillin-binding protein source data are linked to the Active Bacterial Core surveillance-derived dataset described by Li and colleagues. In the current manuscript, this case study functions as provenance and regression validation.

## Results

### A generic MIC table can be converted into a calibrated phenotype map

The generic example establishes the primary package workflow from raw MIC input to phenotype map (Figure 1). The input is a small ordinary data frame containing isolate identifiers, MIC columns and metadata. The package cleans the MIC values, applies log2 transformation, computes pairwise phenotype distances and fits a two-dimensional map. The same workflow returns goodness-of-fit summaries, including residual diagnostics that quantify how well the fitted map preserves the original phenotype distances.

This example is intentionally simple, but it is not a separate toy implementation. It uses the same package functions that support the larger case-study and app workflows. Its purpose is to make the data flow auditable: raw MIC values become a cleaned matrix, the matrix becomes a phenotype distance structure, the distance structure becomes a map, and the map is interpreted through diagnostics and calibration rather than appearance alone.

The generic workflow also clarifies the intended interpretation of map scale. Rotation is available for visual presentation, but MIC-scale statements should follow calibration. This prevents a manually adjusted map from being treated as quantitatively calibrated simply because gridlines appear convenient.

### Phenotype maps can be compared with external biological structure

The second example demonstrates phenotype-versus-external comparison (Figure 2). A phenotype map is fitted from MIC-derived distances, while a second map is fitted from aligned external numeric features. The two maps are joined by isolate identifier and displayed side by side with a reference-distance relationship. The same functions can be applied to external distance matrices, character-state profiles, allele tables or sequence-derived distances.

This workflow separates representation from interpretation. The phenotype map describes multidrug susceptibility structure; the external map describes another structure measured on the same isolates. Their relationship can then be examined using side-by-side panels, group centroids, within-group dispersion, reference-distance summaries or cluster overlays. This is useful in AMR datasets where phenotype structure may be partially related to genotype or lineage but not reducible to either.

The example also tests a common silent-failure mode: isolate alignment. If phenotype and external structures are joined incorrectly, the resulting figure may still look plausible. The package and validation layer therefore enforce identifier-aware joins and check that expected outputs are non-empty.

### Small public MIC examples show cross-species portability without claiming biological inference

The public MIC examples exercise the package across several organism labels and drug panels (Figure 3). Each example preserves raw MIC strings from the CDC & FDA Antimicrobial Resistance Isolate Bank, including censoring notation. The same cleaning, transformation, distance and mapping workflow is then applied without pneumococcus-specific assumptions.

The purpose of these examples is portability, not species-level inference. The subsets are deliberately small and should not be interpreted as representative resistance landscapes for the organisms shown. Their value is practical: they demonstrate that the core workflow can accept realistic public MIC formats across multiple bacterial contexts, and they provide compact fixtures for documentation, tests and app QA.

This evidence layer is important because it moves the manuscript away from a single-case-study software story. The package is not merely a wrapper around the pneumococcal analysis; it can process generic MIC data, public MIC examples and retained biological bundles through a common interface.

### A larger *Streptococcus suis* bundle exercises phenotype-first analysis with matched external structure

The *S. suis* bundle provides a larger non-pneumococcal integration example. It contains 633 isolates with raw MICs for four beta-lactam drugs, metadata and an external penicillin-binding protein distance matrix. The Streamlit app uses deterministic preview subsets for responsiveness, while the full bundled data remain available for package-level workflows.

The role of this example is to test the practical workflow at a more realistic scale. It checks that raw MIC cleaning, log2 transformation, phenotype mapping, metadata handling, optional genotype/structure comparison and report generation remain coherent outside the pneumococcal dataset. Because the bundle is derived from a separate *S. suis* cartography workflow and not presented here as a canonical new data release, the manuscript treats it as a demonstration and provenance asset rather than a new biological result.

### The retained pneumococcal case study validates continuity with the original analysis

The retained *S. pneumoniae* case study connects the package to the analysis that motivated AMR cartography (Figure 4). The packaged bundle includes phenotype and genotype map assets from the beta-lactam workflow and uses package-backed plotting functions to reproduce the central side-by-side map comparison. This case study is therefore a regression target: changes to MIC cleaning, map fitting, identifier handling, visual defaults or report generation can be evaluated against a known analysis path.

This framing is deliberately different from presenting the pneumococcal analysis as the main novelty. The biological conclusions from that work have already appeared online with the original AMR cartography manuscript. In the present manuscript, the pneumococcal bundle demonstrates continuity, provenance and validation. It shows that the general package still supports the original biological workflow while allowing the main software claim to rest on reusable functions and multi-example validation.

### Staged validation catches failures that ordinary execution can miss

The validation framework is itself a software-quality result (Table 3). During development, several failures were not simple syntax errors. Examples included local-only data paths, missing generated artifacts in CI, overly brittle pixel-perfect visual regression checks and app case-study inputs in which phenotype identifiers were not fully shared with genotype-map tables. These problems are typical of data-analysis software: figures may still render, but the analysis can be wrong or incomplete.

The current validation layer addresses this by checking multiple levels of the workflow. R package tests cover exported function behaviour and error paths. Smoke validation checks bundled data, manifests, expected files and backend contracts. Manuscript scripts rebuild figures and tables from package-backed code. Browser-level app QA checks phenotype-only analysis, phenotype-plus-structure analysis, the *S. pneumoniae* preview, the *S. suis* preview, report previews and zipped output bundles. GitHub Actions then runs the Linux release gate.

These checks do not prove biological correctness. They do, however, substantially reduce the risk that a future change silently breaks data alignment, output generation or the manuscript/app contract.

## Discussion

`amrcartography` formalises AMR phenotype cartography as reusable research software. Its main contribution is not a new resistance determinant, a universal genotype importer or a replacement for breakpoint-based reporting. Instead, the package provides a reproducible layer for studying how isolates are arranged in multidrug susceptibility space and for comparing that phenotype landscape with external biological structure.

This matters because AMR phenotypes are often multivariate. A resistance mechanism may affect several drugs unequally, a lineage may occupy a broad region of phenotype space, and a phenotype gradient may be visible before it crosses a clinical threshold. Single-drug summaries and marker-specific association tests remain necessary, but they do not fully describe this structure. Cartography provides a complementary descriptive and comparative view.

The manuscript’s multi-example design reflects the intended scope of the software. The generic workflow shows the core data path. The phenotype-versus-external example shows the central comparison task. The public MIC examples show input portability across organisms and drug panels. The *S. suis* bundle tests a larger non-pneumococcal workflow with metadata and external structure. The *S. pneumoniae* bundle preserves the original biological analysis as provenance and regression validation. Together, these examples support the claim that the package generalises the method without overstating biological conclusions from small teaching datasets.

The package also makes a methodological decision about visual output. In cartographic analysis, visual style is not superficial. Orientation, scale, gridlines, colour, density, legends and panel composition influence how a reader interprets phenotype structure. The package therefore standardises plotting defaults and panel composers so that package output, app output, thesis figures and manuscript figures remain visually coherent.

Several limitations remain. The public MIC examples are compact fixtures, not representative species datasets. The *S. suis* bundle is a demonstration asset derived from a sibling analysis workflow rather than a full independent data release. The Streamlit interface is useful for exploration and demonstration but is not yet a polished end-user product. The advanced mixed-model, LIMIX, epistasis, heritability and BLUP-related functions are retained as provenance and expert extensions, not as routine app workflows. Users who require formal genotype-phenotype association modelling should evaluate those methods separately and apply appropriate study-specific validation.

Future work should focus on manuscript-grade reproducibility, public example expansion with explicit provenance, stronger report export, and figure-by-figure visual parity between package-generated outputs and the original analysis. Larger app expansion should remain secondary to the phenotype-first package workflow unless additional features can be validated with the same rigor as the core cartography path.

## Conclusions

`amrcartography` provides a reusable software framework for analysing AMR MIC panels as calibrated phenotype landscapes. By combining MIC cleaning, phenotype distance construction, map fitting, calibration, external-structure comparison, manuscript-style visualisation and staged validation, the package turns a previously bespoke method into a general workflow. The retained pneumococcal analysis anchors the software in its original biological use case, while generic, public and *S. suis* examples demonstrate portability beyond that case study.

## Availability and requirements

Project name: `amrcartography`

Project home page: <https://github.com/AndrewBalmer/AMRC-R-package>

Archived release used for this manuscript: `v0.2.1`, <https://github.com/AndrewBalmer/AMRC-R-package/releases/tag/v0.2.1>

Operating systems: platform independent where R and package dependencies are available

Programming language: R, with a Python/Streamlit prototype interface

Other requirements: R >= 4.2.0; package dependencies listed in `DESCRIPTION`

License: MIT

## Data availability

The repository includes deterministic generic fixtures, small public MIC subsets derived from the CDC & FDA Antimicrobial Resistance Isolate Bank, a retained *S. pneumoniae* mapping bundle and an *S. suis* demonstration bundle. Public MIC example provenance and panel URLs are documented in `docs/PUBLIC_MIC_EXAMPLE_CITATIONS.md`. The public MIC subsets are provided for software documentation, validation and teaching rather than biological inference. The *S. pneumoniae* bundle is linked to the published source data of Li and colleagues, and the *S. suis* bundle is linked to the large-scale genomic AMR study of Hadjirin and colleagues.

## Code availability

Source code, validation scripts, app code, manuscript figure scripts and manuscript table scripts are available in the project repository at <https://github.com/AndrewBalmer/AMRC-R-package>. Manuscript figures can be regenerated with `Rscript tools/build_manuscript_figures.R`, manuscript tables with `Rscript tools/build_manuscript_tables.R`, and the staged smoke validation with `Rscript tools/run_validation.R --stage smoke`.

## Ethics approval and consent to participate

Not applicable. This manuscript describes software and uses public, synthetic, demonstration or previously assembled data resources.

## Consent for publication

Not applicable.

## Competing interests

The author declares no competing interests.

## Funding

No specific funding statement is declared in the repository metadata for this software manuscript.

## Author contributions

Andrew J. Balmer conceived the software package, migrated the original AMR cartography workflow into reusable functions, curated the bundled examples, implemented validation and app QA workflows, generated the manuscript figures and tables, and wrote the manuscript draft.

## Acknowledgements

The author acknowledges the researchers and public-health agencies whose data resources made the validation and teaching examples possible, including the CDC and FDA Antimicrobial Resistance Isolate Bank, the Active Bacterial Core surveillance-associated pneumococcal data resource and the authors of the large-scale *Streptococcus suis* AMR study. The package also depends on the R, `ggplot2`, `smacof`, `patchwork` and broader open-source scientific software ecosystems.

## References

1. Balmer AJ, Murray GGR, Lo SW, Restif O, Weinert LA. Antimicrobial Resistance Cartography: A generalisable framework for studying multivariate drug resistance. bioRxiv. 2025. doi:10.1101/2025.09.12.675231.
2. Li Y, Metcalf BJ, Chochua S, Li Z, Gertz RE Jr, Walker H, Hawkins PA, Tran T, McGee L, Beall BW, Active Bacterial Core surveillance team. Validation of beta-lactam minimum inhibitory concentration predictions for pneumococcal isolates with newly encountered penicillin binding protein (PBP) sequences. BMC Genomics. 2017;18:621. doi:10.1186/s12864-017-4017-7.
3. Hadjirin NF, Miller EL, Murray GGR, Yen PLK, Phuc HD, Wileman TM, Hernandez-Garcia J, Williamson SM, Parkhill J, Maskell DJ, Zhou R, Fittipaldi N, Gottschalk M, Tucker AWD, Hoa NT, Welch JJ, Weinert LA. Large-scale genomic analysis of antimicrobial resistance in the zoonotic pathogen *Streptococcus suis*. BMC Biology. 2021;19:191. doi:10.1186/s12915-021-01094-1.
4. Lutgring JD, Machado MJ, Benahmed FH, Conville P, Shawar RM, Patel J, Brown AC. FDA-CDC Antimicrobial Resistance Isolate Bank: a publicly available resource to support research, development, and regulatory requirements. Journal of Clinical Microbiology. 2018;56:e01415-17. doi:10.1128/JCM.01415-17.
5. Berends MS, Luz CF, Friedrich AW, Sinha BNM, Albers CJ, Glasner C. AMR: An R package for working with antimicrobial resistance data. Journal of Statistical Software. 2022;104:1-31. doi:10.18637/jss.v104.i03.
6. Feldgarden M, Brover V, Gonzalez-Escalona N, Frye JG, Haendiges J, Haft DH, Hoffmann M, Pettengill JB, Prasad AB, Tillman GE, Tyson GH, Klimke W. AMRFinderPlus and the Reference Gene Catalog facilitate examination of the genomic links among antimicrobial resistance, stress response, and virulence. Scientific Reports. 2021;11:12728. doi:10.1038/s41598-021-91456-0.
7. Bortolaia V, Kaas RS, Ruppe E, Roberts MC, Schwarz S, Cattoir V, Philippon A, Allesoe RL, Rebelo AR, Florensa AF, Fagelhauer L, Chakraborty T, Neumann B, Werner G, Bender JK, Stingl K, Nguyen M, Coppens J, Xavier BB, Malhotra-Kumar S, Westh H, Pinholt M, Anjum MF, Duggett NA, Kempf I, Nykasenoja S, Olkkola S, Wieczorek K, Amaro A, Clemente L, Mossong J, Losch S, Ragimbeau C, Lund O, Aarestrup FM. ResFinder 4.0 for predictions of phenotypes from genotypes. Journal of Antimicrobial Chemotherapy. 2020;75:3491-3500. doi:10.1093/jac/dkaa345.
8. Ellington MJ, Ekelund O, Aarestrup FM, Canton R, Doumith M, Giske C, Grundman H, Hasman H, Holden MTG, Hopkins KL, Iredell J, Kahlmeter G, Köser CU, MacGowan A, Mevius D, Mulvey M, Naas T, Peto T, Rolain JM, Samuelsen Ø, Woodford N. The role of whole genome sequencing in antimicrobial susceptibility testing of bacteria: report from the EUCAST Subcommittee. Clinical Microbiology and Infection. 2017;23:2-22. doi:10.1016/j.cmi.2016.11.012.
9. Kahlmeter G, Turnidge J. How to: ECOFFs, the why, the how, and the don'ts of EUCAST epidemiological cutoff values. Clinical Microbiology and Infection. 2022;28:952-954. doi:10.1016/j.cmi.2022.03.002.
10. World Health Organization. WHO bacterial priority pathogens list, 2024: bacterial pathogens of public health importance to guide research, development and strategies to prevent and control antimicrobial resistance. Geneva: World Health Organization; 2024.
11. Chindelevitch L, Mitchell CL, Srikumar S, et al. Ten simple rules for the sharing of bacterial genotype-phenotype data on antimicrobial resistance. PLOS Computational Biology. 2023;19:e1011129. doi:10.1371/journal.pcbi.1011129.
12. McArthur AG, Tsang KK. Antimicrobial resistance surveillance in the genomic age. Annals of the New York Academy of Sciences. 2017;1388:78-91. doi:10.1111/nyas.13289.
13. Lex A, Gehlenborg N, Strobelt H, Vuillemot R, Pfister H. UpSet: visualization of intersecting sets. IEEE Transactions on Visualization and Computer Graphics. 2014;20:1983-1992. doi:10.1109/TVCG.2014.2346248.
14. R Core Team. R: A language and environment for statistical computing. Vienna: R Foundation for Statistical Computing; 2026. <https://www.R-project.org/>.
15. Wickham H. ggplot2: Elegant graphics for data analysis. New York: Springer-Verlag; 2016.
16. Wickham H, Averick M, Bryan J, Chang W, McGowan LD, François R, Grolemund G, Hayes A, Henry L, Hester J, Kuhn M, Pedersen TL, Miller E, Bache SM, Müller K, Ooms J, Robinson D, Seidel DP, Spinu V, Takahashi K, Vaughan D, Wilke C, Woo K, Yutani H. Welcome to the tidyverse. Journal of Open Source Software. 2019;4:1686. doi:10.21105/joss.01686.
17. Mair P, Groenen PJF, de Leeuw J. Multidimensional scaling using majorization: SMACOF in R. Journal of Statistical Software. 2022;102:1-47. doi:10.18637/jss.v102.i10.
18. Pedersen TL. patchwork: the composer of plots. R package version 1.3.2. 2025. doi:10.32614/CRAN.package.patchwork.
