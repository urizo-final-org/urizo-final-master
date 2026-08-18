[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$required = @(
    'AGENTS.md',
    'CLAUDE.md',
    'README.md',
    'repository-manifest.json',
    'AX-Module-Studio.code-workspace',
    'docs/README.md',
    'docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v0.7.md',
    'docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v0.8.md',
    'docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v1.0.md',
    'docs/product/AX_Module_Studio_TEAM_CHECKLIST_DECISION_OVERLAY_v0.1.md',
    'docs/product/AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md',
    'docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md',
    'docs/traceability/FEATURE_TRACEABILITY_MATRIX_v0.1.md',
    'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md',
    'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md',
    'docs/team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md',
    'docs/team/FLYWAY_RESERVATION_LEDGER.md',
    'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.1.md',
    'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md',
    'docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md',
    'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md',
    'docs/onboarding/TEAMMATE_ONE_CLICK_CMS_START_GUIDE_v0.1.md',
    'docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md',
    'docs/onboarding/TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md',
    'templates/workspace/AGENTS.md',
    'templates/workspace/CLAUDE.md',
    'templates/workspace/AX-Module-Studio.code-workspace',
    'scripts/preflight-workspace.ps1',
    'scripts/bootstrap-workspace.ps1',
    'scripts/sync-workspace.ps1',
    'scripts/health-workspace.ps1',
    'scripts/validate-master-scaffold.ps1'
)

foreach ($relative in $required) {
    $path = Join-Path $masterRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required scaffold file is missing: $relative"
    }
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json
if (@($manifest.repositories).Count -ne 4) {
    throw 'Repository manifest must contain exactly four sibling repositories.'
}
$expectedRemotes = @(
    'https://github.com/urizo-final-org/urizo-final-master.git',
    'https://github.com/urizo-final-org/urizo-final-frontend.git',
    'https://github.com/urizo-final-org/urizo-final-backend.git',
    'https://github.com/urizo-final-org/urizo-final-orchestrator.git'
)
foreach ($remote in $expectedRemotes) {
    if ($remote -notin @($manifest.repositories.remote)) {
        throw "Canonical remote is missing from manifest: $remote"
    }
}

if ($manifest.publishedBaseline.status -ne 'remote-published') {
    throw 'Manifest published baseline must be marked remote-published.'
}
$sourceNames = @('urizo-final-frontend', 'urizo-final-backend', 'urizo-final-orchestrator')
foreach ($sourceName in $sourceNames) {
    $integrationSha = $manifest.publishedBaseline.sourceIntegrationRefs.$sourceName
    $releaseSha = $manifest.publishedBaseline.sourceReleaseRefs.$sourceName
    if ($integrationSha -notmatch '^[0-9a-f]{40}$' -or $releaseSha -notmatch '^[0-9a-f]{40}$') {
        throw "Published baseline SHA is invalid for $sourceName."
    }
}

foreach ($workspaceFile in @(
    (Join-Path $masterRoot 'AX-Module-Studio.code-workspace'),
    (Join-Path $masterRoot 'templates/workspace/AX-Module-Studio.code-workspace')
)) {
    $workspace = Get-Content -Raw -Encoding UTF8 -LiteralPath $workspaceFile | ConvertFrom-Json
    if (@($workspace.folders).Count -ne 4) {
        throw "Workspace template must contain four folders: $workspaceFile"
    }
}

$managedPolicyBegin = '<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:BEGIN -->'
$managedPolicyEnd = '<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:END -->'
$workspaceAgentTemplate = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'templates/workspace/AGENTS.md')
if ([regex]::Matches($workspaceAgentTemplate, [regex]::Escape($managedPolicyBegin)).Count -ne 1 -or
    [regex]::Matches($workspaceAgentTemplate, [regex]::Escape($managedPolicyEnd)).Count -ne 1) {
    throw 'Workspace AGENTS template must contain exactly one managed local-LLM policy block.'
}
$managedWorkspacePolicy = [regex]::Match(
    $workspaceAgentTemplate,
    '(?s)' + [regex]::Escape($managedPolicyBegin) + '(.*?)' + [regex]::Escape($managedPolicyEnd)
).Groups[1].Value
if ([regex]::Matches($managedWorkspacePolicy, 'Every agent-created PR.*targets `dev`').Count -ne 1 -or
    [regex]::Matches($managedWorkspacePolicy, '`main` is reserved for periodic manual promotion').Count -ne 1) {
    throw 'Managed Workspace policy must contain exactly one dev-only PR rule and one manual-main rule.'
}
$workspaceClaudeTemplate = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'templates/workspace/CLAUDE.md')
$claudePolicyBegin = '<!-- AXMS-MANAGED-CLAUDE-ROUTING:BEGIN -->'
$claudePolicyEnd = '<!-- AXMS-MANAGED-CLAUDE-ROUTING:END -->'
if ([regex]::Matches($workspaceClaudeTemplate, [regex]::Escape($claudePolicyBegin)).Count -ne 1 -or
    [regex]::Matches($workspaceClaudeTemplate, [regex]::Escape($claudePolicyEnd)).Count -ne 1 -or
    $workspaceClaudeTemplate -notmatch '@AGENTS\.md' -or
    $workspaceClaudeTemplate -notmatch '@urizo-final-master/AGENTS\.md') {
    throw 'Workspace CLAUDE template must contain one managed block that imports parent and Master AGENTS.md.'
}
$masterClaude = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'CLAUDE.md')
if ($masterClaude -notmatch '(?m)^@AGENTS\.md\r?$') {
    throw 'Master CLAUDE.md must import Master AGENTS.md.'
}
if ($workspaceAgentTemplate -notmatch 'scripts/sync-workspace\.ps1') {
    throw 'Workspace AGENTS template must route shared Git synchronization through sync-workspace.ps1.'
}
$masterAgents = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'AGENTS.md')
$devOnlyPrPattern = 'Every agent-created (pull request|PR).*targets `dev`'
$manualMainPattern = '`main` is (the team lead''s|reserved for) periodic manual promotion'
if ($masterAgents -notmatch $devOnlyPrPattern -or
    $masterAgents -notmatch $manualMainPattern -or
    $workspaceAgentTemplate -notmatch $devOnlyPrPattern -or
    $workspaceAgentTemplate -notmatch $manualMainPattern) {
    throw 'Master and Workspace AGENTS policies must route every agent-created PR to dev and reserve main for manual promotion.'
}
$statusSnapshot = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md')
if ($statusSnapshot -notmatch 'Snapshot-Version:' -or
    $statusSnapshot -notmatch 'MASTER UPDATE COMPLETE' -or
    $statusSnapshot -notmatch 'MASTER CONTEXT PASS') {
    throw 'LLM project-status snapshot must define the versioned team-lead handoff and local recognition handshake.'
}
$operatingPolicy = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md')
if ($operatingPolicy -notmatch 'Task-Version' -or
    $operatingPolicy -notmatch 'MASTER CONTEXT BLOCKED' -or
    $operatingPolicy -notmatch 'Agent-PR-Base: dev' -or
    $operatingPolicy -notmatch 'Main-Promotion: manual-team-lead-only') {
    throw 'Master operating policy must enforce worker-task version matching before implementation.'
}
$masterScriptText = (Get-ChildItem -File -LiteralPath (Join-Path $masterRoot 'scripts') -Filter '*.ps1' |
    Where-Object { $_.Name -ne 'validate-master-scaffold.ps1' } |
    ForEach-Object { Get-Content -Raw -Encoding UTF8 -LiteralPath $_.FullName }) -join "`n"
foreach ($windowsOnlyCrossPlatformPath in @(
    'templates\workspace',
    'urizo-final-backend\scripts'
)) {
    if ($masterScriptText.Contains($windowsOnlyCrossPlatformPath)) {
        throw "Cross-platform Master path contains a Windows-only separator: $windowsOnlyCrossPlatformPath"
    }
}

$parseFailures = [System.Collections.Generic.List[string]]::new()
foreach ($scriptFile in Get-ChildItem -File -LiteralPath (Join-Path $masterRoot 'scripts') -Filter '*.ps1') {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $parseFailures.Add("$($scriptFile.Name): $($errors[0].Message)")
    }
}
if ($parseFailures.Count -gt 0) {
    throw "PowerShell parse failure: $($parseFailures -join '; ')"
}

$forbiddenPatterns = @(
    '(?im)^\s*(?:&\s+)?git\s+(reset|clean|stash|checkout|switch|pull|rebase)\b',
    'Remove-Item[^\r\n]*-Recurse',
    '\bdocker\s+volume\s+(rm|prune)\b',
    '\bdown\s+-v\b',
    '\bflyway\s+(clean|repair)\b',
    '\brm\s+-rf\b'
)
$scriptText = (Get-ChildItem -File -LiteralPath (Join-Path $masterRoot 'scripts') -Filter '*.ps1' |
    Where-Object { $_.Name -ne 'validate-master-scaffold.ps1' } |
    ForEach-Object { Get-Content -Raw -Encoding UTF8 -LiteralPath $_.FullName }) -join "`n"
foreach ($pattern in $forbiddenPatterns) {
    if ($scriptText -match $pattern) {
        throw "Forbidden destructive command pattern detected in scripts: $pattern"
    }
}

foreach ($forbiddenDirectory in @('urizo-final-frontend', 'urizo-final-backend', 'urizo-final-orchestrator')) {
    if (Test-Path -LiteralPath (Join-Path $masterRoot $forbiddenDirectory)) {
        throw "Source repository copy is forbidden inside Master: $forbiddenDirectory"
    }
}

Write-Host "PASS: $($required.Count) required files"
Write-Host 'PASS: manifest and both workspace JSON files parsed'
Write-Host 'PASS: managed local-LLM policy, dev-only PR policy, and Claude routing'
Write-Host 'PASS: four canonical repository remotes'
Write-Host 'PASS: all PowerShell scripts parsed'
Write-Host 'PASS: no forbidden destructive command patterns'
Write-Host 'PASS: no source repository copy inside Master'
