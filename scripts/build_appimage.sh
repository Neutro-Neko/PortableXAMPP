#!/bin/bash
# Builds the PortableXAMPP wrapper AppImage

set -e

# Ensure we execute from the repository root
cd "$(dirname "$0")/.." || exit 1

BUILD_DIR="build_temp/AppDir"

echo "Cleaning old AppImage build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p releases

echo "Copying assets..."
cp "Linux/PortableXAMPP.sh" "$BUILD_DIR/AppRun"
chmod +x "$BUILD_DIR/AppRun"

# Copy UI Template
cp -r "UI_Template" "$BUILD_DIR/usr/bin/UI_Template"

# We need a desktop file and icon at the root of AppDir
cp "Linux/PortableXAMPP.desktop" "$BUILD_DIR/"
cp "Linux/icon.svg" "$BUILD_DIR/"

echo "Downloading appimagetool..."
if [ ! -f "scripts/appimagetool-x86_64.AppImage" ]; then
    curl -L -o scripts/appimagetool-x86_64.AppImage "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x scripts/appimagetool-x86_64.AppImage
fi

echo "Building AppImage..."
export APPIMAGE_EXTRACT_AND_RUN=1
ARCH=x86_64 ./scripts/appimagetool-x86_64.AppImage "$BUILD_DIR" releases/PortableXAMPP-Linux-x86_64.AppImage

echo "Done! Generated releases/PortableXAMPP-Linux-x86_64.AppImage"
rm -rf "$BUILD_DIR"
