#!/bin/bash

# Install Flutter
echo "Installing Flutter..."
curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.5-stable.tar.xz
tar -xf flutter.tar.xz
export PATH="$PATH:$(pwd)/flutter/bin"

# Verify Flutter installation
flutter --version

# Get Flutter dependencies
flutter pub get

# Build Flutter web app
echo "Building Flutter web app..."
flutter build web

echo "Build completed!"
