#!/bin/bash

REPOS_DIR="$HOME/Desktop/Git"
DIFF_DIR="$HOME/Desktop/Git-Diffs"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')

# Bot patterns to exclude (add more as needed)
BOT_PATTERNS=(
  "dependabot"
  "renovate"
  "github-actions"
  "github-actions[bot]"
  "bot@"
  "[bot]"
  "mergify"
)

echo "Checking for differences between local and GitHub"
echo "Repos directory: $REPOS_DIR"
echo "Diffs will be saved to: $DIFF_DIR"
echo ""

mkdir -p "$DIFF_DIR"
cd "$REPOS_DIR" || exit

# Counter for stats
total=0
with_remote_changes=0
with_local_changes=0
sync_errors=0

for repo in */; do
  if [ ! -d "$repo/.git" ]; then
    continue
  fi
  
  total=$((total + 1))
  repo_name="${repo%/}"
  
  echo "[$total] Checking: $repo_name"
  cd "$repo" || continue
  
  # Fetch latest from GitHub
  echo "Fetching from GitHub..."
  if ! git fetch origin 2>/dev/null; then
    echo "Failed to fetch from remote"
    sync_errors=$((sync_errors + 1))
    cd "$REPOS_DIR" || exit
    echo ""
    continue
  fi
  
  # Get current branch
  current_branch=$(git branch --show-current)
  
  if [ -z "$current_branch" ]; then
    echo "No branch checked out, skipping"
    cd "$REPOS_DIR" || exit
    echo ""
    continue
  fi
  
  # Check if remote branch exists
  if ! git rev-parse "origin/$current_branch" &>/dev/null; then
    echo "No remote branch found"
    cd "$REPOS_DIR" || exit
    echo ""
    continue
  fi
  
  # Compare local with remote
  local_commits=$(git rev-list "origin/$current_branch..$current_branch" --count)
  remote_commits=$(git rev-list "$current_branch..origin/$current_branch" --count)
  
  has_changes=false
  repo_diff_dir="$DIFF_DIR/${TIMESTAMP}_${repo_name}"
  
  # Check for unpushed local changes
  if [ "$local_commits" -gt 0 ]; then
    echo "Local has $local_commits unpushed commit(s)"
    has_changes=true
    with_local_changes=$((with_local_changes + 1))
    
    mkdir -p "$repo_diff_dir"
    
    echo "Local Commits Not Pushed to GitHub" > "$repo_diff_dir/local_ahead.txt"
    echo "Repository: $repo_name" >> "$repo_diff_dir/local_ahead.txt"
    echo "Branch: $current_branch" >> "$repo_diff_dir/local_ahead.txt"
    echo "Generated: $(date)" >> "$repo_diff_dir/local_ahead.txt"
    echo "===========================================" >> "$repo_diff_dir/local_ahead.txt"
    echo "" >> "$repo_diff_dir/local_ahead.txt"
    git log "origin/$current_branch..$current_branch" --oneline >> "$repo_diff_dir/local_ahead.txt"
    
    git diff "origin/$current_branch..$current_branch" > "$repo_diff_dir/local_ahead.diff"
  fi
  
  # Check for unpulled remote changes (with bot filtering)
  if [ "$remote_commits" -gt 0 ]; then
    all_commits=$(git log "$current_branch..origin/$current_branch" --format="%H|%an|%ae|%s")
    
    non_bot_hashes=()
    bot_count=0
    
    while IFS='|' read -r hash author email subject; do
      [ -z "$hash" ] && continue
      
      is_bot=false
      for pattern in "${BOT_PATTERNS[@]}"; do
        if [[ "$author" =~ $pattern ]] || [[ "$email" =~ $pattern ]]; then
          is_bot=true
          bot_count=$((bot_count + 1))
          break
        fi
      done
      
      if [ "$is_bot" = false ]; then
        non_bot_hashes+=("$hash")
      fi
    done <<< "$all_commits"
    
    non_bot_count=${#non_bot_hashes[@]}
    
    if [ "$non_bot_count" -gt 0 ]; then
      echo "GitHub has $non_bot_count HUMAN commit(s)! (filtered $bot_count bots)"
      has_changes=true
      with_remote_changes=$((with_remote_changes + 1))
      
      mkdir -p "$repo_diff_dir"
      
      echo "Remote Human Commits from GitHub" > "$repo_diff_dir/remote_ahead.txt"
      echo "Repository: $repo_name" >> "$repo_diff_dir/remote_ahead.txt"
      echo "Branch: $current_branch" >> "$repo_diff_dir/remote_ahead.txt"
      echo "Generated: $(date)" >> "$repo_diff_dir/remote_ahead.txt"
      echo "===========================================" >> "$repo_diff_dir/remote_ahead.txt"
      echo "" >> "$repo_diff_dir/remote_ahead.txt"
      
      for hash in "${non_bot_hashes[@]}"; do
        git log -1 --format="Commit: %h%nAuthor: %an <%ae>%nDate: %ad%nSubject: %s%n" "$hash" >> "$repo_diff_dir/remote_ahead.txt"
      done
      
      git diff "$current_branch..origin/$current_branch" > "$repo_diff_dir/remote_ahead.diff"
      
    elif [ "$bot_count" -gt 0 ]; then
      echo "GitHub has $bot_count bot commit(s) (filtered out)"
    fi
  fi
  
  # Check for uncommitted local changes
  if [ -n "$(git status --porcelain)" ]; then
    echo "Has uncommitted local changes"
    has_changes=true
    
    mkdir -p "$repo_diff_dir"
    
    echo "Uncommitted Local Changes" > "$repo_diff_dir/uncommitted.txt"
    echo "===========================================" >> "$repo_diff_dir/uncommitted.txt"
    git status >> "$repo_diff_dir/uncommitted.txt"
    
    git diff > "$repo_diff_dir/uncommitted.diff"
    git diff --cached > "$repo_diff_dir/uncommitted_staged.diff"
  fi
  
  if [ "$has_changes" = true ]; then
    echo "Sync Status for $repo_name" > "$repo_diff_dir/00_SUMMARY.txt"
    echo "Branch: $current_branch" >> "$repo_diff_dir/00_SUMMARY.txt"
    echo "Generated: $(date)" >> "$repo_diff_dir/00_SUMMARY.txt"
    echo "===========================================" >> "$repo_diff_dir/00_SUMMARY.txt"
    echo "" >> "$repo_diff_dir/00_SUMMARY.txt"
    echo "Local commits ahead: $local_commits" >> "$repo_diff_dir/00_SUMMARY.txt"
    echo "Remote commits ahead: $remote_commits" >> "$repo_diff_dir/00_SUMMARY.txt"
    echo "" >> "$repo_diff_dir/00_SUMMARY.txt"
    
    if [ "$local_commits" -gt 0 ]; then
      echo " You need to PUSH your local commits" >> "$repo_diff_dir/00_SUMMARY.txt"
    fi
    if [ "$remote_commits" -gt 0 ]; then
      echo " You need to PULL commits from GitHub" >> "$repo_diff_dir/00_SUMMARY.txt"
    fi
    if [ "$local_commits" -gt 0 ] && [ "$remote_commits" -gt 0 ]; then
      echo "" >> "$repo_diff_dir/00_SUMMARY.txt"
      echo "WARNING: Both local and remote have changes!" >> "$repo_diff_dir/00_SUMMARY.txt"
      echo "You may need to merge or rebase." >> "$repo_diff_dir/00_SUMMARY.txt"
    fi
    
    echo "Saved to: $repo_diff_dir"
  else
    echo "In sync with GitHub"
  fi
  
  cd "$REPOS_DIR" || exit
  echo ""
done

echo "================================"
echo "Summary:"
echo "  Total repos checked: $total"
echo "  Repos with local changes to push: $with_local_changes"
echo "  Repos with remote changes to pull: $with_remote_changes"
echo "  Sync errors: $sync_errors"

if [ $with_remote_changes -gt 0 ] || [ $with_local_changes -gt 0 ]; then
  echo ""
  echo "  Review diffs in: $DIFF_DIR"
  echo ""
  echo "Files created per repo:"
  echo "  - 00_SUMMARY.txt: Quick overview"
  echo "  - local_ahead.txt/.diff: Unpushed commits"
  echo "  - remote_ahead.txt/.diff: Human commits from GitHub"
  echo "  - uncommitted.txt/.diff: Local uncommitted changes"
fi
echo "================================"
