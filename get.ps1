# TechDevGroup RuneLite plugin sideload installer.
# Usage (PowerShell):  irm https://raw.githubusercontent.com/TechDevGroup/runelite-rect-overlay/dist/get.ps1 | iex
# Downloads the latest release jar of each plugin repo below into the RuneLite
# sideload directory and ensures the launcher passes --developer-mode (which
# sideloading requires). Re-run any time to update to the latest releases.
# Highlight-only plugins; nothing here automates gameplay input.

$repos = @(
  'TechDevGroup/runelite-blast-furnace-helper',
  'TechDevGroup/runelite-rect-overlay',
  'TechDevGroup/runelite-guide-chain'
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
# The launcher's "Client arguments" live in settings.json (config.json is only the JVM bootstrap).
$settings = Join-Path $env:LOCALAPPDATA 'RuneLite\settings.json'
if (Test-Path $settings) {
  try {
    $j = Get-Content $settings -Raw | ConvertFrom-Json
    $cur = [string]$j.clientArguments
    if ($cur -notlike '*--developer-mode*') {
      $newVal = if ($cur) { "$cur --developer-mode" } else { '--developer-mode' }
      if ($j.PSObject.Properties.Name -contains 'clientArguments') { $j.clientArguments = $newVal }
      else { $j | Add-Member -NotePropertyName clientArguments -NotePropertyValue $newVal }
      $j | ConvertTo-Json -Depth 16 | Set-Content $settings -Encoding UTF8
      Write-Host "launcher settings: added --developer-mode to clientArguments"
    } else {
      Write-Host "launcher settings: --developer-mode already set"
    }
  } catch {
    Write-Host "couldn't patch $settings - set Client arguments to --developer-mode in the launcher (gear icon)"
  }
} else {
  Write-Host "no launcher settings.json yet - open the RuneLite launcher once, or set Client arguments to --developer-mode via its gear icon"
}
Write-Host "done. restart RuneLite, then search the plugin list (wrench icon) for the plugin name."
