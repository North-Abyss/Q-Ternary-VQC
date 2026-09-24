#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Starting Q-Ternary VQC Backend..."

# Check if the virtual environment exists
if [ ! -d ".venv" ]; then
    echo "📦 Virtual environment not found. Please run ./run.sh first to install dependencies."
    exit 1
fi

echo "🔄 Activating virtual environment..."
source .venv/bin/activate

echo "🌐 Starting the Flask API server..."
export FLASK_ENV=development
export PYTHONUNBUFFERED=1

echo "✅ Backend will run on http://127.0.0.1:5000"
echo "Press Ctrl+C to stop the server."

# Run Flask in the foreground
python3 src/api/app.py
