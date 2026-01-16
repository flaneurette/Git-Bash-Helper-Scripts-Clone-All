#!/bin/bash

USERNAME="YOURUSERNAME"

echo "Testing GitHub connectivity..."
echo ""

# Test 1: Check if gh CLI is working
echo "1. Testing gh CLI:"
gh auth status
echo ""

# Test 2: Check SSH connection to GitHub
echo "2. Testing SSH to GitHub:"
ssh -T git@github.com
echo ""

# Test 3: Try to clone one repo manually
echo "3. Getting first repo name:"
first_repo=$(gh repo list $USERNAME --limit 1 --json name -q '.[0].name')
echo "First repo: $first_repo"
echo ""

echo "4. Attempting to clone $first_repo:"
git clone "git@github.com:$USERNAME/$first_repo.git" "/tmp/test-clone-$first_repo"
echo ""

if [ -d "/tmp/test-clone-$first_repo" ]; then
  echo "Clone successful!"
  rm -rf "/tmp/test-clone-$first_repo"
else
  echo "Clone failed"
  echo ""
  echo "Trying HTTPS instead:"
  git clone "https://github.com/$USERNAME/$first_repo.git" "/tmp/test-clone-$first_repo"
  
  if [ -d "/tmp/test-clone-$first_repo" ]; then
    echo "HTTPS clone successful!"
    rm -rf "/tmp/test-clone-$first_repo"
  fi
fi