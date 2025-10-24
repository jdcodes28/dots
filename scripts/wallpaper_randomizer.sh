#!/bin/bash

WALLPAPER_DIR=~/Pictures/Wallpapers
INTERVAL=900
WALLPAPER_DIR="${WALLPAPER_DIR/#\~/$HOME}"

kill_swaybg() {
    pkill -9 swaybg 2>/dev/null
}

set_random_wallpaper() {
    local dir="$1"
    
    kill_swaybg
    find "$dir" -maxdepth 1 -type f -print0 | shuf -z -n 1 | xargs -0 -I {} sh -c 'swaybg -i "{}" -m stretch -o "*" &'
    
    sleep 0.5
}

main() {
    while true; do
        set_random_wallpaper "$WALLPAPER_DIR"
        sleep "$INTERVAL"
    done
}

main
