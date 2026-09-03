[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CanonicalBackendRoot,

    [Parameter(Mandatory = $true)]
    [string]$WorktreeRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar)
}

function Test-WindowsHost {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return $true
    }
    return $IsWindows
}

$canonicalRoot = Get-NormalizedPath -Path $CanonicalBackendRoot
$featureRoot = Get-NormalizedPath -Path $WorktreeRoot
if ($canonicalRoot -eq $featureRoot) {
    throw 'Backend Feature Worktree must be distinct from the canonical checkout.'
}
foreach ($root in @($canonicalRoot, $featureRoot)) {
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        throw "Backend checkout does not exist: $root"
    }
}

$canonicalSecrets = Join-Path $canonicalRoot '.local\secrets'
$featureLocal = Join-Path $featureRoot '.local'
$featureSecrets = Join-Path $featureLocal 'secrets'
if (-not (Test-Path -LiteralPath $canonicalSecrets -PathType Container)) {
    New-Item -ItemType Directory -Path $canonicalSecrets -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $featureLocal -PathType Container)) {
    New-Item -ItemType Directory -Path $featureLocal | Out-Null
}

$existingSecrets = Get-Item -LiteralPath $featureSecrets -Force -ErrorAction SilentlyContinue
if ($null -ne $existingSecrets) {
    $rawTarget = @($existingSecrets.Target | Where-Object { $_ } | Select-Object -First 1)
    if ($rawTarget.Count -ne 1) {
        throw "BACKEND LOCAL STATE BLOCKED: independent .local/secrets exists in Feature Worktree; preserved without overwrite: $featureSecrets"
    }
    $targetPath = [string]$rawTarget[0]
    if (-not [IO.Path]::IsPathRooted($targetPath)) {
        $targetPath = Join-Path (Split-Path -Parent $featureSecrets) $targetPath
    }
    if ((Get-NormalizedPath -Path $targetPath) -ne (Get-NormalizedPath -Path $canonicalSecrets)) {
        throw "BACKEND LOCAL STATE BLOCKED: .local/secrets points outside canonical Backend secrets; preserved without overwrite: $featureSecrets"
    }
}
else {
    $itemType = if (Test-WindowsHost) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $itemType -Path $featureSecrets -Target $canonicalSecrets | Out-Null
}

if (-not (Test-Path -LiteralPath $featureSecrets -PathType Container)) {
    throw "Shared Backend secrets link is unavailable: $featureSecrets"
}
Write-Host 'SHARED BACKEND SECRETS PASS: Worktree uses canonical Backend .local/secrets.'
