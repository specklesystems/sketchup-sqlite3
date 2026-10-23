#!/usr/bin/env bash
# PLATFORM_TOOLSET overrides the project's v143 for hosts that only have a
# newer toolset; release binaries keep v143 so they need no newer VC runtime
# than the one SketchUp ships.
set -euo pipefail

version=${1:?usage: $0 <ruby-major.minor>, e.g. 3.4}
repo=$(git rev-parse --show-toplevel)

vswhere="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
msbuild=$("$vswhere" -latest -prerelease -requires Microsoft.Component.MSBuild -find 'MSBuild\**\Bin\MSBuild.exe' | head -n 1)
[ -n "$msbuild" ] || { echo "MSBuild not found" >&2; exit 1; }

"$(cygpath -u "$msbuild")" "$(cygpath -w "$repo/sqlite3.sln")" -nologo -m -t:Rebuild \
  "-p:Configuration=Release ($version)" -p:Platform=x64 \
  ${PLATFORM_TOOLSET:+"-p:PlatformToolset=$PLATFORM_TOOLSET"}

out="$repo/Release ($version)/x64/sqlite3_${version//./}.so"
[ -f "$out" ] || { echo "missing $out" >&2; exit 1; }
echo "$out"
