# Validation

This repository has several validation layers already, and they now share one
staged entrypoint:

- `Rscript tools/run_validation.R --stage smoke`
- `Rscript tools/run_validation.R --stage ci`
- `Rscript tools/run_validation.R --stage release`

This document is repo-specific. For reusable agent guidance, see
[AGENT_VALIDATION_WORKFLOW.md](/Users/ab69/AMRC-R-package/AGENT_VALIDATION_WORKFLOW.md).

## Current Coverage

The repo currently validates several different things:

- package/unit/regression behaviour via `testthat`
- generic workflow behaviour on toy data
- frozen fixture/regression outputs for the pneumococcal case study
- README workflow sanity via `tools/check_readme_examples.R`
- vignette render sanity via `tools/render_vignettes.R`
- preprocessing rebuild parity via `tools/verify_preprocessing_outputs.R`
- environment/dependency visibility via `tools/check_environment.R`
- repo/example/app sanity via `tools/run_validation.R`

## Validation Stages

### Smoke

Use when:

- scaffolding new code
- making small changes
- checking a repo checkout quickly

Command:

```bash
Rscript tools/run_validation.R --stage smoke
```

What it checks:

- validation metrics manifest is present and readable
- bundled generic example files exist and match expected schema/counts
- packaged `mapping_08` case-study bundle exists and has internally consistent
  IDs/counts
- tracked source-checkout generated artefacts exist where the repo expects them
- Streamlit backend smoke workflow emits the expected files and summary metrics

### CI

Use when:

- validating a non-trivial change set
- preparing a commit for CI
- checking repo sanity before sharing work

Command:

```bash
Rscript tools/run_validation.R --stage ci
```

What it checks:

- everything in `smoke`

The GitHub Actions `docs-sanity` job also separately runs:

- `Rscript tools/check_readme_examples.R`
- `Rscript tools/render_vignettes.R`

### Release

Use when:

- preparing a release candidate
- deciding whether to trust a results baseline
- doing a final local pass before or after CI

Command:

```bash
Rscript tools/run_validation.R --stage release
```

What it checks:

- everything in `ci`
- README example workflow
- explicit vignette renders

Optional deeper case-study parity check:

```bash
Rscript tools/verify_preprocessing_outputs.R
```

That final check is intentionally separate because it is closer to a legacy
case-study rebuild than a lightweight general validation pass.

## Main Validation Commands

### Fast repo sanity

```bash
Rscript tools/run_validation.R --stage smoke
```

### Package tests

```bash
Rscript -e 'testthat::test_local(".")'
```

### README workflow sanity

```bash
Rscript tools/check_readme_examples.R
```

### Vignette render sanity

```bash
Rscript tools/render_vignettes.R
```

### Build and check

```bash
R CMD build --no-build-vignettes .
R CMD check --no-manual --ignore-vignettes amrcartography_*.tar.gz
```

## What `tools/run_validation.R` Checks Explicitly

The staged validation runner fails loudly on repo-relevant silent-failure
conditions, including:

- missing required example files
- missing required columns
- duplicate isolate IDs
- sample/metadata mismatches in the `mapping_08` bundle
- empty outputs
- malformed or degenerate map outputs
- broken Streamlit backend result generation
- missing expected backend output files
- summary metrics that no longer match the bundled example contracts

## Source-Checkout Versus Installed-Package Behaviour

Some validation checks are source-checkout specific, especially:

- tracked generated artefact presence in `inst/extdata/generated/spneumoniae`
- top-level docs, tools, and Streamlit backend files

That is intentional. This repo has both package-facing validation and
repo-maintainer validation. The staged runner focuses on the repo checkout.

## Known Local Limitation

This macOS sandbox can still hit the existing OpenMP/shared-memory failure on
heavier R runs. See [docs/LOCAL_VALIDATION.md](/Users/ab69/AMRC-R-package/docs/LOCAL_VALIDATION.md).

Practical consequence:

- local smoke/repo checks are useful
- Linux CI remains the authoritative gate for full validation

## Files To Review When Validation Changes

- [AGENT_VALIDATION_WORKFLOW.md](/Users/ab69/AMRC-R-package/AGENT_VALIDATION_WORKFLOW.md)
- [VALIDATION.md](/Users/ab69/AMRC-R-package/VALIDATION.md)
- [VALIDATION_CHECKLIST.md](/Users/ab69/AMRC-R-package/VALIDATION_CHECKLIST.md)
- [inst/extdata/validation/expected_metrics.json](/Users/ab69/AMRC-R-package/inst/extdata/validation/expected_metrics.json)
- [tools/run_validation.R](/Users/ab69/AMRC-R-package/tools/run_validation.R)
- [tests/testthat/test-validation-contracts.R](/Users/ab69/AMRC-R-package/tests/testthat/test-validation-contracts.R)
