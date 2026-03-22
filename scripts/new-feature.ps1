param([Parameter(Mandatory = $true)][string]$Title)
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FeaturesDir = Join-Path $RootDir "features"
$LatestFile = Join-Path $FeaturesDir "latest.txt"
New-Item -ItemType Directory -Force -Path $FeaturesDir | Out-Null
function Get-Slug([string]$Value) {
    $slug = $Value.ToLower()
    $slug = [regex]::Replace($slug, '[^a-z0-9]+', '-')
    return $slug.Trim('-')
}
function Get-NextNumber {
    if ((Test-Path $LatestFile) -and ((Get-Content $LatestFile -Raw).Trim() -ne "")) {
        $last = (Get-Content $LatestFile -Raw).Trim()
        if ($last -match '^(\d+)-') { return ([int]$matches[1] + 1) }
    }
    $highest = 0
    Get-ChildItem -Path $FeaturesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -match '^(\d+)-') {
            $num = [int]$matches[1]
            if ($num -gt $highest) { $highest = $num }
        }
    }
    return ($highest + 1)
}
$FeatureId = ('{0:D3}' -f (Get-NextNumber)) + '-' + (Get-Slug $Title)
$FeatureDir = Join-Path $FeaturesDir $FeatureId
New-Item -ItemType Directory -Force -Path $FeatureDir | Out-Null
@"
Title: $Title

Describe the feature request here.

Requirements:
- 
- 
- 
"@ | Set-Content -Path (Join-Path $FeatureDir 'request.txt') -Encoding UTF8
'plan.md','execution.md','qa.md','docs.md','raw-output.md','prompt.final.txt' | ForEach-Object { New-Item -ItemType File -Force -Path (Join-Path $FeatureDir $_) | Out-Null }
Set-Content -Path (Join-Path $FeatureDir 'status.txt') -Value 'draft' -Encoding UTF8
Write-Output $FeatureId
