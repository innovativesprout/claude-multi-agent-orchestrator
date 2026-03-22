param(
    [string]$FeatureId
)

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FeaturesDir = Join-Path $RootDir "features"

function Resolve-FeatureId {
    param([string]$Value)

    if ($Value) { return $Value }

    $candidate = $null

    if (Test-Path $FeaturesDir) {
        Get-ChildItem -Path $FeaturesDir -Directory | Sort-Object Name | ForEach-Object {
            $statusFile = Join-Path $_.FullName "status.txt"
            if (Test-Path $statusFile) {
                $status = (Get-Content $statusFile -Raw).Trim()
                if ($status -eq "running") {
                    $candidate = $_.Name
                }
            }
        }
    }

    if (-not $candidate -and (Test-Path $FeaturesDir)) {
        Get-ChildItem -Path $FeaturesDir -Directory | Sort-Object Name | ForEach-Object {
            $statusFile = Join-Path $_.FullName "status.txt"
            if (Test-Path $statusFile) {
                $status = (Get-Content $statusFile -Raw).Trim()
                if ($status -eq "draft") {
                    $candidate = $_.Name
                }
            }
        }
    }

    return $candidate
}

$ResolvedFeatureId = Resolve-FeatureId $FeatureId

if (-not $ResolvedFeatureId) {
    Write-Host "No draft or running feature found."
    exit 1
}

$FeatureDir = Join-Path $FeaturesDir $ResolvedFeatureId
python "$RootDir\scripts\split_output.py" "$FeatureDir"
