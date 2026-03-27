Sys.setenv(
  KMP_USE_SHM = "0",
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1"
)

if (requireNamespace("testthat", quietly = TRUE)) {
  library(testthat)
  library(amrcartography)

  test_check("amrcartography")
} else {
  message("Package 'testthat' is not installed; skipping tests.")
}
