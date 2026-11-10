#!/usr/bin/env bash
# The pin names a released cli: its url serves the jar cli.json's sha256 names, of the version it names. Needs the
# network; CI runs it.
set -euo pipefail

cli=$(cd "$(dirname "$0")/.." && pwd)/plugins/botmaker/cli.json
pinned() { sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$cli"; }
version=$(pinned version)
url=$(pinned url)
sha=$(pinned sha256)

[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "FAIL: cli.json's version $version is no release" >&2; exit 1; }
[[ $url == *"/v$version/"*"-all.jar" ]] || { echo "FAIL: cli.json's url does not name v$version's all jar: $url" >&2; exit 1; }

jar=$(mktemp)
trap 'rm -f "$jar"' EXIT
curl -fsSL --retry 3 -o "$jar" "$url"
got=$(sha256sum "$jar" | cut -d' ' -f1)
[[ $got == "$sha" ]] || { echo "FAIL: $url has sha256 $got, cli.json pins $sha" >&2; exit 1; }
echo "pin-test: ok (botmaker cli $version)"
