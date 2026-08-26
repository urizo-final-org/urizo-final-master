[CmdletBinding()]
param(
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-NestedValue {
    param(
        [Parameter(Mandatory = $true)]$InputObject,
        [Parameter(Mandatory = $true)][string[]]$Path
    )

    $cursor = $InputObject
    foreach ($segment in $Path) {
        if ($null -eq $cursor -or $cursor -is [string]) {
            return $null
        }
        $property = $cursor.PSObject.Properties[$segment]
        if ($null -eq $property) {
            return $null
        }
        $cursor = $property.Value
    }
    return $cursor
}

function Find-WorkspaceRoot {
    param([Parameter(Mandatory = $true)][string]$StartPath)

    if (-not (Test-Path -LiteralPath $StartPath -PathType Container)) {
        return $null
    }
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

$hookInputText = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($hookInputText)) {
    exit 0
}

try {
    $hookInput = $hookInputText | ConvertFrom-Json
}
catch {
    exit 0
}

$commandCandidates = [System.Collections.Generic.List[string]]::new()
foreach ($path in @(
    @('tool_input'),
    @('tool_input', 'command'),
    @('tool_input', 'cmd'),
    @('tool_input', 'input'),
    @('tool_input', 'args', 'command'),
    @('tool_input', 'args', 'cmd'),
    @('command'),
    @('cmd'),
    @('shell_command'),
    @('args', 'command'),
    @('args', 'cmd')
)) {
    $candidate = Get-NestedValue -InputObject $hookInput -Path $path
    if ($candidate -is [string] -and -not [string]::IsNullOrWhiteSpace($candidate)) {
        $commandCandidates.Add($candidate)
    }
}

$commandText = $commandCandidates -join [Environment]::NewLine
$gitPullPattern = '(?im)(?:^|(?:&&|\|\||[;&|])\s*)git(?:\.exe)?(?:\s+--?[^\s]+(?:\s+[^\s]+)?)*\s+pull(?:\s|$)'
if ([string]::IsNullOrWhiteSpace($commandText) -or $commandText -notmatch $gitPullPattern) {
    exit 0
}

$exitCode = Get-NestedValue -InputObject $hookInput -Path @('tool_response', 'exit_code')
if ($null -eq $exitCode) {
    $exitCode = Get-NestedValue -InputObject $hookInput -Path @('tool_response', 'exitCode')
}
if ($null -ne $exitCode -and [int]$exitCode -ne 0) {
    exit 0
}

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    $eventWorkingDirectory = Get-NestedValue -InputObject $hookInput -Path @('cwd')
    $startPath = if ($eventWorkingDirectory -is [string] -and $eventWorkingDirectory) {
        $eventWorkingDirectory
    }
    else {
        (Get-Location).Path
    }
    $WorkspaceRoot = Find-WorkspaceRoot -StartPath $startPath
}

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    exit 0
}

$contextLoader = Join-Path $WorkspaceRoot '.codex/hooks/session-start.ps1'
if (-not (Test-Path -LiteralPath $contextLoader -PathType Leaf)) {
    $blockedReason = 'MASTER CONTEXT BLOCKED: shared SessionStart loader is missing after Git pull.'
    [ordered]@{
        continue = $false
        stopReason = $blockedReason
        systemMessage = $blockedReason
    } | ConvertTo-Json -Compress | Write-Output
    exit 0
}

& $contextLoader -WorkspaceRoot $WorkspaceRoot
