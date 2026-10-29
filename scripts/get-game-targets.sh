#!/usr/bin/env bash
set -euo pipefail

toc_file="${1:-}"

if [[ -z "$toc_file" || ! -f "$toc_file" ]]; then
    printf 'Usage: %s <addon.toc>\n' "$0" >&2
    exit 2
fi

target_line="$(tr -d '\r' < "$toc_file" | sed -nE 's/^[[:space:]]*##[[:space:]]*X-WoWAddonTooling-Targets:[[:space:]]*([^[:space:]].*)$/\1/p' | head -n 1)"

if [[ -z "$target_line" ]]; then
    printf 'No X-WoWAddonTooling-Targets metadata found in %s\n' "$toc_file" >&2
    exit 2
fi

target_line="${target_line//,/ }"
targets=()
for target in $target_line; do
    case "$target" in
        retail|classic|bcc|wrath|cata|mists)
            targets+=("$target")
            ;;
        *)
            printf 'Unsupported game target "%s" in %s\n' "$target" "$toc_file" >&2
            exit 2
            ;;
    esac
done

if [[ "${#targets[@]}" -eq 0 ]]; then
    printf 'No game targets configured in %s\n' "$toc_file" >&2
    exit 2
fi

printf '%s\n' "${targets[@]}"
