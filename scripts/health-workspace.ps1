[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [ValidateRange(5, 1800)]
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

$backendHealth = Join-Path $WorkspaceRoot 'urizo-final-backend/scripts/health.ps1'
if (-not (Test-Path -LiteralPath $backendHealth -PathType Leaf)) {
    throw 'Backend health.ps1 is missing. The source baseline may not be published on this checkout.'
}

& $backendHealth -Profile full -WaitTimeoutSeconds $WaitTimeoutSeconds
if ($LASTEXITCODE -ne 0) {
    throw "Backend local-full health failed with exit code $LASTEXITCODE."
}
