# Aurora — Dark Portfolio Template

A fast, modern, fully responsive one-page portfolio. No build step, no
dependencies — just HTML + CSS (Google Fonts via CDN). Drop it anywhere
(Netlify, Vercel, GitHub Pages, any static host).

## What's included
- `index.html` — the template (violet theme, fully commented)
- `index-violet.html` / `index-emerald.html` / `index-amber.html` — three ready color themes
- This README

## Customize in 3 steps
1. **Pick a theme** — use one of the three `index-*.html` files, or edit the four
   `--brand-*` variables in the `:root` block of any file to make your own.
2. **Replace the content** — search for `{{ }}` placeholders and fill in your name,
   title, projects, about text, stats, and email. Duplicate a `.card` for each project.
3. **Deploy** — upload the file(s) to any static host. Rename your chosen theme to
   `index.html`.

## Sections
Sticky nav · gradient hero · responsive work grid · about + stats · contact · auto-year footer.

## Make your own theme
In `:root`:
```css
--brand-1: #9b7dff;   /* primary accent */
--brand-2: #ff6b6b;   /* secondary (gradient end) */
--brand-glow: rgba(155,125,255,.4);  /* hero glow — match brand-1 */
--bg: #0a0a0f;        /* page background */
```
Everything (buttons, links, hover glows, gradient text) re-skins from those.

## License
Single-site/personal & client use. Don't resell or redistribute the template files.

— Built by Zoheb Alvi · zohebalvi.com
