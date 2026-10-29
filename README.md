# WoWAddonTooling

Shared local deployment scripts and reusable GitHub Actions workflows for the
WoW addons maintained under `LoneWanderer-GH`.

## Add this tooling to an addon

Add a custom target list to the addon's root TOC. These targets are build
flavors, not a claim that the current game API has been tested:

```toc
## X-WoWAddonTooling-Targets: classic, bcc
```

Add this repository as a submodule:

```bash
git submodule add https://github.com/LoneWanderer-GH/WoWAddonTooling.git addon-tooling
git -C addon-tooling checkout v1.0.1
git add .gitmodules addon-tooling
```

Initialize it when cloning:

```bash
git clone --recurse-submodules <addon-repository>
# or, in an existing checkout:
git submodule update --init --recursive
```

Use the same reusable workflows in each addon. They read the target list from
the TOC, validate Lua syntax with wowlua and build one package per flavor on
pushes and pull requests. The release workflow publishes on GitHub Release:

```yaml
name: Addon CI

on:
  push:
  pull_request:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  package:
    uses: LoneWanderer-GH/WoWAddonTooling/.github/workflows/addon-ci.yml@v1.0.1
```

```yaml
name: Addon Release

on:
  release:
    types: [published]

permissions:
  contents: read

jobs:
  publish:
    uses: LoneWanderer-GH/WoWAddonTooling/.github/workflows/addon-release.yml@v1.0.1
    secrets: inherit
```

Configure the repository secret `CF_API_KEY` in each addon repository, or use
an organization secret available to all of them. The release workflow maps it
to the current packager variable `CF_API_TOKEN`. The publishing workflow
requires this secret; the pull-request build never receives publishing
credentials. Discord announcements are intentionally left out of the shared
workflow because their destinations and secret availability vary by project.

## Local deployment from WSL

Initialize all submodules, install Bash, Git, and Subversion in WSL as needed,
then set the WSL-visible path to your WoW installation:

```bash
export WOW_ROOT_LINUX="/mnt/i/BattleNet/World of Warcraft"
bash addon-tooling/scripts/deploy-local.sh
```

The script deploys only flavors declared in the TOC and only into client
folders that exist. Defaults are `_retail_` for Retail, `_classic_era_` for
Classic Era, and `_classic_` for Burning Crusade Classic. Override a local
folder name with `WOW_CLIENT_DIR_<FLAVOR>` (for example
`WOW_CLIENT_DIR_CLASSIC=_classic_`). Missing client folders are reported and
skipped; the script fails if it cannot deploy to any supported client.

The package is written directly into the client's `Interface/AddOns` folder.
This is a local development helper, not a test: run `/reload` and verify the
addon in the corresponding game client.

## Updating the shared tooling

Keep local deployment logic and reusable workflow implementation in this
repository. Addon repositories contain only the target metadata, the submodule
gitlink, and thin caller workflows.

For a tooling release:

1. Change and validate the scripts/workflows on a branch.
2. Tag the reviewed commit (for example `v1.1.0`) and push the branch and tag.
3. In each addon repository, update the `addon-tooling` submodule to that tag
   and change the reusable workflow reference to the same tag.
4. Build and verify each configured target before publishing a release.
