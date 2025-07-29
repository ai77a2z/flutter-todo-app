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

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web

# Install dependencies
echo "📚 Installing dependencies..."
flutter pub get

# Verify dependencies
echo "🔍 Checking project structure..."
ls -la

# Build web app
echo "🔨 Building web app..."
echo "📝 Running: flutter build web --base-href=/ --release --web-renderer=canvaskit"
flutter build web --base-href="/" --release --web-renderer=canvaskit --verbose || {
    echo "❌ Flutter build failed! Trying with different settings..."
    echo "📝 Attempting: flutter build web --base-href=/ --release"
    flutter build web --base-href="/" --release --verbose || {
        echo "❌ Both build attempts failed!"
        echo "🔍 Checking if web is enabled..."
        flutter config --enable-web
        flutter build web --base-href="/" --release --verbose
    }
}

# Verify build output
echo "🔍 Verifying build output..."
if [ -d "build/web" ]; then
    echo "✅ build/web directory exists"
    ls -la build/web/
    if [ -f "build/web/index.html" ]; then
        echo "✅ index.html found!"
    else
        echo "❌ index.html not found in build/web/"
        exit 1
    fi
else
    echo "❌ build/web directory not found!"
    exit 1
fi

echo "🎉 Build complete!" 