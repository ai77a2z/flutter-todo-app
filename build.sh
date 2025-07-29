#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Flutter Web Build..."

# Use Flutter 3.24.5 which doesn't require Chrome for web builds
echo "📦 Installing Flutter 3.24.5 (Chrome-independent)..."
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
rm flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
echo "✅ Verifying Flutter..."
flutter --version
flutter doctor --verbose

# Configure for headless web builds 
echo "🌐 Configuring for headless web build environment..."
export CHROME_EXECUTABLE="/dev/null"
export FLUTTER_WEB_AUTO_DETECT=false
export CI=true

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web
flutter config --no-analytics

# Install dependencies
echo "📚 Installing dependencies..."
flutter pub get

# Verify project structure
echo "🔍 Checking project structure..."
ls -la

# Build web app (Flutter 3.24.5 supports headless builds)
echo "🔨 Building web app (headless mode)..."
flutter build web --release --verbose

# Verify build output
echo "🔍 Verifying build output..."
if [ -d "build/web" ]; then
    echo "✅ build/web directory exists"
    ls -la build/web/
    if [ -f "build/web/index.html" ]; then
        echo "✅ index.html found!"
        echo "🎉 Build complete!"
    else
        echo "❌ index.html not found in build/web/"
        exit 1
    fi
else
    echo "❌ build/web directory not found!"
    exit 1
fi 