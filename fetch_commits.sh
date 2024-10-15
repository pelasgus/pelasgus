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

# Function to fetch and categorize merged commits into first-party and third-party
fetch_merged_commits() {
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/search/issues?q=is:pr+author:$GH_USER+is:merged" |
    jq -r --arg user "$GH_USER" '
      .items[] | 
      "\(.repository_url | sub("https://api.github.com/repos/"; ""))|\(.html_url)|\(.title)"' |
    while IFS="|" read -r repo url title; do
      owner=$(echo $repo | cut -d/ -f1)
      if [[ "$owner" == "$GH_USER" ]]; then
        echo "- [$repo]($url): $title" >> first_party_commits.txt
      else
        echo "- [$repo]($url): $title" >> third_party_commits.txt
      fi
    done
}

# Initialize output files and fetch data
> first_party_commits.txt
> third_party_commits.txt
CONTRIBUTED_REPOS=$(fetch_contributed_repos)
fetch_merged_commits
FIRST_PARTY_COMMITS=$(cat first_party_commits.txt)
THIRD_PARTY_COMMITS=$(cat third_party_commits.txt)

# Define the README file and markers
README_FILE="README.md"
REPOS_START="<!-- Contributed Repos Start -->"
REPOS_END="<!-- Contributed Repos End -->"
FIRST_PARTY_COMMITS_START="<!-- First-Party Commits Start -->"
FIRST_PARTY_COMMITS_END="<!-- First-Party Commits End -->"
THIRD_PARTY_COMMITS_START="<!-- Third-Party Commits Start -->"
THIRD_PARTY_COMMITS_END="<!-- Third-Party Commits End -->"

# Replace content between markers in README.md
awk -v repos="$CONTRIBUTED_REPOS" \
    -v first_party_commits="$FIRST_PARTY_COMMITS" \
    -v third_party_commits="$THIRD_PARTY_COMMITS" \
    -v repos_start="$REPOS_START" -v repos_end="$REPOS_END" \
    -v first_party_commits_start="$FIRST_PARTY_COMMITS_START" -v first_party_commits_end="$FIRST_PARTY_COMMITS_END" \
    -v third_party_commits_start="$THIRD_PARTY_COMMITS_START" -v third_party_commits_end="$THIRD_PARTY_COMMITS_END" '
    # Flag sections for clearing and replacement
    BEGIN {repo_section=0; first_party_section=0; third_party_section=0}
    $0 ~ repos_start {repo_section=1; print; print repos_start; print repos; next}
    $0 ~ repos_end {repo_section=0; print repos_end; next}
    $0 ~ first_party_commits_start {first_party_section=1; print; print first_party_commits_start; print first_party_commits; next}
    $0 ~ first_party_commits_end {first_party_section=0; print first_party_commits_end; next}
    $0 ~ third_party_commits_start {third_party_section=1; print; print third_party_commits_start; print third_party_commits; next}
    $0 ~ third_party_commits_end {third_party_section=0; print third_party_commits_end; next}
    # Skip any old content within sections, allowing only new content to be inserted
    repo_section && $0 ~ repos_end {repo_section=0; next}
    first_party_section && $0 ~ first_party_commits_end {first_party_section=0; next}
    third_party_section && $0 ~ third_party_commits_end {third_party_section=0; next}
    !repo_section && !first_party_section && !third_party_section {print}
' $README_FILE > temp_readme && mv temp_readme $README_FILE

# Clean up temporary files
rm first_party_commits.txt third_party_commits.txt
