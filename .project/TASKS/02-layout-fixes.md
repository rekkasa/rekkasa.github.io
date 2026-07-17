# Bug Fix: Layout and Rendering Issues

## Problem

The website rendered with a broken sidebar layout (appears in the middle, overlaps
content) and the CV page displays as raw/unstyled HTML. Additionally, the `ragg`
package is missing from `renv.lock`.

## Root Causes

1. **Layout**: `include-before-body` injects sidebar HTML as a direct child of
   `<body>`, and `body { display: flex; }` makes it fight Quarto's Bootstrap
   layout. The sidebar and Quarto's `.quarto-container` become competing flex
   siblings, causing overlap and pushing content below.

2. **CV styling**: The CV page uses raw HTML with CSS classes defined in
   `styles.scss`. When the layout is broken, styled sections collapse.

3. **renv**: `ragg` was installed manually but not tracked in `renv.lock`.

## Fix Strategy

### 1. `styles.scss` — Switch from flexbox to fixed positioning

- Remove `body { display: flex; ... }`
- Change `#custom-sidebar` to `position: fixed; left: 0; top: 0; z-index: 1030;`
- Change `#quarto-content` to `margin-left: 280px;` (instead of `flex: 1`)
- Keep responsive breakpoint that stacks sidebar on top at 768px

### 2. `_quarto.yml` — Ensure sidebar is not duplicated

- The current config has both `include-before-body: _includes/sidebar.html`
  AND a Quarto `sidebar:` section with menu links. This creates duplicate
  navigation. Keep only `include-before-body` — remove the `sidebar:` block
  (or vice versa).

### 3. `renv` — Add ragg

- Run `renv::install("ragg")` then `renv::snapshot()`

### 4. Verify after fix

- Run `quarto render` and visually check all pages render correctly
- Sidebar fixed on left, content area to the right with proper margin

## Execution Checklist

### Phase 1 — Implementation: [IMPL]

1. [x] [IMPL] `styles.scss`: Switch sidebar from flexbox to `position: fixed`
   - Remove `body { display: flex; ... }` block
   - `#custom-sidebar`: `position: fixed; left: 0; top: 0; width: 280px;`
   - `#quarto-content`: `margin-left: 280px;`
   - Keep `z-index`, responsive, and all sub-selectors
   - Keep all pub-card, project-card, cv-section, teaching-entry styles

2. [x] [IMPL] `_quarto.yml`: Remove the `sidebar:` block (keep only
   `include-before-body`) or remove `include-before-body` and keep only the
   Quarto native `sidebar:` block. Pick ONE approach — not both. The
   `include-before-body` + custom CSS is the al-folio approach, so remove
   the Quarto `sidebar:` block.

3. [x] [IMPL] `renv`: Install `ragg` and snapshot with
   `renv::install("ragg")` followed by `renv::snapshot()`

4. [x] [IMPL] Run `quarto render` and verify:
   - Sidebar is fixed on the left edge
   - Content flows in the right area with proper spacing
   - CV page sections render with proper styling
   - All 5 pages build without errors
