# BMC Submission Package

This directory contains a BMC Bioinformatics-oriented submission bundle generated from the package-backed manuscript sources.

Primary source files remain in `docs/`; this directory is the submission-facing assembly layer.

Contents:

- `manuscript.md`: BMC-facing manuscript copy with declarations grouped under a Declarations heading.
- `supplementary_information.md`: supplementary notes and reproducibility context.
- `cover_letter.md`: cover letter draft.
- `figure_legends.md`: standalone figure legends.
- `table_legends.md`: standalone table legends.
- `figures/`: regenerated figure PNG files.
- `tables/`: regenerated table CSV files.
- `submission_checklist.md`: BMC readiness checklist.

Regenerate this package with:

```sh
Rscript tools/build_manuscript_figures.R
Rscript tools/build_manuscript_tables.R
Rscript tools/build_bmc_submission_package.R
```
