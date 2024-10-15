# fetch_merged_commits.sh
# Author: D.A.Pelasgus
#!/bin/bash
source "$(dirname "$0")/fetch_primary_language.sh"
source "$(dirname "$0")/fetch_all_public_repos.sh"

# Function to fetch and categorize merged commits into first-party and third-party
fetch_merged_commits() {
  # Create a list of all public repos owned by the user
  fetch_all_public_repos > owned_repos.txt

  # Fetch merged PRs
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/search/issues?q=is:pr+author:$GH_USER+is:merged" |
    jq -r --arg user "$GH_USER" '
      .items[] | 
      "\(.repository_url | sub("https://api.github.com/repos/"; ""))|\(.html_url)|\(.title)"' |
    while IFS="|" read -r repo url title; do
      language=$(fetch_primary_language "$repo")
      
      # Log all repos and their languages, including third-party
      echo "$repo|$language" >> repos.txt

      # Determine if the repo is first-party or third-party and log accordingly
      repo_safe=$(echo "$repo" | sed 's|/|_|')
      if grep -q "^$repo$" owned_repos.txt; then
        echo "- [$title]($url)" >> "commits_${repo_safe}_first.txt"
      else
        echo "$repo" >> repos_with_merged_prs.txt
        echo "- [$title]($url)" >> "commits_${repo_safe}_third.txt"
      fi
    done
}
