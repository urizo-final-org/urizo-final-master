[CmdletBinding()]
param(
    [string]$RepositoryPath = (Get-Location).Path,

    [string]$WorkspaceRoot,

    [switch]$ApproveNetwork
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Split-Path -Parent $masterRoot
}
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
$RepositoryPath = (Resolve-Path -LiteralPath $RepositoryPath).Path

if (-not $ApproveNetwork) {
    throw 'The pre-PR Pull gate requires explicit network approval with -ApproveNetwork.'
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

function Get-AgentsFingerprint {
    param([Parameter(Mandatory = $true)][string[]]$Paths)
    $builder = [Text.StringBuilder]::new()
    foreach ($path in @($Paths | Sort-Object -Unique)) {
        $hash = if (Test-Path -LiteralPath $path -PathType Leaf) {
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        else {
            'missing'
        }
        [void]$builder.AppendLine("$path=$hash")
    }
    return $builder.ToString()
}

$repositoryRoot = Get-GitValue -Path $RepositoryPath -Arguments @('rev-parse', '--show-toplevel')
$repositoryRoot = [IO.Path]::GetFullPath($repositoryRoot)
$branch = Get-GitValue -Path $repositoryRoot -Arguments @('branch', '--show-current')
if ($branch -notmatch '^feature/') {
    throw "Pre-PR Pull gate requires a feature branch; current=$branch"
}
$dirty = (Invoke-GitCapture -Path $repositoryRoot -Arguments @('status', '--porcelain=v1')).Output
if (@($dirty | Where-Object { $_ }).Count -gt 0) {
    throw 'Feature Worktree is dirty. Commit or otherwise resolve changes before the pre-PR Pull gate.'
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json
$integrationBranch = [string]$manifest.branches.integration
$origin = Get-GitValue -Path $repositoryRoot -Arguments @('remote', 'get-url', 'origin')
$repositoryMatches = @($manifest.repositories | Where-Object { $_.remote -eq $origin })
if ($repositoryMatches.Count -ne 1) {
    throw "Repository origin is not a unique workspace manifest entry: $origin"
}
$canonicalPath = [IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $repositoryMatches[0].relativePath))
$canonicalBranch = Get-GitValue -Path $canonicalPath -Arguments @('branch', '--show-current')
if ($canonicalBranch -ne $integrationBranch) {
    throw "Canonical checkout must be on $integrationBranch for the pre-PR Pull gate; current=$canonicalBranch"
}
$canonicalDirty = (Invoke-GitCapture -Path $canonicalPath -Arguments @('status', '--porcelain=v1')).Output
$pullPath = $canonicalPath
$temporaryPullWorktree = $null
if (@($canonicalDirty | Where-Object { $_ }).Count -gt 0) {
    $pullGateRoot = Join-Path $WorkspaceRoot '.worktrees/.pull-gates'
    if (-not (Test-Path -LiteralPath $pullGateRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $pullGateRoot -Force | Out-Null
    }
    $temporaryPullWorktree = Join-Path $pullGateRoot ("$($repositoryMatches[0].name)-" + [Guid]::NewGuid().ToString('N'))
    Invoke-GitCapture -Path $canonicalPath -Arguments @('worktree', 'add', '--detach', $temporaryPullWorktree, "origin/$integrationBranch") | Out-Null
    $pullPath = $temporaryPullWorktree
    Write-Host "CANONICAL DIRTY PRESERVED: using isolated dev Pull Worktree=$temporaryPullWorktree"
}

try {
    # This exact pull is the enforced pre-PR synchronization point.
    $devAgentsPath = Join-Path $pullPath 'AGENTS.md'
    $featureAgentsPath = Join-Path $repositoryRoot 'AGENTS.md'
    $agentsPaths = @($devAgentsPath, $featureAgentsPath)
    $agentsBeforePull = Get-AgentsFingerprint -Paths $agentsPaths
    Invoke-GitCapture -Path $pullPath -Arguments @('pull', '--ff-only', 'origin', $integrationBranch) | Out-Null
    $originDev = Get-GitValue -Path $repositoryRoot -Arguments @('rev-parse', "origin/$integrationBranch")
    $devHead = Get-GitValue -Path $pullPath -Arguments @('rev-parse', 'HEAD')
    if ($devHead -ne $originDev) {
        throw "Pre-PR Pull gate did not leave its clean dev baseline exactly at origin/$integrationBranch."
    }

    $upstreamResult = Invoke-GitCapture -Path $repositoryRoot -Arguments @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}') -AllowFailure
    if ($upstreamResult.ExitCode -eq 0) {
        $upstream = ($upstreamResult.Output -join '').Trim()
        if ($upstream -notmatch '^origin/') {
            throw "Feature upstream must be on origin; current=$upstream"
        }
        Invoke-GitCapture -Path $repositoryRoot -Arguments @('pull', '--ff-only', 'origin', ($upstream -replace '^origin/', '')) | Out-Null
    }
    $agentsAfterPull = Get-AgentsFingerprint -Paths $agentsPaths

    $devAgentsHash = if (Test-Path -LiteralPath $devAgentsPath -PathType Leaf) {
        (Get-FileHash -LiteralPath $devAgentsPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    else {
        'missing'
    }
    $featureAgentsHash = if (Test-Path -LiteralPath $featureAgentsPath -PathType Leaf) {
        (Get-FileHash -LiteralPath $featureAgentsPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    else {
        'missing'
    }
    $instructionsDifferFromDev = $devAgentsHash -ne $featureAgentsHash
    $featureAgentsChange = Invoke-GitCapture -Path $repositoryRoot -Arguments @('diff', '--quiet', "origin/$integrationBranch...HEAD", '--', 'AGENTS.md') -AllowFailure
    if ($featureAgentsChange.ExitCode -notin @(0, 1)) {
        throw 'Could not determine whether the feature branch intentionally changes AGENTS.md.'
    }
    $featureIntentionallyChangesAgents = $featureAgentsChange.ExitCode -eq 1
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
    $contextMode = if ($agentsBeforePull -ne $agentsAfterPull -or $instructionsDifferFromDev) { 'Full' } else { 'Checkpoint' }
    $contextLimit = if ($contextMode -eq 'Full') { 24576 } else { 4096 }
    $contextPath = if ($instructionsDifferFromDev -and -not $featureIntentionallyChangesAgents) { $pullPath } else { $repositoryRoot }
    Push-Location -LiteralPath $contextPath
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
}
finally {
    if ($temporaryPullWorktree -and (Test-Path -LiteralPath $temporaryPullWorktree)) {
        Invoke-GitCapture -Path $canonicalPath -Arguments @('worktree', 'remove', $temporaryPullWorktree) | Out-Null
    }
}

$featureHead = Get-GitValue -Path $repositoryRoot -Arguments @('rev-parse', 'HEAD')
$ancestor = Invoke-GitCapture -Path $repositoryRoot -Arguments @('merge-base', '--is-ancestor', "origin/$integrationBranch", $featureHead) -AllowFailure
if ($ancestor.ExitCode -ne 0) {
    throw "Feature branch is missing current origin/$integrationBranch. Integrate dev explicitly, verify, then rerun this gate."
}

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

Write-Host "PRE-PR PULL GATE PASS: repository=$($repositoryMatches[0].name); branch=$branch; head=$featureHead; origin/dev=$originDev"
Write-Host "PRE-PUSH RECEIPT READY: $receiptPath"
