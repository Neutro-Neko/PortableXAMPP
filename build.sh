#!/bin/bash
echo "Assembling PortableXAMPP Releases..."

# 1. Clean old builds
rm -f PortableXAMPP-macOS.zip
rm -f PortableXAMPP-Linux.zip
rm -rf build_temp
mkdir -p build_temp/macOS
mkdir -p build_temp/Linux

# 2. Assemble macOS Version
echo "Packaging macOS..."
cp -R PortableXAMPP.app build_temp/macOS/
cp -R UI_Template build_temp/macOS/PortableXAMPP.app/Contents/Resources/
cd build_temp/macOS
ditto -c -k --sequesterRsrc --keepParent PortableXAMPP.app ../../PortableXAMPP-macOS.zip
cd ../../

# 3. Assemble Linux Version
echo "Packaging Linux..."
cp Linux/PortableXAMPP.sh build_temp/Linux/
cp Linux/PortableXAMPP.desktop build_temp/Linux/
cp -R UI_Template build_temp/Linux/
cd build_temp/Linux
zip -r ../../PortableXAMPP-Linux.zip ./*
cd ../../

# 4. Cleanup
rm -rf build_temp
echo "Done! Ready to upload to GitHub Releases."
