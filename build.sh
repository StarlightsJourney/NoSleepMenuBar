#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# Replace this with your own reverse-DNS bundle ID if you distribute the app.
# Keeping it generic avoids leaking personal information in public repositories.
BUNDLE_ID="${BUNDLE_ID:-com.example.NoSleep}"

swift build -c release

# Generate the app icon from the coffee-cup SF Symbol.
swift scripts/generate-icon.swift

APP_NAME=".build/NoSleep.app"
BUILD_DIR=".build/release"
HELPER_NAME="NoSleepHelper"
HELPER_DIR="$APP_NAME/Contents/Helpers"

rm -rf "./$APP_NAME"
mkdir -p "./$APP_NAME/Contents/MacOS"
mkdir -p "./$APP_NAME/Contents/Resources"
mkdir -p "./$HELPER_DIR"

cp "$BUILD_DIR/NoSleep" "./$APP_NAME/Contents/MacOS/NoSleep"
cp "$BUILD_DIR/$HELPER_NAME" "./$HELPER_DIR/$HELPER_NAME"
chmod +x "./$HELPER_DIR/$HELPER_NAME"
cp "AppIcon.icns" "./$APP_NAME/Contents/Resources/AppIcon.icns"

cat > "./$APP_NAME/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>NoSleep</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>NoSleep</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc sign the app bundle (including the bundled helper) so macOS treats
# it as a valid local application.
codesign --force --deep --sign - "./$APP_NAME"

echo "Built $APP_NAME"
