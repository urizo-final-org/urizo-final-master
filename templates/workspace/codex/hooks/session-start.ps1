[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [ValidateRange(4096, 1048576)]
    [int]$MaxContextBytes = 24000
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Find-WorkspaceRoot {
    param([Parameter(Mandatory = $true)][string]$StartPath)

    $cursor = (Resolve-Path -LiteralPath $StartPath).Path
    while ($true) {
        $workspaceAgents = Join-Path $cursor 'AGENTS.md'
        $masterAgents = Join-Path $cursor 'urizo-final-master/AGENTS.md'
        if ((Test-Path -LiteralPath $workspaceAgents -PathType Leaf) -and
            (Test-Path -LiteralPath $masterAgents -PathType Leaf)) {
            return $cursor
        }

        $parent = Split-Path -Parent $cursor
        if (-not $parent -or $parent -eq $cursor) {
            return $null
        }
        $cursor = $parent
    }
}

function Get-WorkspaceRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($resolved.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $resolved.Substring($Root.Length).TrimStart([char[]]'\/').Replace('\', '/')
    }
    return $resolved
}

try {
    if ($WorkspaceRoot) {
        if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
            throw "Workspace root does not exist: $WorkspaceRoot"
        }
        $WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
    }
    else {
        $WorkspaceRoot = Find-WorkspaceRoot -StartPath (Get-Location).Path
    }

    if (-not $WorkspaceRoot) {
        throw 'Could not locate the AX Module Studio workspace root.'
    }

    $instructionFiles = [System.Collections.Generic.List[string]]::new()
    $instructionFiles.Add((Join-Path $WorkspaceRoot 'AGENTS.md'))
    $instructionFiles.Add((Join-Path $WorkspaceRoot 'urizo-final-master/AGENTS.md'))

    $currentPath = (Get-Location).Path
    if ($currentPath.StartsWith($WorkspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $cursor = $currentPath
        while ($cursor -and $cursor -ne $WorkspaceRoot) {
            $candidate = Join-Path $cursor 'AGENTS.md'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $resolvedCandidate = (Resolve-Path -LiteralPath $candidate).Path
                if ($resolvedCandidate -notin $instructionFiles) {
                    $instructionFiles.Add($resolvedCandidate)
                }
                break
            }
            $parent = Split-Path -Parent $cursor
            if (-not $parent -or $parent -eq $cursor) {
                break
            }
            $cursor = $parent
        }
    }

    foreach ($path in $instructionFiles) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required instruction file is missing: $path"
        }
    }

    $builder = [System.Text.StringBuilder]::new()
    [void]$builder.AppendLine('MASTER CONTEXT PASS')
    [void]$builder.AppendLine('The following canonical AXMS instructions were reloaded verbatim by SessionStart. Follow them for this session.')
    foreach ($path in $instructionFiles) {
        $relative = Get-WorkspaceRelativePath -Root $WorkspaceRoot -Path $path
        [void]$builder.AppendLine()
        [void]$builder.AppendLine("===== BEGIN $relative =====")
        [void]$builder.AppendLine([System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8).TrimEnd())
        [void]$builder.AppendLine("===== END $relative =====")
    }

    [void]$builder.AppendLine()
    [void]$builder.AppendLine('Task-specific documents remain source-of-truth references and must be read when their scope applies:')
    foreach ($reference in @(
        'urizo-final-master/docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md',
        'urizo-final-master/docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md',
        'urizo-final-master/docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md'
    )) {
        [void]$builder.AppendLine("- $reference")
    }

    $payload = $builder.ToString()
    $payloadBytes = [System.Text.Encoding]::UTF8.GetByteCount($payload)
    if ($payloadBytes -gt $MaxContextBytes) {
        throw "Canonical instruction payload is $payloadBytes bytes, exceeding the $MaxContextBytes-byte safety limit. Read the listed AGENTS.md files directly."
    }

    Write-Output $payload
}
catch {
    $blockedReason = "MASTER CONTEXT BLOCKED: $($_.Exception.Message)"
    [ordered]@{
        continue = $false
        stopReason = $blockedReason
        systemMessage = $blockedReason
    } | ConvertTo-Json -Compress | Write-Output
}
