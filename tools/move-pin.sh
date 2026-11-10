#!/usr/bin/env bash
# Pins cli.json to botmaker cli <version> (default: the newest release on GitHub): fetches its all jar from JitPack
# and writes the version, url and the jar's sha256. Prints nothing and changes nothing when the pin is already there.
set -euo pipefail

cli=$(cd "$(dirname "$0")/.." && pwd)/plugins/botmaker/cli.json
version=${1:-$(gh release view -R BotMakerDev/botmaker-cli --json tagName -q .tagName)}
version=${version#v}
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "move-pin: $version is no release version" >&2; exit 1; }
grep -q "\"version\": \"$version\"" "$cli" && exit 0

url=https://jitpack.io/com/github/BotMakerDev/botmaker-cli/v$version/botmaker-cli-v$version-all.jar
jar=$(mktemp)
trap 'rm -f "$jar"' EXIT
# JitPack builds a tag on its first request, which can take minutes.
for _ in 1 2 3 4 5 6; do
  curl -fsSL -o "$jar" "$url" && [[ -s $jar ]] && break
  sleep 60
done
[[ -s $jar ]] || { echo "move-pin: JitPack serves no $url" >&2; exit 1; }
unzip -Z1 "$jar" 'com/botmaker/cli/mcp/McpBridge.class' >/dev/null 2>&1 || { echo "move-pin: $url has no mcp-bridge" >&2; exit 1; }

printf '{\n  "version": "%s",\n  "url": "%s",\n  "sha256": "%s"\n}\n' \
  "$version" "$url" "$(sha256sum "$jar" | cut -d' ' -f1)" >"$cli"
echo "botmaker cli $version"
