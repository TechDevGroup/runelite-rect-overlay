# TechDevGroup RuneLite plugin sideload installer.
# Usage (PowerShell):  irm https://raw.githubusercontent.com/TechDevGroup/runelite-rect-overlay/dist/get.ps1 | iex
# Downloads the latest release jar of each plugin repo below into the RuneLite
# sideload directory and ensures the launcher passes --developer-mode (which
# sideloading requires). Re-run any time to update to the latest releases.
# Highlight-only plugins; nothing here automates gameplay input.

$repos = @(
  'TechDevGroup/runelite-blast-furnace-helper',
  'TechDevGroup/runelite-rect-overlay'
)

$dir = Join-Path $env:USERPROFILE '.runelite\sideloaded-plugins'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Write-Host "sideload dir: $dir"

foreach ($repo in $repos) {
  $name = ($repo -split '/')[1]
  try {
    $rel = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -ErrorAction Stop
  } catch {
    Write-Host "[$name] no release yet - skipped"
    continue
  }
  $asset = $rel.assets | Where-Object { $_.name -like '*.jar' } | Select-Object -First 1
  if (-not $asset) { Write-Host "[$name] release has no jar - skipped"; continue }
  Get-ChildItem $dir -Filter "$name*.jar" -ErrorAction SilentlyContinue | Remove-Item -Force
  $dest = Join-Path $dir "$name-$($rel.tag_name).jar"
  Invoke-WebRequest $asset.browser_download_url -OutFile $dest
  Write-Host "[$name] installed $($rel.tag_name) -> $dest"
}

# Ensure the launcher starts the client with --developer-mode (required for sideloading).
$cfg = Join-Path $env:LOCALAPPDATA 'RuneLite\config.json'
if (Test-Path $cfg) {
  try {
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    $cliArgs = @($j.clientArguments)
    if ($cliArgs -notcontains '--developer-mode') {
      $j.clientArguments = @($cliArgs + '--developer-mode' | Where-Object { $_ })
      $j | ConvertTo-Json -Depth 16 | Set-Content $cfg -Encoding UTF8
      Write-Host "launcher config: added --developer-mode"
    } else {
      Write-Host "launcher config: --developer-mode already set"
    }
  } catch {
    Write-Host "couldn't patch $cfg - add --developer-mode to Client arguments in the launcher settings"
  }
} else {
  Write-Host "launcher config not found - add --developer-mode to Client arguments in the launcher settings (gear icon on the launcher)"
}
Write-Host "done. restart RuneLite, then search the plugin list (wrench icon) for the plugin name."
