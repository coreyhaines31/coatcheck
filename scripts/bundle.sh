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
# The command-line tool. Not named "coatcheck": it would collide with "CoatCheck" on case-insensitive disks.
cp "$BIN_DIR/CoatCheckCLI" "$APP/Contents/MacOS/coatcheck-cli"
ditto "$BIN_DIR/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath @executable_path/../Frameworks "$APP/Contents/MacOS/CoatCheck"
cp Resources/Info.plist "$APP/Contents/Info.plist"
mkdir -p dist/CoatCheck.iconset
swiftc -O scripts/icon/main.swift -o .build/coatcheck-icon
.build/coatcheck-icon dist/CoatCheck.iconset
iconutil -c icns dist/CoatCheck.iconset -o "$APP/Contents/Resources/CoatCheck.icns"
codesign --force --sign - "$APP/Contents/MacOS/coatcheck-cli"
codesign --force --sign - "$APP"
printf 'Built %s/%s\n' "$PWD" "$APP"
