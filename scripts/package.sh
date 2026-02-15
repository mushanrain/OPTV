#!/usr/bin/env bash
set -euo pipefail

# Build OptV.app in Release to dist/, and optionally create a DMG

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="$ROOT_DIR/OptV.xcodeproj"
SCHEME="OptV"
BUILD_DIR="$ROOT_DIR/build"
DIST_DIR="$ROOT_DIR/dist"

echo "🚀 Building $SCHEME (Release)"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

set -x
xcodebuild \
  -project "$PROJ" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  build
set +x

APP_PATH="$BUILD_DIR/Build/Products/Release/OptV.app"
if [ ! -d "$APP_PATH" ]; then
  echo "❌ Build did not produce OptV.app at $APP_PATH"
  exit 1
fi

cp -R "$APP_PATH" "$DIST_DIR/OptV.app"
echo "✅ App copied to $DIST_DIR/OptV.app"

# Use Asset Catalog icons (generated during build phase); no manual .icns embedding
echo "🎨 Using Asset Catalog icons"

# Create a simple DMG (unsigned) for quick install/share
DMG="$DIST_DIR/OptV.dmg"
echo "📦 Creating DMG: $DMG"
hdiutil create -volname "OptV" -srcfolder "$DIST_DIR/OptV.app" -ov -format UDZO "$DMG"
echo "✅ DMG created: $DMG"

echo "Done. You can drag OptV.app to /Applications, or open the DMG."
