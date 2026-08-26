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

$execCommandPattern = '(?s)\btools\.exec_command\s*\(\s*\{\s*cmd\s*:\s*(?<literal>"(?:\\.|[^"\\])*")'
foreach ($candidate in @($commandCandidates)) {
    foreach ($match in [regex]::Matches($candidate, $execCommandPattern)) {
        try {
            $nestedCommand = $match.Groups['literal'].Value | ConvertFrom-Json
        }
        catch {
            continue
        }
        if ($nestedCommand -is [string] -and -not [string]::IsNullOrWhiteSpace($nestedCommand)) {
            $commandCandidates.Add($nestedCommand)
        }
    }
}

$commandText = $commandCandidates -join [Environment]::NewLine
$gitPullPattern = '(?im)(?:^|(?:&&|\|\||[;&|])\s*)git(?:\.exe)?(?:\s+--?[^\s]+(?:\s+[^\s]+)?)*\s+pull(?:\s|$)'
if ([string]::IsNullOrWhiteSpace($commandText) -or $commandText -notmatch $gitPullPattern) {
    exit 0
}

$exitCodes = [System.Collections.Generic.List[int]]::new()
foreach ($path in @(
    @('tool_response', 'exit_code'),
    @('tool_response', 'exitCode')
)) {
    $exitCode = Get-NestedValue -InputObject $hookInput -Path $path
    if ($null -ne $exitCode) {
        $exitCodes.Add([int]$exitCode)
    }
}

$functionsExecOutput = Get-NestedValue -InputObject $hookInput -Path @('tool_response', 'output')
if ($null -ne $functionsExecOutput) {
    foreach ($item in @($functionsExecOutput)) {
        $responseText = if ($item -is [string]) { $item } else { Get-NestedValue -InputObject $item -Path @('text') }
        if ($responseText -isnot [string] -or -not $responseText.Trim().StartsWith('{')) {
            continue
        }
        try {
            $embeddedResponse = $responseText | ConvertFrom-Json
        }
        catch {
            continue
        }
        $embeddedExitCode = Get-NestedValue -InputObject $embeddedResponse -Path @('exit_code')
        if ($null -ne $embeddedExitCode) {
            $exitCodes.Add([int]$embeddedExitCode)
        }
    }
}

if (@($exitCodes | Where-Object { $_ -ne 0 }).Count -gt 0) {
    exit 0
}

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    $WorkspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
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
