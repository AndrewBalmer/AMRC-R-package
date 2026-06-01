# BMC Submission Checklist

## Article Fit

- [x] Target journal: BMC Bioinformatics.
- [x] Article type: Software Article.
- [x] Software availability and requirements section present.
- [x] Source code is open source under MIT license.
- [x] Manuscript describes reusable software, not only a website.

## Required Files

- [x] Main manuscript: `manuscript.md`.
- [x] Supplementary information: `supplementary_information.md`.
- [x] Figure legends: `figure_legends.md`.
- [x] Table legends: `table_legends.md`.
- [x] Cover letter draft: `cover_letter.md`.
- [x] Main figures copied to `figures/`.
- [x] Main tables copied to `tables/`.

## Declarations

- [x] Ethics approval and consent to participate.
- [x] Consent for publication.
- [x] Availability of data and materials.
- [x] Competing interests.
- [x] Funding.
- [x] Author contributions.
- [x] Acknowledgements.

## Public App Deployment

- [ ] Connect the GitHub repository to Render.
- [ ] Deploy `amrcartography-streamlit` as a Docker Web Service from `main`.
- [ ] Confirm the generated `onrender.com` URL opens the app.
- [ ] Run browser QA against the public URL.
- [ ] Add the public URL to docs and manuscript only after QA passes.

## Validation

- [x] Rebuild manuscript figures.
- [x] Rebuild manuscript tables.
- [x] Run repository smoke validation.
- [x] Run Streamlit UI contract check.
- [x] Run browser QA locally.
- [x] Run whitespace/diff hygiene check.
- [ ] Run browser QA against public Render URL after deployment.
- [ ] Confirm GitHub Actions is green on the submission-package commit.

## Human Sign-off

- [ ] Confirm author list and affiliations.
- [ ] Confirm funding statement.
- [ ] Confirm acknowledgements.
- [ ] Confirm whether a Zenodo DOI is required for the exact submission release.
- [ ] Confirm public app URL before adding it to the manuscript.
