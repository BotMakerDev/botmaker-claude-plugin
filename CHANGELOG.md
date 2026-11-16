# Changelog

All notable changes to `botmaker-claude-plugin`.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this repository uses
[semantic versioning](https://semver.org/).

## [Unreleased]

### Changed

- Licensed under PolyForm Noncommercial 1.0.0, copyright LiQiyeDev: free for any noncommercial use, commercial use
  needs a license from LiQiyeDev. Copies taken before stay CC0 1.0.

### Added

- The `botmaker` marketplace with the `botmaker` plugin. Its MCP server runs the botmaker cli's `mcp-bridge`, pinned
  to cli 0.12.0 by version and sha256, and fetched from JitPack into the plugin's data folder.
- `tests/launcher-test.sh` (sh and Windows launchers), `tests/pin-test.sh`, `tools/move-pin.sh`, and the `check`
  and `follow-cli` workflows.
- The README names the cli's other ways in, `botmaker ai <tool>` and `botmaker mcp install <tool>`: the same MCP
  server for Codex, opencode and Gemini CLI, and a guarded Claude Code session in a bot's folder.
