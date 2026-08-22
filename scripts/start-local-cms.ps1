[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

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

$backendRunner = Join-Path $WorkspaceRoot 'urizo-final-backend/scripts/start-cms-local.ps1'
if (-not (Test-Path -LiteralPath $backendRunner -PathType Leaf)) {
    throw 'Backend start-cms-local.ps1 is missing. Synchronize the Backend dev branch before local CMS startup.'
}

$runnerArguments = @{
    WaitTimeoutSeconds = $WaitTimeoutSeconds
}
if ($ApproveLocalMutation) { $runnerArguments.ApproveLocalMutation = $true }
if ($ApproveNetwork) { $runnerArguments.ApproveNetwork = $true }
if ($Rebuild) { $runnerArguments.Rebuild = $true }

& $backendRunner @runnerArguments
if ($LASTEXITCODE -ne 0) {
    throw "Backend CMS local runner failed with exit code $LASTEXITCODE."
}
