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

# Define the README file and markers
README_FILE="README.md"
REPOS_START="<!-- Contributed Repos Start -->"
REPOS_END="<!-- Contributed Repos End -->"
FIRST_PARTY_COMMITS_START="<!-- First-Party Commits Start -->"
FIRST_PARTY_COMMITS_END="<!-- First-Party Commits End -->"
THIRD_PARTY_COMMITS_START="<!-- Third-Party Commits Start -->"
THIRD_PARTY_COMMITS_END="<!-- Third-Party Commits End -->"

# Ensure each marker appears only once by removing any extra occurrences
sed -i "/${REPOS_START}/,/${REPOS_END}/{/${REPOS_START}/!{/${REPOS_END}/!d;};}" $README_FILE
sed -i "/${FIRST_PARTY_COMMITS_START}/,/${FIRST_PARTY_COMMITS_END}/{/${FIRST_PARTY_COMMITS_START}/!{/${FIRST_PARTY_COMMITS_END}/!d;};}" $README_FILE
sed -i "/${THIRD_PARTY_COMMITS_START}/,/${THIRD_PARTY_COMMITS_END}/{/${THIRD_PARTY_COMMITS_START}/!{/${THIRD_PARTY_COMMITS_END}/!d;};}" $README_FILE

# Update README with new content
awk -v repos="$CONTRIBUTED_REPOS" \
    -v first_party_commits="$FIRST_PARTY_COMMITS" \
    -v third_party_commits="$THIRD_PARTY_COMMITS" \
    -v repos_start="$REPOS_START" -v repos_end="$REPOS_END" \
    -v first_party_commits_start="$FIRST_PARTY_COMMITS_START" -v first_party_commits_end="$FIRST_PARTY_COMMITS_END" \
    -v third_party_commits_start="$THIRD_PARTY_COMMITS_START" -v third_party_commits_end="$THIRD_PARTY_COMMITS_END" '
    $0 ~ repos_start {print; print repos_start; print repos; while(getline && $0 !~ repos_end){}; print repos_end; next}
    $0 ~ first_party_commits_start {print; print first_party_commits_start; print first_party_commits; while(getline && $0 !~ first_party_commits_end){}; print first_party_commits_end; next}
    $0 ~ third_party_commits_start {print; print third_party_commits_start; print third_party_commits; while(getline && $0 !~ third_party_commits_end){}; print third_party_commits_end; next}
    {print}
' $README_FILE > temp_readme && mv temp_readme $README_FILE

# Clean up temporary files
rm commits_* repos.txt