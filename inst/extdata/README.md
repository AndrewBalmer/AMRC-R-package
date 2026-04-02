# Example data

This directory contains two kinds of package example data.

- `examples/generic/` holds small generic MIC and external-data examples used in
  the generic vignettes and tests.
- `examples/spneumoniae-08/` holds the compact tracked data bundle used by the
  legacy `08-Mapping-external-variables` case-study notebook.
- the `spneumoniae_*` files and `generated/` layout support the worked
  `S. pneumoniae` case study retained in the repository for validation and
  regression purposes.

The full raw `S. pneumoniae` source CSVs are not committed here by default. Use
`tools/build_spneumoniae_example_data.R` to download and process the case-study
data into `inst/extdata/generated/`.
