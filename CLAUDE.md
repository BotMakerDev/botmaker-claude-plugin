# CLAUDE.md — botmaker-claude-plugin

A Claude Code marketplace (`.claude-plugin/marketplace.json`, named `botmaker`) holding the plugin `botmaker`
(`plugins/botmaker/`). The plugin's one MCP server is a launcher for the released botmaker cli's `mcp-bridge`. The
umbrella's `CLAUDE.md` is the map; these are the rules here.

- **Not Maven.** It has no pom, and sluice skips it. Nothing pins it and JitPack never builds it.
- **The launcher pins one cli release** in `cli.json`: version, JitPack url and sha256. It never runs a jar whose
  sha256 differs. Only `tools/move-pin.sh` writes `cli.json`, through the `follow-cli` workflow's pull request or
  by hand. Never edit the sha256 by hand.
- **stdout is the MCP protocol.** The launchers write to stderr only, and Java gets stdin and stdout directly.
  On Windows the `.cmd` runs Java itself and the `.ps1` only resolves the paths, because piping through PowerShell
  would re-encode the stream.
- **Two launchers, one behaviour.** `bin/botmaker-mcp` (sh) and `bin/botmaker-mcp.cmd` + `.ps1` change together, and
  `tests/launcher-test.sh` checks both. `plugin.json` names the extension-less path, and on Windows Claude Code
  finds the `.cmd` beside it by `PATHEXT`. Checked on 2026-11-10 with Claude Code 2.1.322: with the `.cmd` it connects,
  and without it the connection closes.
- A checked jar leaves `<jar>.sha256` beside it, so a later start only compares that file's text with the pin and
  never hashes the jar again. A fetch deletes the jars of other versions.
- `.gitattributes` keeps `.cmd`/`.ps1` CRLF and everything else LF.
- A change goes under `## [Unreleased]` in `CHANGELOG.md`. A release bumps `plugin.json`'s `version`, which is what
  Claude Code compares when it updates a plugin.
