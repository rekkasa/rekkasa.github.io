# fetch_abstracts.R --- CrossRef / Europe PMC abstract fetcher
#
# Reads publications.bib, queries the Crossref API for each entry's abstract
# (using the DOI field), falls back to Europe PMC if Crossref returns no
# abstract, and writes the enriched BibTeX file back to disk. Entries that
# already have a non-empty abstract field are skipped (idempotent).

# Coerce a BibTeX field value to a character string, returning "" for
# empty/missing fields.
#
# @param x Any R object (typically from entry$field).
# @return Character string, or "" if the field is empty/missing.
# @keywords internal
ensure_char <- function(x) {
  if (length(x) == 0) "" else as.character(x = x)
}

# Strip HTML tags and decode common HTML entities from abstract text.
#
# @param html Character. Raw abstract text potentially containing HTML
#   markup.
# @return Character. Plain text with tags removed and entities decoded.
# @keywords internal
strip_html <- function(html) {
  result <- stringr::str_replace_all(
    string = html,
    pattern = "<[^>]+>",
    replacement = ""
  )
  result <- stringr::str_replace_all(
    string = result,
    pattern = "&amp;",
    replacement = "&"
  )
  result <- stringr::str_replace_all(
    string = result,
    pattern = "&lt;",
    replacement = "<"
  )
  result <- stringr::str_replace_all(
    string = result,
    pattern = "&gt;",
    replacement = ">"
  )
  result <- stringr::str_replace_all(
    string = result,
    pattern = "&quot;",
    replacement = "\""
  )
  result <- stringr::str_replace_all(
    string = result,
    pattern = "&#39;",
    replacement = "'"
  )
  result <- stringr::str_replace_all(
    string = result,
    pattern = "&ndash;",
    replacement = "\u2013"
  )
  result <- stringr::str_replace_all(
    string = result,
    pattern = "&mdash;",
    replacement = "\u2014"
  )
  result <- stringr::str_squish(string = result)
  return(result)
}

# Query the Crossref REST API for a work's abstract.
#
# @param doi Character. A single DOI string.
# @return Character. The abstract text, or "" if not found or on error.
# @keywords internal
fetch_crossref_abstract <- function(doi) {
  url <- stringr::str_c("https://api.crossref.org/works/", doi)
  tryCatch(
    expr = {
      resp <- httr2::request(url) |>
        httr2::req_user_agent(
          string = "personal_website/1.0 (mailto:arekkas@certh.gr)"
        ) |>
        httr2::req_perform()
      body <- httr2::resp_body_json(resp = resp)
      abstract <- body[["message"]][["abstract"]]
      if (is.null(abstract) || nchar(abstract) == 0) {
        return("")
      }
      return(as.character(x = abstract))
    },
    error = function(e) {
      message("  Crossref API failed: ", conditionMessage(c = e))
      return("")
    }
  )
}

# Query the Europe PMC REST API as a fallback for abstracts.
#
# @param doi Character. A single DOI string.
# @return Character. The abstract text, or "" if not found or on error.
# @keywords internal
fetch_europepmc_abstract <- function(doi) {
  url <- stringr::str_c(
    "https://www.ebi.ac.uk/europepmc/webservices/rest/search",
    "?query=DOI:",
    doi,
    "&format=json&resultType=core"
  )
  tryCatch(
    expr = {
      resp <- httr2::request(url) |>
        httr2::req_user_agent(
          string = "personal_website/1.0 (mailto:arekkas@certh.gr)"
        ) |>
        httr2::req_perform()
      body <- httr2::resp_body_json(resp = resp)
      results <- body[["resultList"]][["result"]]
      if (length(results) == 0) {
        message("  Europe PMC: no results for DOI")
        return("")
      }
      abstract <- results[[1]][["abstractText"]]
      if (is.null(abstract) || nchar(abstract) == 0) {
        return("")
      }
      return(as.character(x = abstract))
    },
    error = function(e) {
      message("  Europe PMC API failed: ", conditionMessage(c = e))
      return("")
    }
  )
}

# Enrich a BibTeX file with abstracts fetched from Crossref and Europe PMC.
#
# Reads the BibTeX file at bib_path, iterates entries, and for each entry
# with a DOI and no existing abstract, queries Crossref then Europe PMC for
# the abstract. Strips HTML from the abstract and writes the enriched file
# back to disk. Idempotent: entries that already have a non-empty abstract
# are skipped.
#
# @param bib_path Character. Path to the BibTeX file.
#   Default: "publications.bib".
# @return Invisibly returns bib_path on success.
# @export
fetch_abstracts <- function(bib_path = "publications.bib") {
  if (!file.exists(bib_path)) {
    rlang::abort(
      message = stringr::str_c("File not found: ", bib_path)
    )
  }

  bib <- RefManageR::ReadBib(
    file = bib_path,
    check = FALSE
  )

  n <- length(x = bib)
  if (n == 0) {
    message("No entries found.")
    return(invisible(x = bib_path))
  }

  modified <- FALSE

  for (i in seq_len(length.out = n)) {
    entry <- bib[i]
    key <- names(x = bib)[[i]]

    existing_abstract <- ensure_char(x = entry$abstract)
    if (nchar(x = existing_abstract) > 0) {
      message("Skipping ", key, ": abstract already exists")
      next
    }

    doi <- ensure_char(x = entry$doi)
    if (nchar(x = doi) == 0) {
      message("Skipping ", key, ": no DOI")
      next
    }

    message("Fetching abstract for ", key, " (DOI: ", doi, ")")
    abstract <- fetch_crossref_abstract(doi = doi)

    if (nchar(x = abstract) == 0) {
      abstract <- fetch_europepmc_abstract(doi = doi)
    }

    if (nchar(x = abstract) > 0) {
      abstract_clean <- strip_html(html = abstract)
      bib[[key]]$abstract <- abstract_clean
      modified <- TRUE
    }

    Sys.sleep(time = 1)
  }

  if (modified) {
    RefManageR::WriteBib(
      bib = bib,
      file = bib_path
    )
    message("Wrote updated bibliography to ", bib_path)
  } else {
    message("No new abstracts added.")
  }

  invisible(x = bib_path)
}
