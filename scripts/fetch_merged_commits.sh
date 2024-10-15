# fetch_merged_commits.sh
# Author: D.A.Pelasgus
#!/bin/bash
source "$(dirname "$0")/fetch_primary_language.sh"

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
