#!/usr/bin/env bash
# Copies the addon into the WoW Forever client's AddOns folder from WSL.
# Run again after each change, then /reload in game (restart the client
# for new files or TOC changes). Override the target with WOW_ADDONS.
#
# Only the files the game loads are copied: the TOC, the files it lists,
# and Bindings.xml, which the game loads by name. Anything else in the
# AddOns folder is removed.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
addons="${WOW_ADDONS:-/mnt/c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns}"

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
    "$src/" "$addons/BuffBot/"

echo "Deployed ${#files[@]} files to $addons/BuffBot"
