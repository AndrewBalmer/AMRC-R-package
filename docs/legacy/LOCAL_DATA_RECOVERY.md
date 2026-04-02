# Local Data Recovery Notes

This repository may have a local-only `data/` directory containing extracted
legacy notebook inputs. That directory is intentionally ignored by Git because
the files are large, machine-specific recovery material rather than packaged or
versioned example data.

As of `2026-04-02`, the extracted local files appear sufficient to revisit
[08-Mapping-external-variables.Rmd](/Users/ab69/AMRC-R-package/01-Phenotype_and_map_analyses/08-Mapping-external-variables/08-Mapping-external-variables.Rmd)
without relying on the original absolute paths, including:

- `MIC_table_Spneumoniae.csv`
- `meta_data_Spneumoniae.csv`
- `Spneumo_3628_PCA_start_2D_METRIC.RData`
- `Spneumo_3628_PCA_start_2D_METRIC_genetic.RData`
- `MIC_S.Pneumo_metadata.csv`
- `Meta_data_spneumoniae_isolates_post_2015.csv`

The original zip file name mentioned during recovery was
`wetransfer_data_2026-04-02_1206.zip`, but the zip itself was not present in
the repo checkout when this note was written. The extracted files were present
directly under the ignored local `data/` directory instead.
