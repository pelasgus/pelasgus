# process_commits.sh
# Author: D.A.Pelasgus
#!/bin/bash

# Function to process commits, displaying dropdowns only for repos with merged PRs
process_commits() {
  local category="$1"
  local output=""

  # List all owned repos, highlighting those with merged PRs
  while IFS= read -r repo; do
    language=$(grep "^$repo|" repos.txt | head -n 1 | cut -d'|' -f2)
    repo_safe=$(echo "$repo" | sed 's|/|_|')
    
    if [[ -f "commits_${repo_safe}_${category}.txt" ]]; then
      # Create a dropdown for repos with merged PRs using HTML formatting
      output+="<details><summary><strong><a href=\"https://github.com/$repo\">$repo</a> - $language</strong></summary>\n\n"
      output+="$(cat "commits_${repo_safe}_${category}.txt")\n\n"
      output+="</details>\n"
    else
      # List the repo using Markdown formatting
      output+="- [$repo](https://github.com/$repo) - $language\n"
    fi
  done < owned_repos.txt

  echo -e "$output"
}
