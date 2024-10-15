# fetch_merged_commits.sh
# Author: D.A.Pelasgus
#!/bin/bash
source "$(dirname "$0")/fetch_primary_language.sh"
source "$(dirname "$0")/fetch_all_public_repos.sh"

# Function to fetch and categorize merged commits into first-party and third-party
fetch_merged_commits() {
  # Fetch all non-forked public repos owned by the user and their languages
  fetch_all_public_repos | while read -r repo; do
    language=$(fetch_primary_language "$repo")
    echo "$repo|$language" >> repos.txt
  done > owned_repos.txt

  # Fetch all repositories with merged PRs and their languages
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/search/issues?q=is:pr+author:$GH_USER+is:merged" |
    jq -r '.items[] | "\(.repository_url | sub("https://api.github.com/repos/"; ""))|\(.html_url)|\(.title)"' |
    while IFS="|" read -r repo url title; do
      # Get the language for this repo and add to repos.txt if not already present
      if ! grep -q "^$repo|" repos.txt; then
        language=$(fetch_primary_language "$repo")
        echo "$repo|$language" >> repos.txt
      fi
      
      repo_safe=$(echo "$repo" | sed 's|/|_|')
      if grep -q "^$repo$" owned_repos.txt; then
        echo "- [$title]($url)" >> "commits_${repo_safe}_first.txt"
      else
        echo "$repo" >> repos_with_merged_prs.txt
        echo "- [$title]($url)" >> "commits_${repo_safe}_third.txt"
      fi
    done
}
