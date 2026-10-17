#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
swift build -c release
BIN_DIR=$(swift build -c release --show-bin-path)
APP=dist/CoatCheck.app
[ -d "$APP" ] && rm -r "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp "$BIN_DIR/CoatCheck" "$APP/Contents/MacOS/CoatCheck"
ditto "$BIN_DIR/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/CoatCheck"
cp Resources/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
printf 'Built %s/%s\n' "$PWD" "$APP"
