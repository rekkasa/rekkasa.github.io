# test-fetch_publications.R
# Unit tests for R/fetch_publications.R
#
# Tests cover: parse_publication_row(), format_scholar_bibtex(),
# fetch_publications() overwrite guard, fetch_publications_rvest() CAPTCHA
# detection, and BibTeX round-trip validation.

# Source the implementation under test
source(file = "../../R/fetch_publications.R")

# ── parse_publication_row() tests ─────────────────────────────────────────────

test_that("parse_publication_row produces valid @article BibTeX wrapper", {
  sample_html <- paste0(
    "<table>",
    "<tr class=\"gsc_a_tr\">",
    "<td class=\"gsc_a_t\">",
    "<a class=\"gsc_a_at\" href=\"#\">Sample Paper Title.</a>",
    "<div class=\"gs_gray\">First Author, Second Author</div>",
    "<div class=\"gs_gray\">Journal of Testing, 2023</div>",
    "</td>",
    "<td class=\"gsc_a_c\">",
    "<span class=\"gsc_a_h gsc_a_hc gs_ibl\">2023</span>",
    "</td>",
    "</tr>",
    "</table>"
  )

  doc <- xml2::read_html(x = sample_html)
  row <- rvest::html_element(
    x = doc,
    css = "tr.gsc_a_tr"
  )

  result <- parse_publication_row(row = row)

  # Must be a single character string
  expect_type(
    object = result,
    type = "character"
  )
  expect_length(
    object = result,
    n = 1
  )

  # Must start with @article{...}
  expect_match(
    object = result,
    regexp = "^@article\\{"
  )

  # Must contain key fields (title retains trailing period from HTML)
  expect_match(
    object = result,
    regexp = "title\\s*=\\s*\\{Sample Paper Title\\.\\}"
  )
  expect_match(
    object = result,
    regexp = "author\\s*=\\s*\\{First Author, Second Author\\}"
  )
  expect_match(
    object = result,
    regexp = "journal\\s*=\\s*\\{Journal of Testing, 2023\\}"
  )
  expect_match(
    object = result,
    regexp = "year\\s*=\\s*\\{2023\\}"
  )
})

test_that("parse_publication_row handles missing venue gracefully", {
  sample_html <- paste0(
    "<table>",
    "<tr class=\"gsc_a_tr\">",
    "<td class=\"gsc_a_t\">",
    "<a class=\"gsc_a_at\" href=\"#\">Preprint Title.</a>",
    "<div class=\"gs_gray\">Solo Author</div>",
    "</td>",
    "<td class=\"gsc_a_c\">",
    "<span class=\"gsc_a_h gsc_a_hc gs_ibl\">2024</span>",
    "</td>",
    "</tr>",
    "</table>"
  )

  doc <- xml2::read_html(x = sample_html)
  row <- rvest::html_element(
    x = doc,
    css = "tr.gsc_a_tr"
  )

  result <- parse_publication_row(row = row)

  expect_match(
    object = result,
    regexp = "author\\s*=\\s*\\{Solo Author\\}"
  )
  # journal field should be present but empty
  expect_match(
    object = result,
    regexp = "journal\\s*=\\s*\\{\\}"
  )
})

test_that("parse_publication_row generates citation key from authors+year+title", {
  sample_html <- paste0(
    "<table>",
    "<tr class=\"gsc_a_tr\">",
    "<td class=\"gsc_a_t\">",
    "<a class=\"gsc_a_at\" href=\"#\">Machine Learning for Healthcare.</a>",
    "<div class=\"gs_gray\">Smith, John and Jones, Mary</div>",
    "<div class=\"gs_gray\">Nature Methods, 2022</div>",
    "</td>",
    "<td class=\"gsc_a_c\">",
    "<span class=\"gsc_a_h gsc_a_hc gs_ibl\">2022</span>",
    "</td>",
    "</tr>",
    "</table>"
  )

  doc <- xml2::read_html(x = sample_html)
  row <- rvest::html_element(
    x = doc,
    css = "tr.gsc_a_tr"
  )

  result <- parse_publication_row(row = row)

  # Citation key should start with "smith22machine"
  expect_match(
    object = result,
    regexp = "smith22machine"
  )
})

test_that("parse_publication_row escapes ampersand in author field", {
  sample_html <- paste0(
    "<table>",
    "<tr class=\"gsc_a_tr\">",
    "<td class=\"gsc_a_t\">",
    "<a class=\"gsc_a_at\" href=\"#\">Collaboration Study.</a>",
    "<div class=\"gs_gray\">A. Author & B. Coauthor</div>",
    "<div class=\"gs_gray\">Journal A, 2021</div>",
    "</td>",
    "<td class=\"gsc_a_c\">",
    "<span class=\"gsc_a_h gsc_a_hc gs_ibl\">2021</span>",
    "</td>",
    "</tr>",
    "</table>"
  )

  doc <- xml2::read_html(x = sample_html)
  row <- rvest::html_element(
    x = doc,
    css = "tr.gsc_a_tr"
  )

  result <- parse_publication_row(row = row)

  # & should be escaped to \& in BibTeX
  expect_match(
    object = result,
    regexp = "\\\\&"
  )
})

# ── format_scholar_bibtex() tests ─────────────────────────────────────────────

test_that("format_scholar_bibtex builds valid BibTeX from data frame row", {
  pub_row <- tibble::tibble(
    title = "Test-Driven Development in R",
    author = "Wickham, Hadley",
    journal = "Journal of Statistical Software",
    year = 2011
  )

  result <- format_scholar_bibtex(pub_row = pub_row, idx = 1)

  expect_type(
    object = result,
    type = "character"
  )
  expect_match(
    object = result,
    regexp = "^@article\\{"
  )
  expect_match(
    object = result,
    regexp = "title\\s*=\\s*\\{Test-Driven Development in R\\}"
  )
  expect_match(
    object = result,
    regexp = "author\\s*=\\s*\\{Wickham, Hadley\\}"
  )
  expect_match(
    object = result,
    regexp = "year\\s*=\\s*\\{2011\\}"
  )
  # Citation key: first-author-lastname + last2ofyear + first-title-word + idx
  # "Test-Driven" is one word (hyphens are not in the split pattern)
  expect_match(
    object = result,
    regexp = "wickham11testdriven1"
  )
})

test_that("format_scholar_bibtex handles empty-string fields gracefully", {
  pub_row <- tibble::tibble(
    title = "",
    author = "",
    journal = "",
    year = 2000
  )

  result <- format_scholar_bibtex(pub_row = pub_row, idx = 42)

  expect_type(
    object = result,
    type = "character"
  )
  expect_match(
    object = result,
    regexp = "@article\\{"
  )
  # Empty title and journal produce empty braces
  expect_match(
    object = result,
    regexp = "title\\s*=\\s*\\{\\}"
  )
  expect_match(
    object = result,
    regexp = "journal\\s*=\\s*\\{\\}"
  )
  # Year is preserved
  expect_match(
    object = result,
    regexp = "year\\s*=\\s*\\{2000\\}"
  )
})

# ── fetch_publications() overwrite guard tests ────────────────────────────────

test_that("fetch_publications errors when output exists and force = FALSE", {
  tmp_file <- tempfile(
    pattern = "test_pubs_",
    fileext = ".bib"
  )
  writeLines(
    text = "% existing BibTeX file",
    con = tmp_file
  )
  on.exit(unlink(tmp_file))

  expect_error(
    object = fetch_publications(
      scholar_id = "test",
      output = tmp_file,
      force = FALSE
    ),
    regexp = "already exists"
  )
})

test_that("fetch_publications overwrites when force = TRUE", {
  tmp_file <- tempfile(
    pattern = "test_pubs_overwrite_",
    fileext = ".bib"
  )
  writeLines(
    text = "% existing content to be overwritten",
    con = tmp_file
  )
  on.exit(unlink(tmp_file))

  mock_bibtex <- "@article{mock2023,\n  title = {Mocked},\n}"

  # Replace scholar_get_bibtex in .GlobalEnv for the duration of this test
  old_scholar_get <- .GlobalEnv$scholar_get_bibtex
  .GlobalEnv$scholar_get_bibtex <- function(scholar_id) mock_bibtex
  on.exit(
    .GlobalEnv$scholar_get_bibtex <- old_scholar_get,
    add = TRUE
  )

  result <- fetch_publications(
    scholar_id = "dummy-id",
    output = tmp_file,
    force = TRUE
  )

  # Result should be the path to the written file
  expect_match(
    object = result,
    regexp = "test_pubs_overwrite_.*\\.bib$"
  )
  expect_true(object = file.exists(tmp_file))
  file_content <- readLines(con = tmp_file)
  expect_equal(
    object = file_content,
    expected = c("@article{mock2023,", "  title = {Mocked},", "}")
  )
})

test_that("fetch_publications writes to new file when output does not exist", {
  tmp_file <- tempfile(
    pattern = "test_pubs_new_",
    fileext = ".bib"
  )
  on.exit(unlink(tmp_file))

  mock_bibtex <- "@article{new2024,\n  title = {A New Paper},\n}"

  old_scholar_get <- .GlobalEnv$scholar_get_bibtex
  .GlobalEnv$scholar_get_bibtex <- function(scholar_id) mock_bibtex
  on.exit(
    .GlobalEnv$scholar_get_bibtex <- old_scholar_get,
    add = TRUE
  )

  result <- fetch_publications(
    scholar_id = "dummy-id",
    output = tmp_file,
    force = FALSE
  )

  expect_true(object = file.exists(tmp_file))
  expect_match(
    object = result,
    regexp = "test_pubs_new_.*\\.bib$"
  )
})

# ── fetch_publications_rvest() CAPTCHA detection tests ───────────────────────

test_that("fetch_publications_rvest detects CAPTCHA and aborts", {
  captcha_html <- paste0(
    "<html><head>",
    "<title>Sorry – CAPTCHA required</title>",
    "</head><body></body></html>"
  )

  testthat::local_mocked_bindings(
    read_html = function(x) xml2::read_html(x = captcha_html),
    .package = "rvest"
  )

  expect_error(
    object = fetch_publications_rvest(scholar_id = "blocked"),
    regexp = "CAPTCHA|blocked"
  )
})

test_that("fetch_publications_rvest detects robot block and aborts", {
  robot_html <- paste0(
    "<html><head>",
    "<title>We're sorry... robot detected</title>",
    "</head><body></body></html>"
  )

  testthat::local_mocked_bindings(
    read_html = function(x) xml2::read_html(x = robot_html),
    .package = "rvest"
  )

  expect_error(
    object = fetch_publications_rvest(scholar_id = "robot"),
    regexp = "CAPTCHA|blocked"
  )
})

# ── BibTeX round-trip validation ──────────────────────────────────────────────

test_that("parse_publication_row output is parseable by RefManageR", {
  sample_html <- paste0(
    "<table>",
    "<tr class=\"gsc_a_tr\">",
    "<td class=\"gsc_a_t\">",
    "<a class=\"gsc_a_at\" href=\"#\">A Study of Important Things.</a>",
    "<div class=\"gs_gray\">Doe, John and Smith, Alice</div>",
    "<div class=\"gs_gray\">Annual Review of Everything, 2020</div>",
    "</td>",
    "<td class=\"gsc_a_c\">",
    "<span class=\"gsc_a_h gsc_a_hc gs_ibl\">2020</span>",
    "</td>",
    "</tr>",
    "</table>"
  )

  doc <- xml2::read_html(x = sample_html)
  row <- rvest::html_element(
    x = doc,
    css = "tr.gsc_a_tr"
  )

  bib_string <- parse_publication_row(row = row)

  # Write to temp file and read back with RefManageR
  tmp_bib <- tempfile(
    pattern = "test_roundtrip_",
    fileext = ".bib"
  )
  on.exit(unlink(tmp_bib))

  writeLines(
    text = bib_string,
    con = tmp_bib
  )

  # RefManageR::ReadBib should parse it without error
  expect_no_error(
    object = RefManageR::ReadBib(
      file = tmp_bib,
      check = FALSE
    )
  )

  # Verify it has exactly one entry
  bib <- RefManageR::ReadBib(
    file = tmp_bib,
    check = FALSE
  )
  expect_length(
    object = bib,
    n = 1
  )
})

test_that("format_scholar_bibtex output is parseable by RefManageR", {
  pub_row <- tibble::tibble(
    title = "Reproducible Research with R",
    author = "Knuth, Donald",
    journal = "Computing Surveys",
    year = 1992
  )

  bib_string <- format_scholar_bibtex(pub_row = pub_row, idx = 1)

  tmp_bib <- tempfile(
    pattern = "test_roundtrip2_",
    fileext = ".bib"
  )
  on.exit(unlink(tmp_bib))

  writeLines(
    text = bib_string,
    con = tmp_bib
  )

  expect_no_error(
    object = RefManageR::ReadBib(
      file = tmp_bib,
      check = FALSE
    )
  )

  bib <- RefManageR::ReadBib(
    file = tmp_bib,
    check = FALSE
  )

  expect_length(
    object = bib,
    n = 1
  )
})

# ── fetch_publications_rvest() normal parsing with mocked page ────────────────

test_that("fetch_publications_rvest parses multiple publications with mock", {
  mock_page_html <- paste0(
    "<html><head><title>Alexandros Rekkas - Google Scholar</title></head>",
    "<body>",
    "<table>",
    "<tr class=\"gsc_a_tr\">",
    "<td class=\"gsc_a_t\">",
    "<a class=\"gsc_a_at\" href=\"#\">First Paper Title.</a>",
    "<div class=\"gs_gray\">Rekkas, A and Doe, J</div>",
    "<div class=\"gs_gray\">Journal One, 2023</div>",
    "</td>",
    "<td class=\"gsc_a_c\">",
    "<span class=\"gsc_a_h gsc_a_hc gs_ibl\">2023</span>",
    "</td>",
    "</tr>",
    "<tr class=\"gsc_a_tr\">",
    "<td class=\"gsc_a_t\">",
    "<a class=\"gsc_a_at\" href=\"#\">Second Paper Title.</a>",
    "<div class=\"gs_gray\">Rekkas, A and Smith, B</div>",
    "<div class=\"gs_gray\">Journal Two, 2024</div>",
    "</td>",
    "<td class=\"gsc_a_c\">",
    "<span class=\"gsc_a_h gsc_a_hc gs_ibl\">2024</span>",
    "</td>",
    "</tr>",
    "</table>",
    "</body></html>"
  )

  testthat::local_mocked_bindings(
    read_html = function(x) xml2::read_html(x = mock_page_html),
    .package = "rvest"
  )

  result <- fetch_publications_rvest(scholar_id = "test-id")

  expect_type(
    object = result,
    type = "character"
  )
  # Should contain both paper titles
  expect_match(
    object = result,
    regexp = "First Paper Title"
  )
  expect_match(
    object = result,
    regexp = "Second Paper Title"
  )
  # Both should be valid @article entries
  article_count <- length(
    stringr::str_extract_all(
      string = result,
      pattern = "@article\\{"
    )[[1]]
  )
  expect_equal(
    object = article_count,
    expected = 2L
  )
})
