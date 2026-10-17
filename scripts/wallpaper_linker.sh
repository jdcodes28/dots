#!/usr/bin/env nix-shell
# nix-shell -i bash -p ffmpeg
# Symlinks wallpapers into per-monitor folders based on resolution.
# Each monitor's folder receives only wallpapers >= its native resolution.

set -u

SOURCE="$HOME/Pictures/Wallpapers/Source"
DEST_BASE="$HOME/Pictures/Wallpapers"
CACHE="$HOME/.cache/wallpaper-link.cache"
LOCK="/tmp/wallpaper-link.lock"

# Format: "folder_name width height"
MONITORS=(
    "4k 3840 2160"
    "2k 2560 1440"
    "1080p 1920 1080"
)

# --- Concurrency guard ---
exec 200>"$LOCK"
flock -n 200 || { echo "Another instance is running. Exiting." >&2; exit 0; }

# --- Sanity checks ---
if [ ! -d "$SOURCE" ]; then
    echo "Source folder $SOURCE does not exist. Aborting." >&2
    exit 1
fi

if [ -z "$(ls -A "$SOURCE" 2>/dev/null)" ]; then
    echo "Source folder $SOURCE is empty. Aborting to avoid wiping symlinks." >&2
    exit 1
fi

if ! command -v ffprobe >/dev/null 2>&1; then
    echo "ffprobe not found. Install ffmpeg." >&2
    exit 1
fi

# --- Setup ---
mkdir -p "$(dirname "$CACHE")"
touch "$CACHE"

for entry in "${MONITORS[@]}"; do
    read -r name _ _ <<< "$entry"
    mkdir -p "$DEST_BASE/$name"
done

# --- Build current file list with mtimes ---
# Cache format: "path|mtime|width|height"
CURRENT=$(mktemp)
CACHED=$(mktemp)
trap 'rm -f "$CURRENT" "$CACHED"' EXIT

find "$SOURCE" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -printf "%p|%T@\n" | awk -F'|' '{ printf "%s|%d\n", $1, $2 }' | sort > "$CURRENT"

# Extract "path|mtime" from cache for comparison
awk -F'|' '{ printf "%s|%s\n", $1, $2 }' "$CACHE" | sort > "$CACHED"

# --- Diff ---
# Removed or modified: in cache but path|mtime not in current
REMOVED=$(comm -23 "$CACHED" "$CURRENT")
# Added or modified: in current but path|mtime not in cache
ADDED=$(comm -13 "$CACHED" "$CURRENT")

# --- Remove stale symlinks ---
if [ -n "$REMOVED" ]; then
    REMOVED_PATHS=$(echo "$REMOVED" | cut -d'|' -f1 | sort -u)
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        for entry in "${MONITORS[@]}"; do
            read -r name _ _ <<< "$entry"
            find "$DEST_BASE/$name" -maxdepth 1 -lname "$f" -delete 2>/dev/null
        done
    done <<< "$REMOVED_PATHS"

    # Drop removed/modified entries from cache
    grep -vFf <(echo "$REMOVED_PATHS") "$CACHE" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
fi

# --- Probe and link new/modified files in parallel ---
if [ -n "$ADDED" ]; then
    total=$(echo "$ADDED" | wc -l)
    echo "Probing $total new/modified file(s)..."

    NEW_CACHE=$(mktemp)
    trap 'rm -f "$CURRENT" "$CACHED" "$NEW_CACHE"' EXIT

    echo "$ADDED" | cut -d'|' -f1 | xargs -P "$(nproc)" -I {} bash -c '
        f="$1"
        [ -z "$f" ] && exit
        mtime=$(stat -c %Y "$f" 2>/dev/null) || exit
        dims=$(ffprobe -v error -select_streams v:0 \
            -show_entries stream=width,height -of default=nw=1:nk=1 "$f" 2>/dev/null | tr "\n" " ")
        [ -z "$dims" ] && exit
        read iw ih <<< "$dims"
        [ -z "$iw" ] || [ -z "$ih" ] && exit
        printf "%s|%s|%s|%s\n" "$f" "$mtime" "$iw" "$ih"
    ' _ {} > "$NEW_CACHE"

    # Append to cache
    cat "$NEW_CACHE" >> "$CACHE"

    # Create symlinks from new cache entries
    linked=0
    while IFS='|' read -r f mtime iw ih; do
        [ -z "$f" ] && continue
        for entry in "${MONITORS[@]}"; do
            read -r name mw mh <<< "$entry"
            if [ "$iw" -ge "$mw" ] && [ "$ih" -ge "$mh" ]; then
                ln -sf "$f" "$DEST_BASE/$name/"
            fi
        done
        linked=$((linked + 1))
    done < "$NEW_CACHE"

    echo "Linked $linked file(s)."
fi

# --- Report ---
if [ -z "$ADDED" ] && [ -z "$REMOVED" ]; then
    echo "No changes."
fi

for entry in "${MONITORS[@]}"; do
    read -r name _ _ <<< "$entry"
    count=$(find "$DEST_BASE/$name" -maxdepth 1 -type l | wc -l)
    echo "$name: $count wallpaper(s)"
done

