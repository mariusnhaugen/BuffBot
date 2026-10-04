#!/usr/bin/env bash
# Copies the addon into the WoW Forever client's AddOns folder from WSL.
# Run again after each change, then /reload in game (restart the client
# for new files or TOC changes). Override the target with WOW_ADDONS.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
addons="${WOW_ADDONS:-/mnt/c/Program Files (x86)/World of Warcraft/_classic_beta_/Interface/AddOns}"

if [ ! -d "$addons" ]; then
    echo "AddOns folder not found: $addons" >&2
    exit 1
fi

rsync -a --delete \
    --exclude .git --exclude .github --exclude tests \
    --exclude .busted --exclude .luacheckrc --exclude .gitignore \
    --exclude TESTING.md --exclude deploy.sh \
    "$src/" "$addons/BuffBot/"

echo "Deployed to $addons/BuffBot"
