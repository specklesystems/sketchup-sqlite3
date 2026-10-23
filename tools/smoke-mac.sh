#!/usr/bin/env bash
# The bundle links SketchUp's Ruby.framework through an install name that only
# resolves inside SketchUp.app, so the smoke loads a copy rebound to the
# running interpreter's libruby. The built bundle itself is left untouched.
set -euo pipefail

bundle=${1:?usage: $0 <path to sqlite3_NN.bundle>}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

lipo -info "$bundle"
otool -L "$bundle"

copy="$tmp/$(basename "$bundle")"
cp "$bundle" "$copy"
framework=$(otool -L "$copy" | awk '/Ruby\.framework/ {print $1}')
libruby=$(ruby -rrbconfig -e 'puts File.join(RbConfig::CONFIG["libdir"], RbConfig::CONFIG["LIBRUBY_SO"])')
[ -n "$framework" ] || { echo "$bundle does not link Ruby.framework" >&2; exit 1; }
[ -f "$libruby" ] || { echo "running ruby has no shared libruby at $libruby" >&2; exit 1; }

install_name_tool -change "$framework" "$libruby" "$copy"
codesign --force --sign - "$copy"
ruby "$(dirname "$0")/smoke.rb" "$copy"
