# AGENT VALIDATION WORKFLOW

## Purpose

This repository uses staged validation throughout development, not only at the
end.

The goal is to catch silent bugs, broken assumptions, missing files, malformed
outputs, schema drift, and reproducibility gaps before those issues get baked
into package code, example outputs, figures, or manuscript claims.

Validation in this repo is intended to be reusable across multiple project
stages:

- early scaffolding
- active feature development
- refactors
- case-study rebuilds
- release preparation
- manuscript/output generation

## When To Use This Workflow

Use this workflow:

- at early scaffold stage, when only minimal code and examples exist
- after major code additions
- after refactors
- before trusting generated results
- before sharing figures, tables, or outputs
- before and after major agent-generated changes
- before cutting a release or treating a commit as a manuscript baseline

## Validation Philosophy

- Code running is not enough.
- Outputs can look plausible and still be wrong.
- Validation must cover data, joins, assumptions, workflow logic, and outputs.
- Agents must look for silent failure modes, not only runtime failures.
- Prefer checks that fail loudly and explain what went wrong.
- Prefer stable summary-metric checks over brittle exact file-equality checks
  when exact equality is not the right invariant.

## Stage-Based Validation Model

### Stage 1: Early Prototype

Use lightweight checks that answer: "Does the shape still make sense?"

- file existence checks
- required-column/schema checks
- duplicate-sample checks
- empty-output checks
- tiny smoke workflow checks
- basic plotting/report-generation smoke checks

Recommended repo commands:

- `Rscript tools/run_validation.R --stage smoke`

### Stage 2: Working Pipeline

Use checks that answer: "Does the workflow still behave sensibly on stable
fixtures?"

- small fixture/test input
- expected row/sample counts
- expected required files
- expected required columns
- output non-emptiness checks
- app/backend smoke contracts where relevant
- package tests

Recommended repo commands:

- `Rscript tools/run_validation.R --stage ci`
- `Rscript -e 'testthat::test_local(\".\")'`

### Stage 3: Mature Analysis

Use checks that answer: "Can I trust this result and reproduce it later?"

- regression checks
- stronger schema/output validation
- baseline comparison where appropriate
- vignette rebuilds
- README workflow validation
- optional deep case-study rebuild verification

Recommended repo commands:

- `Rscript tools/run_validation.R --stage release`
- `R CMD build --no-build-vignettes .`
- `R CMD check --no-manual --ignore-vignettes <tarball>`
- optional: `Rscript tools/verify_preprocessing_outputs.R`

## Core Validation Categories

### Input / Data Validation

Check:

- required files exist
- required columns exist
- expected input counts are sensible
- values are not obviously malformed
- IDs are present and usable

### Metadata / Sample Validation

Check:

- duplicate sample IDs
- dropped or duplicated joins
- sample/metadata alignment
- expected subset/superset relationships
- mislabeled or missing grouping/reference columns

### Workflow / Process Validation

Check:

- key command paths still run
- smoke workflows produce outputs
- app/backend scripts still emit the expected files
- notebook/vignette examples still parse or render when expected

### Output Validation

Check:

- required output files exist
- outputs are non-empty
- required columns exist
- counts/dimensions are in expected ranges
- maps/distances/reports are not all-`NA` or degenerate

### Reproducibility Validation

Check:

- the same validation commands can be rerun later
- fixtures/manifests stay in sync with code
- expected metrics are documented and versioned
- rebuild scripts still match the packaged outputs they claim to create

### Statistical / Domain Sanity Checks

Check:

- group/reference summaries are not empty when they should exist
- distance matrices are square, finite, and aligned
- sample counts do not change unexpectedly
- grouping variables and model inputs are the intended ones
- results are not driven by obvious metadata mismatches or accidental filtering

### Failure-Mode Review

Always ask:

- what could silently go wrong here?
- what assumptions did this code make about IDs, file names, joins, or groups?
- what would still "look fine" but actually be wrong?

## How Could This Be Wrong?

Use this checklist when reviewing pipeline or analysis changes:

- wrong sample mapping
- duplicated samples
- dropped samples after joins or filtering
- incorrect join key
- unexpected one-to-many joins
- metadata misalignment
- over-filtering
- empty intermediates
- all-`NA` columns or near-empty outputs
- wrong grouping variable
- wrong reference group/value
- wrong model inputs
- wrong distance labels
- wrong file matching
- stale fixture/expected-metric assumptions
- missing required outputs
- malformed CSV/RDS output
- silently different counts/dimensions
- contamination, batch, lineage, or confounding effects being mistaken for the
  target signal where relevant

## Reusable Agent Operating Instructions

Future agents working in this repo should:

- inspect current validation coverage before adding new code
- update tests and sanity checks when the workflow changes
- avoid assuming existing validation is sufficient
- prefer stable summary-metric checks over brittle exact output equality when
  appropriate
- document assumptions explicitly
- update validation docs after major implementation changes
- fail loudly on missing files, missing IDs, schema mismatches, and empty
  outputs
- treat Linux CI as the authoritative gate when local macOS/OpenMP behaviour is
  unreliable

## What To Update Each Time

When major changes are made, review and update as needed:

- `AGENT_VALIDATION_WORKFLOW.md`
- `VALIDATION.md`
- `VALIDATION_CHECKLIST.md`
- `tests/`
- sanity-check scripts in `tools/`
- expected metrics / manifests
- `README_AI.md` if the validation workflow for agents changed

## Commands

Primary staged validation commands in this repo:

- `Rscript tools/run_validation.R --stage smoke`
- `Rscript tools/run_validation.R --stage ci`
- `Rscript tools/run_validation.R --stage release`

Supporting commands:

- `Rscript -e 'testthat::test_local(\".\")'`
- `Rscript tools/check_readme_examples.R`
- `Rscript tools/render_vignettes.R`
- `R CMD build --no-build-vignettes .`
- `R CMD check --no-manual --ignore-vignettes <tarball>`
- optional deep check: `Rscript tools/verify_preprocessing_outputs.R`

## Limitations

Passing validation does not prove correctness.

It means:

- the current checks did not detect a problem
- major silent-failure paths are at least partially covered
- basic reproducibility and output integrity are in better shape

It does not replace:

- domain review
- scientific judgement
- critical interpretation of the results
- targeted inspection of new analysis logic
