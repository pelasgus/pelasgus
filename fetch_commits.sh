#!/bin/bash

# Use the environment variables directly from GitHub Actions Secrets
GH_TOKEN="${GH_TOKEN}"
GH_USER="${GH_USER}"

# Function to fetch unique contributed repositories
fetch_contributed_repos() {
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/search/issues?q=is:pr+author:$GH_USER" |
    jq -r '.items[] | .repository_url | sub("https://api.github.com/repos/"; "")' |
    sort -u |
    while read repo; do
      owner=$(echo $repo | cut -d/ -f1)
      echo "- [$repo](https://github.com/$repo) (Owner: $owner)"
    done
}

# Function to fetch merged commits
fetch_merged_commits() {
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/search/issues?q=is:pr+author:$GH_USER+is:merged" |
    jq -r '.items[] | "- [\(.repository_url | sub("https://api.github.com/repos/"; ""))](\(.html_url)): \(.title)"'
}

# Fetch contributed repos and merged commits
CONTRIBUTED_REPOS=$(fetch_contributed_repos)
MERGED_COMMITS=$(fetch_merged_commits)

# Update README.md
README_FILE="README.md"
REPOS_START="<!-- Contributed Repos Start -->"
REPOS_END="<!-- Contributed Repos End -->"
COMMITS_START="<!-- Merged Commits Start -->"
COMMITS_END="<!-- Merged Commits End -->"

# Create a new README content with old data cleared from marked sections
awk -v repos="$CONTRIBUTED_REPOS" -v commits="$MERGED_COMMITS" \
    -v repos_start="$REPOS_START" -v repos_end="$REPOS_END" \
    -v commits_start="$COMMITS_START" -v commits_end="$COMMITS_END" '
    BEGIN {repo_section=0; commit_section=0}
    $0 ~ repos_start {repo_section=1; print; print repos_start; print repos; next}
    $0 ~ repos_end {repo_section=0; print repos_end; next}
    $0 ~ commits_start {commit_section=1; print; print commits_start; print commits; next}
    $0 ~ commits_end {commit_section=0; print commits_end; next}
    !repo_section && !commit_section {print}
' $README_FILE > temp_readme && mv temp_readme $README_FILE
