# amrcartography

> Work-in-progress notice: this repository is under active development and is provided as-is. It may change substantially, and it should not yet be treated as a stable release.
>
> This is the package/code repository only. It is not the source repository for the related manuscript, which is maintained separately.

`amrcartography` is an R package for reusable MIC cartography workflows. The
main goal of the package is to let users bring their own MIC dataset, build
phenotypic maps, compare those maps to an external distance structure when
available, and reuse the same calibration, robustness, clustering, and plotting
tools across datasets.

The repository still contains the migrated *S. pneumoniae* analysis because it
is useful as a worked example and regression target, but that case study is not
the primary purpose of the package.

The package is now at the point where it has:

- a locked package identity and reproducible environment setup
- generic MIC validation, standardisation, and distance helpers
- reusable MDS, robustness, clustering, calibration, and comparison helpers
- explicit support for precomputed, numeric-feature, and character-feature
  external data structures
- generic preparation helpers for bound feature tables, aligned sequence data,
  Hamming-style genotype distances, and binary feature scans
- generic plotting helpers for metadata-coloured maps, MIC-style grid spacing,
  density overlays, marginal distributions, faceting, group envelopes, and
  biplot-style vectors
- a package-backed *S. pneumoniae* case study for example and regression use
- deterministic and fixture-based regression tests

## Status

This is still a GitHub release rather than a CRAN release, and the repository
should be used as-is. The current public milestone is `0.1.0`: the generic API
is now intentionally usable, but the package is still being prepared for
manuscript-centered release and long-term API stabilisation. This repository is
also separate from the related manuscript
repository: it contains the package, migrated analysis code, and development
documentation, not the manuscript submission source itself. The long-term
package goal is a generic MIC cartography toolkit; the current
*S. pneumoniae* workflow should be read as a worked example and validation
case, not the permanent center of the public API. Any interactive app remains
explicitly deferred until the manuscript workflow and exported API stop
moving.

## Installation

For day-to-day package use, install from GitHub:

```r
install.packages("remotes")
remotes::install_github("AndrewBalmer/AMRC-R-package")
```

For repository development and exact dependency capture, use the project-local `renv` environment instead:

```r
source("renv/activate.R")
renv::restore()
```

## Quick Start

Start with the generic vignette if you want to use your own MIC table:

```r
vignette("using-your-own-mic-data", package = "amrcartography")
```

If you want help choosing and preparing the external structure that will be
compared to a phenotype map, use:

```r
vignette("external-data-structures", package = "amrcartography")
```

If you want the advanced feature-analysis layer, including mixed models,
epistasis, heritability, variance decomposition, permutation scans, and
BLUP-style prediction, use:

```r
vignette("advanced-feature-and-mixed-model-analysis", package = "amrcartography")
```

The *S. pneumoniae* case-study vignette is still available separately:

```r
vignette("end-to-end-spneumoniae", package = "amrcartography")
```

For quick generic examples, you can load the bundled toy datasets directly:

```r
library(amrcartography)

amrc_example_data("mic_raw")
amrc_example_data("external_numeric")
```

You can also locate the bundled *S. pneumoniae* example files directly:

```r
library(amrcartography)

amrc_spneumoniae_example_paths("mini_raw")
```

The `mini_raw` example is a tiny raw-input workflow intended for the
case-study vignette and CI. The larger notebook-scale generated outputs are not
bundled in the installed package; build them locally when you need the full
repository workflow.

The core object contracts used throughout these workflows are documented in
[docs/OBJECT_CONTRACTS.md](docs/OBJECT_CONTRACTS.md).

## Generic Workflow

This is the generic package workflow for an arbitrary MIC table:

1. Validate and standardise the MIC table with `amrc_standardise_mic_data()`.
2. Build a phenotype distance matrix with `amrc_compute_mic_distance()`.
3. Fit and diagnose a phenotype map with `amrc_compute_mds()` and `amrc_map_fit_report()`.
4. Optionally prepare external/genotype features with `amrc_prepare_external_features()` and then build an external distance structure with `amrc_compute_external_distance()`, `amrc_compute_external_feature_distance()`, `amrc_compute_hamming_distance()`, or `amrc_compute_sequence_distance()`.
5. Fit an external map with `amrc_compute_mds()`.
6. Build a shared phenotype/external comparison table with `amrc_prepare_map_data()`.
7. Cluster either map with `amrc_cluster_map()` and attach labels with `amrc_add_cluster_assignments()`.
8. Summarise distances from a chosen reference entry with `amrc_compute_reference_distance_table()` and `amrc_summarise_reference_distance_table()`.
9. Plot maps generically with `amrc_plot_map()`, `amrc_add_marginal_distribution()`, and `amrc_add_biplot_vectors()`.

For example:

```r
library(amrcartography)

mic_data <- amrc_standardise_mic_data(
  data = my_mic_table,
  id_col = "isolate_id",
  mic_cols = c("drug_a", "drug_b", "drug_c"),
  metadata_cols = c("country", "lineage"),
  transform = "log2",
  less_than = "numeric",
  greater_than = "numeric"
)

phenotype_distance <- amrc_compute_mic_distance(mic_data)
phenotype_map <- amrc_compute_mds(phenotype_distance)
phenotype_report <- amrc_map_fit_report(phenotype_map)

external_distance <- amrc_compute_sequence_distance(
  data = my_aligned_sequence_table,
  id_col = "isolate_id",
  sequence_cols = c("locus_1", "locus_2", "locus_3")
)
external_map <- amrc_compute_mds(external_distance)

comparison_bundle <- amrc_prepare_map_data(
  metadata = mic_data$metadata,
  phenotype_mds = phenotype_map,
  external_mds = external_map,
  id_col = "isolate_id",
  group_col = "lineage"
)

reference_distances <- amrc_compute_reference_distance_table(
  data = comparison_bundle$data,
  reference_value = "lineage_A",
  reference_col = "lineage",
  phenotype_distance_col = "phenotype_distance",
  external_distance_col = "external_distance"
)
```

If you only need phenotype cartography, you can stop after the MIC
standardisation, distance, and phenotype-map steps.

Raw MIC tables often include censoring prefixes such as `<0.5` or `>=8`, and
sometimes also carry extra symbol clutter such as `~0.5`, `-1`, or `<_0.25`.
The generic MIC preprocessing helpers clean those values before the log
transform. Use `less_than = "numeric"` / `greater_than = "numeric"` to strip
the qualifier and keep the reported number, or `less_than = "half"` /
`greater_than = "double"` to shift censored values by one doubling dilution.

## External Data Formats

The package currently supports four generic ways to bring in the non-MIC
structure you want to compare against the phenotype map:

- a precomputed external distance matrix via `amrc_compute_external_distance()`
- bound or metadata-aligned feature tables via `amrc_bind_external_tables()`
  and `amrc_prepare_external_features()`
- an aligned numeric feature table via `amrc_standardise_external_data()` and
  `amrc_compute_external_feature_distance()`
- an aligned character-state feature table via
  `amrc_standardise_external_data(feature_mode = "character")` and
  `amrc_compute_external_feature_distance()`
- an aligned sequence or allele table via `amrc_compute_sequence_distance()`
- an explicit Hamming-style mismatch distance via `amrc_compute_hamming_distance()`

This means the package is already usable for non-pneumococcal datasets such as
*E. coli* or *Klebsiella* when you can supply aligned sequence/allele data,
gene presence/absence features, numeric feature tables, or a precomputed
distance matrix. The package now includes generic feature-table preparation, so
the remaining non-generic step is mostly only the very upstream parsing when
your starting point is organism-specific raw genotype files such as bespoke
FASTA or VCF exports. In those cases, convert the raw genotype data into
either:

- a precomputed isolate-by-isolate distance matrix
- an aligned numeric feature table
- an aligned character-state or allele table

and then use the generic API from that point onward.

The dedicated external-data vignette walks through those options with small
reproducible examples.

## Plotting

The package now includes generic plotting helpers for the main map workflows:

- `amrc_plot_map()` for metadata-coloured maps with optional `grid_spacing = 1`
  when the coordinates have already been calibrated onto MIC units
- `amrc_add_group_envelopes()` for ellipse-style group outlines or filled
  envelopes
- `amrc_add_marginal_distribution()` for histogram or density marginals
- `amrc_compute_biplot_vectors()` and `amrc_add_biplot_vectors()` for
  biplot-style overlays of numeric metadata variables
- `amrc_compute_calibrated_biplot_axes()` and
  `amrc_add_calibrated_biplot_axes()` for calibrated tick-mark biplot axes
- `amrc_plot_cluster_map()`, `amrc_plot_cluster_elbow()`,
  `amrc_plot_distance_histogram()`, and
  `amrc_plot_reference_distance_relationship()` for the main comparison and
  clustering plots

For group-level phenotype-versus-external summaries, the generic comparison
layer also now includes:

- `amrc_compute_group_centroids()`
- `amrc_compute_group_pairwise_distances()`
- `amrc_compute_group_distance_summary()`
- `amrc_summarise_nested_group_pairwise_distances()`
- `amrc_compare_cluster_assignments()`
- `amrc_scan_single_feature_associations()`
- `amrc_fit_multivariate_linear_model()`
- `amrc_fit_linear_mixed_model()`
- `amrc_scan_single_feature_mixed_models()`
- `amrc_write_limix_mvlmm_inputs()`
- `amrc_run_limix_lmm_scan()`
- `amrc_run_limix_mvlmm()`

These are the generic building blocks for workflows like “compare MLST groups”,
“compare lineages”, “summarise distances among subtypes within each gene
background”, “scan gene presence/absence markers against multiple phenotype
responses”, fit grouped random-intercept LMMs, or run manuscript-style LIMIX
mixed-model scans in a reusable generic form.

The package now offers four association-analysis tiers:

- simple fixed-effect feature scans with
  `amrc_scan_single_feature_associations()`
- direct multivariate linear models with `amrc_fit_multivariate_linear_model()`
- R-native mixed models with `amrc_fit_linear_mixed_model()` and
  `amrc_scan_single_feature_mixed_models()`
- optional Python/LIMIX scans with `amrc_run_limix_lmm_scan()` and
  `amrc_run_limix_mvlmm()` for users who want a true multivariate mixed-model
  route

The LIMIX helpers are optional advanced tooling. They require a working Python
environment with `limix`, `numpy`, and `pandas`, but they accept the same kind
of generic marker matrices that the simpler R-side association helpers use.

That same advanced layer now also exposes the other reusable manuscript-era
mixed-model ideas in generic form:

- heritability estimation with `amrc_run_limix_heritability()`
- variance decomposition across multiple kinship components with
  `amrc_run_limix_variance_decomposition()`
- pairwise interaction scans with `amrc_generate_epistatic_markers()` and
  `amrc_run_limix_epistatic_scan()`
- permutation scans with `amrc_run_limix_permutation_scan()`
- BLUP-style kinship prediction helpers with `amrc_make_train_test_split()`,
  `amrc_make_cv_folds()`, `amrc_fit_kinship_blup()`, and
  `amrc_cross_validate_kinship_blup()`

## S. pneumoniae Case Study

The organism-specific `S. pneumoniae` helpers remain in the package as
case-study infrastructure, legacy-migration support, and regression targets.
They are still useful when you want to reproduce the migrated pneumococcal
workflow or rebuild the notebook-scale example outputs from the bundled raw
example inputs.

The main case-study wrappers are:

- `amrc_process_spneumoniae_phenotype()`
- `amrc_process_spneumoniae_genotype()`
- `amrc_prepare_spneumoniae_map_data()`

Those functions remain supported for compatibility, but they should be read as
example-specific wrappers rather than the long-term primary API. In `0.1.0`
they remain documented and supported, but they are soft-deprecated as the
recommended entry points for new analyses.

The organism-agnostic comparison methods are already available in the generic
API. For example, phenotype-versus-genotype or phenotype-versus-external
comparison workflows are handled by:

- `amrc_prepare_map_data()`
- `amrc_cluster_map()`
- `amrc_add_cluster_assignments()`
- `amrc_compute_reference_distance_table()`
- `amrc_summarise_reference_distance_table()`

For lightweight case-study runs, prefer the bundled `mini_raw` example or the
`sample_n` arguments in the case-study preprocessing wrappers rather than the
full notebook-scale dataset.

For maintainers, the current keep-vs-deprecate decisions are recorded in
[docs/API_LIFECYCLE.md](docs/API_LIFECYCLE.md).

If you want to reconstruct the larger packaged example outputs from the raw example inputs, use:

```r
out_dir <- tempfile("amrc-spneumoniae-generated-")

amrc_build_spneumoniae_example_outputs(
  raw_dir = tempfile("amrc-spneumoniae-raw-"),
  out_dir = out_dir,
  download_missing = TRUE
)

amrc_build_spneumoniae_example_maps(generated_dir = out_dir)
```

If you are working in a source checkout and want the conventional local
generated-output location used by the legacy notebooks, you can inspect it
with:

```r
amrc_spneumoniae_example_paths("generated", mustWork = FALSE)
```

## Expected Runtime

- The generic toy-data vignette workflow should run in seconds.
- The bundled `mini_raw` vignette workflow should run in seconds.
- Rebuilding the full notebook-scale *S. pneumoniae* outputs and maps from raw example inputs can take several minutes, especially on a laptop.
- The full notebook-scale case-study MDS fits are much heavier than the package examples and should not be treated as the default entry point for learning the package.
- Full notebook-style robustness and manuscript analyses are slower again and should be treated as heavier workflows.

## Data Provenance

The package now separates what ships in the repository from what is downloaded or generated locally.

- Narrative provenance policy: [docs/DATA_PROVENANCE.md](docs/DATA_PROVENANCE.md)
- Machine-readable provenance manifest: [data-raw/data-provenance.csv](data-raw/data-provenance.csv)
- Package conversion roadmap: [docs/ROADMAP.md](docs/ROADMAP.md)
- Script-by-script migration audit: [docs/SCRIPT_AUDIT.md](docs/SCRIPT_AUDIT.md)
- Release checklist: [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)
- Object contracts: [docs/OBJECT_CONTRACTS.md](docs/OBJECT_CONTRACTS.md)
- GitHub release notes draft: [docs/RELEASE_NOTES_0.1.0.md](docs/RELEASE_NOTES_0.1.0.md)
- Manuscript scaffold: [docs/MANUSCRIPT_DRAFT.md](docs/MANUSCRIPT_DRAFT.md)
- API lifecycle notes: [docs/API_LIFECYCLE.md](docs/API_LIFECYCLE.md)

## How To Cite

The repository now includes both a GitHub citation file at [CITATION.cff](CITATION.cff) and a standard package citation via `citation("amrcartography")`. For the current publication workflow, the package should be cited as the `0.1.0` software release; once the package manuscript is finalized, the citation text should be updated to cite both the software and the paper.

## Repository Layout

- `R/`: package functions
- `vignettes/`: user-facing generic and case-study worked examples
- `tests/testthat/`: deterministic and fixture-based regression tests
- `tools/`: environment/bootstrap/build helpers
- `01-Phenotype_and_map_analyses/`: legacy notebooks being migrated onto the package API

## Current Caveat

`08-Mapping-external-variables.Rmd` still depends on metadata files that are not currently in the repository, so full manuscript-level reproducibility still requires either recovering those files or rewriting that section around available inputs.
