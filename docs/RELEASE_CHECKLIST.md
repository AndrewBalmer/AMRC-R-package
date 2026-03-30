# Release Checklist

This checklist is for the first usable public release of `amrcartography` and for subsequent tagged releases.

## Before Version Bump

- Confirm the exported API still matches the workflow described in the vignette and README.
- Confirm the generic-first story is still the package identity and the
  pneumococcal material is still framed as a case study.
- Confirm the current scope still excludes the deferred external-variable notebook.
- Check that all generated example files referenced in the package are present and use the short portable filenames.
- Keep the interactive app out of scope unless the manuscript workflow and exported API have clearly stabilised.
- Review open issues and decide whether anything must land before release.

## Version Bump

- Update `Version` in [DESCRIPTION](/Users/ab69/AMRC-R-package/DESCRIPTION).
- Add a dated release heading to [NEWS.md](/Users/ab69/AMRC-R-package/NEWS.md).
- If the package manuscript is already public, update citation/version references in the manuscript and README.
- Re-run `roxygen2::roxygenise()` if any exported functions or docs changed.

## Validation

- Run `testthat::test_local(".")`.
- Run `R CMD build .` locally when `pandoc` is available.
- Run `R CMD check --as-cran --no-manual amrcartography_*.tar.gz` locally when `pandoc` is available.
- If `pandoc` is unavailable, fall back to `R CMD build --no-build-vignettes .`
  and `R CMD check --no-manual --ignore-vignettes amrcartography_*.tar.gz`.
- Confirm GitHub Actions `R-CMD-check` is green on `main`.
- Confirm the docs/example sanity workflow is green on `main`.
- Confirm the vignette rebuild succeeds in CI with pandoc.

## NEWS

- Summarise user-facing additions.
- Summarise breaking or behaviour-changing API updates.
- Summarise reproducibility/data changes.
- Summarise notebook migrations completed in the release.

## Citation Text

- Update `CITATION.cff` and/or `inst/CITATION` so the citation text matches the release being tagged.
- Make sure the citation text matches the maintainer name, package title, version, GitHub URL, and manuscript status.
- Add a short “How to cite” section to the README once the citation text is stable.

## Manuscript Assets

- Confirm the vignette still reflects the manuscript’s core example workflow.
- Freeze the figures/tables that will be generated directly from package functions.
- Record software availability text, repository URL, license, and version used in the manuscript.
- Prepare a software methods paragraph describing phenotype preprocessing, genotype preprocessing, map fitting, clustering, and comparison summaries.
- Confirm supplementary materials list which analyses are fully package-backed and which remain legacy/deferred.

## GitHub Release

- Tag the release from the validated commit.
- Draft GitHub release notes from `NEWS.md` or the prepared release-note draft
  under `docs/`.
- Link the release notes to the manuscript/preprint if available.
- If branch protection is enabled, confirm required checks passed before tagging.

## After Release

- Check that installation from GitHub still works from a clean R session.
- Check that the vignette and README render correctly on GitHub.
- Open the next `Unreleased` or next-version section in [NEWS.md](/Users/ab69/AMRC-R-package/NEWS.md).
