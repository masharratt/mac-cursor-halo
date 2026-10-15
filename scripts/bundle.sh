#!/bin/bash
# Builds a release binary and wraps it in build/CursorHalo.app (ad-hoc signed).
set -euo pipefail

cd "$(dirname "$0")/.."
APP="build/CursorHalo.app"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/CursorHalo"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/CursorHalo"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>CursorHalo</string>
    <key>CFBundleIdentifier</key><string>local.cursorhalo</string>
    <key>CFBundleName</key><string>CursorHalo</string>
    <key>CFBundleDisplayName</key><string>Cursor Halo</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"

# --install: replace /Applications/CursorHalo.app and relaunch it.
if [[ "${1:-}" == "--install" ]]; then
    pkill -x CursorHalo || true
    rm -rf /Applications/CursorHalo.app
    cp -R "$APP" /Applications/
    open /Applications/CursorHalo.app
    echo "Installed /Applications/CursorHalo.app"
fi
