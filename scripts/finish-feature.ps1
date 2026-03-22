param([string]$FeatureId)
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FeaturesDir = Join-Path $RootDir 'features'
$LatestFile = Join-Path $FeaturesDir 'latest.txt'
$LastRunFile = Join-Path $RootDir 'outputs\last-run.md'
function Find-LatestByStatus([string]$Wanted) {
    $latest = $null; $latestNum = -1
    Get-ChildItem -Path $FeaturesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $statusFile = Join-Path $_.FullName 'status.txt'
        if (Test-Path $statusFile) {
            $status = (Get-Content $statusFile -Raw).Trim()
            if ($status -eq $Wanted -and $_.Name -match '^(\d+)-') {
                $num = [int]$matches[1]
                if ($num -gt $latestNum) { $latestNum = $num; $latest = $_.Name }
            }
        }
    }
    return $latest
}
if (-not $FeatureId) { $FeatureId = Find-LatestByStatus 'running' }
if (-not $FeatureId) { $FeatureId = Find-LatestByStatus 'draft' }
if (-not $FeatureId) { Write-Host 'No running or draft feature found.'; exit 1 }
$FeatureDir = Join-Path $FeaturesDir $FeatureId
Set-Content -Path $LatestFile -Value $FeatureId -Encoding UTF8
Set-Content -Path (Join-Path $FeatureDir 'status.txt') -Value 'completed' -Encoding UTF8
@"
# Last Run

## Feature
$FeatureId

## Status
Completed

## Feature Folder
$FeatureDir
"@ | Set-Content -Path $LastRunFile -Encoding UTF8
Write-Output $FeatureId
