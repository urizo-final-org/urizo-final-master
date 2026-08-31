[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [Parameter(Mandatory = $true)]
    [ValidateSet('spring-app', 'frontend', 'coding-runtime', 'mcp-server')]
    [string]$Service,

    [ValidateSet('spring-core', 'full')]
    [string]$Profile = 'full',

    [string]$SourceRoot,

    [switch]$ApproveLocalMutation,

    [switch]$ApproveNetwork,

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

$sourceContracts = @{
    'spring-app' = [pscustomobject]@{
        RepositoryName = 'urizo-final-backend'
        DefaultPath = Join-Path $WorkspaceRoot 'urizo-final-backend'
        RequiredEntries = @('Dockerfile', 'pom.xml', 'src')
    }
    'frontend' = [pscustomobject]@{
        RepositoryName = 'urizo-final-frontend'
        DefaultPath = Join-Path $WorkspaceRoot 'urizo-final-frontend'
        RequiredEntries = @('Dockerfile', 'package.json', 'pnpm-lock.yaml', 'src')
    }
    'coding-runtime' = [pscustomobject]@{
        RepositoryName = 'urizo-final-orchestrator'
        DefaultPath = Join-Path $WorkspaceRoot 'urizo-final-orchestrator'
        RequiredEntries = @('Dockerfile', 'pyproject.toml', 'uv.lock', 'src')
    }
    'mcp-server' = [pscustomobject]@{
        RepositoryName = 'urizo-final-mcp-server'
        DefaultPath = Join-Path $WorkspaceRoot 'urizo-final-mcp-server'
        RequiredEntries = @('Dockerfile', 'pyproject.toml', 'uv.lock', 'src')
    }
}
$sourceContract = $sourceContracts[$Service]
if (-not $SourceRoot) {
    $SourceRoot = $sourceContract.DefaultPath
}
if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
    throw "$($sourceContract.RepositoryName) source root does not exist: $SourceRoot"
}
$SourceRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
$topLevel = (& git -c "safe.directory=$SourceRoot" -C $SourceRoot rev-parse --show-toplevel 2>$null) -join ''
if ($LASTEXITCODE -ne 0 -or [System.IO.Path]::GetFullPath($topLevel) -ne [System.IO.Path]::GetFullPath($SourceRoot)) {
    throw "$($sourceContract.RepositoryName) source root must be the root of a Git worktree: $SourceRoot"
}
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json
$repository = @($manifest.repositories | Where-Object name -eq $sourceContract.RepositoryName) | Select-Object -First 1
$remote = (& git -c "safe.directory=$SourceRoot" -C $SourceRoot remote get-url origin 2>$null) -join ''
if ($null -eq $repository -or $LASTEXITCODE -ne 0 -or $remote -ne $repository.remote) {
    throw "$($sourceContract.RepositoryName) source root does not match the canonical origin: $SourceRoot"
}
foreach ($entry in $sourceContract.RequiredEntries) {
    if (-not (Test-Path -LiteralPath (Join-Path $SourceRoot $entry))) {
        throw "$($sourceContract.RepositoryName) source root is incomplete; missing '$entry': $SourceRoot"
    }
}

$backendRunner = Join-Path $WorkspaceRoot 'urizo-final-backend/scripts/rebuild-local-service.ps1'
if (-not (Test-Path -LiteralPath $backendRunner -PathType Leaf)) {
    throw 'Backend rebuild-local-service.ps1 is missing. Synchronize Backend dev before a partial local rebuild.'
}

$runnerArguments = @{
    Service = $Service
    Profile = $Profile
    SourceRoot = $SourceRoot
    WaitTimeoutSeconds = $WaitTimeoutSeconds
}
if ($ApproveLocalMutation) { $runnerArguments.ApproveLocalMutation = $true }
if ($ApproveNetwork) { $runnerArguments.ApproveNetwork = $true }

& $backendRunner @runnerArguments
if ($LASTEXITCODE -ne 0) {
    throw "Backend partial local rebuild failed with exit code $LASTEXITCODE."
}
