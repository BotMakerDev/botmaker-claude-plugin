# botmaker-mcp.cmd's half that PowerShell does well: reads cli.json, fetches the pinned jar into the cache when it is
# missing or its sha256 differs, and picks Java. It prints the java and the jar on two lines for the .cmd, which runs
# them itself so the MCP protocol on stdin and stdout never passes through PowerShell. Errors go to stderr.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Fail([string] $words) {
    [Console]::Error.WriteLine("botmaker-mcp: $words")
    exit 1
}

$pin = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot '..\cli.json') | ConvertFrom-Json
if (-not $pin.version -or -not $pin.url -or -not $pin.sha256) { Fail 'cli.json names no version, url and sha256' }

if ($env:CLAUDE_PLUGIN_DATA) { $cache = $env:CLAUDE_PLUGIN_DATA }
else { $cache = Join-Path $env:LOCALAPPDATA 'BotMaker\.cache\claude-plugin' }
$jar = Join-Path $cache "botmaker-cli-$($pin.version)-all.jar"

function Sha256([string] $file) { (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLowerInvariant() }

# The .sha256 beside the jar is written only after the jar was checked: a start then reads it instead of hashing.
$mark = "$jar.sha256"
$checked = (Test-Path -LiteralPath $jar) -and (Test-Path -LiteralPath $mark) -and
        ((Get-Content -Raw -LiteralPath $mark) -eq $pin.sha256)
if (-not $checked) {
    New-Item -ItemType Directory -Force -Path $cache | Out-Null
    Remove-Item -Force -ErrorAction SilentlyContinue -LiteralPath $mark
    $part = "$jar.part.$PID"
    [Console]::Error.WriteLine("botmaker-mcp: fetching botmaker cli $($pin.version)")
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        (New-Object Net.WebClient).DownloadFile($pin.url, $part)
    } catch {
        Remove-Item -Force -ErrorAction SilentlyContinue -LiteralPath $part
        Fail "could not fetch $($pin.url): $($_.Exception.Message)"
    }
    $got = Sha256 $part
    if ($got -ne $pin.sha256) {
        Remove-Item -Force -LiteralPath $part
        Fail "$($pin.url) has sha256 $got, cli.json pins $($pin.sha256); not running it"
    }
    Move-Item -Force -LiteralPath $part -Destination $jar
    [IO.File]::WriteAllText($mark, $pin.sha256)
    Get-ChildItem -LiteralPath $cache -Filter 'botmaker-cli-*-all.jar*' |
            Where-Object { $_.Name -ne (Split-Path -Leaf $jar) -and $_.Name -ne (Split-Path -Leaf $mark) } |
            Remove-Item -Force
}

if ($env:BOTMAKER_JAVA) { $java = $env:BOTMAKER_JAVA }
elseif ($env:JAVA_HOME -and (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) {
    $java = Join-Path $env:JAVA_HOME 'bin\java.exe'
} else {
    $onPath = Get-Command java -ErrorAction SilentlyContinue
    if (-not $onPath) { Fail 'BotMaker needs Java 25 or newer: install it, or set BOTMAKER_JAVA to its java' }
    $java = $onPath.Source
}

Write-Output $java
Write-Output $jar
