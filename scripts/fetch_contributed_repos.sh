# fetch_contributed_repos.sh
# Author: D.A.Pelasgus
#!/bin/bash

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
