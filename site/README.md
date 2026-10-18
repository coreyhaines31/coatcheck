# Coat Check website

The static site for https://coatcheckformac.com, generated from shared layouts. The app lives one folder up.

## Editing

- `src/layouts/base.html`: document head, metadata, the hanger symbol, and the Fathom embed (site ID `OFCLTICU`).
- `src/layouts/header.html`, `footer.html`, `get-coatcheck.html`: shared header, footer, and download section.
- `src/pages/`: page content inside the main element. `src/pages.json`: titles, descriptions, and `updated` dates for the sitemap.
- `src/assets/`: styles, icons, the social card, and robots.txt.

Run `make build` to generate `dist/`, or `make lint` to build and check structure, links, assets, and the Fathom embed. `make images` re-renders the social card from `scripts/og.html` and copies the app icon in as the touch icon (run `make app` in the app folder first). The build uses Python's standard library only.

The look is Coat Check's own: New York serif headlines, warm ivory and espresso, and ticket red reserved for the download ticket and the hanger. Product visuals are HTML and CSS illustrations.

## Hosting

Vercel (team `coreys-apps`) runs `make lint` and serves `dist/`. Deploy production from `main` only:

```sh
make lint
vercel deploy --prod --scope coreys-apps --yes
```
