# fetch_merged_commits.sh
# Author: D.A.Pelasgus
#!/bin/bash
source "$(dirname "$0")/fetch_primary_language.sh"
source "$(dirname "$0")/fetch_all_public_repos.sh"

# Function to fetch and categorize merged commits into first-party (owned) projects
fetch_merged_commits() {
  # Create a list of all public repos owned by the user
  fetch_all_public_repos > owned_repos.txt

  # Iterate over all owned repositories to ensure language is captured for each
  while IFS= read -r repo; do
    language=$(fetch_primary_language "$repo")
    echo "$repo|$language" >> repos.txt
  done < owned_repos.txt

  # Check for merged PRs in each owned repository
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/search/issues?q=is:pr+author:$GH_USER+is:merged" |
    jq -r --arg user "$GH_USER" '
      .items[] | 
      "\(.repository_url | sub("https://api.github.com/repos/"; ""))|\(.html_url)|\(.title)"' |
    while IFS="|" read -r repo url title; do
      # Mark that this repo has a merged PR and store commit details
      echo "$repo" >> repos_with_merged_prs.txt
      repo_safe=$(echo "$repo" | sed 's|/|_|')
      echo "- [$title]($url)" >> "commits_${repo_safe}_first.txt"
    done
}
