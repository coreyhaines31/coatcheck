#!/bin/bash
# Renders the social card and copies the app icon in as the touch icon.
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
  --window-size=1200,630 --virtual-time-budget=5000 --screenshot="$PWD/src/assets/og.png" "file://$PWD/scripts/og.html"
# The Brushed app icon from mac-app-kit, flattened onto the page colour for iOS.
ICON="${ICON_SRC:-$HOME/code/mac-app-kit/icons/coat/png/coat-1024.png}"
magick "$ICON" -resize 180x180 -background '#e2e3e2' -flatten src/assets/apple-touch-icon.png
