# Architecture

## System Overview

A Quarto static website that reproduces the al-folio Jekyll theme's visual
design. The site uses a **left sidebar layout** with profile information
and social links, with page content in the main area. The site is
structured as a Quarto website project, configured via `_quarto.yml`.
All content pages are standalone `.qmd` files. The site deploys to GitHub
Pages via GitHub Actions.

```
_quarto.yml          ← Site config, Bootstrap theme, sidebar, custom SCSS
styles.scss           ← al-folio visual overrides
about.qmd             ← Homepage (About)
publications.bib      ← BibTeX bibliography (seeded from Google Scholar)
publications.qmd      ← Publication cards rendered from BibTeX
projects.qmd          ← Research project listings
cv.qmd                ← English CV (HTML page)
teaching.qmd          ← Teaching portfolio
R/fetch_publications.R ← One-time Google Scholar scraper
```

## Modules

| # | Module | Type | Description |
|---|--------|------|-------------|
| 1 | Quarto Website Scaffold | Build | `_quarto.yml` + `styles.scss` — sidebar layout, al-folio theming |
| 2 | About Page | Build | `about.qmd` — biographical text + research interests |
| 3 | Publications Page | Build | `publications.qmd` + `publications.bib` — BibTeX-driven pub list |
| 4 | Projects Page | Build | `projects.qmd` — four research projects |
| 5 | CV Page | Build | `cv.qmd` — English CV with PDF download |
| 6 | Teaching Page | Build | `teaching.qmd` — full teaching portfolio |

All page modules depend on Module 1 (scaffold) for layout and styling.
Modules 2–6 are independent of each other.

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
