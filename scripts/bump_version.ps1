# ─────────────────────────────────────────────────────────────────────────────
# bump_version.ps1
#
# Usage:
#   .\scripts\bump_version.ps1            # increments build number only
#   .\scripts\bump_version.ps1 -patch     # 1.0.0 → 1.0.1, resets build to 1
#   .\scripts\bump_version.ps1 -minor     # 1.0.0 → 1.1.0, resets build to 1
#   .\scripts\bump_version.ps1 -major     # 1.0.0 → 2.0.0, resets build to 1
#   .\scripts\bump_version.ps1 -set 1.2.3+45   # set exact version
#
# Syncs pubspec.yaml version (used by flutter.versionCode + versionName in Gradle)
# ─────────────────────────────────────────────────────────────────────────────

param(
    [switch]$major,
    [switch]$minor,
    [switch]$patch,
    [string]$set = ""
)

$pubspecPath = Join-Path $PSScriptRoot "..\pubspec.yaml"
$content     = Get-Content $pubspecPath -Raw

# Parse current version line: version: X.Y.Z+B
if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $verMajor = [int]$Matches[1]
    $verMinor = [int]$Matches[2]
    $verPatch = [int]$Matches[3]
    $buildNum = [int]$Matches[4]
} else {
    Write-Error "Could not parse version from pubspec.yaml"
    exit 1
}

$oldVersion = "$verMajor.$verMinor.$verPatch+$buildNum"

if ($set -ne "") {
    # --set mode: validate and use directly
    if ($set -notmatch '^\d+\.\d+\.\d+\+\d+$') {
        Write-Error "Invalid format. Use: major.minor.patch+buildNumber  e.g. 1.2.3+45"
        exit 1
    }
    $newVersion = $set
} elseif ($major) {
    $newVersion = "$($verMajor + 1).0.0+1"
} elseif ($minor) {
    $newVersion = "$verMajor.$($verMinor + 1).0+1"
} elseif ($patch) {
    $newVersion = "$verMajor.$verMinor.$($verPatch + 1)+1"
} else {
    # Default: increment build number only
    $newVersion = "$verMajor.$verMinor.$verPatch+$($buildNum + 1)"
}

# Write back
$newContent = $content -replace "version:\s*$([regex]::Escape($oldVersion))", "version: $newVersion"
Set-Content $pubspecPath $newContent -NoNewline

Write-Host "Version bumped: $oldVersion  →  $newVersion" -ForegroundColor Green
