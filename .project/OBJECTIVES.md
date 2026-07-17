# Objectives

## Problem Statement

The CV page (`cv.qmd`) is written entirely as raw indented HTML, causing
Quarto/Pandoc to interpret 4-space-indented content as markdown code blocks.
This wraps the CV content in `<pre><code>` tags in the rendered HTML, displaying
raw HTML entities (`&mdash;`, `&ndash;`) and tags as literal text instead of
styled content. Separately, the Publications page has no abstract display
capability — no `abstract` field is extracted from `publications.bib` and no
toggle UI exists for showing/hiding abstracts inline.

## Solution

Rewrite `cv.qmd` as proper Quarto markdown (not raw HTML), using the user's
existing `quarto-cv-pdf` template as the content reference. Adapt LaTeX
formatting (e.g., `\hfill`, `\newline`) to HTML-compatible markdown. Modify
`styles.scss` as needed so the new markdown output preserves the existing
al-folio visual look (section headings with left border accent, entry
title/meta/desc hierarchy). Add a Crossref API-based script to populate the
`abstract` field in `publications.bib`, with Europe PMC as fallback when
Crossref returns no abstract. Add an "Abs" badge to each publication card
that toggles the abstract text inline, matching the al-folio template
interaction pattern. Entries with no abstract (after both API attempts) get
no badge.

## Out of Scope

- Rendering the CV as PDF (the `quarto-cv-pdf` format is separate; `cv.pdf`
  remains a pre-built static file)
- Dark/light mode toggle
- Google Scholar scraping (already done; `publications.bib` is maintained
  manually)
- Analytics, custom domain, blog/news/announcements
- Adding `abstract` to entries that lack DOIs or where both APIs fail
  (no manual prompting — just skip)
- Changing how the Publications section of the CV works (it remains a link
  to `publications.html`)
- Rendering publications inline on the CV page via `peer_bib.bib` (the
  template's `::: {#refs-peer} :::` approach is not used for HTML)

## Further Notes

- The user provided a `quarto-cv-pdf` template with LaTeX formatting as the
  content reference. The HTML CV must convey the same information but cannot
  use LaTeX commands (`\hfill`, `\newline`, `\begin{tabular}`) — these are
  PDF-only and break HTML rendering.
- The Personal Information section (name, father's name, date of birth, etc.)
  is explicitly excluded from the HTML CV page.
- The existing `styles.scss` has `.cv-section`, `.cv-entry`, `.cv-entry-title`,
  `.cv-entry-meta`, `.cv-entry-desc` classes. As the markdown output will
  produce different HTML elements (not divs with these classes), the CSS
  selectors must be adapted to target the actual elements rendered by Quarto
  from markdown (e.g., `h2`/`h3` within `.cv-section`, `em` for institution
  names, blockquote styling, list styling).
- Crossref API is free and requires no authentication for basic use. Rate
  limits are generous (typically 50 requests/second). Europe PMC is also free.
- The existing `R/fetch_publications.R` handles Google Scholar scraping only.
  The new abstract-fetching function should be a separate script or function
  that reads existing `publications.bib`, queries APIs, and writes back the
  updated file.
- Current `publications.bib` has 17 entries. Most have DOIs. A few entries
  (e.g., the dissertation `rekkas2023beyond`) have no DOI — these will be
  skipped for abstract fetching.

## Modules

### 1. CV Page — Modify

**What it does**: The CV page (`cv.qmd`) showcases education, work experience,
research programmes, teaching, publications link, conference presentations,
and skills. Currently raw indented HTML, must be rewritten as proper Quarto
markdown.

**Key changes**:
- Rewrite entire `cv.qmd` as markdown, using the user's provided template as
  the content reference
- Education: institution names in italic, location/dates on same line via
  Quarto-compatible formatting, thesis/supervisor details as blockquotes
- Add new Work Experience section (not in current CV)
- Replace "Research Projects" with the template's "Research Programmes"
  (numbered list with descriptions)
- Teaching: convert to numbered list with links
- Conference presentations: convert to numbered list (the current `<ol>`
  already works; update content to match template)
- Publications section: keep as a link to `publications.html`
- Skills: keep as blockquote or simple list
- Exclude Personal Information section
- Add download link for `cv.pdf` at top
- No R code execution needed

**Dependencies**: Module 3 (styles.scss changes for CV selectors).

### 2. Publications Page — Modify

**What it does**: Renders publications from `publications.bib` as
al-folio-style cards. Must be extended to extract and display the `abstract`
field with a toggle button matching the al-folio "Abs" badge pattern.

**Key changes**:
- In the R chunk inside `publications.qmd`, add extraction of the `abstract`
  field from BibTeX entries (alongside existing `title`, `journal`, `doi`,
  `url`, etc.)
- For each publication card with a non-empty abstract, add an "Abs" badge
  in the `.pub-links` row (between DOI/URL badges)
- Use Bootstrap's `data-bs-toggle="collapse"` with a unique `id` for each
  abstract, since Bootstrap JS is already loaded by Quarto
- The abstract text expands inline below the links row, inside a
  `.pub-abstract` div (the CSS class already exists in `styles.scss`)
- Entries without abstracts get no badge and no abstract div

**Dependencies**: Module 4 (abstracts must exist in `publications.bib` for
  the toggle to display them).

### 3. CV Styles — Modify

**What it does**: The `styles.scss` file that styles the CV page. Current
selectors target raw HTML classes (`.cv-entry-title`, `.cv-entry-meta`,
`.cv-entry-desc`). After the markdown rewrite, the rendered HTML will use
different elements (paragraphs, headings, blockquotes, emphasis, lists).
The CSS must be adapted to target those while preserving the same visual
look.

**Key changes**:
- Replace class-based selectors (`.cv-entry-title`, `.cv-entry-meta`,
  `.cv-entry-desc`) with element selectors scoped within `.cv-section`
- Style institution names (rendered as `<em>` from markdown `*text*`) with
  appropriate font-weight and color
- Style blockquotes within CV sections to match the former `.cv-entry-desc`
  look
- Style numbered lists within CV sections for research programmes and
  conferences
- Ensure section headings (`.cv-section h2`) retain the left border accent
- Keep `.cv-download` styling unchanged
- Keep `.conf-list` styling unchanged (conference presentations list
  already works)
- Keep responsive breakpoint unchanged

**Dependencies**: Module 1 (must match the HTML elements produced by the
  markdown rewrite).

### 4. Abstract Fetcher — Build

**What it does**: New R script or function that reads `publications.bib`,
queries the Crossref API for each entry's abstract (using the DOI), falls
back to Europe PMC API if Crossref returns no abstract, and writes the
enriched `publications.bib` back to disk.

**Key changes**:
- New file `R/fetch_abstracts.R` containing a `fetch_abstracts()` function
- For each BibTeX entry with a DOI:
  1. Query `https://api.crossref.org/works/{doi}` and extract `abstract`
  2. If empty/missing, query Europe PMC
     `https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=DOI:{doi}&format=json`
     and extract `abstractText`
  3. If both fail, leave abstract empty
- Read existing `publications.bib` with `RefManageR::ReadBib()`, add/edit
  the `abstract` field on each entry, and write back with
  `RefManageR::WriteBib()`
- Follow project style guide: `|>` pipe, `::` prefixes, `snake_case`,
  named args, 80-char lines, double quotes
- Entries without DOIs (e.g., dissertations) are skipped gracefully
- Only add `abstract` field when non-empty; preserve existing BibTeX fields
  intact

**Dependencies**: Requires `publications.bib` to exist. New R packages
  needed: `httr2` or `curl` (HTTP requests), `jsonlite` (JSON parsing),
  `RefManageR`, `stringr`, `purrr`, `tibble`, `dplyr`.
