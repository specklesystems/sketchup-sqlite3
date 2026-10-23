#!/usr/bin/env bash
set -euo pipefail

version=${1:?usage: $0 <ruby-major.minor>, e.g. 3.4}
repo=$(git rev-parse --show-toplevel)

xcodebuild -project "$repo/sqlite3.xcodeproj" -target "Ruby $version" -configuration Release build

out="$repo/Release ($version)/sqlite3_${version//./}.bundle"
cp "$repo/Release ($version)/sqlite3.bundle" "$out"
echo "$out"
