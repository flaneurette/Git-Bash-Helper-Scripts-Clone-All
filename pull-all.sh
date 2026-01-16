#!/bin/bash
USERNAME="YOURUSERNAME"
CLONE_DIR="$HOME/Desktop/Git"

cd "$CLONE_DIR" || exit

for repo in */; do
  echo "Updating $repo"
  cd "$repo" || continue
  git pull
  cd ..
done