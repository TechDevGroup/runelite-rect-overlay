# TechDevGroup RuneLite setup + diagnostics — run NON-elevated in normal PowerShell:
#   irm https://raw.githubusercontent.com/TechDevGroup/runelite-rect-overlay/dist/setup.ps1 | iex
# Installs the plugin jars, sets --developer-mode, then prints a REPORT block.
# Copy the whole REPORT back to the assistant so it can drive the next step.
# User-scope only (no admin); reads logs read-only. Highlight-only plugins.

$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$rl   = Join-Path $env:USERPROFILE '.runelite'
$dir  = Join-Path $rl 'sideloaded-plugins'
$repos = @(
  'TechDevGroup/runelite-guide-chain',
  'TechDevGroup/runelite-blast-furnace-helper',
  'TechDevGroup/runelite-rect-overlay'
)
$report = New-Object System.Collections.Generic.List[string]
function R($s){ $report.Add($s); Write-Host $s }

New-Item -ItemType Directory -Force -Path $dir | Out-Null
R "== TechDevGroup RuneLite setup report =="
R "host: $($env:COMPUTERNAME)  user: $($env:USERNAME)  ps: $($PSVersionTable.PSVersion)"
R "sideload dir: $dir"

# 1. install latest release jar per repo (skip standalone jars)
foreach ($repo in $repos) {
  $name = ($repo -split '/')[1]
  try { $rel = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -Headers @{'User-Agent'='td-setup'} -ErrorAction Stop }
  catch { R "[$name] no release / fetch failed: $($_.Exception.Message)"; continue }
  $asset = $rel.assets | Where-Object { $_.name -like '*.jar' -and $_.name -notlike '*standalone*' } | Select-Object -First 1
  if (-not $asset) { R "[$name] release $($rel.tag_name) has no plugin jar"; continue }
  Get-ChildItem $dir -Filter "$name*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force
  $dest = Join-Path $dir "$name-$($rel.tag_name).jar"
  try { Invoke-WebRequest $asset.browser_download_url -OutFile $dest -Headers @{'User-Agent'='td-setup'} -ErrorAction Stop
        R "[$name] installed $($rel.tag_name) ($((Get-Item $dest).Length) bytes)" }
  catch { R "[$name] download failed: $($_.Exception.Message)" }
}

# 2. ensure --developer-mode in launcher settings.json (client arguments)
$settings = Join-Path $env:LOCALAPPDATA 'RuneLite\settings.json'
if (Test-Path $settings) {
  try {
    $j = Get-Content $settings -Raw | ConvertFrom-Json
    $cur = [string]$j.clientArguments
    if ($cur -notlike '*--developer-mode*') {
      $val = if ($cur) { "$cur --developer-mode" } else { '--developer-mode' }
      if ($j.PSObject.Properties.Name -contains 'clientArguments') { $j.clientArguments = $val }
      else { $j | Add-Member -NotePropertyName clientArguments -NotePropertyValue $val }
      $j | ConvertTo-Json -Depth 16 | Set-Content $settings -Encoding UTF8
      R "launcher: added --developer-mode (was: '$cur')"
    } else { R "launcher: --developer-mode already set" }
  } catch { R "launcher: FAILED to patch $settings — $($_.Exception.Message)" }
} else { R "launcher: no settings.json (open the launcher once, or set Client arguments via its gear icon)" }

# 3. diagnostics
R "-- installed jars --"
Get-ChildItem $dir -Filter *.jar -ErrorAction SilentlyContinue | ForEach-Object { R ("  {0}  {1}b" -f $_.Name,$_.Length) }
R "-- launcher clientArguments --"
if (Test-Path $settings) { R ("  " + ([string]((Get-Content $settings -Raw | ConvertFrom-Json).clientArguments))) }
$log = Join-Path $rl 'logs\client.log'
if (Test-Path $log) {
  R "-- client.log: sideload / errors (last 30) --"
  Select-String -Path $log -Pattern 'Side loading|sideload|developer|Exception|ERROR|Rect Overlay|Blast Furnace|Guide Chain' -ErrorAction SilentlyContinue |
    Select-Object -Last 30 | ForEach-Object { R ("  " + $_.Line) }
  R ("last client.log write: " + (Get-Item $log).LastWriteTime)
} else { R "client.log not found (client not launched yet)" }
R "== end report =="
R ""
R "NEXT: fully close RuneLite, relaunch it DIRECTLY (not via Jagex Launcher), then re-run this"
R "command once more so the log section shows whether the plugins loaded. Paste the whole report back."

# Sideloading requires assertions (-ea); the official launcher build only scans
# ~/.runelite/sideloaded-plugins when the client JVM has -ea. --developer-mode alone
# is NOT enough (it enables dev tools, not the sideload scan). Set it in settings.json.
$settings = Join-Path $env:LOCALAPPDATA 'RuneLite\settings.json'
if (Test-Path $settings) {
  try {
    $s = Get-Content $settings -Raw | ConvertFrom-Json
    $ja = @($s.jvmArguments)
    if ($ja -notcontains '-ea') {
      $ja = @($ja + '-ea' | Where-Object { $_ })
      if ($s.PSObject.Properties.Name -contains 'jvmArguments') { $s.jvmArguments = $ja }
      else { $s | Add-Member -NotePropertyName jvmArguments -NotePropertyValue $ja }
      $s | ConvertTo-Json -Depth 16 | Set-Content $settings -Encoding UTF8
      Write-Host "launcher settings: added -ea to jvmArguments (required for sideloading)"
    } else { Write-Host "launcher settings: -ea already set" }
  } catch { Write-Host "couldn't patch jvmArguments in $settings - add -ea via the launcher's JVM arguments field" }
}
