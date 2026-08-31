[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [switch]$ApproveNetwork,

    [switch]$RunLocalFull,

    [switch]$ApproveLocalFullMutation,

    [switch]$SyncLlmHooks,

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

$manifestPath = Join-Path $masterRoot 'repository-manifest.json'
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$expectedMaster = (Join-Path $WorkspaceRoot 'urizo-final-master')
if ([System.IO.Path]::GetFullPath($expectedMaster) -ne [System.IO.Path]::GetFullPath($masterRoot)) {
    throw 'Master must be the exact urizo-final-master sibling under the selected workspace root.'
}

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    & git -c "safe.directory=$RepositoryPath" -C $RepositoryPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed in ${RepositoryPath}: git $($Arguments -join ' ')"
    }
}

function Get-LocalGitConfig {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $value = @(& git -c "safe.directory=$RepositoryPath" -C $RepositoryPath config --local --get $Key 2>$null)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -eq 1) {
        return $null
    }
    if ($exitCode -ne 0) {
        throw "Could not read local Git config '$Key' in $RepositoryPath"
    }
    return (($value | ForEach-Object { $_.ToString() }) -join '').Trim()
}

function Copy-TemplateIfAbsent {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if (Test-Path -LiteralPath $Target) {
        $sourceContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $Source
        $targetContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $Target
        if ($sourceContent -eq $targetContent) {
            Write-Host "UNCHANGED template: $Target"
        }
        else {
            Write-Warning "Existing file differs and was not overwritten: $Target"
        }
        return
    }

    $targetParent = Split-Path -Parent $Target
    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        if ($WhatIf) {
            Write-Host "PLAN create template directory: $targetParent"
        }
        else {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
            Write-Host "CREATED template directory: $targetParent"
        }
    }
    if ($WhatIf) {
        Write-Host "PLAN create template: $Target"
        return
    }
    Copy-Item -LiteralPath $Source -Destination $Target
    Write-Host "CREATED template: $Target"
}

function Sync-ManagedTemplateFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    $sourceContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $Source
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        $targetContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $Target
        if ($sourceContent -eq $targetContent) {
            Write-Host "UNCHANGED managed file: $Target"
            return
        }
    }

    if ($WhatIf) {
        Write-Host "PLAN synchronize managed file: $Target"
        return
    }

    $targetParent = Split-Path -Parent $Target
    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    $writeUtf8Bom = [System.IO.Path]::GetExtension($Target) -eq '.ps1'
    [System.IO.File]::WriteAllText($Target, $sourceContent, [System.Text.UTF8Encoding]::new($writeUtf8Bom))
    Write-Host "SYNCHRONIZED managed file: $Target"
}

function Sync-ClaudeManagedHooks {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )

    $sourceConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $Source | ConvertFrom-Json
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        try {
            $targetConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $Target | ConvertFrom-Json
        }
        catch {
            throw "Claude project settings are not valid JSON; refusing to rewrite: $Target"
        }
    }
    else {
        $targetConfig = $sourceConfig
    }

    if ($null -eq $targetConfig -or $targetConfig -is [System.Array]) {
        throw "Claude project settings must be one JSON object: $Target"
    }
    $hooksProperty = $targetConfig.PSObject.Properties['hooks']
    if ($null -eq $hooksProperty -or $null -eq $hooksProperty.Value) {
        $targetConfig | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $targetConfig.hooks | Add-Member `
        -NotePropertyName SessionStart `
        -NotePropertyValue $sourceConfig.hooks.SessionStart `
        -Force
    $targetConfig.hooks | Add-Member `
        -NotePropertyName PostToolUse `
        -NotePropertyValue $sourceConfig.hooks.PostToolUse `
        -Force

    $updatedContent = ($targetConfig | ConvertTo-Json -Depth 20) + [Environment]::NewLine
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        $targetContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $Target
        if ($updatedContent -eq $targetContent) {
            Write-Host "UNCHANGED Claude managed Hooks: $Target"
            return
        }
    }

    if ($WhatIf) {
        Write-Host "PLAN synchronize Claude managed Hooks: $Target"
        return
    }

    $targetParent = Split-Path -Parent $Target
    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Target, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "SYNCHRONIZED Claude managed Hooks: $Target"
}

function Sync-ManagedTextBlock {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][string]$BeginMarker,
        [Parameter(Mandatory = $true)][string]$EndMarker
    )

    $sourceContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $Source
    $sourceStart = $sourceContent.IndexOf($BeginMarker)
    $sourceEnd = $sourceContent.IndexOf($EndMarker)
    if ($sourceStart -lt 0 -or $sourceEnd -lt $sourceStart) {
        throw "Managed policy markers are missing or invalid in template: $Source"
    }
    $sourceEnd += $EndMarker.Length
    $managedBlock = $sourceContent.Substring($sourceStart, $sourceEnd - $sourceStart)

    if (-not (Test-Path -LiteralPath $Target -PathType Leaf)) {
        if ($WhatIf) {
            Write-Host "PLAN synchronize managed policy after template creation: $Target"
            return
        }
        throw "Managed policy target is missing after template creation: $Target"
    }

    $targetContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $Target
    $targetBeginCount = [regex]::Matches($targetContent, [regex]::Escape($BeginMarker)).Count
    $targetEndCount = [regex]::Matches($targetContent, [regex]::Escape($EndMarker)).Count
    if ($targetBeginCount -ne $targetEndCount -or $targetBeginCount -gt 1) {
        throw "Managed policy markers are incomplete or duplicated; refusing to rewrite: $Target"
    }
    $targetStart = $targetContent.IndexOf($BeginMarker)
    $targetEnd = $targetContent.IndexOf($EndMarker)

    if ($targetStart -ge 0) {
        if ($targetEnd -lt $targetStart) {
            throw "Managed policy markers are out of order; refusing to rewrite: $Target"
        }
        $targetEnd += $EndMarker.Length
        $updatedContent = $targetContent.Substring(0, $targetStart) +
            $managedBlock +
            $targetContent.Substring($targetEnd)
    }
    else {
        $trimmedContent = $targetContent.TrimEnd([char[]]"`r`n")
        $updatedContent = $trimmedContent +
            [Environment]::NewLine + [Environment]::NewLine +
            $managedBlock + [Environment]::NewLine
    }

    if ($updatedContent -eq $targetContent) {
        Write-Host "UNCHANGED managed policy: $Target"
        return
    }
    if ($WhatIf) {
        Write-Host "PLAN synchronize managed policy: $Target"
        return
    }

    [System.IO.File]::WriteAllText($Target, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "SYNCHRONIZED managed policy: $Target"
}

function Sync-WorkspaceLlmConfiguration {
    $templateRoot = Join-Path $masterRoot 'templates/workspace'
    $agentTemplate = Join-Path $templateRoot 'AGENTS.md'
    $workspaceAgent = Join-Path $WorkspaceRoot 'AGENTS.md'
    if (-not (Test-Path -LiteralPath $workspaceAgent -PathType Leaf)) {
        Copy-TemplateIfAbsent -Source $agentTemplate -Target $workspaceAgent
    }
    Sync-ManagedTextBlock `
        -Source $agentTemplate `
        -Target $workspaceAgent `
        -BeginMarker '<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:BEGIN -->' `
        -EndMarker '<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:END -->'

    $claudeTemplate = Join-Path $templateRoot 'CLAUDE.md'
    $workspaceClaude = Join-Path $WorkspaceRoot 'CLAUDE.md'
    if (-not (Test-Path -LiteralPath $workspaceClaude -PathType Leaf)) {
        Copy-TemplateIfAbsent -Source $claudeTemplate -Target $workspaceClaude
    }
    Sync-ManagedTextBlock `
        -Source $claudeTemplate `
        -Target $workspaceClaude `
        -BeginMarker '<!-- AXMS-MANAGED-CLAUDE-ROUTING:BEGIN -->' `
        -EndMarker '<!-- AXMS-MANAGED-CLAUDE-ROUTING:END -->'

    Sync-ManagedTemplateFile `
        -Source (Join-Path $templateRoot 'codex/hooks.json') `
        -Target (Join-Path $WorkspaceRoot '.codex/hooks.json')
    Sync-ManagedTemplateFile `
        -Source (Join-Path $templateRoot 'codex/hooks/session-start.ps1') `
        -Target (Join-Path $WorkspaceRoot '.codex/hooks/session-start.ps1')
    Sync-ManagedTemplateFile `
        -Source (Join-Path $templateRoot 'codex/hooks/post-pull-context.ps1') `
        -Target (Join-Path $WorkspaceRoot '.codex/hooks/post-pull-context.ps1')
    $workspaceGitHook = Join-Path $WorkspaceRoot '.githooks/pre-push'
    Sync-ManagedTemplateFile `
        -Source (Join-Path $templateRoot 'githooks/pre-push') `
        -Target $workspaceGitHook

    $isWindowsHost = [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
    $claudeSettingsName = if ($isWindowsHost) { 'settings.windows.json' } else { 'settings.unix.json' }
    Sync-ClaudeManagedHooks `
        -Source (Join-Path $templateRoot "claude/$claudeSettingsName") `
        -Target (Join-Path $WorkspaceRoot '.claude/settings.json')

    $workspaceGitHookRoot = [IO.Path]::GetFullPath((Join-Path $WorkspaceRoot '.githooks'))
    foreach ($repository in $manifest.repositories) {
        $repositoryPath = [IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $repository.relativePath))
        if (-not (Test-Path -LiteralPath (Join-Path $repositoryPath '.git'))) {
            if ($WhatIf) {
                Write-Host "PLAN install Pull gate after repository creation: $($repository.name)"
                continue
            }
            throw "Cannot install the Pull gate because a repository checkout is missing: $repositoryPath"
        }

        $existingHooksPath = Get-LocalGitConfig -RepositoryPath $repositoryPath -Key 'core.hooksPath'
        if ($existingHooksPath) {
            $normalizedExisting = $existingHooksPath.Replace('/', '\').TrimEnd('\')
            $normalizedManaged = $workspaceGitHookRoot.Replace('/', '\').TrimEnd('\')
            if (-not $normalizedExisting.Equals($normalizedManaged, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Existing core.hooksPath differs; refusing to overwrite it: repository=$($repository.name); value=$existingHooksPath"
            }
        }

        $existingWorkspaceRoot = Get-LocalGitConfig -RepositoryPath $repositoryPath -Key 'axms.workspaceRoot'
        if ($existingWorkspaceRoot -and
            -not [IO.Path]::GetFullPath($existingWorkspaceRoot).Equals([IO.Path]::GetFullPath($WorkspaceRoot), [StringComparison]::OrdinalIgnoreCase)) {
            throw "Existing axms.workspaceRoot differs; refusing to overwrite it: repository=$($repository.name); value=$existingWorkspaceRoot"
        }

        if ($WhatIf) {
            Write-Host "PLAN install Pull gate Git config: $($repository.name)"
        }
        else {
            Invoke-Git -RepositoryPath $repositoryPath -Arguments @('config', '--local', 'core.hooksPath', $workspaceGitHookRoot)
            Invoke-Git -RepositoryPath $repositoryPath -Arguments @('config', '--local', 'axms.workspaceRoot', $WorkspaceRoot)
            Write-Host "INSTALLED Pull gate Git config: $($repository.name)"
        }
    }

    if (-not $isWindowsHost -and -not $WhatIf) {
        & chmod +x $workspaceGitHook
        if ($LASTEXITCODE -ne 0) {
            throw "Could not mark the managed pre-push Hook executable: $workspaceGitHook"
        }
    }

    if ($WhatIf) {
        Write-Host 'CONTEXT AND PULL GATE SETUP PLAN: lifecycle context, compact checkpoints, and read-only pre-push enforcement were planned.'
    }
    else {
        Write-Host 'CONTEXT AND PULL GATE SETUP PASS: Codex and Claude use bounded context refresh; Git push validates a fresh pre-PR Pull receipt.'
    }
}

if ($SyncLlmHooks) {
    Sync-WorkspaceLlmConfiguration
    return
}

$plans = [System.Collections.Generic.List[object]]::new()
foreach ($repository in $manifest.repositories) {
    $target = Join-Path $WorkspaceRoot $repository.relativePath
    if ($repository.name -eq 'urizo-final-master') {
        if (-not (Test-Path -LiteralPath (Join-Path $target '.git'))) {
            throw 'The running Master folder is not a Git checkout.'
        }
        $remote = (& git -c "safe.directory=$target" -C $target remote get-url origin 2>$null) -join ''
        if ($LASTEXITCODE -ne 0 -or $remote -ne $repository.remote) {
            throw 'Master origin does not match the canonical manifest.'
        }
        $plans.Add([pscustomobject]@{ Repository = $repository; Target = $target; Action = 'fetch' })
        continue
    }

    if (-not (Test-Path -LiteralPath $target)) {
        $plans.Add([pscustomobject]@{ Repository = $repository; Target = $target; Action = 'clone' })
        continue
    }
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        throw "Expected repository target is not a directory: $target"
    }

    $entries = @(Get-ChildItem -Force -LiteralPath $target)
    if (-not (Test-Path -LiteralPath (Join-Path $target '.git'))) {
        if ($entries.Count -eq 0) {
            $plans.Add([pscustomobject]@{ Repository = $repository; Target = $target; Action = 'clone' })
            continue
        }
        throw "Refusing to overwrite a non-empty non-repository folder: $target"
    }

    $remote = (& git -c "safe.directory=$target" -C $target remote get-url origin 2>$null) -join ''
    if ($LASTEXITCODE -ne 0 -or $remote -ne $repository.remote) {
        throw "Canonical origin mismatch; remote was not changed: $target"
    }
    $plans.Add([pscustomobject]@{ Repository = $repository; Target = $target; Action = 'fetch' })
}

$plans | Select-Object @{Name='Repository';Expression={$_.Repository.name}}, Action, Target | Format-Table -AutoSize

if ($WhatIf) {
    Write-Host 'WhatIf complete. No network, template, Git, runtime, or database change was performed.'
    exit 0
}

if (-not $ApproveNetwork) {
    if (@($plans | Where-Object Action -eq 'clone').Count -gt 0) {
        throw 'A required repository is missing. Re-run only after approving network clone with -ApproveNetwork.'
    }
    Write-Warning 'Network was not approved; existing repositories were not fetched.'
}
else {
    foreach ($plan in $plans) {
        if ($plan.Action -eq 'clone') {
            & git clone --origin origin --branch $manifest.branches.integration $plan.Repository.remote $plan.Target
            if ($LASTEXITCODE -ne 0) {
                throw "Clone failed. Any partial target was left untouched for manual inspection: $($plan.Target)"
            }
            Write-Host "CLONED $($plan.Repository.name) on $($manifest.branches.integration)"
        }
        else {
            Invoke-Git -RepositoryPath $plan.Target -Arguments @('fetch', '--prune', 'origin')
            Write-Host "FETCHED refs only: $($plan.Repository.name)"
        }
    }
}

$templateRoot = Join-Path $masterRoot 'templates/workspace'
Sync-WorkspaceLlmConfiguration
Copy-TemplateIfAbsent -Source (Join-Path $templateRoot 'AX-Module-Studio.code-workspace') -Target (Join-Path $WorkspaceRoot 'AX-Module-Studio.code-workspace')

if ($RunLocalFull) {
    if (-not $ApproveLocalFullMutation) {
        throw 'Local-full bootstrap creates local secrets, builds images, applies Flyway, and changes container state. Re-run only with -ApproveLocalFullMutation after approval.'
    }
    if (-not $ApproveNetwork) {
        throw 'Local-full builds may require dependency/image downloads. -ApproveNetwork is also required.'
    }

    foreach ($repository in $manifest.repositories | Where-Object { $_.name -ne 'urizo-final-master' }) {
        $path = Join-Path $WorkspaceRoot $repository.relativePath
        $dirty = @(& git -c "safe.directory=$path" -C $path status --porcelain=v1)
        if ($LASTEXITCODE -ne 0) {
            throw "Could not inspect source worktree: $($repository.name)"
        }
        if (@($dirty | Where-Object { $_ }).Count -gt 0) {
            throw "Local-full bootstrap stopped because a source worktree is dirty: $($repository.name)"
        }
    }

    $backendBootstrap = Join-Path $WorkspaceRoot 'urizo-final-backend/scripts/bootstrap-dev.ps1'
    if (-not (Test-Path -LiteralPath $backendBootstrap -PathType Leaf)) {
        throw 'Backend bootstrap-dev.ps1 is missing. The reviewed source baseline is not available on this checkout.'
    }
    & $backendBootstrap -Profile full
    if ($LASTEXITCODE -ne 0) {
        throw "Backend local-full bootstrap failed with exit code $LASTEXITCODE."
    }

    $health = Join-Path $PSScriptRoot 'health-workspace.ps1'
    & $health -WorkspaceRoot $WorkspaceRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Workspace health failed with exit code $LASTEXITCODE."
    }
}
else {
    Write-Host 'Repository assembly complete. Local-full mutation was not requested.'
}
