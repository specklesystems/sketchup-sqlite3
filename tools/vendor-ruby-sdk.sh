#!/usr/bin/env bash
# Vendors one Ruby version's SketchUp SDK (headers, Windows import library,
# macOS Ruby.framework) from SketchUp/ruby-c-extension-examples at a pinned
# commit, staging the exact upstream blobs and modes so the framework
# symlinks survive a Windows checkout with core.symlinks=false.
set -euo pipefail

SDK_REPO=https://github.com/SketchUp/ruby-c-extension-examples.git
SDK_SHA=7648cf54a6fc92958ec5690aa56f0dc3ba01decd

version=${1:?usage: $0 <ruby-major.minor>, e.g. 3.4}
abi=${version//./}0
paths=(
  "ThirdParty/include/ruby/$version"
  "ThirdParty/lib/win32/x64-ucrt-ruby$abi.lib"
  "ThirdParty/lib/mac/$version"
)

repo=$(git rev-parse --show-toplevel)
sdk=$(mktemp -d)
trap 'rm -rf "$sdk"' EXIT

git -C "$sdk" init -q
git -C "$sdk" sparse-checkout set --no-cone "${paths[@]}"
git -C "$sdk" fetch -q --depth 1 --filter=blob:none "$SDK_REPO" "$SDK_SHA"
git -C "$sdk" -c core.symlinks=false checkout -q FETCH_HEAD

git -C "$sdk" ls-tree -r "$SDK_SHA" -- "${paths[@]}" > "$sdk/tree"
[ -s "$sdk/tree" ] || { echo "no SDK files for Ruby $version at $SDK_SHA" >&2; exit 1; }

while IFS=$'\t' read -r meta path; do
  read -r mode _ blob <<< "$meta"
  stored=$(git -C "$sdk" cat-file blob "$blob" | git -C "$repo" hash-object -w --stdin)
  [ "$stored" = "$blob" ] || { echo "blob mismatch for $path" >&2; exit 1; }
  git -C "$repo" update-index --add --cacheinfo "$mode,$blob,$path"
done < "$sdk/tree"

git -C "$repo" checkout -- "${paths[@]}"

git -C "$repo" ls-files -s -- "${paths[@]}" | awk '{print $1, $2, $4}' > "$sdk/staged"
awk -F'\t' '{split($1, m, " "); print m[1], m[3], $2}' "$sdk/tree" > "$sdk/expected"
diff "$sdk/expected" "$sdk/staged"
echo "vendored $(wc -l < "$sdk/tree") files for Ruby $version from $SDK_SHA"
