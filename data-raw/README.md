# data-raw

Use this directory for scripts that download, standardise, and version the
example datasets used for package development.

Recommended convention:

- raw downloads go in `data-raw/raw-data/`
- processed reproducible outputs go in `inst/extdata/generated/`
- package-ready internal datasets can later be created with `usethis::use_data()`

The current build helper is `tools/build_spneumoniae_example_data.R`.
