# fetch_publications.R --- one-time Google Scholar scraper
#
# Scrapes the author's Google Scholar profile and writes publications.bib.
# Uses the scholar package as primary method; falls back to rvest-based
# manual scraping if Google Scholar blocks automated access.

#' Parse a single publication row from Google Scholar HTML
#'
#' @param row An xml_node <tr> element from the Scholar publications table.
#' @return A character string containing a formatted BibTeX entry.
#' @keywords internal
parse_publication_row <- function(row) {
  title <- rvest::html_element(
    x = row,
    css = "a.gsc_a_at"
  ) |>
    rvest::html_text(trim = TRUE)

  author_text <- rvest::html_elements(
    x = row,
    css = "div.gs_gray"
  )
  authors <- if (length(author_text) >= 1) {
    rvest::html_text(x = author_text[[1]], trim = TRUE)
  } else {
    ""
  }

  venue <- if (length(author_text) >= 2) {
    rvest::html_text(x = author_text[[2]], trim = TRUE)
  } else {
    ""
  }

  year <- rvest::html_element(
    x = row,
    css = "span.gsc_a_h.gsc_a_hc.gs_ibl"
  ) |>
    rvest::html_text(trim = TRUE)

  # Generate citation key: first author lastname + year + first title word
  first_author <- stringr::str_split(
    string = authors,
    pattern = ","
  )[[1]][[1]] |>
    stringr::str_trim(side = "both") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all(
      pattern = "[^a-z]",
      replacement = ""
    )

  title_first_word <- stringr::str_split(
    string = title,
    pattern = "[ ,.:;]+"
  )[[1]][[1]] |>
    stringr::str_to_lower() |>
    stringr::str_replace_all(
      pattern = "[^a-z]",
      replacement = ""
    )

  short_year <- stringr::str_sub(
    string = year,
    start = -2
  )

  cite_key <- stringr::str_c(
    first_author,
    short_year,
    title_first_word,
    sep = ""
  )

  # Escape special characters for BibTeX
  authors_escaped <- stringr::str_replace_all(
    string = authors,
    pattern = "&",
    replacement = "\\\\&"
  )
  title_escaped <- stringr::str_replace_all(
    string = title,
    pattern = "[{}]",
    replacement = ""
  )

  bib_entry <- stringr::str_c(
    "@article{", cite_key, ",\n",
    "  title = {", title_escaped, "},\n",
    "  author = {", authors_escaped, "},\n",
    "  journal = {", venue, "},\n",
    "  year = {", year, "}\n",
    "}"
  )

  return(bib_entry)
}

#' Fallback scraper using rvest to manually parse Google Scholar
#'
#' @param scholar_id Character. Google Scholar user ID.
#' @return Character string with combined BibTeX entries.
#' @keywords internal
fetch_publications_rvest <- function(scholar_id) {
  url <- stringr::str_c(
    "https://scholar.google.com/citations?user=",
    scholar_id,
    "&hl=en&sortby=pubdate&pagesize=100"
  )

  page <- rvest::read_html(x = url)
  page_title <- rvest::html_element(
    x = page,
    css = "title"
  ) |>
    rvest::html_text(trim = TRUE)

  if (stringr::str_detect(
    string = stringr::str_to_lower(page_title),
    pattern = "robot|captcha|sorry"
  )) {
    stop(
      "Google Scholar returned a CAPTCHA or blocked the request. ",
      "Manual entry required. Please export your publications from ",
      "https://scholar.google.com and save as publications.bib."
    )
  }

  rows <- rvest::html_elements(
    x = page,
    css = "tr.gsc_a_tr"
  )

  if (length(rows) == 0) {
    stop("No publication rows found on Google Scholar profile page.")
  }

  entries <- purrr::map_chr(
    .x = rows,
    .f = parse_publication_row
  )

  result <- stringr::str_c(entries, collapse = "\n\n")
  return(result)
}

#' Format a single publication row into a BibTeX entry
#'
#' @param pub_row A one-row data frame from scholar::get_publications().
#' @param idx Integer index for generating unique citation keys.
#' @return A character string with a formatted BibTeX entry.
#' @keywords internal
format_scholar_bibtex <- function(pub_row, idx) {
  title <- if (is.null(pub_row[["title"]])) "" else pub_row[["title"]]
  author <- if (is.null(pub_row[["author"]])) "" else pub_row[["author"]]
  journal <- if (is.null(pub_row[["journal"]])) "" else pub_row[["journal"]]
  year_raw <- pub_row[["year"]]
  year <- if (is.null(year_raw)) "" else as.character(year_raw)

  # Generate citation key
  first_author <- stringr::str_split(
    string = author,
    pattern = " "
  )[[1]][[1]] |>
    stringr::str_to_lower() |>
    stringr::str_replace_all(
      string = _,
      pattern = "[^a-z]",
      replacement = ""
    )

  short_year <- stringr::str_sub(string = year, start = -2)

  title_first_word <- stringr::str_split(
    string = title,
    pattern = "[ ,.:;]+"
  )[[1]][[1]] |>
    stringr::str_to_lower() |>
    stringr::str_replace_all(
      string = _,
      pattern = "[^a-z]",
      replacement = ""
    )

  cite_key <- stringr::str_c(
    first_author, short_year, title_first_word, idx,
    sep = ""
  )

  # Escape special characters
  title_escaped <- stringr::str_replace_all(
    string = title,
    pattern = "[{}]",
    replacement = ""
  )
  author_escaped <- stringr::str_replace_all(
    string = author,
    pattern = "&",
    replacement = "\\\\&"
  )

  bib_entry <- stringr::str_c(
    "@article{", cite_key, ",\n",
    "  title = {", title_escaped, "},\n",
    "  author = {", author_escaped, "},\n",
    "  journal = {", journal, "},\n",
    "  year = {", year, "}\n",
    "}"
  )
  return(bib_entry)
}

#' Retrieve BibTeX entries using the scholar package
#'
#' @param scholar_id Character. Google Scholar user ID.
#' @return Character string with combined BibTeX entries.
#' @keywords internal
scholar_get_bibtex <- function(scholar_id) {
  pubs <- scholar::get_publications(id = scholar_id)

  if (nrow(pubs) == 0) {
    stop("No publications found for Google Scholar ID: ", scholar_id)
  }

  bib_vec <- purrr::imap_chr(
    .x = purrr::transpose(pubs),
    .f = ~ format_scholar_bibtex(
      pub_row = tibble::as_tibble(.x),
      idx = .y
    )
  )

  result <- stringr::str_c(bib_vec, collapse = "\n\n")
  return(result)
}

#' Fetch publications from Google Scholar and write BibTeX file
#'
#' Scrapes the author's Google Scholar profile using the scholar package.
#' Falls back to rvest-based manual scraping if the primary method fails.
#'
#' @param scholar_id Character. Google Scholar user ID.
#'   Default: "2VGBdDwAAAAJ".
#' @param output Character. Path to write BibTeX output.
#'   Default: "publications.bib".
#' @param force Logical. If TRUE, overwrite existing output file.
#'   Default: FALSE.
#' @return Invisibly returns the path to the written file (character).
#' @export
fetch_publications <- function(
    scholar_id = "2VGBdDwAAAAJ",
    output = "publications.bib",
    force = FALSE) {
  if (file.exists(output) && !force) {
    stop(
      "Output file '", output,
      "' already exists. Set force = TRUE to overwrite."
    )
  }

  bib_text <- tryCatch(
    expr = {
      scholar_get_bibtex(scholar_id = scholar_id)
    },
    error = function(e_primary) {
      message(
        "Primary method (scholar package) failed: ",
        conditionMessage(e_primary)
      )
      message("Attempting fallback method (rvest)...")
      tryCatch(
        expr = {
          fetch_publications_rvest(scholar_id = scholar_id)
        },
        error = function(e_fallback) {
          stop(
            "Both scholar and rvest methods failed.\n",
            "Primary error: ", conditionMessage(e_primary), "\n",
            "Fallback error: ", conditionMessage(e_fallback)
          )
        }
      )
    }
  )

  writeLines(
    text = bib_text,
    con = output
  )

  message("Wrote ", length(bib_text), " bytes to ", output)
  invisible(output)
}
