# AMR Cartography Roadmap

This roadmap records the current post-`v0.2.1` state. Earlier migration
planning has been superseded by the package, validation, app and manuscript
work already present in the repository.

## Current Stable Position

- Package name: `amrcartography`.
- Latest formal release: `v0.2.1`.
- Current development head: green on GitHub Actions after the public MIC
  showcase expansion.
- Target manuscript shape: BMC Bioinformatics-style software/methods article.
- Release posture: no new tag until the manuscript and public app deployment
  decisions are stable.

The repository now contains the core generic MIC cartography workflow, public
MIC portability examples, the larger `S. suis` demonstration bundle, the
retained `S. pneumoniae` validation/provenance bundle, a staged validation
runner and a phenotype-first Streamlit prototype.

## Immediate Manuscript Work

- Polish `docs/MANUSCRIPT_DRAFT.md` into journal prose rather than README-style
  documentation.
- Keep the Results ordered around:
  1. generic MIC cartography,
  2. phenotype-versus-external comparison,
  3. six public MIC portability examples,
  4. `S. suis` larger integration/provenance demonstration,
  5. `S. pneumoniae` validation/provenance,
  6. staged validation and reproducibility.
- Treat public MIC examples as portability/schema demonstrations only.
- Treat `S. pneumoniae` as continuity with the original AMR cartography work,
  not the main new biological result.
- Keep mixed-model, LIMIX, epistasis, heritability and BLUP material as
  documented provenance/expert extensions.

## Manuscript Assets

- Regenerate figures with `Rscript tools/build_manuscript_figures.R`.
- Regenerate tables with `Rscript tools/build_manuscript_tables.R`.
- Keep Figure 3 as the six-panel public MIC portability figure.
- Keep Table 4 as the generated public MIC metrics/provenance table.
- Maintain `docs/SUPPLEMENTARY_INFORMATION.md` as the manuscript supplement
  source.
- Keep `docs/MANUSCRIPT_TABLES_AND_CAPTIONS.md` aligned with generated figure
  and table files.
- Build the BMC-facing submission bundle with
  `Rscript tools/build_bmc_submission_package.R`.

## Validation Gate

Run these checks before pushing manuscript or app-facing changes:

```sh
Rscript tools/run_validation.R --stage smoke
python3 streamlit_app/check_ui_contract.py
python3 streamlit_app/run_browser_qa.py --include-case-studies
git diff --check
```

Also search active manuscript/docs files for unresolved marker phrases before
any submission package is considered complete. Exclude `docs/legacy/` because
it intentionally preserves historical notebooks.

Linux GitHub Actions remains the authoritative release gate.

## Public App Deployment

The app should be deployed after manuscript text and example outputs are stable,
but before preprint or public sharing. The current recommended deployment path
is Render using the existing Docker scaffold.

Deployment tasks:

- connect the GitHub repository in Render,
- create a Docker-backed Web Service,
- deploy from green `main`,
- run browser QA against the public URL,
- add the public URL to app docs and the manuscript only after it is stable.

## Release Decision

Do not move existing tags. Keep `v0.2.1` as the current formal release unless a
new maintenance release is deliberately needed.

Cut `v0.2.2` only if the manuscript or public app needs a citable release that
includes post-`v0.2.1` public MIC showcase and documentation changes. If so,
follow `docs/RELEASE_CHECKLIST.md`.

## Deferred Work

- Full polished end-user app product.
- Advanced association tabs in the app.
- Routine app exposure of LIMIX, epistasis, heritability or full BLUP workflows.
- Larger public cross-species biological benchmark datasets.
- CRAN submission.
