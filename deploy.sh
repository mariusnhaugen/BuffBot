#!/usr/bin/env bash
# Copies the addon into the WoW Forever client's AddOns folder from WSL.
# Run again after each change, then /reload in game (restart the client
# for new files or TOC changes). Override the target with WOW_ADDONS.
#
# It goes in its own folder, BuffBot_Dev, so the BuffBot folder stays
# CurseForge's. The game only loads a TOC named after its folder, so the TOC
# is copied as BuffBot_Dev.toc, titled "BuffBot (dev)". Both copies use the
# same globals: enable only one of them in the AddOns list.
#
# Only the files the game loads are copied: the TOC, the files it lists,
# and Bindings.xml, which the game loads by name. Anything else in the
# BuffBot_Dev folder is removed.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
addons="${WOW_ADDONS:-/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns}"
folder="BuffBot_Dev"
dest="$addons/$folder"

if [ ! -d "$addons" ]; then
    echo "AddOns folder not found: $addons" >&2
    exit 1
fi

files=(BuffBot.toc Bindings.xml)
while IFS= read -r line; do
    line="${line%$'\r'}"
    [[ -z "$line" || "$line" == "#"* ]] && continue
    files+=("$line")
done < "$src/BuffBot.toc"

includes=()
for file in "${files[@]}"; do
    if [ ! -f "$src/$file" ]; then
        echo "Missing file listed for deploy: $file" >&2
        exit 1
    fi
    includes+=(--include "/$file")
done

rsync -a --delete --delete-excluded "${includes[@]}" --exclude '*' \
    "$src/" "$dest/"

sed 's/^## Title: BuffBot /## Title: BuffBot (dev) /' "$dest/BuffBot.toc" > "$dest/$folder.toc"
rm "$dest/BuffBot.toc"

echo "Deployed ${#files[@]} files to $dest"
