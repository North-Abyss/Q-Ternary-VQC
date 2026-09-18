#!/bin/bash

# Exit if any command fails
set -e

# Use the first argument as the commit message, or default to a generic message
COMMIT_MSG=${1:-"Auto-sync update"}

echo "🔄 Syncing repository to GitHub..."

# Add all changes
git add .

# Commit with the provided message
git commit -m "$COMMIT_MSG"

# Push to the main branch
git push origin main

echo "✅ Git sync complete!"
