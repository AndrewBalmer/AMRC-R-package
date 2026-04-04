# Visual Audit

This note records the current visual-style audit for the package plotting layer
and the Streamlit prototype.

## Goal

The package and app should preserve the visual language used across the thesis
and manuscript notebooks rather than drifting toward generic plotting defaults
or an unrelated app aesthetic.

## What was checked

The current audit focused on the plotting helpers and app surfaces that are now
part of the supported package/app workflow:

- `amrc_plot_map()`
- `amrc_plot_side_by_side_maps()`
- `amrc_plot_cluster_map()`
- `amrc_plot_cluster_elbow()`
- `amrc_plot_reference_distance_relationship()`
- manuscript/thesis panel composers in `R/plotting.R`
- Streamlit map, scree, reference, and report outputs

The audit also used the screenshot baselines under
`tests/visual-regression/baseline/` plus direct inspection of the generated
figures in `docs/manuscript-figures/`, together with the browser-level app QA
notes in `streamlit_app/UI_QA_RESULTS.md`.

## Style elements currently preserved

- light-background scientific figure style rather than dashboard-dark styling
- manuscript-like qualitative palette and black point outlines
- calibration-first interpretation of one-unit grid spacing
- panel composition helpers matching the recurring two-panel, triptych, and
  storyboard layouts used in the notebooks
- consistent legend and label styling across the main cartography plots
- Streamlit shell styling that does not visually clash with the package plots

## Concrete outputs checked in this pass

- `docs/manuscript-figures/figure01_generic_workflow.png`
- `docs/manuscript-figures/figure02_comparison.png`
- `docs/manuscript-figures/figure03_cross_species.png`
- `docs/manuscript-figures/figure04_spneumoniae_validation.png`
- visual regression baselines in `tests/visual-regression/baseline/`
- browser screenshots captured during the 4 April 2026 QA pass:
  - `.tmp_browser_artifacts/02_mic_only_result.png`
  - `.tmp_browser_artifacts/03_numeric_external_result.png`

## Remaining gaps

- This is not yet a strict figure-by-figure parity guarantee for every
  historical manuscript panel.
- Some secondary plotting helpers outside the main app/manuscript path may
  still need closer notebook-by-notebook comparison.
- The Streamlit shell is stylistically aligned, but it is still intentionally
  lightweight and not a full reproduction of the Pf-PeptideFilter app layout.

## Recommended next visual pass

- compare each final manuscript figure against the current package-built
  equivalent
- decide whether any figure-specific presets should be promoted from the figure
  builder into exported helper functions
- add more visual regression baselines only for figures that are truly stable
  and important enough to freeze
