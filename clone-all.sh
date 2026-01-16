#!/bin/bash

USERNAME="YOURUSERNAME"
CLONE_DIR="$HOME/Desktop/Git"

echo "Cloning all repositories for $USERNAME"
echo "Target directory: $CLONE_DIR"
echo ""

# Create the directory if it doesn't exist
mkdir -p "$CLONE_DIR"
cd "$CLONE_DIR" || exit

# Check if gh CLI is authenticated
if ! gh auth status &>/dev/null; then
  echo "Error: gh CLI is not authenticated."
  echo "Please run: gh auth login"
  exit 1
fi

# Get all repository names
echo "Fetching repository list..."
repos=$(gh repo list "$USERNAME" --limit 1000 --json name -q '.[].name')

if [ -z "$repos" ]; then
  echo "No repositories found or error fetching repos."
  exit 1
fi

# Count total repos
total=$(echo "$repos" | wc -l)
echo "Found $total repositories"
echo ""

# Clone each repository
count=0
for repo in $repos; do
  count=$((count + 1))
  echo "[$count/$total] Cloning $repo..."
  
  # Check if directory already exists
  if [ -d "$repo" ]; then
    echo "Already exists, skipping"
    continue
  fi
  
  # Try SSH first
  if git clone "git@github.com:$USERNAME/$repo.git" 2>/dev/null; then
    echo "Cloned successfully (SSH)"
  else
    # Fall back to HTTPS if SSH fails
    echo "SSH failed, trying HTTPS..."
    if git clone "https://github.com/$USERNAME/$repo.git" 2>/dev/null; then
      echo "Cloned successfully (HTTPS)"
    else
      echo "Failed to clone"
    fi
  fi
  echo ""
done

echo "Cloning complete!"
echo "All repositories are in: $CLONE_DIR"