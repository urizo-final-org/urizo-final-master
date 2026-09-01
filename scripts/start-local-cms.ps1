[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [ValidateSet('spring-core', 'full')]
    [string]$Profile = 'spring-core',

    [string]$BackendSourceRoot,

    [string]$FrontendSourceRoot,

    [string]$OrchestratorSourceRoot,

    [string]$McpSourceRoot,

    [switch]$ApproveLocalMutation,

    [switch]$ApproveNetwork,

    [switch]$Rebuild,

    [switch]$RequireCleanSourceBindings,

    [ValidateRange(30, 1800)]
    [int]$WaitTimeoutSeconds = 180
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

if ($Profile -eq 'spring-core' -and ($OrchestratorSourceRoot -or $McpSourceRoot)) {
    throw 'OrchestratorSourceRoot and McpSourceRoot are valid only with -Profile full.'
}
$repositoryManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json

function Resolve-GitSourceRoot {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$RequiredEntries
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$RepositoryName source root does not exist: $Path"
    }
    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $topLevel = (& git -c "safe.directory=$resolvedPath" -C $resolvedPath rev-parse --show-toplevel 2>$null) -join ''
    if ($LASTEXITCODE -ne 0 -or [System.IO.Path]::GetFullPath($topLevel) -ne [System.IO.Path]::GetFullPath($resolvedPath)) {
        throw "$RepositoryName source root must be the root of a Git worktree: $resolvedPath"
    }

    $repository = @($repositoryManifest.repositories | Where-Object name -eq $RepositoryName) | Select-Object -First 1
    $remote = (& git -c "safe.directory=$resolvedPath" -C $resolvedPath remote get-url origin 2>$null) -join ''
    if ($null -eq $repository -or $LASTEXITCODE -ne 0 -or $remote -ne $repository.remote) {
        throw "$RepositoryName source root does not match the canonical origin: $resolvedPath"
    }
    foreach ($entry in $RequiredEntries) {
        if (-not (Test-Path -LiteralPath (Join-Path $resolvedPath $entry))) {
            throw "$RepositoryName source root is incomplete; missing '$entry': $resolvedPath"
        }
    }
    return $resolvedPath
}

function Get-SourceBinding {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$SourceRoot
    )

    $sourceSha = (& git -c "safe.directory=$SourceRoot" -C $SourceRoot rev-parse HEAD 2>$null) -join ''
    if ($LASTEXITCODE -ne 0 -or $sourceSha -notmatch '^[0-9a-f]{40}$') {
        throw "$RepositoryName source SHA could not be resolved: $SourceRoot"
    }
    $sourceStatus = @(& git -c "safe.directory=$SourceRoot" -C $SourceRoot status --porcelain=v1 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "$RepositoryName source status could not be resolved: $SourceRoot"
    }
    return [pscustomobject]@{
        RepositoryName = $RepositoryName
        SourceRoot = $SourceRoot
        SourceSha = $sourceSha
        Dirty = @($sourceStatus | Where-Object { $_ }).Count -gt 0
    }
}

$requestedSourceRoots = @(
    $BackendSourceRoot,
    $FrontendSourceRoot,
    $OrchestratorSourceRoot,
    $McpSourceRoot
)
$sourceBindingRequested = $Rebuild -or @($requestedSourceRoots | Where-Object { $_ }).Count -gt 0
if ($RequireCleanSourceBindings -and -not $sourceBindingRequested) {
    throw 'RequireCleanSourceBindings requires -Rebuild or explicit SourceRoot bindings.'
}
if ($sourceBindingRequested) {
    if (-not $BackendSourceRoot) { $BackendSourceRoot = Join-Path $WorkspaceRoot 'urizo-final-backend' }
    if (-not $FrontendSourceRoot) { $FrontendSourceRoot = Join-Path $WorkspaceRoot 'urizo-final-frontend' }
    $BackendSourceRoot = Resolve-GitSourceRoot -RepositoryName 'urizo-final-backend' -Path $BackendSourceRoot `
        -RequiredEntries @('Dockerfile', 'pom.xml', 'src')
    $FrontendSourceRoot = Resolve-GitSourceRoot -RepositoryName 'urizo-final-frontend' -Path $FrontendSourceRoot `
        -RequiredEntries @('Dockerfile', 'package.json', 'pnpm-lock.yaml', 'src')

    if ($Profile -eq 'full') {
        if (-not $OrchestratorSourceRoot) { $OrchestratorSourceRoot = Join-Path $WorkspaceRoot 'urizo-final-orchestrator' }
        if (-not $McpSourceRoot) { $McpSourceRoot = Join-Path $WorkspaceRoot 'urizo-final-mcp-server' }
        $OrchestratorSourceRoot = Resolve-GitSourceRoot -RepositoryName 'urizo-final-orchestrator' -Path $OrchestratorSourceRoot `
            -RequiredEntries @('Dockerfile', 'pyproject.toml', 'uv.lock', 'src')
        $McpSourceRoot = Resolve-GitSourceRoot -RepositoryName 'urizo-final-mcp-server' -Path $McpSourceRoot `
            -RequiredEntries @('Dockerfile', 'pyproject.toml', 'uv.lock', 'src')
    }
}

$sourceBindings = [System.Collections.Generic.List[object]]::new()
if ($sourceBindingRequested) {
    $sourceBindings.Add((Get-SourceBinding -RepositoryName 'urizo-final-master' -SourceRoot $masterRoot))
    $sourceBindings.Add((Get-SourceBinding -RepositoryName 'urizo-final-backend' -SourceRoot $BackendSourceRoot))
    $sourceBindings.Add((Get-SourceBinding -RepositoryName 'urizo-final-frontend' -SourceRoot $FrontendSourceRoot))
    if ($Profile -eq 'full') {
        $sourceBindings.Add((Get-SourceBinding -RepositoryName 'urizo-final-orchestrator' -SourceRoot $OrchestratorSourceRoot))
        $sourceBindings.Add((Get-SourceBinding -RepositoryName 'urizo-final-mcp-server' -SourceRoot $McpSourceRoot))
    }
}

if ($RequireCleanSourceBindings) {
    $dirtyBinding = @($sourceBindings | Where-Object { $_.Dirty }) | Select-Object -First 1
    if ($dirtyBinding) {
        throw "Final runtime verification requires a clean Source binding: $($dirtyBinding.RepositoryName)"
    }
}

$backendRunnerRoot = if ($sourceBindingRequested) {
    $BackendSourceRoot
}
else {
    Join-Path $WorkspaceRoot 'urizo-final-backend'
}
$backendRunner = Join-Path $backendRunnerRoot 'scripts/start-cms-local.ps1'
if (-not (Test-Path -LiteralPath $backendRunner -PathType Leaf)) {
    throw 'Backend start-cms-local.ps1 is missing. Synchronize the Backend dev branch before local CMS startup.'
}

$runnerArguments = @{
    Profile = $Profile
    WaitTimeoutSeconds = $WaitTimeoutSeconds
}
if ($ApproveLocalMutation) { $runnerArguments.ApproveLocalMutation = $true }
if ($ApproveNetwork) { $runnerArguments.ApproveNetwork = $true }
if ($Rebuild) { $runnerArguments.Rebuild = $true }
if ($BackendSourceRoot) { $runnerArguments.BackendSourceRoot = $BackendSourceRoot }
if ($FrontendSourceRoot) { $runnerArguments.FrontendSourceRoot = $FrontendSourceRoot }
if ($OrchestratorSourceRoot) { $runnerArguments.OrchestratorSourceRoot = $OrchestratorSourceRoot }
if ($McpSourceRoot) { $runnerArguments.McpSourceRoot = $McpSourceRoot }

foreach ($binding in $sourceBindings) {
    Write-Output ("RUNTIME SOURCE BINDING: repository={0}; root={1}; sha={2}; dirty={3}" -f `
        $binding.RepositoryName, $binding.SourceRoot, $binding.SourceSha, $binding.Dirty)
}
& $backendRunner @runnerArguments
if ($LASTEXITCODE -ne 0) {
    throw "Backend $Profile local runner failed with exit code $LASTEXITCODE."
}
foreach ($binding in $sourceBindings) {
    $verifiedSha = (& git -c "safe.directory=$($binding.SourceRoot)" -C $binding.SourceRoot rev-parse HEAD 2>$null) -join ''
    if ($LASTEXITCODE -ne 0 -or $verifiedSha -ne $binding.SourceSha) {
        throw "Runtime source HEAD changed while $Profile was starting: $($binding.RepositoryName)"
    }
    if ($RequireCleanSourceBindings) {
        $verifiedStatus = @(& git -c "safe.directory=$($binding.SourceRoot)" -C $binding.SourceRoot status --porcelain=v1 2>$null)
        if ($LASTEXITCODE -ne 0 -or @($verifiedStatus | Where-Object { $_ }).Count -gt 0) {
            throw "Runtime source became dirty while $Profile was starting: $($binding.RepositoryName)"
        }
    }
    Write-Output ("RUNTIME SOURCE VERIFIED: repository={0}; sha={1}" -f `
        $binding.RepositoryName, $verifiedSha)
}
