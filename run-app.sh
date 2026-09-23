#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting Q-Ternary VQC Platform..."

# 1. Start the Flask Backend
# Check if the virtual environment exists
if [ ! -d ".venv" ]; then
    echo "📦 Virtual environment not found. Please run ./run.sh first to install dependencies."
    exit 1
fi

echo "🔄 Activating virtual environment..."
source .venv/bin/activate

echo "🌐 Starting the Flask API server in the background..."
export FLASK_ENV=development
export PYTHONUNBUFFERED=1

# Run Flask in the background and save its PID
python3 src/api/app.py &
FLASK_PID=$!

echo "✅ Backend running on http://127.0.0.1:5000"

# 2. Start the Flutter Web App
echo "📱 Preparing the Flutter Web Frontend..."
cd quanta

if ! command -v flutter &> /dev/null; then
    echo "⚠️ Flutter is not installed or not in PATH. Please install Flutter to run the frontend."
    echo "The API backend is still running (PID: $FLASK_PID). Press Ctrl+C to stop it."
    wait $FLASK_PID
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
echo "Press Ctrl+C to stop both servers."

# Run a simple HTTP server to serve the Flutter web build
python3 -m http.server 8080 -d build/web

# Cleanup: Kill Flask when the HTTP server stops (if the user stops it via Ctrl+C)
echo "🛑 Stopping Flask API server..."
kill $FLASK_PID || true
