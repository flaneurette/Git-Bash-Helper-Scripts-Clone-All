#!/bin/bash

REPOS_DIR="$HOME/Desktop/Git"
COMMIT_MESSAGE="${1:-Update: $(date +'%Y-%m-%d %H:%M')}"

echo "Commit and push all repositories"
echo "Directory: $REPOS_DIR"
echo "Commit message: $COMMIT_MESSAGE"
echo ""

# Check if GPG signing is configured
if git config --global user.signingkey &>/dev/null; then
  echo "GPG signing key found: $(git config --global user.signingkey)"
  echo ""
fi

cd "$REPOS_DIR" || exit

# Counter for stats
total=0
changed=0
errors=0

for repo in */; do
  # Skip if not a directory or not a git repo
  if [ ! -d "$repo/.git" ]; then
    continue
  fi
  
  total=$((total + 1))
  repo_name="${repo%/}"
  
  echo "[$total] Processing: $repo_name"
  cd "$repo" || continue
  
  # Check if there are any changes
  if [ -z "$(git status --porcelain)" ]; then
    echo "No changes"
  else
    echo "Changes detected, committing..."
    
    # Add all changes
    git add .
    
    # Commit (with GPG signing if configured)
    if git commit -S -m "$COMMIT_MESSAGE" 2>/dev/null || git commit -m "$COMMIT_MESSAGE"; then
      echo "Committed successfully"
      
      # Push
      if git push; then
        echo "Pushed successfully"
        changed=$((changed + 1))
      else
        echo "Push failed"
        errors=$((errors + 1))
      fi
    else
      echo "Commit failed"
      errors=$((errors + 1))
    fi
  fi
  
  cd "$REPOS_DIR" || exit
  echo ""
done

echo "================================"
echo "Summary:"
echo "  Total repos checked: $total"
echo "  Repos updated: $changed"
echo "  Errors: $errors"
echo "================================"
