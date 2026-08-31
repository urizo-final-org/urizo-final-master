[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [ValidateRange(4096, 1048576)]
    [int]$MaxContextBytes = 32768
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

function Get-GitHubIdentity {
    $ghCommand = Get-Command 'gh' -ErrorAction SilentlyContinue
    if ($null -eq $ghCommand) {
        return [pscustomobject]@{
            Id = $null
            State = 'gh CLI 없음'
        }
    }

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $statusLines = @(& $ghCommand.Source auth status --active --hostname github.com 2>&1)
        $statusExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $statusText = ($statusLines | ForEach-Object { $_.ToString() }) -join "`n"
    $accountMatch = [regex]::Match(
        $statusText,
        '(?im)(?:logged in to github\.com account|github\.com account|account)\s+([A-Za-z0-9](?:[A-Za-z0-9-]{0,38}))'
    )

    if (-not $accountMatch.Success) {
        return [pscustomobject]@{
            Id = $null
            State = 'gh 설정 계정 확인 불가'
        }
    }

    return [pscustomobject]@{
        Id = $accountMatch.Groups[1].Value
        State = if ($statusExitCode -eq 0) { '인증 확인됨' } else { '설정 계정 확인됨 · 인증 점검 필요' }
    }
}

function Get-AiFeatureContexts {
    param(
        [Parameter(Mandatory = $true)][string]$MasterRoot,
        [string]$GitHubId
    )

    $features = [System.Collections.Generic.List[object]]::new()
    if (-not $GitHubId) {
        return $features
    }

    $detailRoot = Join-Path $MasterRoot 'docs/product/ai-core'
    if (-not (Test-Path -LiteralPath $detailRoot -PathType Container)) {
        return $features
    }

    foreach ($file in Get-ChildItem -File -LiteralPath $detailRoot -Filter '*.md' | Sort-Object Name) {
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
        $ownerPattern = '(?im)^>\s*담당자:.*\(`?' + [regex]::Escape($GitHubId) + '`?\)\s*$'
        if ($content -notmatch $ownerPattern) {
            continue
        }

        $titleMatch = [regex]::Match($content, '(?m)^#\s+(.+)$')
        $featureMatch = [regex]::Match($file.BaseName, '^(\d{2})_')
        if (-not $featureMatch.Success) {
            continue
        }

        $featureNumber = $featureMatch.Groups[1].Value
        $openWork = [System.Collections.Generic.List[string]]::new()
        $trackedPullRequests = [System.Collections.Generic.List[string]]::new()
        $highestSequence = 0

        foreach ($line in $content -split "`r?`n") {
            if ($line -notmatch '^\|\s*(AI\d{2}-\d{3})\s*\|') {
                continue
            }

            $cells = @($line.Trim().Trim([char]'|').Split([char]'|') | ForEach-Object { $_.Trim() })
            if ($cells.Count -lt 9) {
                continue
            }

            $workId = $cells[0]
            $sequenceMatch = [regex]::Match($workId, '^AI' + $featureNumber + '-(\d{3})$')
            if ($sequenceMatch.Success) {
                $sequence = [int]$sequenceMatch.Groups[1].Value
                if ($sequence -gt $highestSequence) {
                    $highestSequence = $sequence
                }
            }

            $status = $cells[4]
            if ($status -notmatch '완료|취소') {
                $openWork.Add("$workId ($status)")
            }

            $pullRequestMatch = [regex]::Match($cells[7], 'https://github\.com/[^\s|)]+/pull/\d+')
            if ($pullRequestMatch.Success -and $status -notmatch '완료|취소') {
                $trackedPullRequests.Add("$workId $($pullRequestMatch.Value)")
            }
        }

        $features.Add([pscustomobject]@{
            Title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $file.BaseName }
            Path = $file.FullName
            OpenWork = @($openWork)
            TrackedPullRequests = @($trackedPullRequests)
            NextWorkId = 'AI' + $featureNumber + '-' + ($highestSequence + 1).ToString('000')
        })
    }

    return $features
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
    $masterAgentsPath = Join-Path $WorkspaceRoot 'urizo-final-master/AGENTS.md'
    $instructionFiles.Add($masterAgentsPath)

    $currentPath = (Get-Location).Path
    if ($currentPath.StartsWith($WorkspaceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $cursor = $currentPath
        while ($cursor -and $cursor -ne $WorkspaceRoot) {
            $candidate = Join-Path $cursor 'AGENTS.md'
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $resolvedCandidate = (Resolve-Path -LiteralPath $candidate).Path
                if ($resolvedCandidate -notin $instructionFiles) {
                    $masterHeading = (Get-Content -Encoding UTF8 -TotalCount 1 -LiteralPath $masterAgentsPath).Trim()
                    $candidateHeading = (Get-Content -Encoding UTF8 -TotalCount 1 -LiteralPath $resolvedCandidate).Trim()
                    if ($candidateHeading -eq $masterHeading) {
                        [void]$instructionFiles.Remove($masterAgentsPath)
                    }
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

    $masterRoot = Join-Path $WorkspaceRoot 'urizo-final-master'
    $githubIdentity = Get-GitHubIdentity
    $aiFeatureContexts = @(Get-AiFeatureContexts -MasterRoot $masterRoot -GitHubId $githubIdentity.Id)

    [void]$builder.AppendLine()
    [void]$builder.AppendLine('AI FEATURE SESSION CONTEXT')
    if ($githubIdentity.Id) {
        [void]$builder.AppendLine("- Current PC GitHub ID: $($githubIdentity.Id) ($($githubIdentity.State))")
    }
    else {
        [void]$builder.AppendLine("- Current PC GitHub ID: 확인 불가 ($($githubIdentity.State))")
    }

    if ($aiFeatureContexts.Count -eq 0) {
        [void]$builder.AppendLine('- Assigned AI feature: 확인되지 않음. 2~6번 작업이면 담당자 대조 전 문서를 수정하지 않는다.')
    }
    else {
        foreach ($feature in $aiFeatureContexts) {
            $relativePath = Get-WorkspaceRelativePath -Root $WorkspaceRoot -Path $feature.Path
            [void]$builder.AppendLine("- Assigned: $($feature.Title) | $relativePath")
            $openWorkText = if ($feature.OpenWork.Count -gt 0) { $feature.OpenWork -join ', ' } else { '없음' }
            [void]$builder.AppendLine("  Open Work ID: $openWorkText | Next candidate: $($feature.NextWorkId)")
            if ($feature.TrackedPullRequests.Count -gt 0) {
                [void]$builder.AppendLine("  Tracked PR sync: $($feature.TrackedPullRequests -join ', ')")
            }
        }
    }

    [void]$builder.AppendLine('- LLM cycle: 새 작업 지시 때 Work ID·slug를 한 번 제안하고, 같은 PR의 여러 작업은 한 ID에 묶는다.')
    [void]$builder.AppendLine('- LLM cycle: PR 생성 때 문서 연결을 한 번 제안한다. 기록된 PR은 다음 SessionStart에서 병합 여부를 확인해 추가 질문 없이 현행화한다.')
    [void]$builder.AppendLine('- LLM cycle: 현재 Work ID의 PR이 dev에 병합됐으면 검증 후 원격·로컬 Head Branch와 clean Worktree를 정리하고, Dirty·Diverged·local-only 또는 미병합 작업은 보존한다.')
    [void]$builder.AppendLine('- Hook is read-only: 실제 기능 MD 수정과 GitHub 확인은 담당 LLM이 수행한다.')

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
