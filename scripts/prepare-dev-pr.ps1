[CmdletBinding()]
param(
    [string]$RepositoryPath = (Get-Location).Path,

    [string]$WorkspaceRoot,

    [switch]$ApproveNetwork
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$RepositoryPath = (Resolve-Path -LiteralPath $RepositoryPath).Path

if (-not $ApproveNetwork) {
    throw 'The pre-PR gate requires explicit network approval with -ApproveNetwork.'
}

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -c "safe.directory=$Path" -C $Path @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $detail = ($output | ForEach-Object { $_.ToString() }) -join ' '
        throw "Git command failed in ${Path}: git $($Arguments -join ' '); $detail"
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output | ForEach-Object { $_.ToString() }) }
}

function Get-GitValue {
    param([string]$Path, [string[]]$Arguments)
    return ((Invoke-GitCapture -Path $Path -Arguments $Arguments).Output -join '').Trim()
}

function Get-ReceiptName {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Branch)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
    return "$hash.json"
}

if (-not $WorkspaceRoot) {
    $configuredWorkspaceResult = Invoke-GitCapture `
        -Path $masterRoot `
        -Arguments @('config', '--local', '--get', 'axms.workspaceRoot') `
        -AllowFailure
    if ($configuredWorkspaceResult.ExitCode -notin @(0, 1)) {
        throw 'Could not read the AXMS workspace root from local Git config.'
    }
    $configuredWorkspace = ($configuredWorkspaceResult.Output -join '').Trim()
    $WorkspaceRoot = if ($configuredWorkspace) {
        $configuredWorkspace
    }
    else {
        Split-Path -Parent $masterRoot
    }
}
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
if (-not (Test-Path -LiteralPath (Join-Path $WorkspaceRoot 'AGENTS.md') -PathType Leaf) -or
    -not (Test-Path -LiteralPath (Join-Path $WorkspaceRoot 'urizo-final-master/AGENTS.md') -PathType Leaf)) {
    throw "Resolved AXMS workspace root is invalid: $WorkspaceRoot. Run bootstrap-workspace.ps1 -SyncLlmHooks or pass -WorkspaceRoot explicitly."
}

$repositoryRoot = Get-GitValue -Path $RepositoryPath -Arguments @('rev-parse', '--show-toplevel')
$repositoryRoot = [IO.Path]::GetFullPath($repositoryRoot)
$branch = Get-GitValue -Path $repositoryRoot -Arguments @('branch', '--show-current')
if ($branch -notmatch '^feature/') {
    throw "Pre-PR dev gate requires a feature branch; current=$branch"
}
$dirty = (Invoke-GitCapture -Path $repositoryRoot -Arguments @('status', '--porcelain=v1')).Output
if (@($dirty | Where-Object { $_ }).Count -gt 0) {
    throw 'Feature Worktree is dirty. Commit or otherwise resolve changes before the pre-PR dev gate.'
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json
$integrationBranch = [string]$manifest.branches.integration
$origin = Get-GitValue -Path $repositoryRoot -Arguments @('remote', 'get-url', 'origin')
$repositoryMatches = @($manifest.repositories | Where-Object { $_.remote -eq $origin })
if ($repositoryMatches.Count -ne 1) {
    throw "Repository origin is not a unique workspace manifest entry: $origin"
}
$originDevBeforeResult = Invoke-GitCapture -Path $repositoryRoot -Arguments @('rev-parse', "origin/$integrationBranch") -AllowFailure
$originDevBefore = if ($originDevBeforeResult.ExitCode -eq 0) { ($originDevBeforeResult.Output -join '').Trim() } else { $null }
Invoke-GitCapture -Path $repositoryRoot -Arguments @('fetch', 'origin', $integrationBranch) | Out-Null
$originDev = Get-GitValue -Path $repositoryRoot -Arguments @('rev-parse', "origin/$integrationBranch")
$featureHead = Get-GitValue -Path $repositoryRoot -Arguments @('rev-parse', 'HEAD')
$ancestor = Invoke-GitCapture -Path $repositoryRoot -Arguments @('merge-base', '--is-ancestor', "origin/$integrationBranch", $featureHead) -AllowFailure
if ($ancestor.ExitCode -ne 0) {
    throw "Feature branch is missing current origin/$integrationBranch. Integrate dev explicitly, verify, then rerun this gate."
}

$devAgentsChanged = -not $originDevBefore
if ($originDevBefore -and $originDevBefore -ne $originDev) {
    $devAgentsChange = Invoke-GitCapture -Path $repositoryRoot -Arguments @('diff', '--quiet', $originDevBefore, $originDev, '--', 'AGENTS.md') -AllowFailure
    if ($devAgentsChange.ExitCode -notin @(0, 1)) {
        throw 'Could not determine whether origin/dev changed AGENTS.md.'
    }
    $devAgentsChanged = $devAgentsChange.ExitCode -eq 1
}
$featureAgentsChange = Invoke-GitCapture -Path $repositoryRoot -Arguments @('diff', '--quiet', "origin/$integrationBranch...HEAD", '--', 'AGENTS.md') -AllowFailure
if ($featureAgentsChange.ExitCode -notin @(0, 1)) {
    throw 'Could not determine whether the feature branch changes AGENTS.md.'
}
$contextLoader = Join-Path $WorkspaceRoot '.codex/hooks/session-start.ps1'
$templateContextLoader = Join-Path $masterRoot 'templates/workspace/codex/hooks/session-start.ps1'
if (-not (Test-Path -LiteralPath $contextLoader -PathType Leaf) -or
    (Get-Content -Raw -Encoding UTF8 -LiteralPath $contextLoader) -notmatch "ValidateSet\('Full', 'Checkpoint'\)") {
    $contextLoader = $templateContextLoader
    Write-Host 'CONTEXT LOADER ROLLOUT: using the feature-branch template until Workspace bootstrap installs context v2.'
}
if (-not (Test-Path -LiteralPath $contextLoader -PathType Leaf)) {
    throw 'MASTER CONTEXT BLOCKED: context v2 loader is missing. Run bootstrap-workspace.ps1 -SyncLlmHooks.'
}
$contextMode = if ($devAgentsChanged -or $featureAgentsChange.ExitCode -eq 1) { 'Full' } else { 'Checkpoint' }
$contextLimit = if ($contextMode -eq 'Full') { 24576 } else { 4096 }
Push-Location -LiteralPath $repositoryRoot
try {
    $contextOutput = @(& $contextLoader -WorkspaceRoot $WorkspaceRoot -Mode $contextMode -Reason PrePr -MaxContextBytes $contextLimit)
}
finally {
    Pop-Location
}
$contextFirstLine = @(($contextOutput -join [Environment]::NewLine) -split "`r?`n", 2)[0].Trim()
$expectedContextFirstLine = if ($contextMode -eq 'Full') { 'MASTER CONTEXT PASS' } else { 'AXMS CONTEXT CHECKPOINT v2: reason=PrePr' }
if ($contextFirstLine -ne $expectedContextFirstLine) {
    throw "MASTER CONTEXT BLOCKED: pre-PR context refresh returned an invalid $contextMode payload."
}
$contextOutput | Write-Output
Write-Host "PRE-PR CONTEXT REFRESH PASS: mode=$contextMode"

$commonGitDir = Get-GitValue -Path $repositoryRoot -Arguments @('rev-parse', '--git-common-dir')
if (-not [IO.Path]::IsPathRooted($commonGitDir)) {
    $commonGitDir = Join-Path $repositoryRoot $commonGitDir
}
$receiptDirectory = Join-Path ([IO.Path]::GetFullPath($commonGitDir)) 'axms-pull-gates'
if (-not (Test-Path -LiteralPath $receiptDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $receiptDirectory -Force | Out-Null
}
$receiptPath = Join-Path $receiptDirectory (Get-ReceiptName -Branch $branch)
$receipt = [ordered]@{
    schemaVersion = 1
    repositoryRoot = $repositoryRoot
    branch = $branch
    head = $featureHead
    originDev = $originDev
    checkedAt = [DateTimeOffset]::Now.ToString('o')
}
[IO.File]::WriteAllText($receiptPath, (($receipt | ConvertTo-Json -Depth 4) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))

Write-Host "PRE-PR DEV GATE PASS: repository=$($repositoryMatches[0].name); branch=$branch; head=$featureHead; origin/dev=$originDev"
Write-Host "PRE-PUSH RECEIPT READY: $receiptPath"
