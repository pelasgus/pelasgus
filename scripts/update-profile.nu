#!/usr/bin/env nu

def github-get [path: string] {
    let token = ($env.GITHUB_TOKEN? | default "")
    let base_headers = {
        Accept: "application/vnd.github+json"
        X-GitHub-Api-Version: "2022-11-28"
        User-Agent: "pelasgus-profile-updater"
    }
    let headers = if ($token | is-empty) {
        $base_headers
    } else {
        $base_headers | insert Authorization $"Bearer ($token)"
    }

    http get --headers $headers $"https://api.github.com/($path)"
}

def escape-xml [value: string] {
    $value
    | str replace --all "&" "&amp;"
    | str replace --all "<" "&lt;"
    | str replace --all ">" "&gt;"
}

def main [] {
    let root = ($env.CURRENT_FILE | path dirname | path dirname)
    let user = ($env.GITHUB_REPOSITORY_OWNER? | default "pelasgus")

    let repos = (github-get $"users/($user)/repos?per_page=100&sort=pushed")
    let gpg_keys = (github-get $"users/($user)/gpg_keys")
    let ssh_keys = (github-get $"users/($user)/keys")

    let language_repos = ($repos
        | where {|repo|
            $repo.fork == false and $repo.archived == false and $repo.name != $user and $repo.language? != null
        })
    let language_total = ($language_repos | length)
    let language_groups = if $language_total == 0 {
        []
    } else {
        $language_repos
        | group-by language
        | transpose language repositories
        | insert count {|row| $row.repositories | length }
        | sort-by count --reverse
        | first 5
    }
    let language_svg_raw = if $language_total == 0 {
        '\n    <text class="display language muted" x="898" y="160">no language data</text>\n  '
    } else {
        $language_groups
        | enumerate
        | each {|entry|
            let y = (160 + ($entry.index * 32))
            let bar_y = ($y + 9)
            let bar_number = ($entry.index + 1)
            let percentage = (($entry.item.count * 100 / $language_total) | math round --precision 2)
            let width = (($percentage * 2.18) | math round --precision 1)
            let language = (escape-xml $entry.item.language)
            [
                $'\n    <text class="display language ink" x="898" y="($y)">($language)</text>'
                $'\n    <text class="folio muted" x="1116" y="($y)" text-anchor="end">($percentage)%</text>'
                $'\n    <rect class="bar-bg" x="898" y="($bar_y)" width="218" height="3" />'
                $'\n    <rect class="bar bar-($bar_number)" x="898" y="($bar_y)" width="($width)" height="3" />'
            ] | str join
        }
        | str join
        | $in + "\n  "
    }
    let language_svg = ($language_svg_raw | str replace --all '\n' (char newline))

    let gpg_id = if ($gpg_keys | is-empty) {
        "not published"
    } else {
        $"0x($gpg_keys.0.key_id)"
    }

    let ssh_fingerprint = if ($ssh_keys | is-empty) {
        "not published"
    } else {
        let temp_dir = ($env.TMPDIR? | default "/tmp")
        let key_file = ($temp_dir | path join $"pelasgus-key-(random uuid).pub")
        $ssh_keys.0.key | save --force $key_file
        let fingerprint = (^ssh-keygen -lf $key_file
            | split row " "
            | where {|part| not ($part | is-empty) }
            | get 1)
        rm $key_file
        $fingerprint
    }

    let gpg_xml = (escape-xml $gpg_id)
    let ssh_xml = (escape-xml $ssh_fingerprint)

    for svg in ["assets/typing.template.svg" "assets/typing.svg"] {
        let path = ($root | path join $svg)
        let base = (open --raw $path
        | str replace --regex '(<text id="gpg-value"[^>]*>)[^<]*(</text>)' $"${1}($gpg_xml)${2}"
        | str replace --regex '(<text id="ssh-value"[^>]*>)[^<]*(</text>)' $"${1}($ssh_xml)${2}"
        | str replace --regex '(?s)(<g id="language-values">).*?(</g>)' $"${1}($language_svg)${2}")
        $base | save --force $path
    }
}
