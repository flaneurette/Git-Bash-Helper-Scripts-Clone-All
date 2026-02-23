#!/bin/bash

# Create a new file in ALL your repositories, and commit it.
# Especially useful if you want to add/update a copyright.md or other file that changes often, to ALL your repositories.
# Standard runs in dry run (no changes made)

# Your username
USERNAME="YOURUSERNAME"

# Dry-run mode: set to "true" to test without pushing, "false" to actually push
DRY_RUN=true

repos=$(gh repo list $USERNAME --limit 100 --json name,createdAt -q 'sort_by(.createdAt) | .[] | .name + " " + .createdAt')

cat > /tmp/NEWFILE.md << 'EOF'
# TEXT HERE
More text here.
Even more text here.
Copyright by so and so... 
EOF

while IFS= read -r line; do
    repo=$(echo "$line" | awk '{print $1}')
    created_at=$(echo "$line" | awk '{print $2}')

    echo "Processing $repo (created: $created_at)..."

    rm -rf "/tmp/$repo"

    if ! git clone -c core.autocrlf=false "https://github.com/$USERNAME/$repo.git" "/tmp/$repo" 2>&1; then
        echo "  FAILED to clone $repo"
        continue
    fi

    cd "/tmp/$repo" || continue

    cp /tmp/NEWFILE.md .
    git add NEWFILE.md

    if git diff --cached --quiet; then
        echo "  No changes needed for $repo"
        cd /tmp
        rm -rf "/tmp/$repo"
        continue
    fi

    echo "  Changes detected, committing with date $created_at..."

    if ! GIT_AUTHOR_DATE="$created_at" GIT_COMMITTER_DATE="$created_at" git commit -S -m "Update commit verification documentation" 2>&1; then
        echo "  FAILED to commit to $repo - check GPG signing"
        cd /tmp
        rm -rf "/tmp/$repo"
        continue
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY-RUN] Would push NEWFILE.md to $repo"
    else
        if git push 2>&1; then
            echo "  OK pushed NEWFILE.md to $repo"
        else
            echo "  FAILED to push to $repo"
        fi
    fi

    cd /tmp
    rm -rf "/tmp/$repo"

done <<< "$repos"

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "DRY-RUN COMPLETE - no changes pushed"
else
    echo "Done processing all repos"
fi