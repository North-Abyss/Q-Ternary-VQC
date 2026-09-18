#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "🚀 Initializing Project Qutrit..."

# 1. Check if the virtual environment exists, if not, create it
if [ ! -d ".venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv .venv
fi

# 2. Activate the virtual environment
echo "🔄 Activating virtual environment..."
source .venv/bin/activate
# To deactivate: deactivate

# 3. Install dependencies
echo "📥 Installing dependencies (this may take a moment)..."
pip install --upgrade pip
pip install -r requirements.txt

# 4. Run the hybrid quantum machine learning engine
echo "⚡ Running Hybrid QML Engine..."
echo "==============================================="
python3 src/core_engine.py
