# fetch_merged_commits.sh
# Author: D.A.Pelasgus
#!/bin/bash
source "$(dirname "$0")/fetch_primary_language.sh"

# Function to fetch all public repositories owned by the user
fetch_public_repos() {
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/users/$GH_USER/repos?type=public" |
    jq -r '.[] | .full_name'
}

# Function to fetch and categorize merged commits for first-party and third-party
fetch_merged_commits() {
  # Fetch merged PRs and store in associative array by repo
  declare -A merged_prs
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/search/issues?q=is:pr+author:$GH_USER+is:merged" |
    jq -r --arg user "$GH_USER" '
      .items[] | 
      "\(.repository_url | sub("https://api.github.com/repos/"; ""))|\(.html_url)|\(.title)"' |
    while IFS="|" read -r repo url title; do
      language=$(fetch_primary_language "$repo")
      if [[ "$repo" == "$GH_USER/"* ]]; then
        echo "- [$title]($url)" >> "commits_${repo//\//_}_first.txt"
        merged_prs["$repo"]=$language
      else
        echo "- [$title]($url)" >> "commits_${repo//\//_}_third.txt"
      fi
    done

  # Fetch all public repos owned by the user and identify ones without PRs
  for repo in $(fetch_public_repos); do
    if [[ -z "${merged_prs[$repo]}" ]]; then
      language=$(fetch_primary_language "$repo")
      echo "$repo|$language|no-prs" >> repos_no_prs.txt
    else
      echo "$repo|${merged_prs[$repo]}|has-prs" >> repos_with_prs.txt
    fi
  done
}
