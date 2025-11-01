#!/usr/bin/env nu
use ./utils.nu *

let config_dir = $"($env.HOME)/dots/configs"
let current_gnome_mode = (get-gnome-color-scheme)
let niri_config = $"($config_dir)/niri/config.kdl"

if $current_gnome_mode == "'prefer-light'" {
  (try { hyprctl setcursor catppuccin-mocha-dark-cursors 24 } catch { })
  file-replace $niri_config "xcursor-theme" "catpuccin-latte-light-cursors" "catppuccin-mocha-dark-cursors"
} else {
  (try { hyprctl setcursor catppuccin-latte-light-cursors 24 } catch { })
  file-replace $niri_config "xcursor-theme" "catpuccin-mocha-dark-cursors" "catppuccin-latte-light-cursors"
}
