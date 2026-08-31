[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [switch]$ApproveNetwork,

    [switch]$AsJson,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Split-Path -Parent $masterRoot
}
if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
    throw "Workspace root does not exist: $WorkspaceRoot"
}
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path

if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.git')) {
    throw 'The shared workspace must not be a Git repository.'
}

$expectedMaster = [System.IO.Path]::GetFullPath((Join-Path $WorkspaceRoot 'urizo-final-master'))
if ($expectedMaster -ne [System.IO.Path]::GetFullPath($masterRoot)) {
    throw 'Run this script from the canonical urizo-final-master sibling in the selected workspace.'
}

if (-not $ApproveNetwork -and -not $WhatIf) {
    throw 'Canonical Git synchronization requires the explicit -ApproveNetwork switch.'
}

$manifestPath = Join-Path $masterRoot 'repository-manifest.json'
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$integrationBranch = [string]$manifest.branches.integration
$results = [System.Collections.Generic.List[object]]::new()

function Get-InstructionFingerprint {
    $instructionPaths = [System.Collections.Generic.List[string]]::new()
    $instructionPaths.Add((Join-Path $WorkspaceRoot 'AGENTS.md'))
    foreach ($repository in $manifest.repositories) {
        $instructionPaths.Add((Join-Path (Join-Path $WorkspaceRoot $repository.relativePath) 'AGENTS.md'))
    }

    $builder = [Text.StringBuilder]::new()
    foreach ($path in @($instructionPaths | Sort-Object)) {
        $relative = [IO.Path]::GetFullPath($path).Substring($WorkspaceRoot.Length).TrimStart([char[]]'\/').Replace('\', '/')
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
            [void]$builder.AppendLine("$relative=$hash")
        }
        else {
            [void]$builder.AppendLine("$relative=missing")
        }
    }

    $bytes = [Text.Encoding]::UTF8.GetBytes($builder.ToString())
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

$instructionFingerprintBefore = Get-InstructionFingerprint

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -c "safe.directory=$RepositoryPath" -C $RepositoryPath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }

    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $detail = ($output | ForEach-Object { $_.ToString() }) -join ' '
        throw "Git command failed in ${RepositoryPath}: git $($Arguments -join ' '); $detail"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = @($output | ForEach-Object { $_.ToString() })
    }
}

function Get-RepositoryState {
    param([Parameter(Mandatory = $true)][string]$RepositoryPath)

    $origin = (Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('remote', 'get-url', 'origin')).Output -join ''
    $branch = (Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('branch', '--show-current')).Output -join ''
    $head = (Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('rev-parse', '--verify', 'HEAD')).Output -join ''
    $statusLines = (Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('status', '--porcelain=v1')).Output
    $upstreamResult = Invoke-GitCapture `
        -RepositoryPath $RepositoryPath `
        -Arguments @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}') `
        -AllowFailure

    return [pscustomobject]@{
        Origin = $origin
        Branch = $branch
        Head = $head
        DirtyCount = @($statusLines | Where-Object { $_ }).Count
        Upstream = if ($upstreamResult.ExitCode -eq 0) { $upstreamResult.Output -join '' } else { '' }
    }
}

function Test-GitRef {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$Ref
    )

    $result = Invoke-GitCapture `
        -RepositoryPath $RepositoryPath `
        -Arguments @('show-ref', '--verify', '--quiet', $Ref) `
        -AllowFailure
    return $result.ExitCode -eq 0
}

function Get-DevDelta {
    param([Parameter(Mandatory = $true)][string]$RepositoryPath)

    $devRef = "refs/remotes/origin/$integrationBranch"
    if (-not (Test-GitRef -RepositoryPath $RepositoryPath -Ref $devRef)) {
        return 'origin/dev unavailable'
    }

    $result = Invoke-GitCapture `
        -RepositoryPath $RepositoryPath `
        -Arguments @('rev-list', '--left-right', '--count', "HEAD...origin/$integrationBranch")
    $parts = (($result.Output -join ' ').Trim() -split '\s+')
    if ($parts.Count -ne 2) {
        return 'delta unavailable'
    }
    return "local-only=$($parts[0]); dev-only=$($parts[1])"
}

function Invoke-FastForward {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$TargetRef,
        [Parameter(Mandatory = $true)][bool]$AheadIsBlocked
    )

    $targetResult = Invoke-GitCapture `
        -RepositoryPath $RepositoryPath `
        -Arguments @('rev-parse', '--verify', $TargetRef) `
        -AllowFailure
    if ($targetResult.ExitCode -ne 0) {
        return [pscustomobject]@{ Status = 'WARN'; Action = 'FETCH_ONLY'; Detail = "Target ref unavailable: $TargetRef" }
    }

    $head = (Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('rev-parse', 'HEAD')).Output -join ''
    $target = $targetResult.Output -join ''
    if ($head -eq $target) {
        return [pscustomobject]@{ Status = 'PASS'; Action = 'UNCHANGED'; Detail = "Already at $TargetRef" }
    }

    $headBehind = Invoke-GitCapture `
        -RepositoryPath $RepositoryPath `
        -Arguments @('merge-base', '--is-ancestor', 'HEAD', $TargetRef) `
        -AllowFailure
    if ($headBehind.ExitCode -eq 0) {
        if ($WhatIf) {
            return [pscustomobject]@{ Status = 'PLAN'; Action = 'FAST_FORWARD'; Detail = "Would fast-forward to $TargetRef" }
        }
        Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('merge', '--ff-only', $TargetRef) | Out-Null
        return [pscustomobject]@{ Status = 'PASS'; Action = 'FAST_FORWARDED'; Detail = "Fast-forwarded to $TargetRef" }
    }

    $targetBehind = Invoke-GitCapture `
        -RepositoryPath $RepositoryPath `
        -Arguments @('merge-base', '--is-ancestor', $TargetRef, 'HEAD') `
        -AllowFailure
    if ($targetBehind.ExitCode -eq 0) {
        if ($AheadIsBlocked) {
            return [pscustomobject]@{ Status = 'BLOCKED'; Action = 'LOCAL_AHEAD'; Detail = "Local integration branch is ahead of $TargetRef" }
        }
        return [pscustomobject]@{ Status = 'PASS'; Action = 'LOCAL_AHEAD'; Detail = "Local feature work is ahead of $TargetRef" }
    }

    return [pscustomobject]@{ Status = 'BLOCKED'; Action = 'DIVERGED'; Detail = "Local HEAD diverged from $TargetRef; no merge or rebase performed" }
}

function Add-SyncResult {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$Branch,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$DevDelta,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:results.Add([pscustomobject]@{
        Repository = $Repository
        Branch = $Branch
        Status = $Status
        Action = $Action
        DevDelta = $DevDelta
        Detail = $Detail
    })
}

function Sync-Repository {
    param(
        [Parameter(Mandatory = $true)]$Repository,
        [switch]$IsMaster
    )

    $repositoryPath = Join-Path $WorkspaceRoot $Repository.relativePath
    if (-not (Test-Path -LiteralPath (Join-Path $repositoryPath '.git'))) {
        Add-SyncResult -Repository $Repository.name -Branch 'N/A' -Status 'BLOCKED' -Action 'NONE' -DevDelta 'N/A' -Detail 'Canonical checkout is missing.'
        return $false
    }

    $before = Get-RepositoryState -RepositoryPath $repositoryPath
    if ($before.Origin -ne $Repository.remote) {
        Add-SyncResult -Repository $Repository.name -Branch $before.Branch -Status 'BLOCKED' -Action 'NONE' -DevDelta 'N/A' -Detail "Origin mismatch: $($before.Origin)"
        return $false
    }

    if ($WhatIf) {
        $fetchAction = 'PLAN_FETCH'
    }
    else {
        Invoke-GitCapture -RepositoryPath $repositoryPath -Arguments @('fetch', '--prune', 'origin') | Out-Null
        $fetchAction = 'FETCHED'
    }

    $state = Get-RepositoryState -RepositoryPath $repositoryPath
    $devDelta = Get-DevDelta -RepositoryPath $repositoryPath

    if ($IsMaster) {
        if ($state.Branch -ne $integrationBranch) {
            Add-SyncResult -Repository $Repository.name -Branch $state.Branch -Status 'BLOCKED' -Action $fetchAction -DevDelta $devDelta -Detail "Master must remain on clean $integrationBranch for teammate workspaces. No branch switch performed."
            return $false
        }
        if ($state.DirtyCount -gt 0) {
            Add-SyncResult -Repository $Repository.name -Branch $state.Branch -Status 'BLOCKED' -Action $fetchAction -DevDelta $devDelta -Detail "Master has $($state.DirtyCount) local changes; no working-tree update performed."
            return $false
        }

        $ff = Invoke-FastForward `
            -RepositoryPath $repositoryPath `
            -TargetRef "origin/$integrationBranch" `
            -AheadIsBlocked $true
        Add-SyncResult -Repository $Repository.name -Branch $state.Branch -Status $ff.Status -Action "$fetchAction+$($ff.Action)" -DevDelta (Get-DevDelta -RepositoryPath $repositoryPath) -Detail $ff.Detail
        return $ff.Status -in @('PASS', 'PLAN')
    }

    if ($state.DirtyCount -gt 0) {
        Add-SyncResult -Repository $Repository.name -Branch $state.Branch -Status 'WARN' -Action $fetchAction -DevDelta $devDelta -Detail "Preserved $($state.DirtyCount) local changes; fetched refs only."
        return $true
    }
    if (-not $state.Branch) {
        Add-SyncResult -Repository $Repository.name -Branch 'DETACHED' -Status 'WARN' -Action $fetchAction -DevDelta $devDelta -Detail 'Detached HEAD preserved; fetched refs only.'
        return $true
    }

    if ($state.Branch -eq $integrationBranch) {
        $ff = Invoke-FastForward `
            -RepositoryPath $repositoryPath `
            -TargetRef "origin/$integrationBranch" `
            -AheadIsBlocked $true
        Add-SyncResult -Repository $Repository.name -Branch $state.Branch -Status $ff.Status -Action "$fetchAction+$($ff.Action)" -DevDelta (Get-DevDelta -RepositoryPath $repositoryPath) -Detail $ff.Detail
        return $ff.Status -in @('PASS', 'PLAN')
    }

    if (-not $state.Upstream) {
        Add-SyncResult -Repository $Repository.name -Branch $state.Branch -Status 'WARN' -Action $fetchAction -DevDelta $devDelta -Detail 'Feature branch has no available upstream; no dev merge or branch switch performed.'
        return $true
    }

    $featureFf = Invoke-FastForward `
        -RepositoryPath $repositoryPath `
        -TargetRef $state.Upstream `
        -AheadIsBlocked $false
    Add-SyncResult -Repository $Repository.name -Branch $state.Branch -Status $featureFf.Status -Action "$fetchAction+$($featureFf.Action)" -DevDelta (Get-DevDelta -RepositoryPath $repositoryPath) -Detail $featureFf.Detail
    return $featureFf.Status -in @('PASS', 'PLAN', 'WARN')
}

$masterRepository = @($manifest.repositories | Where-Object { $_.name -eq 'urizo-final-master' })
if ($masterRepository.Count -ne 1) {
    throw 'Repository manifest must contain exactly one urizo-final-master entry.'
}

$masterReady = Sync-Repository -Repository $masterRepository[0] -IsMaster
if (-not $masterReady) {
    if ($AsJson) {
        [pscustomobject]@{ masterReady = $false; results = $results } | ConvertTo-Json -Depth 5
    }
    else {
        $results | Format-Table -AutoSize -Wrap
        Write-Host 'BLOCKED: Master did not reach a current clean dev state. Source working trees were not updated.'
    }
    exit 2
}

foreach ($repository in $manifest.repositories | Where-Object { $_.name -ne 'urizo-final-master' }) {
    Sync-Repository -Repository $repository | Out-Null
}

$bootstrapScript = Join-Path $masterRoot 'scripts/bootstrap-workspace.ps1'
if (-not (Test-Path -LiteralPath $bootstrapScript -PathType Leaf)) {
    throw 'Workspace bootstrap script is missing after Master synchronization.'
}
if ($WhatIf) {
    & $bootstrapScript -WorkspaceRoot $WorkspaceRoot -SyncLlmHooks -WhatIf
}
else {
    & $bootstrapScript -WorkspaceRoot $WorkspaceRoot -SyncLlmHooks
}

$activeContext = @()
$activeContextReloaded = $false
$activeContextMode = $null
if (-not $WhatIf) {
    $contextLoader = Join-Path $WorkspaceRoot '.codex/hooks/session-start.ps1'
    if (-not (Test-Path -LiteralPath $contextLoader -PathType Leaf)) {
        throw 'Shared SessionStart context loader is missing after LLM Hook synchronization.'
    }

    $instructionFingerprintAfter = Get-InstructionFingerprint
    $activeContextMode = if ($instructionFingerprintBefore -eq $instructionFingerprintAfter) { 'Checkpoint' } else { 'Full' }
    $activeContextLimit = if ($activeContextMode -eq 'Full') { 24576 } else { 4096 }
    $activeContext = @(& $contextLoader -WorkspaceRoot $WorkspaceRoot -Mode $activeContextMode -Reason Sync -MaxContextBytes $activeContextLimit)
    $activeContextText = $activeContext -join [Environment]::NewLine
    $activeContextFirstLine = @($activeContextText -split "`r?`n", 2)[0].Trim()
    $expectedFirstLine = if ($activeContextMode -eq 'Full') { 'MASTER CONTEXT PASS' } else { 'AXMS CONTEXT CHECKPOINT v2: reason=Sync' }
    if ([string]::IsNullOrWhiteSpace($activeContextText) -or $activeContextFirstLine -ne $expectedFirstLine) {
        throw "Shared context loader did not return a valid $activeContextMode payload."
    }
    $activeContextReloaded = $true
}

$blockedCount = @($results | Where-Object Status -eq 'BLOCKED').Count
$warningCount = @($results | Where-Object Status -eq 'WARN').Count
$summary = [pscustomobject]@{
    observedAt = [DateTimeOffset]::Now.ToString('o')
    workspaceRoot = $WorkspaceRoot
    masterReady = $true
    activeContextReloaded = $activeContextReloaded
    activeContextMode = $activeContextMode
    blocked = $blockedCount
    warnings = $warningCount
    results = $results
}

if ($AsJson) {
    $summary | ConvertTo-Json -Depth 5
}
else {
    $results | Format-Table -AutoSize -Wrap
    if ($activeContextReloaded) {
        Write-Host "ACTIVE SESSION CONTEXT REFRESH PASS: mode=$activeContextMode; full instructions are emitted only when an AGENTS.md fingerprint changed."
        $activeContext | Write-Output
    }
    Write-Host 'LOCAL RUNTIME CONTEXT PASS REQUIRED: report the full-script, Frontend Watch/HMR, and isolated-service update modes from the active context checkpoint.'
    Write-Host "BLOCKED=$blockedCount WARN=$warningCount"
}

if ($blockedCount -gt 0) {
    exit 2
}
