# process_commits.sh
# Author: D.A.Pelasgus
#!/bin/bash

# Function to process commits and create collapsible dropdowns
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

