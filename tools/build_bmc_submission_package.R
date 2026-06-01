`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

full_args <- commandArgs(trailingOnly = FALSE)
script_flag <- "--file="
script_path <- sub(script_flag, "", full_args[grep(script_flag, full_args)])

if (length(script_path) == 0L) {
  stop("This script must be run with Rscript.", call. = FALSE)
}

repo_root <- normalizePath(file.path(dirname(script_path[[1]]), ".."), mustWork = TRUE)
docs_dir <- file.path(repo_root, "docs")
submission_dir <- file.path(docs_dir, "submission", "bmc")
figures_dir <- file.path(submission_dir, "figures")
tables_dir <- file.path(submission_dir, "tables")

dir.create(submission_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

read_text <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

write_text <- function(lines, path) {
  writeLines(lines, path, useBytes = TRUE)
  message("Wrote ", path)
}

extract_section <- function(lines, heading) {
  start <- which(lines == heading)
  if (length(start) == 0L) {
    stop("Missing section heading: ", heading, call. = FALSE)
  }
  start <- start[[1]]
  following <- which(seq_along(lines) > start & grepl("^## ", lines))
  end <- if (length(following) == 0L) length(lines) else following[[1]] - 1L
  lines[start:end]
}

drop_heading <- function(section_lines) {
  section_lines[-1L]
}

as_subsection <- function(section_lines) {
  section_lines[[1]] <- sub("^## ", "### ", section_lines[[1]])
  section_lines
}

manuscript <- read_text(file.path(docs_dir, "MANUSCRIPT_DRAFT.md"))
references <- extract_section(manuscript, "## References")

top <- manuscript[seq_len(which(manuscript == "## Background")[[1]] - 1L)]
body_sections <- c(
  extract_section(manuscript, "## Background"),
  extract_section(manuscript, "## Implementation"),
  extract_section(manuscript, "## Example data"),
  extract_section(manuscript, "## Results"),
  extract_section(manuscript, "## Discussion"),
  extract_section(manuscript, "## Conclusions"),
  extract_section(manuscript, "## Availability and requirements")
)

data_availability <- drop_heading(extract_section(manuscript, "## Data availability"))
code_availability <- drop_heading(extract_section(manuscript, "## Code availability"))

declarations <- c(
  "## Declarations",
  "",
  as_subsection(extract_section(manuscript, "## Ethics approval and consent to participate")),
  "",
  as_subsection(extract_section(manuscript, "## Consent for publication")),
  "",
  "### Availability of data and materials",
  "",
  data_availability,
  "",
  code_availability,
  "",
  as_subsection(extract_section(manuscript, "## Competing interests")),
  "",
  as_subsection(extract_section(manuscript, "## Funding")),
  "",
  "### Authors' contributions",
  "",
  drop_heading(extract_section(manuscript, "## Author contributions")),
  "",
  as_subsection(extract_section(manuscript, "## Acknowledgements"))
)

bmc_manuscript <- c(top, body_sections, "", declarations, "", references)
write_text(bmc_manuscript, file.path(submission_dir, "manuscript.md"))

supplement <- read_text(file.path(docs_dir, "SUPPLEMENTARY_INFORMATION.md"))
write_text(supplement, file.path(submission_dir, "supplementary_information.md"))

captions <- read_text(file.path(docs_dir, "MANUSCRIPT_TABLES_AND_CAPTIONS.md"))
figure_start <- which(captions == "## Figure 1")[[1]]
table_start <- which(captions == "## Table 1")[[1]]
supp_start <- which(captions == "## Supplementary figure candidates")[[1]]
figure_legends <- c(
  "# Figure Legends",
  "",
  captions[figure_start:(table_start - 1L)]
)
table_legends <- c(
  "# Table Legends",
  "",
  captions[table_start:(supp_start - 1L)]
)
write_text(figure_legends, file.path(submission_dir, "figure_legends.md"))
write_text(table_legends, file.path(submission_dir, "table_legends.md"))

cover_letter <- c(
  "# Cover Letter",
  "",
  "Dear Editor,",
  "",
  "Please consider the manuscript entitled \"amrcartography: reusable cartographic analysis of multidrug antimicrobial susceptibility phenotypes\" for publication as a Software Article in BMC Bioinformatics.",
  "",
  "The manuscript describes `amrcartography`, an open-source R package for analysing antimicrobial resistance minimum inhibitory concentration panels as calibrated phenotype landscapes. The software generalises an earlier AMR cartography workflow into reusable functions for MIC cleaning, phenotype-distance construction, map fitting, calibration, external-structure comparison, manuscript-style visualisation, staged validation and exploratory app-based review.",
  "",
  "The submission is framed as a software/methods article. The examples include a generic MIC workflow, phenotype-versus-external comparison, six compact public MIC portability examples, a larger `Streptococcus suis` integration demonstration and a retained `Streptococcus pneumoniae` validation/provenance case study. The public MIC examples are explicitly used to demonstrate schema portability rather than species-level biological inference.",
  "",
  "The software is available under the MIT license at https://github.com/AndrewBalmer/AMRC-R-package. The current formal software release described in the manuscript is `v0.2.1`.",
  "",
  "The manuscript is not under consideration elsewhere. The author declares no competing interests.",
  "",
  "Sincerely,",
  "",
  "Andrew J. Balmer"
)
write_text(cover_letter, file.path(submission_dir, "cover_letter.md"))

checklist <- c(
  "# BMC Submission Checklist",
  "",
  "## Article Fit",
  "",
  "- [x] Target journal: BMC Bioinformatics.",
  "- [x] Article type: Software Article.",
  "- [x] Software availability and requirements section present.",
  "- [x] Source code is open source under MIT license.",
  "- [x] Manuscript describes reusable software, not only a website.",
  "",
  "## Required Files",
  "",
  "- [x] Main manuscript: `manuscript.md`.",
  "- [x] Supplementary information: `supplementary_information.md`.",
  "- [x] Figure legends: `figure_legends.md`.",
  "- [x] Table legends: `table_legends.md`.",
  "- [x] Cover letter draft: `cover_letter.md`.",
  "- [x] Main figures copied to `figures/`.",
  "- [x] Main tables copied to `tables/`.",
  "",
  "## Declarations",
  "",
  "- [x] Ethics approval and consent to participate.",
  "- [x] Consent for publication.",
  "- [x] Availability of data and materials.",
  "- [x] Competing interests.",
  "- [x] Funding.",
  "- [x] Author contributions.",
  "- [x] Acknowledgements.",
  "",
  "## Public App Deployment",
  "",
  "- [ ] Connect the GitHub repository to Render.",
  "- [ ] Deploy `amrcartography-streamlit` as a Docker Web Service from `main`.",
  "- [ ] Confirm the generated `onrender.com` URL opens the app.",
  "- [ ] Run browser QA against the public URL.",
  "- [ ] Add the public URL to docs and manuscript only after QA passes.",
  "",
  "## Validation",
  "",
  "- [x] Rebuild manuscript figures.",
  "- [x] Rebuild manuscript tables.",
  "- [x] Run repository smoke validation.",
  "- [x] Run Streamlit UI contract check.",
  "- [x] Run browser QA locally.",
  "- [x] Run whitespace/diff hygiene check.",
  "- [ ] Run browser QA against public Render URL after deployment.",
  "- [ ] Confirm GitHub Actions is green on the submission-package commit.",
  "",
  "## Human Sign-off",
  "",
  "- [ ] Confirm author list and affiliations.",
  "- [ ] Confirm funding statement.",
  "- [ ] Confirm acknowledgements.",
  "- [ ] Confirm whether a Zenodo DOI is required for the exact submission release.",
  "- [ ] Confirm public app URL before adding it to the manuscript."
)
write_text(checklist, file.path(submission_dir, "submission_checklist.md"))

readme <- c(
  "# BMC Submission Package",
  "",
  "This directory contains a BMC Bioinformatics-oriented submission bundle generated from the package-backed manuscript sources.",
  "",
  "Primary source files remain in `docs/`; this directory is the submission-facing assembly layer.",
  "",
  "Contents:",
  "",
  "- `manuscript.md`: BMC-facing manuscript copy with declarations grouped under a Declarations heading.",
  "- `supplementary_information.md`: supplementary notes and reproducibility context.",
  "- `cover_letter.md`: cover letter draft.",
  "- `figure_legends.md`: standalone figure legends.",
  "- `table_legends.md`: standalone table legends.",
  "- `figures/`: regenerated figure PNG files.",
  "- `tables/`: regenerated table CSV files.",
  "- `submission_checklist.md`: BMC readiness checklist.",
  "",
  "Regenerate this package with:",
  "",
  "```sh",
  "Rscript tools/build_manuscript_figures.R",
  "Rscript tools/build_manuscript_tables.R",
  "Rscript tools/build_bmc_submission_package.R",
  "```"
)
write_text(readme, file.path(submission_dir, "README.md"))

copy_files <- function(from_dir, to_dir, pattern) {
  paths <- list.files(from_dir, pattern = pattern, full.names = TRUE)
  for (path in paths) {
    ok <- file.copy(path, file.path(to_dir, basename(path)), overwrite = TRUE)
    if (!ok) {
      stop("Failed to copy ", path, call. = FALSE)
    }
    message("Copied ", path)
  }
}

copy_files(file.path(docs_dir, "manuscript-figures"), figures_dir, "\\.png$")
copy_files(file.path(docs_dir, "manuscript-tables"), tables_dir, "\\.csv$")

message("BMC submission package written to ", submission_dir)
