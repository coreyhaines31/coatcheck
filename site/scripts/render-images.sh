#!/bin/bash
# Renders the social card and copies the app icon in as the touch icon.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1200,630 --screenshot="$PWD/src/assets/og.png" "file://$PWD/scripts/og.html"
# The app icon, rendered by the app's bundle script.
sips -z 180 180 ../dist/CoatCheck.iconset/icon_256x256@2x.png --out src/assets/apple-touch-icon.png >/dev/null
