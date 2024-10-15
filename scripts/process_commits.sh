#!/bin/bash

# Function to process commits and create collapsible dropdowns
process_commits() {
  local category="$1"
  local output=""

  for repo_file in commits_*_${category}.txt; do
    # Convert the safe filename format back to owner/repo format
    repo=$(echo "$repo_file" | sed -e "s/^commits_//" -e "s/_${category}.txt$//" -e "s|_|/|")
    
    # Extract the primary language from repos.txt file, using the original repo format
    language=$(grep "^$repo|" repos.txt | head -n 1 | cut -d'|' -f2)

    # Format the output as an HTML <details> section with a summary for the repository and a Markdown list of commits
    output+="<details><summary><strong><a href=\"https://github.com/$repo\">$repo</a> - $language</strong></summary>\n\n"
    output+="$(cat "$repo_file")\n\n"
    output+="</details>\n"
  done

  echo -e "$output"
}
