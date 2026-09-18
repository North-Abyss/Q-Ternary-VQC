#!/bin/bash

# Git Commit & Sync Script - /gitsync.sh
# Syncs local repository with remote and optionally triggers Cloud CI/CD
# Usage: ./gitsync.sh [commit_message] [release_tag] [deploy_web_y_n]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Project Qutrit git sync...${NC}"

# Stage all changes
echo -e "${BLUE}Staging changes...${NC}"
git add .

# Commit changes
echo -e "${BLUE}Committing changes...${NC}"
commit_message="$1"
if [[ -z "$commit_message" ]]; then
    read -p "Enter commit message (leave blank for auto-timestamp): " commit_message
fi

if [[ -z "$commit_message" ]]; then
    commit_message="$(date '+%d-%b-%Y-T-%H:%M')"
    echo -e "${YELLOW}Using auto commit message: $commit_message${NC}"
fi

git commit -m "$commit_message" || echo "No changes to commit"

# Fetch latest changes from remote (this also fetches the latest tags)
echo -e "${BLUE}Fetching from remote...${NC}"
git fetch origin "$(git rev-parse --abbrev-ref HEAD)" --tags

# Pull latest changes to current branch
echo -e "${BLUE}Pulling changes...${NC}"
git pull origin "$(git rev-parse --abbrev-ref HEAD)"

# Push local commits to remote
echo -e "${BLUE}Pushing changes...${NC}"
git push origin "$(git rev-parse --abbrev-ref HEAD)"

echo -e "${GREEN}Git sync completed successfully!${NC}"
echo ""

# # ==========================================
# # 🚀 CLOUD PIPELINE TRIGGER
# # ==========================================
# echo -e "${YELLOW}--- Release Manager ---${NC}"
# version_tag="$2"

# if [[ -n "$version_tag" ]]; then
#     trigger_release="y"
# else
#     read -p "Do you want to trigger a Cloud Release for these changes? (y/n): " trigger_release
# fi

# if [[ "$trigger_release" == "y" || "$trigger_release" == "Y" ]]; then
#     if [[ -z "$version_tag" ]]; then
#         read -p "Enter version tag (e.g., v1.0.0 or v0.0.0 for testing): " version_tag
#     fi
    
#     echo -e "${BLUE}Preparing tag $version_tag...${NC}"
    
#     # Check if the tag already exists
#     if git rev-parse -q --verify "refs/tags/$version_tag" >/dev/null; then
#         echo -e "${RED}Warning: Tag '$version_tag' already exists!${NC}"
#         read -p "Can I remove it and replace it with the current code? (y/n): " replace_tag
        
#         if [[ "$replace_tag" == "y" || "$replace_tag" == "Y" ]]; then
#             echo -e "${YELLOW}Deleting old tag '$version_tag'...${NC}"
            
#             # Clean up duplicate GitHub releases/drafts but keep the latest one as backup
#             if command -v gh &> /dev/null; then
#                 release_ids=$(gh api repos/:owner/:repo/releases --jq '.[] | select(.tag_name == "'"$version_tag"'") | .id' 2>/dev/null | sort -nr || true)
#                 if [[ -n "$release_ids" ]]; then
#                     mapfile -t ids_array <<< "$release_ids"
#                     if [ ${#ids_array[@]} -ge 2 ]; then
#                         echo -e "${YELLOW}Keeping latest release backup and deleting older duplicates...${NC}"
#                         for (( i=1; i<${#ids_array[@]}; i++ )); do
#                             gh api -X DELETE repos/:owner/:repo/releases/${ids_array[$i]} 2>/dev/null || true
#                         done
#                     fi
#                 fi
#             fi
            
#             git tag -d "$version_tag" 2>/dev/null || true
#             git push origin --delete "$version_tag" 2>/dev/null || true
#         else
#             echo -e "${BLUE}Release aborted to protect the existing tag. Have a great day!${NC}"
#             exit 0
#         fi
#     fi
    
#     # Create the brand new tag on the current code
#     echo -e "${BLUE}Tagging current code as $version_tag...${NC}"
#     git tag "$version_tag"
    
#     # Push the new tag to GitHub to wake up the CI/CD servers
#     git push origin "$version_tag"
    
#     echo -e "${GREEN}Boom! Release tag pushed.${NC}"
#     echo -e "${GREEN}The GitHub Cloud Servers are now compiling your apps!${NC}"
# else
#     echo -e "${BLUE}Skipping release.${NC}"
# fi

# # ==========================================
# # 🌐 GITHUB PAGES WEB DEPLOY
# # ==========================================
# echo -e "${YELLOW}--- Web Deploy (GitHub Pages) ---${NC}"
# deploy_web="$3"

# if [[ -z "$deploy_web" ]]; then
#     read -p "Do you want to trigger a Cloud Deploy for the Web PWA? (y/n): " deploy_web
# fi

# if [[ "$deploy_web" == "y" || "$deploy_web" == "Y" ]]; then
#     # Generate a unique tag based on current timestamp
#     web_tag="web-deploy-$(date +%Y%m%d-%H%M%S)"
    
#     echo -e "${BLUE}Tagging current code as $web_tag to trigger Cloud Web Deploy...${NC}"
#     git tag "$web_tag"
#     git push origin "$web_tag"
    
#     echo -e "${GREEN}Web deployment triggered! The Cloud Compiler is now building and deploying to GitHub Pages.${NC}"
#     echo -e "${GREEN}Your web version will be live in ~2-3 minutes.${NC}"
# else
#     echo -e "${BLUE}Skipping Web Deploy.${NC}"
# fi

# echo -e "${BLUE}Have a great day!${NC}"
