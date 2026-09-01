[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryName,

    [Parameter(Mandatory = $true)]
    [string]$BranchName,

    [string]$WorkspaceRoot,

    [string]$WorktreePath,

    [switch]$ApproveNetwork
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Split-Path -Parent $masterRoot
}
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path

if (-not $ApproveNetwork) {
    throw 'The pre-work Pull gate requires explicit network approval with -ApproveNetwork.'
}
if ($BranchName -notmatch '^feature/[A-Za-z0-9._-]+$') {
    throw 'BranchName must use the feature/<owner>_<work-slug>_<version> form.'
}
if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.git')) {
    throw 'The shared workspace must not be a Git repository.'
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json
$integrationBranch = [string]$manifest.branches.integration
$repositoryMatches = @($manifest.repositories | Where-Object { $_.name -eq $RepositoryName })
if ($repositoryMatches.Count -ne 1) {
    throw "RepositoryName must match one manifest repository: $RepositoryName"
}
$repository = $repositoryMatches[0]
$repositoryPath = [IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $repository.relativePath))
if (-not (Test-Path -LiteralPath (Join-Path $repositoryPath '.git'))) {
    throw "Canonical repository checkout is missing: $repositoryPath"
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

function Get-AgentsFingerprint {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 'missing'
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$origin = Get-GitValue -Path $repositoryPath -Arguments @('remote', 'get-url', 'origin')
if ($origin -ne [string]$repository.remote) {
    throw "Origin mismatch; no Git state was changed: $origin"
}
$branch = Get-GitValue -Path $repositoryPath -Arguments @('branch', '--show-current')
$canonicalHeadBeforePull = Get-GitValue -Path $repositoryPath -Arguments @('rev-parse', 'HEAD')
$dirty = (Invoke-GitCapture -Path $repositoryPath -Arguments @('status', '--porcelain=v1')).Output
$canonicalStatusBeforePull = @($dirty | ForEach-Object { $_.ToString() }) -join "`n"
$pullPath = $repositoryPath
$temporaryPullWorktree = $null
$canonicalIsDirty = @($dirty | Where-Object { $_ }).Count -gt 0
try {
    if ($branch -ne $integrationBranch -or $canonicalIsDirty) {
        # Keep the transient path short enough for repositories with deep Java package paths on Windows.
        $pullGateRoot = Join-Path $WorkspaceRoot '.worktrees/.g'
        if (-not (Test-Path -LiteralPath $pullGateRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $pullGateRoot -Force | Out-Null
        }
        $temporaryPullWorktree = Join-Path $pullGateRoot ([Guid]::NewGuid().ToString('N').Substring(0, 16))
        Invoke-GitCapture -Path $repositoryPath -Arguments @('worktree', 'add', '--detach', $temporaryPullWorktree, "origin/$integrationBranch") | Out-Null
        $pullPath = $temporaryPullWorktree
        Write-Host "CANONICAL CHECKOUT PRESERVED: branch=$branch; dirty=$canonicalIsDirty; using isolated dev Pull Worktree=$temporaryPullWorktree"
    }

    # This exact pull is the enforced pre-work synchronization point.
    $agentsPath = Join-Path $pullPath 'AGENTS.md'
    $agentsBeforePull = Get-AgentsFingerprint -Path $agentsPath
    Invoke-GitCapture -Path $pullPath -Arguments @('pull', '--ff-only', 'origin', $integrationBranch) | Out-Null
    $agentsAfterPull = Get-AgentsFingerprint -Path $agentsPath
    $head = Get-GitValue -Path $pullPath -Arguments @('rev-parse', 'HEAD')
}
finally {
    if ($temporaryPullWorktree) {
        $cleanup = Invoke-GitCapture -Path $repositoryPath `
            -Arguments @('worktree', 'remove', '--force', $temporaryPullWorktree) -AllowFailure
        if ($cleanup.ExitCode -ne 0 -and (Test-Path -LiteralPath $temporaryPullWorktree)) {
            throw "Temporary dev Pull Worktree cleanup failed: $temporaryPullWorktree"
        }
    }
}
if ($temporaryPullWorktree) {
    $canonicalBranchAfterPull = Get-GitValue -Path $repositoryPath -Arguments @('branch', '--show-current')
    $canonicalHeadAfterPull = Get-GitValue -Path $repositoryPath -Arguments @('rev-parse', 'HEAD')
    $canonicalStatusAfterPull = @((Invoke-GitCapture -Path $repositoryPath -Arguments @('status', '--porcelain=v1')).Output | ForEach-Object { $_.ToString() }) -join "`n"
    if ($canonicalBranchAfterPull -ne $branch -or
        $canonicalHeadAfterPull -ne $canonicalHeadBeforePull -or
        $canonicalStatusAfterPull -ne $canonicalStatusBeforePull) {
        throw 'Canonical checkout changed while the isolated dev Pull gate was running.'
    }
}
$originDev = Get-GitValue -Path $repositoryPath -Arguments @('rev-parse', "origin/$integrationBranch")
if ($head -ne $originDev) {
    throw "Pre-work Pull gate did not leave its clean dev baseline exactly at origin/$integrationBranch."
}

$worktreeRoot = [IO.Path]::GetFullPath((Join-Path $WorkspaceRoot '.worktrees'))
if (-not $WorktreePath) {
    $safeName = ($RepositoryName + '-' + ($BranchName -replace '^feature/', '')) -replace '[^A-Za-z0-9._-]', '-'
    if ($safeName.Length -gt 48) {
        $branchHasher = [Security.Cryptography.SHA256]::Create()
        try {
            $branchHashBytes = $branchHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($BranchName))
        }
        finally {
            $branchHasher.Dispose()
        }
        $branchHash = (($branchHashBytes | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 12)
        $safeName = $safeName.Substring(0, 35).TrimEnd('-', '_', '.') + '-' + $branchHash
    }
    $WorktreePath = Join-Path $worktreeRoot $safeName
}
$WorktreePath = [IO.Path]::GetFullPath($WorktreePath)
$worktreePrefix = $worktreeRoot.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if (-not $WorktreePath.StartsWith($worktreePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "WorktreePath must stay under the workspace isolation root: $worktreeRoot"
}

if (Test-Path -LiteralPath $WorktreePath) {
    $existingRoot = Get-GitValue -Path $WorktreePath -Arguments @('rev-parse', '--show-toplevel')
    $existingBranch = Get-GitValue -Path $WorktreePath -Arguments @('branch', '--show-current')
    if ([IO.Path]::GetFullPath($existingRoot) -ne $WorktreePath -or $existingBranch -ne $BranchName) {
        throw "Existing WorktreePath does not match the requested feature branch: $WorktreePath"
    }
    $action = 'REUSED'
}
else {
    if (-not (Test-Path -LiteralPath $worktreeRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $worktreeRoot -Force | Out-Null
    }
    $branchExists = (Invoke-GitCapture -Path $repositoryPath -Arguments @('show-ref', '--verify', '--quiet', "refs/heads/$BranchName") -AllowFailure).ExitCode -eq 0
    if ($branchExists) {
        $branchContainsDev = Invoke-GitCapture -Path $repositoryPath -Arguments @('merge-base', '--is-ancestor', "origin/$integrationBranch", $BranchName) -AllowFailure
        if ($branchContainsDev.ExitCode -ne 0) {
            throw "Existing feature branch does not contain the pulled origin/$integrationBranch baseline; no Worktree was created."
        }
        Invoke-GitCapture -Path $repositoryPath -Arguments @('worktree', 'add', $WorktreePath, $BranchName) | Out-Null
    }
    else {
        Invoke-GitCapture -Path $repositoryPath -Arguments @('worktree', 'add', '-b', $BranchName, $WorktreePath, "origin/$integrationBranch") | Out-Null
    }
    $action = 'CREATED'
}

$featureHead = Get-GitValue -Path $WorktreePath -Arguments @('rev-parse', 'HEAD')
$ancestor = Invoke-GitCapture -Path $WorktreePath -Arguments @('merge-base', '--is-ancestor', "origin/$integrationBranch", $featureHead) -AllowFailure
if ($ancestor.ExitCode -ne 0) {
    throw "The isolated feature branch does not contain the pulled origin/$integrationBranch baseline."
}

Write-Host "PRE-WORK PULL GATE PASS: repository=$RepositoryName; dev=$originDev"
Write-Host "ISOLATED WORKTREE $action`: branch=$BranchName; path=$WorktreePath"

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
$contextMode = if ($agentsBeforePull -eq $agentsAfterPull) { 'Checkpoint' } else { 'Full' }
$contextLimit = if ($contextMode -eq 'Full') { 24576 } else { 4096 }
Push-Location -LiteralPath $WorktreePath
try {
    $contextOutput = @(& $contextLoader -WorkspaceRoot $WorkspaceRoot -Mode $contextMode -Reason PreWork -MaxContextBytes $contextLimit)
}
finally {
    Pop-Location
}
$contextFirstLine = @(($contextOutput -join [Environment]::NewLine) -split "`r?`n", 2)[0].Trim()
$expectedContextFirstLine = if ($contextMode -eq 'Full') { 'MASTER CONTEXT PASS' } else { 'AXMS CONTEXT CHECKPOINT v2: reason=PreWork' }
if ($contextFirstLine -ne $expectedContextFirstLine) {
    throw "MASTER CONTEXT BLOCKED: pre-work context refresh returned an invalid $contextMode payload."
}
$contextOutput | Write-Output
Write-Host "PRE-WORK CONTEXT REFRESH PASS: mode=$contextMode"
