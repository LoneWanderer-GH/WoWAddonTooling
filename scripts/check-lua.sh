#!/usr/bin/env bash
set -euo pipefail

WOWLUA_BIN="${WOWLUA_BIN:-wowlua}"
if ! command -v "$WOWLUA_BIN" >/dev/null 2>&1; then
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

output_dir="$(mktemp -d "${TMPDIR:-/tmp}/wowaddon-wowlua.XXXXXX")"
trap 'rm -rf "$output_dir"' EXIT

printf 'Checking %d Lua file(s) with wowlua\n' "${#lua_files[@]}"
"$WOWLUA_BIN" compile "${lua_files[@]}" --no-bundle --out "$output_dir"
