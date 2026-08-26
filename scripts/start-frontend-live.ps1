[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [string]$FrontendSourceRoot,

    [switch]$ApproveLocalMutation,

    [switch]$RestoreImageOnly,

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

if (-not $FrontendSourceRoot) {
    $FrontendSourceRoot = Join-Path $WorkspaceRoot 'urizo-final-frontend'
}
if (-not (Test-Path -LiteralPath $FrontendSourceRoot -PathType Container)) {
    throw "Frontend source root does not exist: $FrontendSourceRoot"
}
$FrontendSourceRoot = (Resolve-Path -LiteralPath $FrontendSourceRoot).Path

$backendRunner = Join-Path $WorkspaceRoot 'urizo-final-backend/scripts/start-frontend-live.ps1'
if (-not (Test-Path -LiteralPath $backendRunner -PathType Leaf)) {
    throw 'Backend start-frontend-live.ps1 is missing. Synchronize Backend dev before Frontend live development.'
}

$runnerArguments = @{
    FrontendSourceRoot = $FrontendSourceRoot
    WaitTimeoutSeconds = $WaitTimeoutSeconds
}
if ($ApproveLocalMutation) { $runnerArguments.ApproveLocalMutation = $true }
if ($RestoreImageOnly) { $runnerArguments.RestoreImageOnly = $true }

& $backendRunner @runnerArguments
if ($LASTEXITCODE -ne 0) {
    throw "Backend Frontend live runner failed with exit code $LASTEXITCODE."
}
