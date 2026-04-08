# Bundled S. suis Demo

This compact bundle is derived from the sibling local analysis repository
`AMR_cartography_suis` and is included here so the Streamlit app can expose a
real larger case-study workflow without depending on laptop-only file paths.

Included files:

- `suis_raw_mic_panel.csv`
- `phenotype_map_input_non_divergent_log2.csv`
- `mic_metadata_non_divergent.csv`
- `pbp_distance_matrix_non_divergent.csv`

The bundle is intended for package/app demonstration and reproducibility
checks, not as the canonical full analysis archive. The Streamlit app should
prefer `suis_raw_mic_panel.csv` so MIC cleaning and `log2` transformation are
demonstrated inside the app itself rather than starting from already
transformed values.
