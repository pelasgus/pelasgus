# fetch_all_public_repos.sh
# Author: D.A.Pelasgus
#!/bin/bash

# Function to fetch all public repositories owned by the user
fetch_all_public_repos() {
  curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/users/$GH_USER/repos?type=public&per_page=100" |
    jq -r '.[] | select(.owner.login == "'$GH_USER'") | .full_name'
}

