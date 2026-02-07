#!/usr/bin/env nu
use ./utils.nu *

let config_dir = $"($env.HOME)/dots/configs"
let current_gnome_mode = (get-gnome-color-scheme)
let niri_config = $"($config_dir)/niri/config.kdl"
let dark = "catppuccin-latte-light-cursors"
let light = "catppuccin-mocha-dark-cursors"

if $current_gnome_mode == "'prefer-light'" {
  (try { hyprctl setcursor $light 24 } catch { })
  file-replace $niri_config "xcursor-theme" $dark $light
} else {
  (try { hyprctl setcursor $dark 24 } catch { })
  file-replace $niri_config "xcursor-theme" $light $dark
}
