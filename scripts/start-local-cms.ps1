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

$requestedSourceRoots = @(
    $BackendSourceRoot,
    $FrontendSourceRoot,
    $OrchestratorSourceRoot,
    $McpSourceRoot
)
$sourceBindingRequested = $Rebuild -or @($requestedSourceRoots | Where-Object { $_ }).Count -gt 0
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

$backendRunner = Join-Path $WorkspaceRoot 'urizo-final-backend/scripts/start-cms-local.ps1'
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

& $backendRunner @runnerArguments
if ($LASTEXITCODE -ne 0) {
    throw "Backend $Profile local runner failed with exit code $LASTEXITCODE."
}
