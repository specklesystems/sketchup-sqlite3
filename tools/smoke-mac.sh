#!/usr/bin/env bash
set -euo pipefail

bundle=${1:?usage: $0 <path to sqlite3_NN.bundle>}
prefix=$(ruby -rrbconfig -e 'print RbConfig::CONFIG["prefix"]')

lipo -info "$bundle"
codesign --verify --strict --verbose "$bundle"
deps=$(otool -L "$bundle" | tail -n +2)
echo "$deps"
if grep -E 'Ruby\.framework|libruby' <<< "$deps" || grep -F "$prefix" <<< "$deps"; then
  echo "$bundle must resolve Ruby from the host process, not link it" >&2
  exit 1
fi

before=$(shasum -a 256 "$bundle")
ruby "$(dirname "$0")/smoke.rb" "$bundle"
after=$(shasum -a 256 "$bundle")
echo "$after"
[ "$before" = "$after" ] || { echo "$bundle changed during the smoke test" >&2; exit 1; }
