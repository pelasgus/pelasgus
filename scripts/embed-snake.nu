#!/usr/bin/env nu

def main [snake: path] {
    let root = ($env.CURRENT_FILE | path dirname | path dirname)
    let snake_path = ($snake | path expand)
    if not ($snake_path | path exists) {
        error make { msg: $"Generated snake SVG not found: ($snake_path)" }
    }

    let parsed = (open --raw $snake_path
        | parse --regex '(?s)<style>(?<css>.*?)</style>(?<body>.*?)</svg>'
        | first)
    let snippet = ([
        '<!-- SNAKE:START -->'
        '<g id="snake-game">'
        '<style>'
        $parsed.css
        '</style>'
        '<g transform="translate(0 340)">'
        $parsed.body
        '</g>'
        '</g>'
        '<!-- SNAKE:END -->'
    ] | str join (char newline))

    for asset in ["assets/typing.template.svg" "assets/typing.svg"] {
        let path = ($root | path join $asset)
        open --raw $path
        | str replace --regex '(?s)<!-- SNAKE:START -->.*?<!-- SNAKE:END -->' $snippet
        | save --force $path
    }
}
