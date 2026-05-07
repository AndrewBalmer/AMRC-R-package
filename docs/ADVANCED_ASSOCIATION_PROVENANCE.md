# Advanced Association Provenance

This package is centred on antimicrobial resistance cartography:

- cleaning MIC tables
- building phenotype maps
- optionally comparing phenotype maps with genotype or other structure maps
- summarising clusters, metadata groups, reference distances, and map fit

The mixed-model, LIMIX, heritability, epistatic, permutation, and BLUP material
comes from the original AMR cartography manuscript and thesis analysis layer.
Those methods were used downstream of the main map workflow to interrogate
candidate genotype-to-phenotype relationships. They are useful provenance and
advanced reference workflows, but they are not the primary package or app
interface.

## Current status

The following functionality remains available as advanced package tooling:

- simple fixed-effect feature scans
- R-native grouped random-intercept mixed models
- optional Python/LIMIX input staging and execution wrappers
- optional LIMIX heritability and variance-decomposition wrappers
- epistatic marker construction and optional LIMIX epistatic scans
- permutation wrappers for LIMIX-style scans
- lightweight kinship-BLUP prediction helpers

These functions are intentionally not exposed as first-line Streamlit app
features. They require stronger user assumptions, larger inputs, and more
domain review than the phenotype-map workflow.

## Recommended interpretation

Use the advanced association layer when you are deliberately recreating or
extending the original manuscript-style genotype-to-phenotype analyses.

For general package users, the recommended route is:

1. build and validate a phenotype map
2. optionally build a genotype or structure map
3. compare maps, groups, clusters, and reference distances
4. use single-feature and cluster-difference summaries before considering
   mixed-model analyses

Mixed-model and LIMIX outputs should not be treated as automatic evidence.
They need explicit checks for population structure, sample matching, model
inputs, marker frequency, multiple testing, and biological plausibility.

## Heritability and BLUP

Heritability and BLUP-style prediction remain useful as specialist follow-up
analyses.

The package keeps:

- LIMIX-backed heritability and variance-decomposition staging wrappers for
  users recreating manuscript-style analyses
- a lightweight R-side kinship-BLUP helper for prediction workflows
- grouped cross-validation support so predictions can be evaluated on unseen
  genotype, lineage, or type groups rather than only random isolate splits

The grouped BLUP evaluation pattern follows the more recent cleaned
`AMR_cartography_suis` workflow, where random folds were not enough to describe
prediction performance on novel PBP/genotype types.

## What should stay out of the app for now

The following should remain package/documentation/provenance workflows unless a
future release designs a dedicated expert-facing association interface:

- LIMIX multivariate mixed-model scans
- LIMIX epistatic scans
- permutation scans
- multi-component variance decomposition
- full BLUP model-comparison workflows
- organism-specific association evidence ranking

This keeps the app focused on the map workflow while preserving the original
paper methods in a traceable, reusable form.
