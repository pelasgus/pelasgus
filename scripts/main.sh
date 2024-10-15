# main.sh
# Author: D.A.Pelasgus
#!/bin/bash

# Load all function scripts from the scripts directory
source "$(dirname "$0")/fetch_contributed_repos.sh"
source "$(dirname "$0")/fetch_primary_language.sh"
source "$(dirname "$0")/fetch_merged_commits.sh"
source "$(dirname "$0")/process_commits.sh"

# Environment Variables
GH_TOKEN="${GH_TOKEN}"
GH_USER="${GH_USER}"

# Initialize output files and fetch data
> repos.txt
CONTRIBUTED_REPOS=$(fetch_contributed_repos)
fetch_merged_commits

# Prepare the contributed repositories section as a simple Markdown list
CONTRIBUTED_REPOS=$(cat repos.txt | awk -F'|' '!seen[$1]++ {print "- ["$1"](https://github.com/"$1") (Owner: "gensub("/.*", "", "g", $1)")"}')

# Process commits and prepare dropdowns
FIRST_PARTY_COMMITS=$(process_commits "first")
THIRD_PARTY_COMMITS=$(process_commits "third")

# Define the README file and markers (README located one directory up)
README_FILE="../README.md"
REPOS_START="<!-- Contributed Repos Start -->"
REPOS_END="<!-- Contributed Repos End -->"
FIRST_PARTY_COMMITS_START="<!-- First-Party Commits Start -->"
FIRST_PARTY_COMMITS_END="<!-- First-Party Commits End -->"
THIRD_PARTY_COMMITS_START="<!-- Third-Party Commits Start -->"
THIRD_PARTY_COMMITS_END="<!-- Third-Party Commits End -->"

# Function to enforce marker uniqueness and clear content between them
ensure_marker_uniqueness_and_clear_content() {
  local start_marker="$1"
  local end_marker="$2"
  local content="$3"

  # Remove any existing markers and their content
  sed -i "/${start_marker}/,/${end_marker}/{/${start_marker}/!{/${end_marker}/!d;};}" "$README_FILE"

  # Ensure markers appear only once and add new content between them
  awk -v content="$content" \
      -v start_marker="$start_marker" -v end_marker="$end_marker" '
      $0 ~ start_marker {print; print start_marker; print content; while(getline && $0 !~ end_marker){}; print end_marker; next}
      {print}
  ' "$README_FILE" > temp_readme && mv temp_readme "$README_FILE"
}

# Clear and update content between each marker set
ensure_marker_uniqueness_and_clear_content "$REPOS_START" "$REPOS_END" "$CONTRIBUTED_REPOS"
ensure_marker_uniqueness_and_clear_content "$FIRST_PARTY_COMMITS_START" "$FIRST_PARTY_COMMITS_END" "$FIRST_PARTY_COMMITS"
ensure_marker_uniqueness_and_clear_content "$THIRD_PARTY_COMMITS_START" "$THIRD_PARTY_COMMITS_END" "$THIRD_PARTY_COMMITS"

# Clean up temporary files
rm commits_* repos.txt
