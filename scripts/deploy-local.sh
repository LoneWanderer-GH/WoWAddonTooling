#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
addon_root="$(cd -- "${script_dir}/../.." && pwd)"

: "${WOW_ROOT_LINUX:?Set WOW_ROOT_LINUX to the WoW install path visible to WSL}"

if [[ ! -x "${addon_root}/addon-tooling/packager/release.sh" ]]; then
    printf 'Missing shared packager. Run: git submodule update --init --recursive\n' >&2
    exit 2
fi

if grep -Eq '^[[:space:]]*externals:[[:space:]]*$' "${addon_root}/.pkgmeta" 2>/dev/null \
    && ! command -v svn >/dev/null 2>&1; then
    printf 'Subversion is required by this addon .pkgmeta. Install it in WSL (for example: sudo apt install subversion).\n' >&2
    exit 2
fi

map_client_dir() {
    local flavor="$1"
    local variable="WOW_CLIENT_DIR_${flavor^^}"
    local configured_dir="${!variable:-}"

    if [[ -n "$configured_dir" ]]; then
        printf '%s\n' "$configured_dir"
        return
    fi

    case "$flavor" in
        retail)  printf '_retail_\n' ;;
        classic) printf '_classic_era_\n' ;;
        bcc)     printf '_classic_\n' ;;
        wrath|cata|mists) printf '_classic_\n' ;;
        *)
            printf 'Unsupported game target "%s"\n' "$flavor" >&2
            return 2
            ;;
    esac
}

toc_file="$(find "${addon_root}" -maxdepth 1 -type f -name '*.toc' -print -quit)"
if [[ -z "$toc_file" ]]; then
    printf 'No addon TOC found in %s\n' "$addon_root" >&2
    exit 2
fi

deployed=0
while IFS= read -r flavor; do
    client_dir="$(map_client_dir "$flavor")"
    addons_dir="${WOW_ROOT_LINUX}/${client_dir}/Interface/AddOns"

    if [[ ! -d "$addons_dir" ]]; then
        printf 'Skipping %s; no AddOns directory at %s\n' "$flavor" "$addons_dir"
        continue
    fi

    printf 'Deploying %s to %s\n' "$flavor" "$addons_dir"
    (
        cd "$addon_root"
        ./addon-tooling/packager/release.sh -r "$addons_dir" -g "$flavor" -d -l -z
    )
    deployed=$((deployed + 1))
done < <("${script_dir}/get-game-targets.sh" "$toc_file")

if [[ "$deployed" -eq 0 ]]; then
    printf 'No supported client was available under %s\n' "$WOW_ROOT_LINUX" >&2
    exit 1
fi
