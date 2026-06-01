# Release Notes: 0.2.1

`amrcartography` 0.2.1 is a maintenance and app-prototype release on top of
the earlier `v0.2.0` generic package baseline.

## What changed

- Added the packaged `mapping_08` case-study bundle and moved the legacy
  mapping notebook onto package-backed data paths.
- Expanded the Streamlit prototype with a phenotype-first workflow, optional
  genotype / structure maps, map diagnostics, robustness summaries, grouped
  summaries, single-feature summaries, cluster-difference summaries, and
  downloadable report bundles.
- Added bundled `S. suis` and public MIC exploration examples for app/demo use.
- Tightened manuscript-style plotting defaults and added local visual
  regression baselines for key plots.
- Added staged validation docs and a reusable validation runner.
- Clarified that LIMIX, epistasis, permutation, heritability, and full BLUP
  workflows are original-paper provenance and expert package methods rather
  than first-line app workflows.
- Added grouped cross-validation folds for lightweight kinship-BLUP prediction
  checks.

## Validation

Local validation before tagging included:

- `testthat::test_local(".", filter = "generic-analysis|validation-contracts")`
- `Rscript tools/run_validation.R --stage smoke`
- `Rscript tools/render_vignettes.R`
- `Rscript tools/check_readme_examples.R`
- browser QA against a live local Streamlit app
- full `rcmdcheck` with compact vignettes and `--no-manual`

GitHub Actions passed on the tagged release head before `v0.2.1` was created.

## Manuscript baseline

The current BMC-style manuscript draft cites `v0.2.1` as the formal software
release because it discusses the app, validation, public MIC examples, and
documentation/provenance maintenance work introduced after `v0.2.0`.
