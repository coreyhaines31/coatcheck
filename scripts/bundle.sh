#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
# Set CODESIGN_IDENTITY to a real identity so permission grants survive rebuilds; ad-hoc otherwise.
swift build -c release
BIN_DIR=$(swift build -c release --show-bin-path)
APP=dist/CoatCheck.app
[ -d "$APP" ] && rm -r "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN_DIR/CoatCheck" "$APP/Contents/MacOS/CoatCheck"
# The command-line tool. Not named "coatcheck": it would collide with "CoatCheck" on case-insensitive disks.
cp "$BIN_DIR/CoatCheckCLI" "$APP/Contents/MacOS/coatcheck-cli"
ditto "$BIN_DIR/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
# PanelKit's fonts. Bundle.module looks for this in Contents/Resources and stops the app if it is missing.
ditto "$BIN_DIR/PanelKit_PanelKit.bundle" "$APP/Contents/Resources/PanelKit_PanelKit.bundle"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/CoatCheck"
cp Resources/Info.plist "$APP/Contents/Info.plist"
# The Brushed icon, exported from mac-app-kit icons/coat/coat.icns.
cp Resources/CoatCheck.icns "$APP/Contents/Resources/CoatCheck.icns"
codesign --force --sign "${CODESIGN_IDENTITY:--}" "$APP/Contents/MacOS/coatcheck-cli"
codesign --force --sign "${CODESIGN_IDENTITY:--}" "$APP"
printf 'Built %s/%s\n' "$PWD" "$APP"
