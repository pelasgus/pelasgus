# main.sh
# Author: D.A.Pelasgus
#!/bin/bash

# Get the absolute path of the root directory
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
README_FILE="$BASE_DIR/README.md"

# Load all function scripts from the scripts directory
source "$(dirname "$0")/fetch_contributed_repos.sh"
source "$(dirname "$0")/fetch_primary_language.sh"
source "$(dirname "$0")/fetch_merged_commits.sh"
source "$(dirname "$0")/fetch_all_public_repos.sh"
source "$(dirname "$0")/process_commits.sh"

# Environment Variables
GH_TOKEN="${GH_TOKEN}"
GH_USER="${GH_USER}"

# Check if necessary environment variables are set
if [ -z "$GH_TOKEN" ] || [ -z "$GH_USER" ]; then
  echo "Error: GH_TOKEN and GH_USER must be set as environment variables."
  exit 1
fi

# Initialize output files and fetch data
> repos.txt
fetch_merged_commits

# Process commits for first-party (owned) projects and generate dropdowns for those with merged PRs
FIRST_PARTY_COMMITS=$(process_commits "first")

# Define markers in the README file
FIRST_PARTY_COMMITS_START="<!-- First-Party Commits Start -->"
FIRST_PARTY_COMMITS_END="<!-- First-Party Commits End -->"

# Ensure the marker for first-party commits appears only once by removing any extra occurrences
sed -i "/${FIRST_PARTY_COMMITS_START}/,/${FIRST_PARTY_COMMITS_END}/{/${FIRST_PARTY_COMMITS_START}/!{/${FIRST_PARTY_COMMITS_END}/!d;};}" "$README_FILE"

# Update README with new content using awk to insert the fetched data
awk -v first_party_commits="$FIRST_PARTY_COMMITS" \
    -v first_party_commits_start="$FIRST_PARTY_COMMITS_START" -v first_party_commits_end="$FIRST_PARTY_COMMITS_END" '
    $0 ~ first_party_commits_start {print; print first_party_commits_start; print first_party_commits; while(getline && $0 !~ first_party_commits_end){}; print first_party_commits_end; next}
    {print}
' "$README_FILE" > temp_readme && mv temp_readme "$README_FILE"

# Clean up temporary files
rm -f commits_* repos.txt repos_with_merged_prs.txt owned_repos.txt
