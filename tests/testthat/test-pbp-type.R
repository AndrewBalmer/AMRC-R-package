test_that("amrc_clean_pbp_type repairs spreadsheet-style PBP types", {
  expect_equal(
    amrc_clean_pbp_type(c("1930/1938", "2007", "2-0-2")),
    c("30-38", "7", "2-0-2")
  )
})

test_that("default exclusions are returned as a character vector", {
  exclusions <- amrc_default_sequence_exclusions()

  expect_type(exclusions, "character")
  expect_gt(length(exclusions), 0)
})
