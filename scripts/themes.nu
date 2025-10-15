#!/usr/bin/env nu

def get-gnome-color-scheme [] {
    dconf read /org/gnome/desktop/interface/color-scheme | str trim
}

def file-replace [
    file:         string,
    line_has:     string,
    target:       string,
    replacement:  string
] {
    open --raw $file | lines | each { |line|
        if ($line | str contains $line_has) {
            $line | str replace $target $replacement
        } else {
            $line
        }
    } | save --force $file
}

def set-gnome-themes [mode: string] {
    let config_dir     = $"($env.HOME)/dots/configs"
    let helix_config   = $"($config_dir)/helix/config.toml"
    let rofi_config    = $"($config_dir)/rofi/config.rasi"
    let clipse_config  = $"($config_dir)/clipse/config.json"

    let themes = {
        "Dark": {
            color_scheme: "'prefer-dark'",
            gtk_theme: "'Adwaita-dark'",
            icon_theme: "'Adwaita-dark'",
            prefer_dark: "1",
            cursor: "catppuccin-latte-light-cursors",
            helix: "papercolor-dark",
            rofi_from: "light",
            rofi_to: "dark",
            clipse: "dark.json"
        },
        "Light": {
            color_scheme: "'prefer-light'",
            gtk_theme: "'Adwaita'",
            icon_theme: "'Adwaita'",
            prefer_dark: "0",
            cursor: "catppuccin-mocha-dark-cursors",
            helix: "papercolor-light",
            rofi_from: "dark",
            rofi_to: "light",
            clipse: "light.json"
        }
    }

    if not ($themes | columns | any { |m| $m == $mode }) {
        print "Invalid mode. Please use 'Light' or 'Dark'."
        return
    }

    let cfg = $themes | get $mode

    print $"Setting color scheme to ($cfg.color_scheme)"

    dconf write /org/gnome/desktop/interface/color-scheme $cfg.color_scheme
    dconf write /org/gnome/desktop/interface/gtk-theme $cfg.gtk_theme
    dconf write /org/gnome/desktop/interface/icon-theme $cfg.icon_theme
    dconf write /gtk3/extraConfig/gtk-application-prefer-dark-theme $cfg.prefer_dark
    hyprctl setcursor $cfg.cursor 24

    open $helix_config | update theme $cfg.helix | save --force $helix_config
    file-replace $rofi_config "theme" $cfg.rofi_from $cfg.rofi_to
    open $clipse_config | update themeFile $cfg.clipse | to json | save --raw --force $clipse_config
}

let current = (get-gnome-color-scheme)
let next = if $current == "'prefer-light'" { "Dark" } else { "Light" }
set-gnome-themes $next
