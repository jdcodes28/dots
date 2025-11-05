#!/bin/bash

WALLPAPER_DIR=~/Pictures/Wallpapers
INTERVAL=900
USED_LIST="~/.cache/used_wallpapers.txt"
WALLPAPER_DIR="${WALLPAPER_DIR/#\~/$HOME}"

kill_swaybg() {
    pkill -9 swaybg 2>/dev/null
}

get_all_wallpapers() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f
}

get_unused_wallpaper() {
    local dir="$1"

    touch "$USED_LIST"

    local all_wallpapers=$(get_all_wallpapers "$dir")
    local total_count=$(echo "$all_wallpapers" | wc -l)
    local unused=$(comm -23 <(echo "$all_wallpapers" | sort) <(sort "$USED_LIST"))
    local unused_count=$(echo "$unused" | grep -c '^')

    if [ -z "$unused" ] || [ "$unused_count" -eq 0 ]; then
        unused="$all_wallpapers"
        unused_count="$total_count"
    fi
}

set_random_wallpaper() {
    local dir="$1"

    kill_swaybg

    local wallpaper=$(get_unused_wallpaper "$dir")

    if [ -z "$wallpaper" ]; then
        return 1
    fi

    echo "$wallpaper" >> "$USED_LIST"
    swaybg -i "$wallpaper" -m stretch -o "*" &
    sleep 0.25
}

main() {
    while true; do
        set_random_wallpaper "$WALLPAPER_DIR"
        sleep "$INTERVAL"
    done
}

main
