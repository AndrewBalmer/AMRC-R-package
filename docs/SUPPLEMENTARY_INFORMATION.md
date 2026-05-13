# Supplementary Information

Manuscript: `amrcartography: reusable cartographic analysis of multidrug antimicrobial susceptibility phenotypes`

Software release described: `v0.2.1`

## Supplementary Note 1: Package workflow

`amrcartography` starts from a phenotype table in which rows represent isolates and columns contain isolate identifiers, MIC values and optional metadata. The minimal package workflow validates the isolate identifier column, checks the requested MIC columns, converts common laboratory MIC strings into numeric values, applies the selected transformation and constructs a cleaned MIC matrix aligned to metadata.

For raw MIC values, the standard transformation is log2 because MIC assays are normally measured on a doubling-dilution scale. If the user supplies columns that have already been log2-transformed, the transformation should be set to `none`. This distinction is used consistently in the package and in the Streamlit prototype.

The cleaned MIC matrix is converted into pairwise phenotype distances. These distances are fitted as a low-dimensional map using multidimensional scaling. The fitted object is accompanied by stress, residual and distance-correlation summaries so that the user can inspect whether the map preserves the original phenotype structure.

## Supplementary Note 2: Calibration and map-unit interpretation

Rotation and calibration are distinct steps. Rotation changes the map orientation and is useful for visual comparison, panel composition and continuity with previous figures. It does not change distances among isolates. Calibration estimates how distances in the fitted map relate to distances in the original phenotype space.

This distinction determines how map grids should be interpreted. A one-unit gridline on a map should be treated as a phenotype-scale unit only when the calibration model supports that interpretation. The package does not recommend manual dilation as a substitute for calibration. Manual stretching may make a figure visually convenient, but it does not provide a quantitative link back to MIC distances.

The manuscript figures therefore use package-backed map fitting and plotting defaults, while quantitative scale interpretation follows the calibration relationship. This keeps visual presentation separate from phenotype-distance inference.

## Supplementary Note 3: Supported external data structures

The package supports phenotype-versus-external comparison through an identifier-aligned map table. External structure can be supplied as a precomputed distance matrix, a numeric feature table, a character-state feature table, an aligned allele table or an aligned sequence table. These structures are standardised before comparison so that the phenotype map and external structure are joined by isolate identifier.

This design is intentionally broad but not assumption-free. Users remain responsible for producing biologically meaningful external inputs. For example, a penicillin-binding protein distance matrix, a lineage-distance matrix and an aligned sequence table can all be compared with a phenotype map, but each carries different assumptions about what similarity means. The package checks alignment and format; biological interpretation remains study-specific.

Identifier matching is treated as a validation requirement because it is a high-risk silent failure mode. If phenotype and external rows are misaligned, a map comparison can still render while being scientifically wrong. The repository validation layer and Streamlit case-study loader therefore check that bundled phenotype and genotype/structure inputs share the expected identifiers before analysis.

## Supplementary Note 4: Validation framework

Validation is staged throughout the repository. Function-level tests check exported helper behaviour and error handling. Repository smoke validation checks bundled data, manifests, expected generated files and the app backend contract. Manuscript scripts rebuild static figures and tables from package-backed code. Browser-level QA exercises representative app workflows, including MIC-only analysis, phenotype-plus-structure analysis, retained *S. pneumoniae* previews, *S. suis* previews, report rendering and zipped result bundles.

The main local commands are:

```sh
Rscript tools/run_validation.R --stage smoke
Rscript tools/build_manuscript_figures.R
Rscript tools/build_manuscript_tables.R
python3 streamlit_app/check_ui_contract.py
python3 streamlit_app/run_browser_qa.py --include-case-studies
```

GitHub Actions provides the Linux release gate through the repository R-CMD-check workflow. That workflow runs package checks on Ubuntu release and devel, alongside docs-sanity validation. Passing validation does not prove that a scientific interpretation is correct, but it reduces the likelihood of silent data, schema, output or reporting failures.

## Supplementary Note 5: Streamlit prototype

The Streamlit prototype provides an interactive wrapper around the package backend. It is phenotype-first. The initial path is to select or upload MIC data, choose MIC-cleaning and transformation settings, fit a phenotype map, inspect fit summaries and generate reports. Genotype or external structure maps are optional and are controlled separately from the phenotype map.

The app exposes separate controls for phenotype and genotype map rotation, colouring, faceting, density overlays, clustering and gridlines. This separation is necessary because a phenotype map and an external structure map may need different orientations and display settings. The app also includes bundled demonstration datasets, report previews, downloadable output bundles and contextual guidance for interpreting each analysis section.

The prototype is not presented as the main scientific product. It is a demonstration and exploratory interface for the package. Advanced association, LIMIX, epistatic, heritability and full BLUP workflows are intentionally not part of the default app surface.

## Supplementary Note 6: Advanced provenance methods

The repository retains advanced association and mixed-model logic that was useful in earlier project stages. These methods include marker-matrix preparation, single-feature scans, adjusted and unadjusted model summaries, LIMIX staging, multivariate mixed-model wrappers, heritability and variance-decomposition helpers, epistatic scan helpers, permutation summaries and BLUP-related utilities.

These methods are documented as provenance and expert extensions because they have stronger study-specific assumptions than the core cartography workflow. A formal association model may require explicit phenotype definitions, genetic relatedness correction, marker filtering, multiple-testing control, convergence diagnostics and organism-specific biological review. For that reason, the manuscript does not make the advanced modelling layer central to the software claim.

## Supplementary datasets

The generic fixture is a deterministic package example used for documentation, tests and smoke validation. The public MIC examples are small subsets from the CDC & FDA Antimicrobial Resistance Isolate Bank and are used to test raw MIC parsing across several organism labels and drug panels. They are not biological benchmark datasets.

The *S. suis* demonstration bundle contains 633 isolates with raw MICs for four beta-lactam drugs, metadata and an external penicillin-binding protein distance matrix. It is derived from the sibling *S. suis* cartography workflow and linked to the large-scale genomic AMR study by Hadjirin and colleagues. It is used here as a larger integration example and app QA dataset.

The retained *S. pneumoniae* bundle preserves the original AMR cartography case-study workflow using phenotype and genotype map assets linked to the Li and colleagues pneumococcal beta-lactam dataset. In this manuscript, it functions as provenance and regression validation rather than the primary new biological result.

## Supplementary tables and reproducibility assets

Supplementary Table S1 corresponds to the workflow component table generated at `docs/manuscript-tables/table01_workflow_components.csv`.

Supplementary Table S2 corresponds to the example dataset table generated at `docs/manuscript-tables/table02_example_datasets.csv`.

Supplementary Table S3 corresponds to the validation gate table generated at `docs/manuscript-tables/table03_validation_gates.csv`.

Supplementary provenance for public MIC examples is documented in `docs/PUBLIC_MIC_EXAMPLE_CITATIONS.md`, and package-level data provenance is documented in `docs/DATA_PROVENANCE.md`.
