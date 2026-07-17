# Code Implementation Plan

## Overview

Rewrite the CV page (`cv.qmd`) as proper Quarto markdown to fix the raw-HTML
rendering bug, using the `quarto-cv-pdf` template as the content reference.
Add abstract display with an al-folio-style "Abs" toggle badge to the
Publications page (`publications.qmd`). Write a new `R/fetch_abstracts.R`
script that populates the `abstract` field in `publications.bib` via the
Crossref API (with Europe PMC fallback). Adapt `styles.scss` CV selectors
from class-based to element-based to match the new markdown-rendered HTML.

**Note**: No `quarto-cv-pdf` template file is present on disk — the content
reference was shared in conversation. The CV rewrite derives its structure
from the template description in `OBJECTIVES.md` and the existing `cv.qmd`
content. The Work Experience section content must be supplied by the
implementer from the template reference.

The architecture described here is consistent with `ARCHITECTURE.md`.

## Language and Stack

- **Language**: R 4.6+, Quarto Markdown (`.qmd`), SCSS/CSS
- **Key R packages**: `RefManageR`, `httr2`, `jsonlite`, `stringr`, `dplyr`,
  `purrr`, `tibble`, `rlang`, `htmltools`
- **Key non-R dependencies**: Quarto CLI 1.6+, Bootstrap 5 (bundled with
  Quarto; `data-bs-toggle="collapse"` for abstract togglejs, Font Awesome
  (bundled with Quarto), Academicons CSS (already loaded via
  `_quarto.yml`)
- **Style conventions** (from `STYLE_GUIDE.md`):
  - Native pipe `|>` — never `%>%`. Trailing pipe at end of line.
  - No `library()` or `require()` — always `package::function()`.
  - Named arguments for every function call, each on its own line.
  - `snake_case` for all user-defined names.
  - Double quotes for strings, `TRUE`/`FALSE` spelled out.
  - 80-character line limit.
  - `<-` for assignment, `=` only in function argument lists.

## Assumptions

- The `quarto-cv-pdf` template is not on disk; Work Experience section
  content must be provided by the implementer from the conversation
  reference. The plan leaves a placeholder with `[INSERT FROM TEMPLATE]`
  markers.
- The Education section in the template follows the same structure as the
  current CV (three degrees), so the existing content is preserved and
  reformatted. If the template lists a different degree count or order, the
  implementer should adjust to match the template.
- Crossref API abstract field may contain HTML/JATS markup — it must be
  stripped to plain text before storing in BibTeX.
- Bootstrap JS is already loaded by Quarto's default template, so
  `data-bs-toggle="collapse"` works without additional includes.
- `RefManageR::WriteBib()` handles multiline abstract fields correctly
  (wrapping with BibTeX braces).
- Entries that already have a non-empty `abstract` field in
  `publications.bib` should be skipped by the fetcher (idempotency).

## File Layout

```
personal_website/
├── cv.qmd                    (modify)  ← rewrite as markdown
├── publications.qmd           (modify)  ← add abstract toggle
├── styles.scss                (modify)  ← element-based CV selectors
├── R/
│   └── fetch_abstracts.R     (new)     ← Crossref/Europe PMC fetcher
└── publications.bib           (modify)  ← enriched with abstract fields
```

## Module Specs

---

### `cv.qmd` — Modify

**Responsibility**: The CV page showing education, work experience, research
programmes, teaching, publications link, conference presentations, and
skills. Currently raw indented HTML that Quarto misinterprets as a code
block. Must be rewritten as Quarto-compatible markdown using the
`quarto-cv-pdf` template as the content reference.

**Key structural changes**:

1. **Download link** (top): Keep the existing `<div class="cv-download">`
   and `<a>` tag unchanged — it is already flat HTML (no indentation
   issue) and works correctly.

2. **Education**: Rewrite as markdown with this pattern per degree entry:
   ```markdown
   **Degree Title**  
   *Institution, Country* — YYYY–YYYY

   > **Dissertation:** [Title](URL)  
   > **Supervisors:** Name, Name
   ```
   - The two trailing spaces after the title line create a hard `<br>`
     within the same `<p>`, keeping the title and institution line
     visually together.
   - Institution name in `*italic*` (renders as `<em>`).
   - Thesis and supervisor details in a blockquote (`>` prefix, renders
     as `<blockquote>`).
   - Entries without thesis details (e.g., B.Sc.) omit the blockquote.
   - A blank line separates entries (renders as a new `<p>`).

3. **Work Experience** (new): Add a section with the same markdown pattern
   as Education. Content comes from the template. Mark with a comment:
   ```
   [INSERT WORK EXPERIENCE ENTRIES FROM quarto-cv-pdf TEMPLATE]
   ```
   Each entry follows:
   ```markdown
   **Position Title**  
   *Organization, Country* — YYYY–YYYY

   > Description of responsibilities and achievements
   ```

4. **Research Programmes** (renamed from "Research Projects"): Change the
   heading from "Research Projects" to "Research Programmes". Convert to
   a numbered list:
   ```markdown
   1. **[SYNTHIA](https://www.ihi-synthia.eu/)**
      *IHI Innovative Health Initiative — 2025*  
      Synthetic data generation framework for integrated validation of
      use cases and AI healthcare applications.

   2. **[Smart Health EDIH](https://smarthealth-edih.eu/en/homepag/)**
      *Digital Europe Programme (DEP) & ESPA 2021–2027 — 2024*  
      European Digital Innovation Hub for Smart Health.

   3. **[EHDEN](https://www.ehden.eu/)**
      *Innovative Medicines Initiative 2 Joint Undertaking — 2019–2023*  
      European Health Data and Evidence Network. Doctoral research on
      personalized medicine using real-world data.

   4. **[ADVANCE](https://www.imi.europa.eu/projects-results/project-factsheets/advance)**
      *IHI Innovative Health Initiative — 2016*  
      Accelerated Development of Vaccine Benefit-risk Collaboration in
      Europe. Internship as statistician for evaluating case-finding
      algorithms using real-world medical data.
   ```
   - Each item: bold linked project name, italic funding/timeline on
     next line (use two trailing spaces for `<br>`), description on a
     new paragraph (blank line).

5. **Teaching**: Convert to a numbered list with links:
   ```markdown
   1. University of Western Macedonia — Undergraduate courses in
      Educational Research, Statistics in Educational Research, and
      Quantitative Methods (Winter 2025–2026).
      See the [Teaching](teaching.html) page for the full portfolio.

   2. [NIHES](https://www.nihes.com/) — Advanced Analysis of Prognosis
      Studies (2018–2019), Erasmus MC, Rotterdam.

   3. [OHDSI Symposium Tutorial](https://www.ohdsi.org/2019-tutorial-population-level-estimation/) —
      Population-Level Estimation (2019), North Bethesda, USA.

   4. Student supervision — Gidius van de Kamp, M.Sc. internship (2023):
      [Developing an R package for performing plasmode simulations](https://healthdatascience.nl/gidius-van-de-kamp-cv).
   ```

6. **Publications**: Keep as a simple link paragraph:
   ```markdown
   See the [Publications](publications.html) page for the full list of
   peer-reviewed journal articles and conference contributions.
   ```

7. **Conference Presentations**: Keep as an ordered list `<ol
   class="conf-list">` in raw HTML — this already works correctly (the
   `<ol>` tag is flush-left, not indented, so Quarto does not treat it
   as a code block). The content and links remain unchanged.

8. **Skills**: Convert to a simple markdown list:
   ```markdown
   - **Programming:** R (advanced), Python (intermediate)
   - **Languages:** English (C2 proficiency), German (B2), Greek (native)
   ```

**Section wrappers**: Each major section (Education, Work Experience,
Research Programmes, Teaching, Publications, Conference Presentations,
Skills) is wrapped in `<div class="cv-section">...</div>`. Since these
`<div>` tags are at zero indentation, Quarto renders them as literal HTML.

**Important**: No content inside the `.qmd` file may be indented with 4+
spaces, as Quarto interprets that as a code block. All markdown content
must be flush-left or indented with at most 3 spaces (for nested list
items).

---

### `publications.qmd` — Modify

**Responsibility**: Renders publications from `publications.bib` as
al-folio-style cards grouped by year. Must be extended to extract the
`abstract` field from BibTeX entries and add an "Abs" toggle badge using
Bootstrap collapse.

**Key changes** (all within the existing R chunk, `#| output: asis`):

1. **Extract abstract field** (in the extraction loop, near line 40, after
   `url <- ensure_char(entry$url)`):
   ```r
   abstract <- ensure_char(entry$abstract)
   ```

2. **Add `abstract` to the pub_list tibble** (in the `list()` call near
   line 62, after `url = url`):
   ```r
   abstract = abstract
   ```

3. **Add "Abs" badge** (in the links-building block near line 128, inside
   the `links_parts` accumulation, after the URL badge logic):
   ```r
   if (nchar(row[["abstract"]]) > 0) {
     abs_id <- stringr::str_c(
       "abs-",
       row[["key"]]
     )
     links_parts <- c(
       links_parts,
       stringr::str_c(
         '<a class="badge" data-bs-toggle="collapse"',
         ' href="#', abs_id, '"',
         ' role="button" aria-expanded="false"',
         ' aria-controls="', abs_id, '">Abs</a>'
       )
     )
   }
   ```
   The badge uses Bootstrap's `data-bs-toggle="collapse"` attribute.
   The `href` points to the abstract div's `id` with a `#` prefix.
   Each abstract gets a unique `id` based on the BibTeX citation key
   (e.g., `abs-rekkas2023standardized`).

4. **Add abstract collapse div** (after the links `<div>` is emitted, near
   line 158, before the closing `</div>` of the card):
   ```r
   if (nchar(row[["abstract"]]) > 0) {
     cat(
       '<div class="collapse" id="abs-', row[["key"]], '">\n',
       '  <div class="pub-abstract">',
       htmltools::htmlEscape(text = row[["abstract"]]),
       '</div>\n',
       '</div>\n',
       sep = ""
     )
   }
   ```
   The `.collapse` class is hidden by default; Bootstrap JS toggles it
   when the "Abs" badge is clicked. The `.pub-abstract` div already has
   styling in `styles.scss` (background, border-radius, font-size).

5. **No-badge behaviour**: Entries where `abstract` is empty (zero-length
   string) produce no badge and no collapse div. The links row may have
   only DOI/URL badges or be omitted entirely (existing behaviour).

**Note on ordering**: The "Abs" badge should appear after the URL badge
(if any) in the `.pub-links` row. This maintains the al-folio convention.

---

### `styles.scss` — Modify

**Responsibility**: Adapt CSS selectors for the CV page from class-based
(`.cv-entry-title`, `.cv-entry-meta`, `.cv-entry-desc`) to element-based
selectors that match the HTML produced by Quarto's markdown-to-HTML
rendering. Preserve the existing visual look: section headings with left
border accent, entry title/meta/desc hierarchy, separator borders.

**Changes to the `.cv-section` block** (lines 237–267 of current
`styles.scss`):

Replace the entire `.cv-section { ... }` block with:

```scss
// CV section styling
.cv-section {
  margin-bottom: 2rem;

  h2 {
    border-left: 4px solid $primary;
    padding-left: 0.75rem;
    font-size: 1.25rem;
    font-weight: 600;
    color: $primary;
    margin-top: 0;
  }

  // Entry title: the bold text at the start of a paragraph
  // Rendered from markdown **Title** as <strong> inside <p>
  strong {
    font-weight: 600;
    font-size: 1rem;
  }

  // Institution/org meta: italic text within paragraphs
  // Rendered from markdown *text* as <em>
  em {
    font-style: italic;
    color: #555;
  }

  // Paragraphs within CV sections: body text for entries
  p {
    font-size: 0.9rem;
    line-height: 1.5;
    margin-bottom: 0.25rem;
  }

  // Thesis/supervisor descriptions: markdown > blockquote
  blockquote {
    font-size: 0.85rem;
    margin: 0.25rem 0 1rem 0;
    padding: 0 0 1rem 0;
    border-left: none;
    border-bottom: 1px solid #eee;

    p {
      margin-bottom: 0.25rem;
      font-size: 0.85rem;
    }
  }

  // Last blockquote in a section gets no border-bottom
  // (no visual separator after the last entry)
  blockquote:last-of-type {
    border-bottom: none;
    padding-bottom: 0;
  }

  // Numbered lists in CV (Research Programmes, Teaching, Conferences)
  ol {
    font-size: 0.9rem;
    line-height: 1.5;
    padding-left: 1.5rem;

    li {
      margin-bottom: 0.75rem;
      padding-bottom: 0.75rem;
      border-bottom: 1px solid #eee;

      &:last-child {
        border-bottom: none;
        padding-bottom: 0;
      }

      // Bold text inside list items (project names, presentation type)
      strong {
        font-size: 0.95rem;
      }

      // Italic text inside list items (funding metadata)
      em {
        font-size: 0.85rem;
        display: block;
        margin-top: 0.1rem;
      }
    }
  }

  // Unordered lists (Skills section)
  ul {
    list-style: none;
    padding-left: 0;
    font-size: 0.9rem;

    li {
      margin-bottom: 0.5rem;

      strong {
        font-size: 0.9rem;
      }
    }
  }
}
```

**What is removed**:
- `.cv-entry` and all its sub-rules (`margin-bottom`, `padding-bottom`,
  `border-bottom`, `:last-child`) — entry boundaries are now defined by
  blockquote borders and paragraph margins.
- `.cv-entry-title` — replaced by `.cv-section strong`.
- `.cv-entry-meta` — replaced by `.cv-section em` and `.cv-section p`.
- `.cv-entry-desc` — replaced by `.cv-section blockquote`.

**What is kept unchanged**:
- `.cv-download` (line 269–271) — no changes needed.
- `.conf-list` (lines 274–295) — remains for the conference presentations
  ordered list, which stays as raw HTML with the `conf-list` class.
- All publication card styles (`.pub-card`, `.pub-year`, `.pub-title`,
  `.pub-authors`, `.pub-venue`, `.pub-links`, `.pub-abstract`) — no
  changes.
- Project card styles, teaching styles, about page styles — no changes.
- Responsive breakpoint at 768px — no changes.

---

### `R/fetch_abstracts.R` — New

**Responsibility**: Read `publications.bib`, query the Crossref API for each
entry's abstract (using the DOI field), fall back to Europe PMC if Crossref
returns no abstract, and write the enriched file back to disk. Idempotent:
entries that already have a non-empty `abstract` field are skipped.

**Exported functions**:

#### `fetch_abstracts(bib_path = "publications.bib")`

- **Purpose**: Enrich a BibTeX file with abstracts fetched from Crossref
  and Europe PMC APIs.
- **Args**:
  - `bib_path` (`character`, default `"publications.bib"`): Path to the
    BibTeX file to read and write.
- **Returns**: `character` — invisibly returns `bib_path` on success.
- **Errors**:
  - If `bib_path` does not exist: `rlang::abort("File not found: ...")`.
  - If the file contains zero entries: message and return early.
  - Individual API failures for a single entry are caught and logged;
    the entry is skipped (no abstract added) and processing continues
    with the next entry.
- **Pseudocode**:
  ```
  1. Validate: if bib_path does not exist, abort
  2. bib <- RefManageR::ReadBib(file = bib_path, check = FALSE)
  3. n <- length(bib)
  4. If n == 0, message("No entries found."); return invisible(bib_path)
  5. modified <- FALSE
  6. For i in seq_len(n):
     a. entry <- bib[i]
     b. key <- names(bib)[i]
     c. existing_abstract <- ensure_char(entry$abstract)
     d. If nchar(existing_abstract) > 0:
        - message("Skipping ", key, ": abstract already exists")
        - next iteration
     e. doi <- ensure_char(entry$doi)
     f. If nchar(doi) == 0:
        - message("Skipping ", key, ": no DOI")
        - next iteration
     g. message("Fetching abstract for ", key, " (DOI: ", doi, ")")
     h. abstract <- fetch_crossref_abstract(doi = doi)
     i. If nchar(abstract) == 0:
        - abstract <- fetch_europepmc_abstract(doi = doi)
     j. If nchar(abstract) > 0:
        - abstract_clean <- strip_html(html = abstract)
        - entry$abstract <- abstract_clean
        - bib[i] <- entry
        - modified <- TRUE
     k. Sys.sleep(1)  // polite rate limiting
  7. If modified:
     - RefManageR::WriteBib(bib = bib, file = bib_path)
     - message("Wrote updated bibliography to ", bib_path)
     else:
     - message("No new abstracts added.")
  8. Return invisible(bib_path)
  ```

**Internal helpers** (not exported):

#### `ensure_char(x)`

- **Purpose**: Coerce a BibTeX field value to a character string, returning
  `""` for empty/missing fields.
- **Args**:
  - `x`: Any R object (typically from `entry$field`).
- **Returns**: `character` — the value as a string, or `""`.
- **Pseudocode**:
  ```
  if (length(x) == 0) "" else as.character(x)
  ```

#### `fetch_crossref_abstract(doi)`

- **Purpose**: Query the Crossref REST API for a work's abstract.
- **Args**:
  - `doi` (`character`): A single DOI string.
- **Returns**: `character` — The abstract text, or `""` if not found or
  on error.
- **Errors**: None — catches all errors internally and returns `""`.
- **Pseudocode**:
  ```
  1. Build URL: stringr::str_c("https://api.crossref.org/works/", doi)
  2. Try:
     a. resp <- httr2::request(url) |>
          httr2::req_user_agent(
            string = "personal_website/1.0 (mailto:arekkas@certh.gr)"
          ) |>
          httr2::req_perform()
     b. body <- httr2::resp_body_json(resp = resp)
     c. abstract <- body[["message"]][["abstract"]]
     d. If is.null(abstract) or nchar(abstract) == 0:
        - Return ""
     e. Return abstract as character
  3. On error (network, parsing):
     - message("  Crossref API failed: ", conditionMessage(e))
     - Return ""
  ```

#### `fetch_europepmc_abstract(doi)`

- **Purpose**: Query the Europe PMC REST API as a fallback for abstracts.
- **Args**:
  - `doi` (`character`): A single DOI string.
- **Returns**: `character` — The abstract text, or `""` if not found or
  on error.
- **Errors**: None — catches all errors internally and returns `""`.
- **Pseudocode**:
  ```
  1. Build URL: stringr::str_c(
       "https://www.ebi.ac.uk/europepmc/webservices/rest/search",
       "?query=DOI:", doi, "&format=json&resultType=core"
     )
  2. Try:
     a. resp <- httr2::request(url) |>
          httr2::req_user_agent(
            string = "personal_website/1.0 (mailto:arekkas@certh.gr)"
          ) |>
          httr2::req_perform()
     b. body <- httr2::resp_body_json(resp = resp)
     c. results <- body[["resultList"]][["result"]]
     d. If length(results) == 0:
        - message("  Europe PMC: no results for DOI")
        - Return ""
     e. abstract <- results[[1]][["abstractText"]]
     f. If is.null(abstract) or nchar(abstract) == 0:
        - Return ""
     g. Return abstract as character
  3. On error (network, parsing):
     - message("  Europe PMC API failed: ", conditionMessage(e))
     - Return ""
  ```

#### `strip_html(html)`

- **Purpose**: Strip HTML tags and decode common HTML entities from
  abstract text returned by APIs.
- **Args**:
  - `html` (`character`): Raw abstract text potentially containing HTML
    markup.
- **Returns**: `character` — Plain text with tags removed.
- **Pseudocode**:
  ```
  1. Remove HTML tags: stringr::str_replace_all(
       string = html,
       pattern = "<[^>]+>",
       replacement = ""
     )
  2. Decode common entities:
     - &amp;  → &
     - &lt;   → <
     - &gt;   → >
     - &quot; → "
     - &#39;  → '
     - &ndash; → –
     - &mdash; → —
     (Use a series of stringr::str_replace_all() calls)
  3. Collapse multiple whitespace characters:
     stringr::str_squish(string = result)
  4. Return cleaned text
  ```

**Dependencies**: No internal project modules. This is a standalone script.

**New packages** (add to `renv.lock`): `httr2`, `jsonlite`, `RefManageR`,
`stringr`, `purrr`, `dplyr`, `tibble`, `rlang`.

---

## Data Flow

```
R/fetch_abstracts.R
    │  reads publications.bib
    │  queries Crossref API (primary) / Europe PMC (fallback)
    │  writes enriched publications.bib
    ▼
publications.bib  (now with abstract fields)
    │
    ▼
publications.qmd (R chunk: RefManageR::ReadBib → extracts abstract)
    │  emits HTML with "Abs" badge + Bootstrap collapse div
    ▼
cv.qmd (plain markdown, no R execution)
    │  produces HTML with <h2>, <p>, <strong>, <em>, <blockquote>, <ol>
    ▼
styles.scss
    │  .cv-section selectors target the new HTML elements
    ▼
quarto render → _site/ (static HTML)
```

The render flow for this task:
1. Run `R/fetch_abstracts.R` once to populate `publications.bib` with
   abstracts.
2. `publications.qmd` reads the enriched `publications.bib` at render time
   and includes abstract data in the generated HTML.
3. `cv.qmd` renders as clean markdown, producing semantic HTML.
4. `styles.scss` styles the CV HTML via element selectors and the
   publication cards via existing class selectors.

## Execution Checklist

### Phase 1 — Implementation: [IMPL]

1. [x] [IMPL] `R/fetch_abstracts.R`: create the file with internal helper
    `ensure_char()`
2. [x] [IMPL] `R/fetch_abstracts.R`: implement `strip_html()` — strip HTML
    tags and decode common entities from abstract text
3. [x] [IMPL] `R/fetch_abstracts.R`: implement `fetch_crossref_abstract()`
    — query Crossref `/works/{doi}` endpoint, extract `abstract` field from
    JSON response, return `""` on error/missing
4. [x] [IMPL] `R/fetch_abstracts.R`: implement `fetch_europepmc_abstract()`
    — query Europe PMC search endpoint with `DOI:{doi}` query, extract
    `abstractText` from first result, return `""` on error/missing
5. [x] [IMPL] `R/fetch_abstracts.R`: implement exported `fetch_abstracts()`
    — read BibTeX, iterate entries, skip entries with existing abstracts or
    no DOI, call Crossref then Europe PMC, strip HTML, assign abstract,
    write back. Include `Sys.sleep(1)` rate limiting and progress messages.
    Follow STYLE_GUIDE.md: `|>` pipe, `::` prefix, `snake_case`, named
    args, 80-char lines, double quotes.
6. [x] [IMPL] `R/fetch_abstracts.R`: add roxygen2 `@export` tag on
    `fetch_abstracts()`, `@keywords internal` on helpers, and a file-level
    comment block describing the script's purpose.
7. [x] [IMPL] Run `R/fetch_abstracts.R` to fetch abstracts and update
    `publications.bib`. Verify the file has new `abstract = {...}` fields
    on entries with DOIs, and no abstract field on the dissertation entry
    (`rekkas2023beyond`, which has no DOI).
8. [x] [IMPL] `publications.qmd`: in the extraction loop, add
    `abstract <- ensure_char(entry$abstract)` after the `url` line
9. [x] [IMPL] `publications.qmd`: add `abstract = abstract` to the
    `pub_list[[i]] <- list(...)` call
10. [x] [IMPL] `publications.qmd`: in the badge-building section, add an
     "Abs" badge with `data-bs-toggle="collapse"`, `href="#abs-{key}"`,
     `role="button"`, `aria-expanded="false"`, and
     `aria-controls="abs-{key}"` — only when `abstract` is non-empty
11. [x] [IMPL] `publications.qmd`: after the links `<div>`, emit a
     `<div class="collapse" id="abs-{key}">` containing a
     `<div class="pub-abstract">` with the abstract text (HTML-escaped via
     `htmltools::htmlEscape()`) — only when abstract is non-empty
12. [x] [IMPL] `cv.qmd`: rewrite the entire file as Quarto markdown.
     Replace raw indented HTML with flush-left markdown following the
     structure specified in Module Specs above. Use `<div
     class="cv-section">` wrappers for major sections. Format Education
     entries with `**Title**`, `*Institution* — dates`, and `> blockquote`
     for thesis/supervisor details. Add Work Experience section using
     content from the `quarto-cv-pdf` template (insert placeholder comment
     if exact content is unknown). Rename "Research Projects" to "Research
     Programmes" and convert to a numbered list. Keep the conference
     presentations `<ol class="conf-list">` as raw HTML (flush-left, not
     indented). Keep the download link `<div>` unchanged. Ensure no content
     is indented 4+ spaces.
13. [x] [IMPL] `styles.scss`: replace the entire `.cv-section { ... }`
     block (lines 237–267) with element-based selectors as specified in
     Module Specs above. Remove `.cv-entry`, `.cv-entry-title`,
     `.cv-entry-meta`, `.cv-entry-desc`. Add selectors for `strong`, `em`,
     `p`, `blockquote`, `ol li`, `ul li` scoped within `.cv-section`.
     Preserve `.cv-download` and `.conf-list` blocks unchanged.
14. [x] [IMPL] `renv.lock`: install new packages (`httr2`, `jsonlite`) if
     not already present, then run `renv::snapshot()` to update the
     lockfile.
15. [x] [IMPL] Run `quarto render` locally and verify:
     - The CV page renders with proper markdown styling (no raw HTML/code
       block artifacts).
     - Education and Work Experience entries show title bold, institution
       italic, and thesis/supervisor details in blockquotes.
     - Research Programmes display as a numbered list.
     - The Publications page shows "Abs" badges for entries with abstracts.
     - Clicking an "Abs" badge toggles the abstract text inline.
     - Entries without abstracts have no "Abs" badge and no collapse div.
     - All 5 pages build without errors.

