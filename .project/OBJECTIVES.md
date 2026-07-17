# Objectives

## Problem Statement

Alexandros Rekkas (INAB | CERTH) needs an academic personal website to
showcase his research, publications, teaching, and CV. The site must match
the visual design of the al-folio Jekyll theme but be built with Quarto
for easier R-based content management.

## Solution

Build a Quarto static website that reproduces the al-folio visual design
via custom SCSS/CSS. The site uses a left sidebar layout with profile
photo and social links (GitHub, email, Google Scholar). Publications are
seeded by scraping the author's Google Scholar profile into a BibTeX file,
then maintained manually. The CV page renders as HTML (translated from an
existing Greek CV) and offers a downloadable PDF. The site deploys to
GitHub Pages at `rekkasa.github.io`, with a custom domain (`arekkas.gr`)
planned for later.

## Out of Scope

- News / blog / announcements
- Selected publications section (all pubs on one page only)
- GitHub repository showcase
- Analytics (Google Analytics, etc.)
- Custom domain setup (arekkas.gr) — deferred until the site is live
- Dark/light mode toggle (not requested; can be added later)
- Any non-English content (site is English-only, aside from CV PDF which
  may retain Greek)

## Further Notes

- **al-folio reference**: The al-folio theme uses Bootstrap 5, Font Awesome
  icons, and a distinctive card-based layout for publications/projects.
  Quarto also uses Bootstrap, so custom SCSS can likely achieve high
  fidelity by overriding variables and adding sidebar styles.
- **Google Scholar scraping**: Google Scholar actively blocks automated
  scraping. The one-time scrape may require a fallback plan (manual BibTeX
  entry) if Scholar returns CAPTCHAs.
- **Quarto CV format**: The existing CV uses `quarto-cv-pdf` format
  (designed for PDF output). The website CV page will be a standalone
  `.qmd` rendered as HTML; the PDF will be generated separately and linked.
- **Profile photo**: Use the GitHub avatar from
  `https://github.com/rekkasa.png`.
- Open: Should the default al-folio theme color (purple) be kept, or
  customized? Not discussed.
- Open: Should the CV PDF be generated at build time or pre-built and
  committed to the repo? Pre-built and committed is simpler.
- Open: The existing `.Rprofile` points to `renv`. Is `renv` needed for
  this website project? The site is primarily Quarto/Markdown with
  minimal R.

## Modules

### 1. Quarto Website Scaffold — Build

**What it does**: The top-level Quarto project configuration and site
structure that ties all pages together with the al-folio sidebar layout.

**Key changes**:
- `_quarto.yml`: project type `website`, Bootstrap theme with custom SCSS,
  navbar disabled, sidebar enabled with profile photo, name, affiliation,
  and icon links
- Custom `styles.scss` importing Bootstrap overrides and sidebar layout CSS
- `index.qmd`: redirect or landing (About page as homepage)
- Google Scholar icon (not in standard Font Awesome — may need custom SVG
  or Academicons)

**Dependencies**: All page modules listed below.

### 2. About Page — Build

**What it does**: Homepage with minimal biographical text and research
interests.

**Key changes**:
- `about.qmd`: "My name is Alexandros Rekkas. I hold a PhD in Medical
  Informatics from Erasmus University."
- Research interests: clinical prediction modeling, treatment effect
  heterogeneity using machine learning and causal inference methods

**Dependencies**: Quarto Website Scaffold.

### 3. Publications Page — Build

**What it does**: Renders a list of publications from a BibTeX file, styled
as al-folio publication cards (title, authors, venue, year, links).

**Key changes**:
- R script (`R/fetch_publications.R`) to scrape Google Scholar profile
  (`https://scholar.google.com/citations?user=2VGBdDwAAAAJ`) and write
  `publications.bib`
- `publications.qmd`: reads `publications.bib` and renders publications
  using a custom listing or manual BibTeX-to-HTML approach
- ~20 publications (mix of journal articles, conference abstracts)

**Dependencies**: Quarto Website Scaffold.

### 4. Projects Page — Build

**What it does**: Lists research projects with descriptions, funding,
timeline.

**Key changes**:
- `projects.qmd`: renders four research projects:
  - SYNTHIA (IHI, 2025)
  - Smart Health EDIH (DEP/ESPA, 2024)
  - EHDEN (IMI2, 2019–2023)
  - ADVANCE (IHI, 2016)

**Dependencies**: Quarto Website Scaffold.

### 5. CV Page — Build

**What it does**: English HTML rendering of the academic CV with a link to
download the PDF version.

**Key changes**:
- Translate `cv_greek.qmd` from Greek to English
- `cv.qmd`: HTML-rendered CV page (education, research projects, teaching,
  publications, skills)
- Linked PDF version (pre-built, committed to repo)

**Dependencies**: Quarto Website Scaffold.

### 6. Teaching Page — Build

**What it does**: Full teaching portfolio with course details, tutorials,
and student supervision.

**Key changes**:
- `teaching.qmd`: lists all teaching activities from the CV (U. of Western
  Macedonia courses, NIHES course, OHDSI tutorial, student supervision)
  with links

**Dependencies**: Quarto Website Scaffold.
