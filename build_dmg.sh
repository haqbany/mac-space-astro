#!/bin/bash

# Configuration
APP_NAME="MacSpaceAstro"
BUNDLE_NAME="${APP_NAME}.app"
BUILD_DIR=".build/release"
STAGING_DIR="staging"
DMG_NAME="${APP_NAME}_Quantum_Edition.dmg"

echo "🚀 Building ${APP_NAME} for Universal (Intel + Apple Silicon)..."
swift build -c release --arch arm64 --arch x86_64 --disable-sandbox

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "📦 Creating App Bundle..."
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}/${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${STAGING_DIR}/${BUNDLE_NAME}/Contents/Resources"

# Copy binary (Universal path)
cp .build/apple/Products/Release/${APP_NAME} "${STAGING_DIR}/${BUNDLE_NAME}/Contents/MacOS/"

# Copy Info.plist
cp Info.plist "${STAGING_DIR}/${BUNDLE_NAME}/Contents/"

# Copy Icon
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${STAGING_DIR}/${BUNDLE_NAME}/Contents/Resources/"
fi

# Create Applications symlink for DMG
ln -s /Applications "${STAGING_DIR}/Applications"

echo "💿 Creating DMG..."
rm -f "${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING_DIR}" -ov -format UDZO "${DMG_NAME}"

echo "✅ Success! ${DMG_NAME} created."
