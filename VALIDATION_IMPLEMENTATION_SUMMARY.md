# Validation Implementation Summary

## What Existed Already

Before this validation pass, the repo already had useful validation pieces:

- `testthat` coverage across generic MIC/data helpers, robustness/maps, generic
  workflows, and regression fixtures
- frozen case-study fixtures in `tests/testthat/fixtures/`
- README workflow sanity in `tools/check_readme_examples.R`
- explicit vignette render sanity in `tools/render_vignettes.R`
- environment visibility in `tools/check_environment.R`
- deeper preprocessing parity checking in `tools/verify_preprocessing_outputs.R`
- Linux GitHub Actions for `R CMD check` and docs sanity
- local validation notes in `docs/LOCAL_VALIDATION.md`

What was missing was a reusable staged validation layer that:

- tied these pieces together
- documented when to use which checks
- added explicit file/schema/sample-count sanity checks
- added a lightweight expected-metrics contract
- covered the Streamlit backend output contract
- gave future agents a consistent validation workflow

## What Was Added Or Changed

### New docs

- [AGENT_VALIDATION_WORKFLOW.md](/Users/ab69/AMRC-R-package/AGENT_VALIDATION_WORKFLOW.md)
- [VALIDATION.md](/Users/ab69/AMRC-R-package/VALIDATION.md)
- [VALIDATION_CHECKLIST.md](/Users/ab69/AMRC-R-package/VALIDATION_CHECKLIST.md)
- [README_AI.md](/Users/ab69/AMRC-R-package/README_AI.md)
- [VALIDATION_IMPLEMENTATION_SUMMARY.md](/Users/ab69/AMRC-R-package/VALIDATION_IMPLEMENTATION_SUMMARY.md)

### New validation assets / scripts

- [tools/run_validation.R](/Users/ab69/AMRC-R-package/tools/run_validation.R)
- [inst/extdata/validation/expected_metrics.json](/Users/ab69/AMRC-R-package/inst/extdata/validation/expected_metrics.json)
- [tests/testthat/test-validation-contracts.R](/Users/ab69/AMRC-R-package/tests/testthat/test-validation-contracts.R)

### Updated files

- [README.md](/Users/ab69/AMRC-R-package/README.md)
- [docs/LOCAL_VALIDATION.md](/Users/ab69/AMRC-R-package/docs/LOCAL_VALIDATION.md)
- [DESCRIPTION](/Users/ab69/AMRC-R-package/DESCRIPTION)
- [.github/workflows/r-cmd-check.yaml](/Users/ab69/AMRC-R-package/.github/workflows/r-cmd-check.yaml)
- [tools/check_readme_examples.R](/Users/ab69/AMRC-R-package/tools/check_readme_examples.R)
- [tools/render_vignettes.R](/Users/ab69/AMRC-R-package/tools/render_vignettes.R)

## How To Run Validation

Primary staged commands:

```bash
Rscript tools/run_validation.R --stage smoke
Rscript tools/run_validation.R --stage ci
Rscript tools/run_validation.R --stage release
```

Supporting commands:

```bash
Rscript -e 'testthat::test_local(".")'
Rscript tools/check_readme_examples.R
Rscript tools/render_vignettes.R
R CMD build --no-build-vignettes .
R CMD check --no-manual --ignore-vignettes amrcartography_*.tar.gz
Rscript tools/verify_preprocessing_outputs.R
```

## What Is Covered Now

The new validation layer now explicitly covers:

- bundled generic example file existence
- bundled generic example schema/count stability
- duplicate isolate ID detection on the bundled generic examples
- square/symmetric precomputed-distance sanity
- packaged `mapping_08` case-study file existence
- `mapping_08` row-count expectations
- `mapping_08` phenotype/genotype/sample-ID alignment checks
- tracked generated source artefact presence in the repo checkout
- Streamlit backend config/output smoke contract
- required Streamlit output-file existence and non-emptiness
- Streamlit summary metric sanity
- reusable staged validation docs for future agents

It also now makes the README/vignette validation tooling more reproducible by
loading the current source checkout with `pkgload` when available, rather than
silently validating against whatever package version happened to be installed.

## What Was Run In This Pass

Passed locally in an unsandboxed R path:

- `Rscript tools/run_validation.R --stage smoke`
- `Rscript tools/run_validation.R --stage release`
- `Rscript -e 'testthat::test_local(".", filter = "validation-contracts")'`
- `R CMD build --no-build-vignettes .`
- `R CMD check --no-manual --ignore-vignettes amrcartography_0.2.0.tar.gz`

External baseline also confirmed:

- GitHub Actions run `23912516588` on commit `a0286a0` finished `success`

## Real Issues Found And Fixed During This Work

This was not a docs-only pass. The new validation layer found and drove fixes
for real problems:

- `tools/run_validation.R` argument parsing initially only accepted
  `--stage=...`; it now also accepts `--stage ...`
- the Streamlit backend smoke contract exposed a reference-distance output-name
  mismatch; the validation now checks the stable current names and the likely
  future generic names
- `tools/render_vignettes.R` and `tools/check_readme_examples.R` were
  validating against an installed package copy rather than the current source
  checkout; they now load the current repo via `pkgload` when available
- the expected-metrics manifest was initially repo-only; it is now shipped at
  [inst/extdata/validation/expected_metrics.json](/Users/ab69/AMRC-R-package/inst/extdata/validation/expected_metrics.json)
  so installed-package tests and source-checkout validation use the same
  contract

## What Is Not Yet Covered

Still not fully covered:

- full browser-level Streamlit UI interaction
- optional deep preprocessing verification in this exact pass
- domain/scientific correctness beyond the structural sanity checks
- exact-output regression for every notebook-era figure/table workflow
- GitHub Actions on this exact uncommitted validation-layer change set

## What Should Be Revisited Later

- decide whether to add a dedicated CI job for `tools/run_validation.R --stage release`
- expand Streamlit backend tests if the app becomes a more central interface
- add stronger summary-metric baselines for advanced LIMIX outputs if those
  workflows stabilize further
- revisit expected metrics whenever bundled example data are intentionally
  updated
- update the validation docs whenever workflows, example bundles, or file
  contracts change
