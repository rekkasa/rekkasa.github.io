# testthat entry point for R CMD check / devtools::test().
# Run directly with:  Rscript tests/testthat/testthat.R
# When sourced via testthat::test_dir(), is_testing() is TRUE and we
# skip re-invocation to avoid nested test runs.
if (!testthat::is_testing()) {
  testthat::test_check(package = NULL)
}
