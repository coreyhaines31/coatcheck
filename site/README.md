# Coat Check website

The static site for https://coatcheckformac.com, generated from shared layouts. The app lives one folder up.

## Editing

- `src/layouts/base.html`: document head, metadata, fonts, and the TracerKit loader (key `tk_4ywfCRdH98-aEeEu`), which serves the Headstream analytics tag.
- `src/layouts/header.html`, `footer.html`, `get-coatcheck.html`: shared header, footer, and download section.
- `src/pages/`: page content inside the main element. `src/pages.json`: titles, descriptions, and `updated` dates for the sitemap.
- `src/assets/`: styles, icons, the social card, and robots.txt.
- `_og/`: Remotion source for the homepage link preview (`og.mp4` and its still `og-video.png` in `src/assets/`). See `_og/README.md`. Not deployed.

Run `make build` to generate `dist/`, or `make lint` to build and check structure, links, assets, and the TracerKit loader. `make images` re-renders the social card from `scripts/og.html` and copies the app icon in as the touch icon (run `make app` in the app folder first). The build uses Python's standard library only.

The look is the Mac app family's Brushed design: `src/assets/brushed.css` and `popover.css` are copied from `mac-app-kit/site-kit` (edit them there, then copy them in), and `styles.css` maps this site's sections onto them. Coat Check's raspberry `#c4366f` appears only as pilot lights. The homepage hero mounts the static Brushed popover from `site-kit/popovers/coat.html`.

## Hosting

Vercel (team `coreys-apps`) runs `make lint` and serves `dist/`. Deploy production from `main` only:

```sh
make lint
vercel deploy --prod --scope coreys-apps --yes
```
