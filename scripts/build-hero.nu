#!/usr/bin/env nu

def main [font?: path] {
    let root = ($env.CURRENT_FILE | path dirname | path dirname)
    let font_path = if $font == null {
        let package = (^nix build $"path:($root)#operator-mono" --no-link --print-out-paths
            | complete)

        if $package.exit_code != 0 {
            error make { msg: $"Operator Mono build failed:\n($package.stderr)" }
        }

        $package.stdout
        | str trim
        | path join "share" "fonts" "opentype" "OperatorMonoLig-Light.otf"
    } else {
        $font | path expand
    }

    if not ($font_path | path exists) {
        error make { msg: $"Operator Mono font not found: ($font_path)" }
    }

    let italic_font_path = ($font_path
        | path dirname
        | path join "OperatorMonoLig-LightItalic.otf")
    if not ($italic_font_path | path exists) {
        error make { msg: $"Operator Mono italic font not found: ($italic_font_path)" }
    }

    let template = ($root | path join "assets" "typing.template.svg")
    let output = ($root | path join "assets" "typing.svg")
    let encoded_font = (open --raw $font_path | encode base64)
    let encoded_italic_font = (open --raw $italic_font_path | encode base64)

    open --raw $template
    | str replace "__FONT_DATA__" $encoded_font
    | str replace "__FONT_ITALIC_DATA__" $encoded_italic_font
    | save --force $output

    print $"wrote ($output)"
}
