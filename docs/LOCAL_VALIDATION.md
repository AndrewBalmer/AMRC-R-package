# Local Validation Notes

## What works reliably here

On this repository checkout, the following local validation paths are useful:

- `Rscript tools/run_validation.R --stage smoke`
- `Rscript tools/run_validation.R --stage ci`
- `Rscript tools/run_validation.R --stage release`
- `R CMD build --no-build-vignettes .`
- `R CMD check --no-manual --ignore-vignettes <tarball>`
- `knitr::purl()` for syntax-level vignette checks
- direct Python syntax checks for the Streamlit app and LIMIX helpers

## Known local limitation

Some full R workflows on this machine still fail with:

```text
OMP: Error #179: Function Can't open SHM2 failed:
OMP: System error #2: No such file or directory
```

In practice, this affects package-loading paths that trigger the same OpenMP
runtime behaviour, including:

- `roxygen2::roxygenise()`
- full vignette builds that execute the heavier `smacof` workflows
- some standalone source-level test runs

## Practical policy

- Use `tools/run_validation.R` as the main staged validation entrypoint.
- Treat GitHub Actions on Linux as the authoritative full validation pass.
- Treat local no-vignette checks as a useful preflight, not as the final gate.
- If full local validation is required, run it in an unsandboxed R
  environment rather than relying on this sandboxed macOS session.
