#!/usr/bin/env bash
# Runs the launcher against a fake jar served from a file:// URL and a fake java that prints what it was given:
# it fetches once and keeps the jar, refuses a jar whose sha256 is not the pinned one, and says nothing on stdout but
# what Java says. On Windows (Git Bash) it runs botmaker-mcp.cmd too.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }

windows=false
case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) windows=true ;; esac
native() { if $windows; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
url_of() { if $windows; then printf 'file:///%s' "$(cygpath -m "$1")"; else printf 'file://%s' "$1"; fi; }

printf 'not really a jar' >"$work/served.jar"
if command -v sha256sum >/dev/null; then good=$(sha256sum "$work/served.jar" | cut -d' ' -f1)
else good=$(shasum -a 256 "$work/served.jar" | cut -d' ' -f1)
fi

# A copy of the plugin whose cli.json pins the served jar with the given sha256.
plugin_pinning() {
  local dir=$work/plugin-$1
  rm -rf "$dir"
  cp -r "$root/plugins/botmaker" "$dir"
  printf '{\n  "version": "9.9.9",\n  "url": "%s",\n  "sha256": "%s"\n}\n' "$(url_of "$work/served.jar")" "$1" \
    >"$dir/cli.json"
  printf '%s' "$dir"
}

cat >"$work/java" <<'EOF'
#!/bin/sh
echo "java $*"
EOF
chmod +x "$work/java"
printf '@echo off\r\necho java %%*\r\n' >"$work/java.cmd"

# run <launcher> <plugin dir> <cache dir> -> stdout in $work/out, stderr in $work/err, exit status in $status
run() {
  local launcher=$1 plugin=$2 cache=$3 java=$work/java
  status=0
  if [[ $launcher == cmd ]]; then
    CLAUDE_PLUGIN_DATA=$(native "$cache") BOTMAKER_JAVA=$(native "$work/java.cmd") \
      cmd //c "$(native "$plugin/bin/botmaker-mcp.cmd")" --quiet </dev/null >"$work/out" 2>"$work/err" || status=$?
  else
    CLAUDE_PLUGIN_DATA=$cache BOTMAKER_JAVA=$java \
      sh "$plugin/bin/botmaker-mcp" --quiet </dev/null >"$work/out" 2>"$work/err" || status=$?
  fi
  tr -d '\r' <"$work/out" >"$work/out.lf"
}

check_launcher() {
  local launcher=$1 cache=$work/cache-$1
  local plugin
  plugin=$(plugin_pinning "$good")

  run "$launcher" "$plugin" "$cache"
  local jar=$cache/botmaker-cli-9.9.9-all.jar
  [[ $status == 0 ]] || fail "$launcher: first run exited $status: $(cat "$work/err")"
  [[ -f $jar ]] || fail "$launcher: the jar is not kept in the cache"
  grep -q -- "-jar .*botmaker-cli-9.9.9-all.jar\"\? mcp-bridge --quiet" "$work/out.lf" \
    || fail "$launcher: java was not run as -jar <jar> mcp-bridge <args>: $(cat "$work/out.lf")"
  (($(wc -l <"$work/out.lf") == 1)) || fail "$launcher: stdout carries more than Java's output: $(cat "$work/out.lf")"
  grep -q "fetching botmaker cli 9.9.9" "$work/err" || fail "$launcher: the fetch is not said on stderr"

  [[ $(tr -d '\r\n' <"$jar.sha256") == "$good" ]] || fail "$launcher: the checked jar has no .sha256 beside it"

  rm "$work/served.jar"
  run "$launcher" "$plugin" "$cache"
  [[ $status == 0 ]] || fail "$launcher: the kept jar was fetched again: $(cat "$work/err")"
  printf 'not really a jar' >"$work/served.jar"

  printf 'old' >"$cache/botmaker-cli-1.0.0-all.jar"
  rm "$jar.sha256"
  run "$launcher" "$plugin" "$cache"
  [[ $status == 0 && -f $jar.sha256 ]] || fail "$launcher: a jar with no .sha256 was not fetched again"
  [[ ! -e $cache/botmaker-cli-1.0.0-all.jar ]] || fail "$launcher: a fetch left another version's jar"

  rm -rf "$cache"
  plugin=$(plugin_pinning "0000000000000000000000000000000000000000000000000000000000000000")
  run "$launcher" "$plugin" "$cache"
  [[ $status != 0 ]] || fail "$launcher: a jar whose sha256 differs from the pin was run"
  [[ ! -s $work/out.lf ]] || fail "$launcher: a refusal wrote to stdout: $(cat "$work/out.lf")"
  grep -q "not running it" "$work/err" || fail "$launcher: the refusal does not say why: $(cat "$work/err")"
  [[ -z $(ls "$cache" 2>/dev/null) ]] || fail "$launcher: a refused download was left in the cache: $(ls "$cache")"
}

check_launcher sh
if $windows; then check_launcher cmd; fi

if ((failures)); then
  echo "$failures failure(s)" >&2
  exit 1
fi
echo "launcher-test: ok ($($windows && echo "sh and cmd" || echo "sh"))"
