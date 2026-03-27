# Script Audit

This audit maps each legacy script to its likely package home, highlights the
most important reproducibility risks, and notes what should happen before the
script is retired.

## Core findings

- The repository contains a genuine analysis workflow, not a package-ready codebase.
- Most scripts assume local absolute paths and previously created intermediate files.
- Repeated logic appears in multiple notebooks and should be extracted once into package functions.
- Several long notebooks mix reusable computation, manuscript plotting, and one-off exploratory work.
- Some analyses depend on external metadata files that are not currently present in the repo.

## Script-by-script mapping

| Legacy script | Main purpose | Immediate problems | Likely package destination |
| --- | --- | --- | --- |
| `01-Inputting-and-processing-phenotype-data.R` | Download, merge, and clean phenotype MIC inputs; compute phenotype distance matrix | Hard-coded paths, ad hoc download, saves outside repo, suspicious `add_count()`/rename sequence | `R/phenotype.R`, `R/data_sources.R`, `tools/build_spneumoniae_example_data.R` |
| `02-Inputting-and-processing-genetic-data.R` | Download and process PBP sequence data; compute genetic distance matrix | Hard-coded paths, output written outside repo, no reusable function boundaries | `R/genotype.R`, `R/pbp_type.R`, `R/data_sources.R` |
| `03-generating-phenotype-map-Spneumoniae.Rmd` | Generate phenotype MDS maps, compare starts, compare dimensionality, optimisation experiments | Very long notebook, repeated MDS logic, mixed manuscript figure code and methods development | `R/mds.R`, future `R/plotting.R`, vignette replacing exploratory sections |
| `04-generating-genotype-map-Spneumoniae.Rmd` | Generate genotype MDS maps and optimisation comparisons | Same structural issues as phenotype map notebook; depends on hidden intermediate `.RData` | `R/mds.R`, future genotype-map wrappers and vignettes |
| `05-06-Estimating-goodness-of-fit-phenotype.Rmd` | Stress diagnostics, residual summaries, dilation/rotation, bootstrap ideas | Repeats calibration logic, partially duplicated code blocks | `R/mds.R`, future `R/goodness_of_fit.R` |
| `07-Estimating-goodness-of-fit-genetic-map.Rmd` | Goodness-of-fit diagnostics for genotype map | Same repeated calibration and plotting patterns as phenotype notebook | `R/mds.R`, future `R/goodness_of_fit.R` |
| `08-Mapping-external-variables.Rmd` | Rotating maps, coloring by MIC, biplot vectors, later MLST overlays and summary tables | Huge mixed-purpose notebook; depends on absent metadata files; not all content is reproducible from repo alone | future `R/plotting.R`, `R/external_variables.R`, separate article/vignette modules |
| `09-Missing-MIC-value-analysis.Rmd` | Missing-value robustness analysis and cross-validation | Long compute-heavy notebook, parallel code mixed with plotting, repeated scale-calibration blocks | future `R/robustness_missingness.R` plus test fixtures |
| `10-Noise-added-value-analysis.Rmd` | Noise-perturbation robustness analysis | Similar structure and duplication to missing-value notebook | future `R/robustness_noise.R` |
| `11-Combining-MIC-and-disc-diffusion-analysis.Rmd` | Mixed data-type robustness analysis | Large notebook, hidden assumptions about weighting and batching, multiple save/restore checkpoints | future `R/robustness_mixed_inputs.R` |
| `12-Testing-effect-of-threshold-values.Rmd` | Thresholding experiments and weighted MDS comparisons | Repeats transformation, comparison, and plotting logic already present elsewhere | future `R/robustness_thresholds.R` |
| `13-Dimensionality-tests.Rmd` | Dimensionality and low-dimensional simulation work | Mixed simulation and plotting notebook; useful for a methodology vignette later | future `R/dimensionality.R` and an article-style vignette |
| `14-defining-optimal-number-of-clusters.Rmd` | Cluster selection and intra/inter-cluster distance summaries | Depends on phenotype and genotype maps already existing; mixes methods and manuscript plots | future `R/clustering.R` |
| `16-Side-by-side-gen-phen-comparison.Rmd` | Compare phenotype and genotype maps, centroids, and cluster summaries | Depends on outputs from multiple prior notebooks; good candidate for an end-to-end vignette once upstream API exists | future `R/comparison.R` and a reproducible case-study vignette |

## External files referenced but not present

- `MIC_S.Pneumo_metadata.csv`
- `Meta_data_spneumoniae_isolates_post_2015.csv`
- multiple `.RData` files expected to be created by earlier scripts and then loaded later

## Migration rule of thumb

- If code is pure data cleaning or computation, move it into `R/`.
- If code is a user tutorial or a worked case study, move it into a vignette.
- If code only exists to make one manuscript figure, rewrite it on top of package functions rather than packaging the notebook directly.
