#!/usr/bin/env nu

def get-gnome-color-scheme [] {
  dconf read /org/gnome/desktop/interface/color-scheme | str trim
}

let current_gnome_mode = (get-gnome-color-scheme)

if $current_gnome_mode == "'prefer-light'" {
  hyprctl setcursor catppuccin-mocha-dark-cursors 24
} else {
  hyprctl setcursor catppuccin-latte-light-cursors 24
}
