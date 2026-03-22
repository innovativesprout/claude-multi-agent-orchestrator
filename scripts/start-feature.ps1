param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureId
)

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FeatureDir = Join-Path $RootDir "features\$FeatureId"

if (Test-Path $FeatureDir) {
    Write-Host "Feature already exists: $FeatureDir"
    exit 1
}

New-Item -ItemType Directory -Path $FeatureDir | Out-Null
Copy-Item (Join-Path $RootDir "templates\implementation-plan-template.md") (Join-Path $FeatureDir "plan.md")
Copy-Item (Join-Path $RootDir "templates\execution-template.md") (Join-Path $FeatureDir "execution.md")
Copy-Item (Join-Path $RootDir "templates\qa-report-template.md") (Join-Path $FeatureDir "qa.md")
Copy-Item (Join-Path $RootDir "templates\feature-doc-template.md") (Join-Path $FeatureDir "docs.md")
Copy-Item (Join-Path $RootDir "templates\feature-request-template.txt") (Join-Path $FeatureDir "request.txt")
Set-Content (Join-Path $FeatureDir "status.txt") "draft"

Write-Host "Created feature scaffold: $FeatureId"
Write-Host "Edit: features/$FeatureId/request.txt"
