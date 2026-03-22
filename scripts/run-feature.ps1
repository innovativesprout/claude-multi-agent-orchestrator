param(
    [string]$FeatureId
)

$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$FeaturesDir = Join-Path $RootDir "features"
$TemplateFile = Join-Path $RootDir "prompts\run-feature.txt"
$LastRunFile = Join-Path $RootDir "outputs\last-run.md"

function Resolve-FeatureId {
    param([string]$Value)

    if ($Value) { return $Value }

    $candidate = $null
    if (Test-Path $FeaturesDir) {
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
    Write-Host "No draft feature found."
    exit 1
}

$FeatureDir = Join-Path $FeaturesDir $ResolvedFeatureId
$RequestFile = Join-Path $FeatureDir "request.txt"
$FinalPromptFile = Join-Path $FeatureDir "prompt.final.txt"
$RawOutputFile = Join-Path $FeatureDir "raw-output.md"
$StatusFile = Join-Path $FeatureDir "status.txt"

if (!(Test-Path $RequestFile)) {
    Write-Host "Missing request file: $RequestFile"
    exit 1
}

$template = Get-Content $TemplateFile -Raw
$request = Get-Content $RequestFile -Raw
$finalPrompt = $template.Replace("{{FEATURE_REQUEST}}", $request)
Set-Content -Path $FinalPromptFile -Value $finalPrompt -Encoding UTF8
Set-Content -Path $StatusFile -Value "running" -Encoding UTF8

Write-Host "Generated final prompt:"
Write-Host "  $FinalPromptFile"
Write-Host ""

$ClaudeCommand = Get-Command claude -ErrorAction SilentlyContinue
if ($ClaudeCommand) {
    try {
        Get-Content $FinalPromptFile -Raw | claude | Set-Content -Path $RawOutputFile -Encoding UTF8
        python "$RootDir\scripts\split_output.py" "$FeatureDir"

        @"
# Last Run

## Feature
$ResolvedFeatureId

## Status
Prompt executed successfully and output was split

## Prompt File
$FinalPromptFile

## Raw Output File
$RawOutputFile
"@ | Set-Content -Path $LastRunFile -Encoding UTF8

        Write-Host "Claude output saved and split for:"
        Write-Host "  $ResolvedFeatureId"
    }
    catch {
        @"
# Last Run

## Feature
$ResolvedFeatureId

## Status
Claude execution failed

## Prompt File
$FinalPromptFile
"@ | Set-Content -Path $LastRunFile -Encoding UTF8

        Write-Host "Claude execution failed."
        Write-Host "Paste this manually into claude: $FinalPromptFile"
        exit 1
    }
}
else {
    @"
# Last Run

## Feature
$ResolvedFeatureId

## Status
Claude CLI not found

## Prompt File
$FinalPromptFile
"@ | Set-Content -Path $LastRunFile -Encoding UTF8

    Write-Host "Claude CLI not found. Paste this manually into claude: $FinalPromptFile"
    exit 1
}
