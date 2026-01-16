# Git Bash Helper Scripts aka Clone-All.

Clone all your GitHub repos

Download GitHub CLI:  
https://cli.github.com/

Attached are a few **git bash** helper scripts as well, for more control.

---

## Bash (Linux / macOS / Git Bash)

    # Login first
    gh auth login

    # Create a folder for all your repos
    mkdir github-all
    cd github-all

    # List all your repos and clone them
    for repo in $(gh repo list YOUR_USERNAME --limit 100 --json name -q '.[].name'); do
      gh repo clone YOUR_USERNAME/$repo
    done

---

## PowerShell (Windows)

    # Login first
    gh auth login
    
    # Create a folder
    mkdir github-all
    cd github-all

    # Get all repos from your GitHub account
    $repos = gh repo list YOUR_USERNAME --limit 100 --json nameWithOwner | ConvertFrom-Json

    # Clone each repo
    foreach ($repo in $repos) {
        gh repo clone $repo.nameWithOwner
    }
