# Manuscript Tables And Captions

Figures are regenerated with:

```sh
Rscript tools/build_manuscript_figures.R
```

Tables are regenerated with:

```sh
Rscript tools/build_manuscript_tables.R
```

## Figure 1

File: [figure01_generic_workflow.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure01_generic_workflow.png)

Title: Generic MIC cartography workflow.

Caption: A bundled MIC table is processed through the core `amrcartography`
workflow. Raw MIC values are cleaned, log2-transformed, converted into
pairwise phenotype distances and fitted as a two-dimensional map. Points
represent isolates and colour indicates bundled lineage metadata. The
diagnostic panel summarizes residual fit after mapping, illustrating that
cartographic interpretation depends on goodness-of-fit and calibration rather
than visual appearance alone.

## Figure 2

File: [figure02_comparison.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure02_comparison.png)

Title: Phenotype-versus-external structure comparison.

Caption: Phenotype and external feature maps are fitted from aligned isolate
data and compared using a shared plotting surface. The phenotype map is built
from MIC-derived distances, while the external map is built from aligned
non-phenotype features. The reference-distance panel summarizes how distance
from a selected reference group differs between phenotype and external map
space. This illustrates the package workflow for comparing multidrug
susceptibility structure with genotype, lineage, sequence or other external
biological structure.

## Figure 3

File: [figure03_cross_species.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure03_cross_species.png)

Title: Cross-species public MIC portability examples.

Caption: Small public MIC subsets from the CDC & FDA Antimicrobial Resistance
Isolate Bank are processed through the same MIC cleaning, transformation,
distance and mapping workflow. The panels demonstrate that the package can
operate on different organism labels and drug panels without pneumococcus-
specific assumptions. These compact examples are intended for portability
testing, documentation and teaching, not for estimating species-level
resistance landscapes.

## Figure 4

File: [figure04_spneumoniae_validation.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure04_spneumoniae_validation.png)

Title: Retained pneumococcal validation and provenance case study.

Caption: Package-backed phenotype and genotype maps preserve the original
*Streptococcus pneumoniae* beta-lactam cartography workflow as a worked
example and regression target. The phenotype map summarizes multivariate MIC
structure and the genotype map summarizes retained external penicillin-binding
protein structure. The figure demonstrates continuity with the original
biological analysis while the manuscript's main software claim rests on the
generic package workflow and multi-example validation.

## Table 1

File: [table01_workflow_components.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table01_workflow_components.csv)

Title: Main workflow components and representative package functions.

Caption: Package workflow stages, representative exported functions, outputs
and manuscript claims supported by each stage. The table identifies which
parts of the original cartography workflow have been promoted into reusable
package functions.

## Table 2

File: [table02_example_datasets.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table02_example_datasets.csv)

Title: Example datasets included in the manuscript, package and app workflows.

Caption: Bundled generic fixtures, public MIC subsets, the larger *S. suis*
demonstration bundle and the retained *S. pneumoniae* validation bundle. The
public MIC subsets are intentionally small and should be interpreted as
documentation and validation fixtures rather than biological benchmark
datasets.

## Table 3

File: [table03_validation_gates.csv](/Users/ab69/AMRC-R-package/docs/manuscript-tables/table03_validation_gates.csv)

Title: Validation gates used for the `v0.2.1` software release.

Caption: Validation layers used to detect schema drift, identifier mismatches,
missing files, empty outputs, app regressions and installed-package failures.
The table documents checks that go beyond ordinary function-level unit tests
and are intended to be rerun as the repository evolves.

## Supplementary figure candidates

Supplementary Figure S1: Streamlit phenotype-first workflow screenshots.

Supplementary Figure S2: Visual audit panels documenting manuscript/thesis
style continuity.

Supplementary Figure S3: *Streptococcus suis* phenotype-first demonstration
using the bundled raw MIC panel and matched external structure.

Supplementary Figure S4: Advanced provenance workflow schematic for retained
association, mixed-model, epistatic, heritability and BLUP-related methods.

## Supplementary table candidates

Supplementary Table S1: Full exported function inventory grouped by workflow.

Supplementary Table S2: Public MIC source panels, URLs and citation notes.

Supplementary Table S3: Validation checklist and CI status at release.

Supplementary Table S4: App capability matrix at `v0.2.1`.
