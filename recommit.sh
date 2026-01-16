#!/bin/bash

# Create a new file in ALL your repositories, and commit it.
# Especially useful if you want to add a copyright.md or other file to ALL your repositories.
# Standard runs in dry run (no changes made)

# Your username
USERNAME="YOURUSERNAME"

# Dry-run mode: set to "true" to test without pushing, "false" to actually push
DRY_RUN=true

# Get all repo names (increase limit if you have more than 100 repos)
repos=$(gh repo list $USERNAME --limit 100 --json name,createdAt -q 'sort_by(.createdAt) | .[].name')

# Create NEWFILE.md content
cat > /tmp/NEWFILE.md << 'EOF'
# TEXT HERE
More text here.
EOF
if [ "$DRY_RUN" = true ]; then
  echo "DRY-RUN MODE - No changes will be pushed"
  echo "Set DRY_RUN=false to actually push changes"
  echo ""
fi
# Clone, add file, commit, push
for repo in $repos; do
  echo "Processing $repo..."
  
  # Clone repo using HTTPS
  if git clone "https://github.com/$USERNAME/$repo.git" "/tmp/$repo" 2>/dev/null; then
    cd "/tmp/$repo" || continue
    
    # Always copy/overwrite NEWFILE.md
    cp /tmp/NEWFILE.md .
    git add NEWFILE.md
    
    # Check if there are actually changes to commit
    if git diff --cached --quiet; then
      echo "No changes needed for $repo (file already up to date)"
    else
      if git commit -S -m "Update commit verification documentation"; then
        if [ "$DRY_RUN" = true ]; then
          echo "[DRY-RUN] Would push NEWFILE.md to $repo"
          echo "Commit created but not pushed"
        else
          git push
          echo "Successfully updated NEWFILE.md in $repo"
        fi
      else
        echo "Failed to commit to $repo"
      fi
    fi
    
    cd /tmp
    rm -rf "/tmp/$repo"
  else
    echo "Failed to clone $repo"
  fi
done
if [ "$DRY_RUN" = true ]; then
  echo ""
  echo "DRY-RUN COMPLETE - No changes were pushed"
  echo "Review the output above, then set DRY_RUN=false to push for real"
else
  echo ""
  echo "Done! Processed all repos."

fi
