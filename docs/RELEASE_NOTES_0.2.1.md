# Release Notes: 0.2.1

`amrcartography` 0.2.1 is a maintenance and app-prototype release on top of
the `v0.2.0` manuscript software baseline.

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

The manuscript can continue to cite `v0.2.0` as the software baseline. Move the
manuscript citation to `v0.2.1` only if you want the app/docs maintenance work
included in the cited software state.
