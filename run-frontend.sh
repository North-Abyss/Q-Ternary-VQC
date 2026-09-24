#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "📱 Preparing the Flutter Web Frontend..."
cd quanta

if ! command -v flutter &> /dev/null; then
    echo "⚠️ Flutter is not installed or not in PATH. Please install Flutter to run the frontend."
    exit 1
fi

# Check for --rebuild argument
if [ "$1" == "--rebuild" ]; then
    echo "🧹 Clean up requested. Forcing rebuild..."
    rm -rf build/web
    flutter clean
fi

# Check if web build exists
if [ ! -d "build/web" ]; then
    echo "⚙️ Compiling Flutter Web App... (This may take a minute)"
    flutter build web
else
    echo "⚡ Found existing Flutter Web build. Skipping compilation."
    echo "   (Run with --rebuild to force compilation)"
fi

echo "🌐 Starting Frontend Web Server on http://127.0.0.1:8080"
echo "👉 Open http://127.0.0.1:8080 in your browser to use Q-Ternary VQC"
echo "Press Ctrl+C to stop the server."

# Run a simple HTTP server to serve the Flutter web build
python3 -m http.server 8080 -d build/web
