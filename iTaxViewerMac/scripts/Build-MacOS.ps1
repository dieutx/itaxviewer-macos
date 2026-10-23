# Build the committed application on a GitHub-hosted Mac, then download its artifacts.
# No local document, fixture folder or working-tree change is uploaded by this script.
[CmdletBinding()]
param(
    [string] $Repository,
    [string] $Ref = 'main',
    [string] $OutputDirectory,
    [switch] $NoWait,
    [ValidateRange(1, 120)] [int] $TimeoutMinutes = 40
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw 'GitHub CLI (gh) is required. Install it and run gh auth login first.'
}

function Invoke-GitHub {
    param([string[]] $Arguments)
    $result = & gh @Arguments
    if ($LASTEXITCODE -ne 0) { throw "GitHub CLI failed: gh $($Arguments -join ' ')" }
    return ($result -join "`n")
}

Push-Location (Join-Path $PSScriptRoot '..')
try {
    if (-not $Repository) {
        $Repository = (Invoke-GitHub -Arguments @('repo', 'view', '--json', 'nameWithOwner', '--jq', '.nameWithOwner')).Trim()
    }
    if ($Repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
        throw 'Repository must have the form owner/repository.'
    }
    # The workflow builds only the selected remote commit, never uncommitted local files.
    $commit = (Invoke-GitHub -Arguments @('api', "repos/$Repository/commits/$([Uri]::EscapeDataString($Ref))", '--jq', '.sha')).Trim()
    $requestID = [Guid]::NewGuid().ToString('N')
    $title = "Windows build $requestID"
    Write-Host "Requesting macOS universal build: $Repository, ref $Ref, commit $commit"
    Invoke-GitHub -Arguments @('workflow', 'run', 'macos.yml', '--repo', $Repository, '--ref', $Ref, '-f', "request_id=$requestID") | Out-Host

    $deadline = [DateTime]::UtcNow.AddMinutes($TimeoutMinutes)
    $run = $null
    while ([DateTime]::UtcNow -lt $deadline) {
        $runs = Invoke-GitHub -Arguments @('run', 'list', '--repo', $Repository, '--workflow', 'macos.yml', '--event', 'workflow_dispatch', '--limit', '50', '--json', 'databaseId,displayTitle,headSha,url,status,conclusion')
        $run = @($runs | ConvertFrom-Json | Where-Object { $_.displayTitle -eq $title }) | Select-Object -First 1
        if ($run) { break }
        Start-Sleep -Seconds 5
    }
    if (-not $run) {
        throw "Timed out locating the requested workflow run. Check https://github.com/$Repository/actions/workflows/macos.yml"
    }
    if ($run.headSha -ne $commit) {
        throw "Remote ref changed during dispatch. Expected $commit, run uses $($run.headSha). Review $($run.url) before downloading."
    }
    Write-Host "Build run: $($run.url)"
    if ($NoWait) { return }

    while ($run.status -ne 'completed' -and [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Seconds 10
        $run = Invoke-GitHub -Arguments @('run', 'view', [string] $run.databaseId, '--repo', $Repository, '--json', 'databaseId,url,status,conclusion') | ConvertFrom-Json
    }
    if ($run.status -ne 'completed') { throw "Build is still running: $($run.url)" }
    if ($run.conclusion -ne 'success') {
        throw "macOS build result: $($run.conclusion). Review compiler/test output at $($run.url)"
    }
    if (-not $OutputDirectory) {
        $OutputDirectory = Join-Path (Join-Path (Get-Location).Path 'build/downloads') ([string] $run.databaseId)
    }
    if (Test-Path -LiteralPath $OutputDirectory) {
        if (@(Get-ChildItem -LiteralPath $OutputDirectory -Force).Count -ne 0) {
            throw "Output directory is not empty: $OutputDirectory. Use another directory to avoid overwriting artifacts."
        }
    }
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    Invoke-GitHub -Arguments @('run', 'download', [string] $run.databaseId, '--repo', $Repository, '--name', 'iTaxViewerMac-universal', '--dir', $OutputDirectory) | Out-Host
    $checksums = @(Get-Content -LiteralPath (Join-Path $OutputDirectory 'SHA256SUMS.txt'))
    if ($checksums.Count -ne 2) { throw 'Expected checksums for exactly the ZIP and DMG.' }
    $checkedNames = @{}
    foreach ($line in $checksums) {
        if ($line -notmatch '^([a-fA-F0-9]{64})\s+\*?(iTaxViewerMac-universal\.zip|iTaxViewerMac-unsigned\.dmg)$') {
            throw 'Unexpected checksum manifest entry.'
        }
        $expected = $Matches[1]
        $name = $Matches[2]
        if ($checkedNames.ContainsKey($name)) { throw 'Duplicate checksum manifest entry.' }
        $checkedNames[$name] = $true
        $actual = (Get-FileHash -LiteralPath (Join-Path $OutputDirectory $name) -Algorithm SHA256).Hash
        if ($actual -ne $expected) { throw "Checksum mismatch: $name" }
    }
    Write-Host "Downloaded and checksum-checked: $OutputDirectory"
    Write-Host 'Open the DMG on macOS. The app is ad-hoc signed and not notarized; native UI/print verification remains necessary.'
} finally {
    Pop-Location
}
