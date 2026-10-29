#!/usr/bin/env bash
set -euo pipefail

if ! command -v wowlua >/dev/null 2>&1; then
    printf 'wowlua is required for Lua syntax validation.\n' >&2
    exit 2
fi

mapfile -d '' lua_files < <(
    find . \
        -type d \( -name .git -o -name addon-tooling -o -name packager -o -name .release \) -prune \
        -o -type f -name '*.lua' -print0
)

if [[ "${#lua_files[@]}" -eq 0 ]]; then
    printf 'No Lua source files found.\n' >&2
    exit 2
fi

for source in "${lua_files[@]}"; do
    printf 'Checking %s\n' "$source"
    wowlua compile "$source" --no-bundle >/dev/null
done
