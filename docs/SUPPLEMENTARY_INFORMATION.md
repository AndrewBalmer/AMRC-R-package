# Supplementary Information Draft

Manuscript: `amrcartography: a generic toolkit for cartographic analysis of
antimicrobial susceptibility phenotypes`

Software baseline: `v0.2.0`

Maintenance/app release: `v0.2.1`

## Supplementary Note 1: Package Workflow

The `amrcartography` workflow starts from a phenotype MIC table. A minimal
input table requires:

- one isolate identifier column
- one or more MIC columns
- optional metadata columns for plotting, grouping, clustering, or faceting

The core phenotype path is:

```r
mic_data <- amrc_standardise_mic_data(
  data = mic_table,
  id_col = "isolate_id",
  mic_cols = c("drug_a", "drug_b", "drug_c"),
  metadata_cols = c("lineage", "source"),
  transform = "log2"
)

phenotype_distance <- amrc_compute_mic_distance(mic_data)
phenotype_map <- amrc_compute_mds(phenotype_distance)
fit_report <- amrc_map_fit_report(phenotype_map)
```

For raw MIC data, `transform = "log2"` is the standard default. If the input
MIC columns are already log2-transformed, users should set `transform = "none"`.

## Supplementary Note 2: Calibration And Map Units

Map rotation and calibration are separate operations. Rotation changes visual
orientation but does not change pairwise map distances. Calibration estimates
how map distances relate to phenotype distances.

The package therefore treats one-unit gridlines as interpretable in MIC-style
units only after model-based calibration. Manual dilation is intentionally not
the recommended route for forcing a map to match one MIC unit. This preserves
the manuscript-consistent interpretation of map scale.

## Supplementary Note 3: External Structure Inputs

The package can compare phenotype maps with external structure supplied as:

- precomputed distance matrices
- numeric feature tables
- character-state feature tables
- aligned sequence or allele tables
- package-prepared genotype structures

The downstream comparison path depends on isolate identifier alignment. The
validation layer and app case-study loader explicitly check or enforce this
alignment to avoid phenotype rows being compared with missing genotype rows.

## Supplementary Note 4: Advanced Association Provenance

The repository contains advanced association and mixed-model helpers inherited
from the original manuscript/thesis workflow. These include:

- single-feature association scans
- R-native linear and mixed-model wrappers
- LIMIX input staging
- LIMIX multivariate mixed-model wrappers
- heritability and variance-decomposition wrappers
- epistatic marker construction
- permutation scan summaries
- kinship BLUP helpers

These are retained as expert/provenance workflows. They should not be presented
as the primary app workflow unless a future release adds stronger validation,
clearer user guidance, and dedicated case-study examples.

## Supplementary Note 5: Streamlit App

The Streamlit app is a lightweight prototype around the package backend. It is
phenotype-first. The default workflow is:

1. upload or select MIC phenotype data
2. choose MIC cleaning and transformation settings
3. fit a phenotype map
4. inspect fit, diagnostics, clustering, and reports
5. optionally add a genotype or structure map

The app exposes separate controls for phenotype and genotype maps. Rotation,
colouring, faceting, density contours, clustering, and gridline display are not
shared between maps.

The app does not expose mixed-model, LIMIX, epistatic, heritability, or full
BLUP workflows in the default interface.

## Supplementary Note 6: Validation

Validation is staged rather than treated as a final-only release step. The
main validation commands are:

```sh
Rscript tools/run_validation.R --stage smoke
python3 streamlit_app/check_ui_contract.py
python3 streamlit_app/run_browser_qa.py --include-case-studies
Rscript tools/build_manuscript_figures.R
Rscript tools/build_manuscript_tables.R
```

CI validation runs the R-CMD-check workflow on Ubuntu release and devel, plus
the repository docs-sanity validation stage.

## Supplementary Note 7: Example Data

The package includes several classes of example data:

- generic synthetic fixtures for documentation and tests
- tiny public MIC subsets from the CDC & FDA Antimicrobial Resistance Isolate
  Bank
- a retained *Streptococcus pneumoniae* mapping bundle
- an *S. suis* app/demo bundle

The public MIC subsets are intentionally tiny and should not be used for new
biological inference. Their purpose is to exercise MIC parsing, cleaning,
transformation, and mapping across multiple organism labels and drug panels.

## Supplementary Tables

Supplementary Table S1:

Full workflow component table generated from
[tools/build_manuscript_tables.R](/Users/ab69/AMRC-R-package/tools/build_manuscript_tables.R).

Supplementary Table S2:

Example dataset table generated at
[docs/manuscript-tables/table02_example_datasets.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table02_example_datasets.csv).

Supplementary Table S3:

Validation gate table generated at
[docs/manuscript-tables/table03_validation_gates.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table03_validation_gates.csv).

Supplementary Table S4:

Public MIC source citation notes in
[docs/PUBLIC_MIC_EXAMPLE_CITATIONS.md](/Users/ab69/AMRC-R-package/docs/PUBLIC_MIC_EXAMPLE_CITATIONS.md).

## Supplementary Reproducibility Checklist

- Repository release exists for `v0.2.1`.
- Manuscript baseline remains `v0.2.0` unless explicitly changed.
- Figure files regenerate from package-backed code.
- Table files regenerate from package-backed code.
- Public example citations are documented.
- App QA includes phenotype-only, phenotype-plus-genotype, *S. pneumoniae*,
  and *S. suis* workflows.
- Advanced mixed-model workflows are documented as provenance/expert methods,
  not as default app workflows.
