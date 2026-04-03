# Public MIC Example Citations

The small public cross-species MIC examples bundled in
`inst/extdata/examples/public-mic/` were curated from the public CDC & FDA
Antimicrobial Resistance Isolate Bank website.

These packaged subsets are intended for documentation, testing, teaching, and
lightweight cross-species workflow examples. They are not intended to replace
the underlying AR Isolate Bank resource or to serve as standalone biological
benchmark datasets.

## General resource citation

Please cite the AR Isolate Bank resource alongside the package when these
bundled public examples are used:

- Lutgring JD, Machado MJ, Benahmed FH, et al. FDA-CDC Antimicrobial
  Resistance Isolate Bank: a Publicly Available Resource To Support Research,
  Development, and Regulatory Requirements. *Journal of Clinical
  Microbiology*. 2018;56(2):e01415-17.
  DOI: [10.1128/JCM.01415-17](https://doi.org/10.1128/JCM.01415-17)

## Dataset-specific source pages

- `salmonella_enterica_mic`
  Source panel: [CDC AR Isolate Bank panel 6](https://wwwn.cdc.gov/ArIsolateBank/Panel/PanelDetail?ID=6)
- `campylobacter_jejuni_mic`
  Source panel: [CDC AR Isolate Bank panel 6](https://wwwn.cdc.gov/ArIsolateBank/Panel/PanelDetail?ID=6)
- `escherichia_coli_o157_mic`
  Source panel: [CDC AR Isolate Bank panel 6](https://wwwn.cdc.gov/ArIsolateBank/Panel/PanelDetail?ID=6)
- `acinetobacter_baumannii_mic`
  Source panel: [CDC AR Isolate Bank panel 1](https://wwwn.cdc.gov/ArIsolateBank/Panel/PanelDetail?ID=1)
- `pseudomonas_aeruginosa_mic`
  Source panel: [CDC AR Isolate Bank panel 12](https://wwwn.cdc.gov/ArIsolateBank/Panel/PanelDetail?ID=12)
- `staphylococcus_aureus_mic`
  Source panel: [CDC AR Isolate Bank panel 13](https://wwwn.cdc.gov/ArIsolateBank/Panel/PanelDetail?ID=13)

## Notes

- The packaged CSVs were programmatically derived from the public isolate-detail
  pages linked through those panel collections.
- The tiny subsets intentionally preserve the raw public MIC string values,
  including censoring notation such as `<`, `<=`, `>`, and `>=`, so the package
  cleaning/calibration workflow can be exercised on real public values.
- The public panel pages listed above were accessed during curation on
  3 April 2026.
