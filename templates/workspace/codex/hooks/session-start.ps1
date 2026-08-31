[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [ValidateSet('Full', 'Checkpoint')]
    [string]$Mode = 'Full',

    [ValidateSet('Lifecycle', 'Resume', 'Pull', 'Sync', 'PreWork', 'PrePr')]
    [string]$Reason = 'Lifecycle',

    [ValidateRange(1024, 1048576)]
    [int]$MaxContextBytes = 24576
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Find-WorkspaceRoot {
    param([Parameter(Mandatory = $true)][string]$StartPath)

    $cursor = (Resolve-Path -LiteralPath $StartPath).Path
    while ($true) {
        if ((Test-Path -LiteralPath (Join-Path $cursor 'AGENTS.md') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $cursor 'urizo-final-master/AGENTS.md') -PathType Leaf)) {
            return $cursor
        }

        $parent = Split-Path -Parent $cursor
        if (-not $parent -or $parent -eq $cursor) {
            return $null
        }
        $cursor = $parent
    }
}

function Get-WorkspaceRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $resolved.Substring($Root.Length).TrimStart([char[]]'\/').Replace('\', '/')
    }
    return $resolved
}

function Get-NearestAgentsPath {
    param(
        [Parameter(Mandatory = $true)][string]$StartPath,
        [Parameter(Mandatory = $true)][string]$Root
    )

    if (-not $StartPath.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $null
    }

    $cursor = $StartPath
    while ($cursor -and $cursor -ne $Root) {
        $candidate = Join-Path $cursor 'AGENTS.md'
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        $parent = Split-Path -Parent $cursor
        if (-not $parent -or $parent -eq $cursor) {
            break
        }
        $cursor = $parent
    }
    return $null
}

function Get-FileFingerprint {
    param([Parameter(Mandatory = $true)][string]$Path)

    $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    return $hash.Substring(0, 12)
}

function Invoke-GitRead {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& git -c "safe.directory=$RepositoryPath" -C $RepositoryPath @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return $null
    }
    return (($output | ForEach-Object { $_.ToString() }) -join "`n").Trim()
}

function Get-GitContext {
    param([Parameter(Mandatory = $true)][string]$StartPath)

    $repositoryRoot = Invoke-GitRead -RepositoryPath $StartPath -Arguments @('rev-parse', '--show-toplevel')
    if (-not $repositoryRoot) {
        return [pscustomobject]@{
            Repository = 'workspace-parent'
            Branch = 'n/a'
            Head = 'n/a'
            State = 'not-a-repository'
        }
    }

    $repositoryRoot = $repositoryRoot.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $branch = Invoke-GitRead -RepositoryPath $repositoryRoot -Arguments @('branch', '--show-current')
    $head = Invoke-GitRead -RepositoryPath $repositoryRoot -Arguments @('rev-parse', '--short=12', 'HEAD')
    $status = Invoke-GitRead -RepositoryPath $repositoryRoot -Arguments @('status', '--porcelain')
    $origin = Invoke-GitRead -RepositoryPath $repositoryRoot -Arguments @('remote', 'get-url', 'origin')
    $repository = Split-Path -Leaf $repositoryRoot
    if ($origin) {
        $originLeaf = (($origin -replace '\\', '/').TrimEnd('/') -split '/')[-1]
        $originLeaf = $originLeaf -replace '\.git$', ''
        if ($originLeaf) {
            $repository = $originLeaf
        }
    }

    return [pscustomobject]@{
        Repository = $repository
        Branch = if ($branch) { $branch } else { 'detached' }
        Head = if ($head) { $head } else { 'unknown' }
        State = if ($status) { 'dirty' } else { 'clean' }
    }
}

function Get-InstructionSelection {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$CurrentPath
    )

    $workspaceAgents = Join-Path $Root 'AGENTS.md'
    $canonicalMasterAgents = Join-Path $Root 'urizo-final-master/AGENTS.md'
    foreach ($requiredPath in @($workspaceAgents, $canonicalMasterAgents)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Required instruction file is missing: $requiredPath"
        }
    }

    $effectiveMasterAgents = (Resolve-Path -LiteralPath $canonicalMasterAgents).Path
    $sourceAgents = $null
    $nearestAgents = Get-NearestAgentsPath -StartPath $CurrentPath -Root $Root
    if ($nearestAgents) {
        $masterHeading = (Get-Content -Encoding UTF8 -TotalCount 1 -LiteralPath $canonicalMasterAgents).Trim()
        $nearestHeading = (Get-Content -Encoding UTF8 -TotalCount 1 -LiteralPath $nearestAgents).Trim()
        if ($nearestHeading -eq $masterHeading) {
            $effectiveMasterAgents = $nearestAgents
        }
        elseif ($nearestAgents -ne (Resolve-Path -LiteralPath $workspaceAgents).Path) {
            $sourceAgents = $nearestAgents
        }
    }

    return [pscustomobject]@{
        WorkspaceAgents = (Resolve-Path -LiteralPath $workspaceAgents).Path
        MasterAgents = $effectiveMasterAgents
        SourceAgents = $sourceAgents
    }
}

function Add-Checkpoint {
    param(
        [Parameter(Mandatory = $true)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory = $true)]$Selection,
        [Parameter(Mandatory = $true)]$GitContext,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$CheckpointReason
    )

    [void]$Builder.AppendLine("AXMS CONTEXT CHECKPOINT v2: reason=$CheckpointReason")
    [void]$Builder.AppendLine("- Git: repo=$($GitContext.Repository); branch=$($GitContext.Branch); head=$($GitContext.Head); state=$($GitContext.State)")
    [void]$Builder.AppendLine("- Instructions: workspace=$(Get-FileFingerprint -Path $Selection.WorkspaceAgents); master=$(Get-FileFingerprint -Path $Selection.MasterAgents)")
    if ($Selection.SourceAgents) {
        $sourceRelative = Get-WorkspaceRelativePath -Root $Root -Path $Selection.SourceAgents
        [void]$Builder.AppendLine("- Active Source: $sourceRelative; sha256=$(Get-FileFingerprint -Path $Selection.SourceAgents)")
    }
    else {
        [void]$Builder.AppendLine('- Active Source: none; select the target repository before implementation.')
    }
    [void]$Builder.AppendLine('- Before implementation: update canonical dev first, then create/reuse the isolated Worktree with the approved Work ID.')
    [void]$Builder.AppendLine('- Before PR: pass the dev Pull gate again; PR base is dev; never push directly to dev or main.')
    [void]$Builder.AppendLine('- Preserve dirty, diverged, local-only, open-PR, and unmerged work. Never expose secrets or expand scope without approval.')
    [void]$Builder.AppendLine('- Runtime: choose full, frontend-live, or isolated from the actual changed Sources and report LOCAL RUNTIME CONTEXT PASS before mutation.')
    [void]$Builder.AppendLine('- Response: report MASTER CONTEXT PASS/BLOCKED and keep the common response format from the active instructions.')
    [void]$Builder.AppendLine('- Full canonical instructions are loaded only for startup/clear/compact or when an instruction file changes.')
}

try {
    if ($WorkspaceRoot) {
        if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
            throw "Workspace root does not exist: $WorkspaceRoot"
        }
        $WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
    }
    else {
        $WorkspaceRoot = Find-WorkspaceRoot -StartPath (Get-Location).Path
    }

    if (-not $WorkspaceRoot) {
        throw 'Could not locate the AX Module Studio workspace root.'
    }

    $currentPath = (Get-Location).Path
    $selection = Get-InstructionSelection -Root $WorkspaceRoot -CurrentPath $currentPath
    $gitContext = Get-GitContext -StartPath $currentPath
    $builder = [System.Text.StringBuilder]::new()

    if ($Mode -eq 'Full') {
        [void]$builder.AppendLine('MASTER CONTEXT PASS')
        [void]$builder.AppendLine("Canonical AXMS instructions refreshed: reason=$Reason. Workspace AGENTS is supplied by native directory routing and is not duplicated below.")
        Add-Checkpoint -Builder $builder -Selection $selection -GitContext $gitContext -Root $WorkspaceRoot -CheckpointReason $Reason

        foreach ($path in @($selection.MasterAgents, $selection.SourceAgents)) {
            if (-not $path) {
                continue
            }
            $relative = Get-WorkspaceRelativePath -Root $WorkspaceRoot -Path $path
            [void]$builder.AppendLine()
            [void]$builder.AppendLine("===== BEGIN $relative =====")
            [void]$builder.AppendLine([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8).TrimEnd())
            [void]$builder.AppendLine("===== END $relative =====")
        }
    }
    else {
        Add-Checkpoint -Builder $builder -Selection $selection -GitContext $gitContext -Root $WorkspaceRoot -CheckpointReason $Reason
    }

    $payload = $builder.ToString()
    $payloadBytes = [System.Text.Encoding]::UTF8.GetByteCount($payload)
    if ($payloadBytes -gt $MaxContextBytes) {
        throw "$Mode context payload is $payloadBytes bytes, exceeding the $MaxContextBytes-byte safety limit. Read the active AGENTS.md files directly."
    }

    Write-Output $payload
}
catch {
    $blockedReason = "MASTER CONTEXT BLOCKED: $($_.Exception.Message)"
    [ordered]@{
        continue = $false
        stopReason = $blockedReason
        systemMessage = $blockedReason
    } | ConvertTo-Json -Compress | Write-Output
}
