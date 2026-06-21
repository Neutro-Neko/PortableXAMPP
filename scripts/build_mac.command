#!/bin/bash

# Move to the project root directory
cd "$(dirname "$0")/.."

echo "Compiling AppleScript..."
osacompile -o "Portable XAMPP.app/Contents/Resources/Scripts/main.scpt" src/main.applescript

echo "Clearing Finder detritus..."
find "Portable XAMPP.app" -type f -name '.DS_Store' -delete
find "Portable XAMPP.app" -type f -name '._*' -delete
xattr -cr "Portable XAMPP.app"

echo "Re-signing app bundle..."
codesign --force --deep --sign - "Portable XAMPP.app"

echo "Build complete! You can close this window."
