# Architecture

## System Overview

A Quarto static website that reproduces the al-folio Jekyll theme's visual
design. The site uses a **left sidebar layout** with profile information
and social links, with page content in the main area. The site is
structured as a Quarto website project, configured via `_quarto.yml`.
All content pages are standalone `.qmd` files. The site deploys to GitHub
Pages via GitHub Actions.

```
_quarto.yml             ← Site config, Bootstrap theme, sidebar, custom SCSS
styles.scss              ← al-folio visual overrides
_includes/sidebar.html   ← Sidebar HTML partial (profile, nav, social links)
index.qmd                ← Homepage (About)
publications.bib         ← BibTeX bibliography (maintained manually)
publications.qmd         ← Publication cards with abstract toggle
projects.qmd             ← Research project listings
cv.qmd                   ← English CV (Quarto markdown)
teaching.qmd             ← Teaching portfolio
cv.pdf                   ← Pre-built downloadable CV PDF
R/fetch_publications.R   ← One-time Google Scholar scraper
R/fetch_abstracts.R      ← Crossref/Europe PMC abstract fetcher
```

## Modules

| # | Module | Type | Description |
|---|--------|------|-------------|
| 1 | Quarto Website Scaffold | Build | `_quarto.yml` + `styles.scss` — sidebar layout, al-folio theming |
| 2 | About Page | Build | `index.qmd` — biographical text + research interests |
| 3 | Publications Page | Build | `publications.qmd` + `publications.bib` — BibTeX-driven pub cards with abstract toggle |
| 4 | Projects Page | Build | `projects.qmd` — four research projects |
| 5 | CV Page | Build | `cv.qmd` — English CV as Quarto markdown with PDF download |
| 6 | Teaching Page | Build | `teaching.qmd` — full teaching portfolio |
| 7 | Abstract Fetcher | Build | `R/fetch_abstracts.R` — populates abstracts from Crossref/Europe PMC APIs |

All page modules depend on Module 1 (scaffold) for layout and styling.
Modules 2–6 are independent of each other. Module 7 feeds data into
`publications.bib`, which Module 3 consumes at render time.

## Key Decisions

1. **Quarto over Jekyll**: Quarto chosen for native R/BibTeX integration
   and simpler content authoring in Markdown, while still outputting a
   Bootstrap-based static site compatible with GitHub Pages.

2. **Custom SCSS over Quarto themes**: Standard Quarto Bootstrap themes
   (cosmo, flatly, etc.) don't match al-folio's sidebar-centric layout.
   Custom SCSS is needed to reproduce the sidebar and card styling, but
   builds on Quarto's Bootstrap foundation rather than replacing it
   entirely.

3. **BibTeX for publications**: Standard academic practice. Seeded once
   from Google Scholar (via scraping), then maintained manually. This
   avoids fragile repeated scraping and gives full control over metadata.

4. **Sidebar over top navbar**: Matches al-folio's distinctive layout and
   keeps the user's identity always visible.

5. **No JavaScript framework**: al-folio uses minimal JS. The Quarto
   reproduction will likewise rely on CSS for interactivity (responsive
   sidebar, hover states), avoiding JS frameworks.

6. **GitHub Pages deployment**: Quarto's `gh-pages` workflow is mature and
   well-documented. Custom domain (`arekkas.gr`) requires only a CNAME
   record and can be enabled later without code changes.

7. **CV as Quarto markdown, not raw HTML**: The CV page was originally
   written as raw indented HTML, which Pandoc interpreted as code blocks.
   Rewritten as Quarto markdown using `styles.scss` element-based selectors
   (heading styles, emphasis for institution names, blockquotes for
   thesis/supervisor details). This avoids the indentation code-block trap
   while preserving the al-folio visual identity.

8. **Crossref API for abstracts**: Publication abstracts are fetched from
   the Crossref API (DOI lookup) with Europe PMC as fallback for
   biomedical papers. Abstracts are stored in `publications.bib` and
   displayed via an al-folio-style "Abs" toggle badge using Bootstrap's
   collapse component. This avoids embedding JavaScript or scraping
   publisher pages, keeping the site static and maintainable.
