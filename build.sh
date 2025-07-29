#!/bin/bash

# Exit on any error
set -e

echo "🚀 Starting Flutter Web Build..."

# Install Flutter
echo "📦 Installing Flutter..."
wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

# Verify Flutter installation
echo "✅ Verifying Flutter..."
flutter --version

# Install dependencies
echo "📚 Installing dependencies..."
flutter pub get

# Build web app
echo "🔨 Building web app..."
flutter build web --base-href="/" --release --dart-define=FLUTTER_WEB_USE_SKIA=true

echo "�� Build complete!" 