# fetch_primary_language.sh
# Author: D.A.Pelasgus
#!/bin/bash

# Function to fetch the primary language of a repository
fetch_primary_language() {
  local repo="$1"
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$repo" |
    jq -r '.language'
}
