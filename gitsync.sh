#!/bin/bash

# Exit if any command fails
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Project Qutrit git sync...${NC}"

# Stage all changes
echo -e "${BLUE}Staging changes...${NC}"
git add .

# Prompt for commit message, or default to a generic message
echo -e "${BLUE}Committing changes...${NC}"
read -p "Enter commit message [Auto-sync: Update files]: " input_message
commit_message="${input_message:-Auto-sync: Update files}"

# Commit changes (don't fail if there are no changes to commit)
git commit -m "$commit_message" || echo -e "${BLUE}No changes to commit${NC}"

# Fetch latest changes from remote
echo -e "${BLUE}Fetching from remote...${NC}"
git fetch origin

# Pull latest changes to current branch
echo -e "${BLUE}Pulling changes...${NC}"
git pull origin "$(git rev-parse --abbrev-ref HEAD)"

# Push local commits to remote
echo -e "${BLUE}Pushing changes...${NC}"
git push origin "$(git rev-parse --abbrev-ref HEAD)"

echo -e "${GREEN}Git sync completed successfully!${NC}"
