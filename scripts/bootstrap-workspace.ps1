[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [switch]$ApproveNetwork,

    [switch]$RunLocalFull,

    [switch]$ApproveLocalFullMutation,

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
    if ($WhatIf) {
        Write-Host "PLAN create template: $Target"
        return
    }
    Copy-Item -LiteralPath $Source -Destination $Target
    Write-Host "CREATED template: $Target"
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

$templateRoot = Join-Path $masterRoot 'templates\workspace'
Copy-TemplateIfAbsent -Source (Join-Path $templateRoot 'AGENTS.md') -Target (Join-Path $WorkspaceRoot 'AGENTS.md')
Copy-TemplateIfAbsent -Source (Join-Path $templateRoot 'CLAUDE.md') -Target (Join-Path $WorkspaceRoot 'CLAUDE.md')
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

    $backendBootstrap = Join-Path $WorkspaceRoot 'urizo-final-backend\scripts\bootstrap-dev.ps1'
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
