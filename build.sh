#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Flutter Web Build..."

# Install Flutter
echo "📦 Installing Flutter..."
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.0-stable.tar.xz
tar xf flutter_linux_3.32.0-stable.tar.xz
rm flutter_linux_3.32.0-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
echo "✅ Verifying Flutter..."
flutter --version
flutter doctor --verbose

# Configure for headless web builds (ENHANCED for Flutter 3.32.0)
echo "🌐 Configuring for headless web build environment..."
export CHROME_EXECUTABLE="/dev/null"
export FLUTTER_WEB_AUTO_DETECT=false
export FLUTTER_WEB_USE_SKIA=true
export FLUTTER_WEB_USE_CANVASKIT=true
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export CI=true

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web
flutter config --no-analytics

# Install dependencies
echo "📚 Installing dependencies..."
flutter pub get

# Verify dependencies
echo "🔍 Checking project structure..."
ls -la

# Build web app with explicit HTML renderer (most compatible for CI)
echo "🔨 Building web app..."
echo "📝 Checking web targets available..."
flutter devices

echo "📝 Attempting web build with HTML renderer (CI-friendly)..."
flutter build web --web-renderer html --release --verbose 2>&1 || {
    echo "❌ HTML renderer failed! Trying with canvaskit renderer..."
    flutter build web --web-renderer canvaskit --release --verbose --dart-define=FLUTTER_WEB_USE_SKIA=true 2>&1 || {
        echo "❌ CanvasKit failed! Trying with auto renderer..."
        flutter build web --web-renderer auto --release --verbose 2>&1 || {
            echo "❌ Auto renderer failed! Trying basic build..."
            flutter build web --release --verbose 2>&1 || {
                echo "❌ All build attempts failed!"
                echo "🔍 Flutter configuration:"
                flutter config
                echo "🔍 Environment:"
                env | grep FLUTTER
                exit 1
            }
        }
    }
}

# Verify build output
echo "🔍 Verifying build output..."
if [ -d "build/web" ]; then
    echo "✅ build/web directory exists"
    ls -la build/web/
    if [ -f "build/web/index.html" ]; then
        echo "✅ index.html found!"
        echo "📄 index.html content preview:"
        head -10 build/web/index.html
    else
        echo "❌ index.html not found in build/web/"
        exit 1
    fi
else
    echo "❌ build/web directory not found!"
    exit 1
fi

echo "�� Build complete!" 