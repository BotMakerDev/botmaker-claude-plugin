@echo off
rem BotMaker's MCP server for Claude Code on Windows: botmaker-mcp.ps1 fetches and checks the pinned cli jar and
rem picks Java; this file runs them, so stdin and stdout, the MCP protocol, go straight to Java. PowerShell gets NUL
rem for stdin, so it cannot read the client's first request or wait on the open pipe.
setlocal
set "BM_JAVA="
set "BM_JAR="
for /f "usebackq delims=" %%L in (`powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0botmaker-mcp.ps1" ^<NUL`) do (
  if not defined BM_JAVA (set "BM_JAVA=%%L") else set "BM_JAR=%%L"
)
if not defined BM_JAR exit /b 1
"%BM_JAVA%" -jar "%BM_JAR%" mcp-bridge %*
