#!/bin/bash

# Use the environment variables directly from GitHub Actions Secrets
GH_TOKEN="${GH_TOKEN}"
GH_USER="${GH_USER}"

# Function to fetch the primary language of a repository
fetch_primary_language() {
  local repo="$1"
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$repo" |
    jq -r '.language'
}

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
      language=$(fetch_primary_language "$repo")
      if [[ "$repo" == "$GH_USER/"* ]]; then
        echo "- [$title]($url)" >> "commits_${repo//\//_}_first.txt"
      else
        echo "- [$title]($url)" >> "commits_${repo//\//_}_third.txt"
      fi
      echo "$repo|$language" >> repos.txt
    done
}

# Initialize output files and fetch data
> repos.txt
fetch_contributed_repos
fetch_merged_commits

# Process commits and group by repository with dropdowns
process_commits() {
  local category="$1"
  local output=""

  for repo_file in commits_*_${category}.txt; do
    repo=$(echo "$repo_file" | sed -e "s/commits_//" -e "s/_$category.txt//" -e "s/_/\//g")
    language=$(grep "^$repo|" repos.txt | head -n 1 | cut -d'|' -f2)
    output+="<details><summary><strong><a href=\"https://github.com/$repo\">$repo</a> - $language</strong></summary>\n\n"
    output+="$(cat "$repo_file")\n\n"
    output+="</details>\n"
  done

  echo -e "$output"
}

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
