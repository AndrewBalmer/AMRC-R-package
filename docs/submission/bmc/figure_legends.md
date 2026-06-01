# Figure Legends

## Figure 1

File: [figure01_generic_workflow.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure01_generic_workflow.png)

Title: Generic MIC cartography workflow.

Caption: A bundled generic MIC table is processed through the core
`amrcartography` workflow. Raw MIC values are parsed from user-facing tabular
input, converted to numeric values, log2-transformed to reflect doubling
dilutions, converted into pairwise phenotype distances and fitted as a
two-dimensional map. Points represent isolates and colour indicates bundled
lineage metadata. The diagnostic panel summarizes residual fit after mapping,
illustrating that cartographic interpretation depends on goodness-of-fit and
calibration rather than visual appearance alone.

## Figure 2

File: [figure02_comparison.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure02_comparison.png)

Title: Phenotype-versus-external structure comparison.

Caption: Phenotype and external feature maps are fitted from identifier-aligned
isolate data and compared using a shared plotting surface. The phenotype map is
built from MIC-derived distances, while the external map is built from aligned
non-phenotype features. The reference-distance panel summarizes how distance
from a selected reference group differs between phenotype and external map
space. This illustrates the package workflow for comparing multidrug
susceptibility structure with genotype, lineage, sequence or other external
biological structure while keeping the phenotype map as the primary analysis
object.

## Figure 3

File: [figure03_cross_species.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure03_cross_species.png)

Title: Cross-species public MIC portability examples.

Caption: Six compact public MIC subsets from the CDC & FDA Antimicrobial
Resistance Isolate Bank are processed through the same MIC cleaning,
transformation, distance and mapping workflow. Panels show *Salmonella
enterica*, *Campylobacter jejuni*, *Escherichia coli* O157, *Acinetobacter
baumannii*, *Pseudomonas aeruginosa* and *Staphylococcus aureus*. Each subset
contains four isolates and six or seven MIC columns, preserving raw public MIC
strings and censoring notation where present. The panels demonstrate that the
package can operate on different organism labels, MIC schemas, drug panels and
censored MIC formats without pneumococcus-specific assumptions. These examples
are intended for portability testing, documentation and teaching, not for
estimating species-level resistance landscapes.

## Figure 4

File: [figure04_spneumoniae_validation.png](/Users/ab69/AMRC-R-package/docs/manuscript-figures/figure04_spneumoniae_validation.png)

Title: Retained pneumococcal validation and provenance case study.

Caption: Package-backed phenotype and genotype maps preserve the original
*Streptococcus pneumoniae* beta-lactam cartography workflow as a worked example
and regression target. The phenotype map summarizes multivariate MIC structure
and the genotype map summarizes retained external penicillin-binding protein
structure. The figure demonstrates continuity with the original biological
analysis while the manuscript's main software claim rests on the generic
package workflow and multi-example validation rather than re-presenting the
pneumococcal result as the central novelty.

