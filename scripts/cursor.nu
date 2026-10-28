#!/usr/bin/env nu
use ./utils.nu *

let config_dir = $"($env.HOME)/dots/configs"
let current_gnome_mode = (get-gnome-color-scheme)
let niri_config = $"($config_dir)/niri/config.kdl"
let dark = "Bibata-Modern-Ice"
let light = "Bibata-Modern-Classic"

if $current_gnome_mode == "'prefer-light'" {
  (try { hyprctl setcursor $light 24 } catch { })
  file-replace $niri_config "xcursor-theme" $dark $light
  sleep 2sec
  noctalia msg theme-mode-set light
} else {
  (try { hyprctl setcursor $dark 24 } catch { })
  file-replace $niri_config "xcursor-theme" $light $dark
  sleep 2sec
  noctalia msg theme-mode-set dark
}
