if (requireNamespace("testthat", quietly = TRUE)) {
  library(testthat)
  library(amrcartography)

  test_check("amrcartography")
} else {
  message("Package 'testthat' is not installed; skipping tests.")
}
