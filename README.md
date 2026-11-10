# BotMaker for Claude Code

A Claude Code marketplace with one plugin, `botmaker`: BotMaker's MCP tools in any Claude Code session. They cover
your bots and their runs, and the Android emulators on this computer (`device`: list, start, install, screenshot,
tap…). They work with or without BotMaker Studio open.

## Install

```
claude plugin marketplace add BotMakerDev/botmaker-claude-plugin
claude plugin install botmaker@botmaker
```

Or inside a session: `/plugin marketplace add BotMakerDev/botmaker-claude-plugin`, then `/plugin install botmaker@botmaker`.

You need **Java 25 or newer**. The launcher uses `$BOTMAKER_JAVA`, then `$JAVA_HOME`, then `java` on `PATH`.

## What it runs

`plugins/botmaker/bin/botmaker-mcp` (on Windows `botmaker-mcp.cmd`, which `botmaker-mcp.ps1` helps):

1. Reads the botmaker cli release that `plugins/botmaker/cli.json` pins: its version, JitPack url and sha256.
2. Downloads that jar into the plugin's data folder (`$CLAUDE_PLUGIN_DATA`), but only when the jar is missing or
   its sha256 differs. A jar whose sha256 is not the pinned one is never run.
3. Runs `java -jar <jar> mcp-bridge`.

The bridge forwards to BotMaker's core on this computer and starts the core when none is running. Set
`$BOTMAKER_UMBRELLA` to a BotMaker checkout to start the core from that checkout when no Studio has run.

## Development

- `bash tests/launcher-test.sh`: both launchers, against a fake jar and a fake java (the `.cmd` on Windows only).
- `bash tests/pin-test.sh`: the pin names a released cli (needs the network).
- `bash tools/move-pin.sh [version]`: pins a cli release. The `follow-cli` workflow runs it every day and opens a
  pull request.
- `claude plugin validate .` and `claude plugin validate ./plugins/botmaker`.
- To try a local change: `claude plugin marketplace add ./botmaker-claude-plugin`, then install as above.
