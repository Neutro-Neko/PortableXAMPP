#!/bin/bash

# Ensure we always execute from the repository root
cd "$(dirname "$0")/.." || exit 1

echo "Assembling PortableXAMPP Releases..."

mkdir -p releases
rm -rf build_temp
mkdir -p build_temp/macOS

# 1. Assemble macOS Version (Only on macOS runners)
if [ "$(uname -s)" = "Darwin" ]; then
    echo "Packaging macOS..."
    cp -R PortableXAMPP.app build_temp/macOS/
    cp -R UI_Template build_temp/macOS/PortableXAMPP.app/Contents/Resources/
    cd build_temp/macOS
    ditto -c -k --sequesterRsrc --keepParent PortableXAMPP.app ../../releases/PortableXAMPP-macOS.zip
    cd ../../
else
    echo "Skipping macOS packaging (Not running on Darwin)."
fi

# 2. Assemble Linux AppImage (Only on Linux runners)
if [ "$(uname -s)" = "Linux" ]; then
    echo "Packaging Linux AppImage..."
    bash scripts/build_appimage.sh
    
    echo "Zipping AppImage..."
    cd releases
    zip PortableXAMPP-Linux.AppImage.zip PortableXAMPP-Linux-x86_64.AppImage
    rm -f PortableXAMPP-Linux-x86_64.AppImage # Cleanup the raw AppImage
    cd ..
else
    echo "Skipping Linux AppImage build (Not running on Linux)."
fi

# 3. Cleanup
rm -rf build_temp
echo "Done!"
