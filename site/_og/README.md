# Link preview video

Remotion source for `src/assets/og.mp4` (the homepage `og:video` that iMessage and Discord autoplay) and `src/assets/og-video.png` (the homepage `og:image` still, frame 225 of the 6-second, 60 fps loop). The build copies both to the site root. Needs Node and ffmpeg.

```sh
cd site/_og && npm install && npm run render
```

`npm run studio` opens a live preview. `OgVideo.tsx` is the shared Mac app site shell (color field, glass card, brand, headline) in its wide arrangement, and takes its text and colors as props in `Root.tsx`; `MenuBarScene.tsx` is the Coat Check animation below the headline. The loop ends on its first frame, so keep the first and last frames identical when changing the timing.

This folder is in `.vercelignore`, so none of it is deployed.
