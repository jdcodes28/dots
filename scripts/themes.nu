#!/usr/bin/env nu
use ./utils.nu *

def set-gnome-themes [mode: string] {
    let config_dir     = $"($env.HOME)/dots/configs"
    let helix_config   = $"($config_dir)/helix/config.toml"
    let rofi_config    = $"($config_dir)/rofi/config.rasi"
    let clipse_config  = $"($config_dir)/clipse/config.json"
    let niri_config    = $"($config_dir)/niri/config.kdl"

    let themes = {
        "Dark": {
            color_scheme: "'prefer-dark'",
            gtk_theme: "'Adwaita-dark'",
            icon_theme: "'Adwaita-dark'",
            prefer_dark: "1",
            cursor_from: "catppuccin-mocha-dark-cursors",
            cursor_to: "catppuccin-latte-light-cursors",
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
            cursor_from: "catppuccin-latte-light-cursors",
            cursor_to: "catppuccin-mocha-dark-cursors",
            helix: "papercolor-light",
            rofi_from: "dark",
            rofi_to: "light",
            clipse: "light.json"
        }
    }

    # if not ($themes | has $mode) {
    #     print "Invalid mode. Please use 'Light' or 'Dark'."
    #     return
    # }

    let cfg = $themes | get $mode

    print $"Setting color scheme to ($cfg.color_scheme)"

    dconf write /org/gnome/desktop/interface/color-scheme $cfg.color_scheme
    dconf write /org/gnome/desktop/interface/gtk-theme $cfg.gtk_theme
    dconf write /org/gnome/desktop/interface/icon-theme $cfg.icon_theme
    dconf write /gtk3/extraConfig/gtk-application-prefer-dark-theme $cfg.prefer_dark
    # hyprctl setcursor $cfg.cursor_to 24
    (try { hyprctl setcursor $cfg.cursor_to 24 } catch { })

    open $helix_config | update theme $cfg.helix | save --force $helix_config
    file-replace $rofi_config "theme" $cfg.rofi_from $cfg.rofi_to
    open $clipse_config | update themeFile $cfg.clipse | to json | save --raw --force $clipse_config
    file-replace $niri_config "xcursor-theme" $cfg.cursor_from $cfg.cursor_to
}

let current = (get-gnome-color-scheme)
let next = if $current == "'prefer-light'" { "Dark" } else { "Light" }
set-gnome-themes $next
