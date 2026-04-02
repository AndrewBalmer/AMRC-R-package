# Validation Checklist

Use this checklist before trusting major changes, generated outputs, or release
candidates.

## Quick Pre-Merge Checklist

- Run `Rscript tools/run_validation.R --stage smoke`
- Run `Rscript -e 'testthat::test_local(\".\")'` when the change touches package
  code or tests
- Confirm changed workflows still have matching tests or sanity checks
- Confirm changed docs still describe the real command path
- Confirm no expected example files or fixtures were accidentally removed

## Before Trusting Results

- Run `Rscript tools/run_validation.R --stage ci`
- Check sample counts and ID alignment for the workflow you changed
- Check outputs are non-empty and contain the expected columns
- Check no new all-`NA` or near-empty intermediates appeared
- Check grouped/reference summaries still use the intended grouping variables

## Before Sharing Outputs

- Confirm the workflow ran on the intended input files
- Confirm IDs/group labels look correct
- Confirm plots/tables are not built from empty or filtered-out data
- Confirm output counts/dimensions are sensible
- Confirm any new expected metrics or fixtures were updated intentionally

## Before Treating A Commit As A Baseline

- Run `Rscript tools/run_validation.R --stage release`
- Run `R CMD build --no-build-vignettes .`
- Run `R CMD check --no-manual --ignore-vignettes amrcartography_*.tar.gz`
- Confirm Linux CI is green
- If relevant, run `Rscript tools/verify_preprocessing_outputs.R`

## Silent-Failure Review

Ask:

- Did any join key change?
- Did any filtering step drop more samples than intended?
- Did any grouping/reference variable change meaning?
- Did any workflow now depend on a file that is absent from the repo?
- Did any output become empty while still rendering?
- Did expected counts change, and if so, was that intentional?

## Required Doc/Test Updates When The Workflow Changes

- `AGENT_VALIDATION_WORKFLOW.md`
- `VALIDATION.md`
- `VALIDATION_CHECKLIST.md`
- `tests/`
- `tools/run_validation.R`
- `inst/extdata/validation/expected_metrics.json`
- `README_AI.md` if agent-facing workflow guidance changed
