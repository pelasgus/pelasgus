#!/bin/bash

# Function to process commits, displaying dropdowns only for repos with merged PRs
process_commits() {
  local category="$1"
  local output=""

  # Select the appropriate list of repos based on the category
  if [[ "$category" == "first" ]]; then
    repo_list=owned_repos.txt
  else
    repo_list=repos_with_merged_prs.txt
  fi

  while IFS= read -r repo; do
    language=$(grep "^$repo|" repos.txt | head -n 1 | cut -d'|' -f2)
    repo_safe=$(echo "$repo" | sed 's|/|_|')
    
    if [[ -f "commits_${repo_safe}_${category}.txt" ]]; then
      output+="<details><summary><strong><a href=\"https://github.com/$repo\">$repo</a> - $language</strong></summary>\n\n"
      output+="$(cat "commits_${repo_safe}_${category}.txt")\n\n"
      output+="</details>\n\n"
    else
      output+="- [$repo](https://github.com/$repo) - $language\n\n"
    fi
  done < "$repo_list"

  echo -e "$output"
}
