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
    '.github/PULL_REQUEST_TEMPLATE.md',
    'AX-Module-Studio.code-workspace',
    'docs/README.md',
    'docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md',
    'docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md',
    'docs/architecture/TECH_STACK_AND_RATIONALE_v0.1.md',
    'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md',
    'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md',
    'docs/team/FLYWAY_RESERVATION_LEDGER.md',
    'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md',
    'docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md',
    'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md',
    'docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md',
    'docs/onboarding/TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md',
    'templates/workspace/AGENTS.md',
    'templates/workspace/CLAUDE.md',
    'templates/workspace/AX-Module-Studio.code-workspace',
    'templates/workspace/codex/hooks.json',
    'templates/workspace/codex/hooks/session-start.ps1',
    'templates/workspace/claude/settings.windows.json',
    'templates/workspace/claude/settings.unix.json',
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

$hookTemplatePath = Join-Path $masterRoot 'templates/workspace/codex/hooks.json'
$hookConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $hookTemplatePath | ConvertFrom-Json
$hookEventNames = @($hookConfig.hooks.PSObject.Properties.Name)
$sessionStartRules = @($hookConfig.hooks.SessionStart)
if ($hookEventNames.Count -ne 1 -or $hookEventNames[0] -ne 'SessionStart' -or
    $sessionStartRules.Count -ne 1 -or
    $sessionStartRules[0].matcher -ne '^(startup|resume|clear|compact)$') {
    throw 'Codex Hook template must contain only the approved SessionStart lifecycle rule.'
}
$sessionStartCommands = @($sessionStartRules[0].hooks)
if ($sessionStartCommands.Count -ne 1 -or
    $sessionStartCommands[0].type -ne 'command' -or
    $sessionStartCommands[0].command -notmatch 'session-start\.ps1' -or
    $sessionStartCommands[0].commandWindows -notmatch 'session-start\.ps1' -or
    $sessionStartCommands[0].additionalContextLimit -ne 8000) {
    throw 'Codex SessionStart Hook must use one cross-platform command with the approved context limit.'
}
$sessionStartScriptPath = Join-Path $masterRoot 'templates/workspace/codex/hooks/session-start.ps1'
$sessionStartScript = Get-Content -Raw -Encoding UTF8 -LiteralPath $sessionStartScriptPath
if ($sessionStartScript -notmatch 'continue\s*=\s*\$false' -or
    $sessionStartScript -notmatch 'stopReason\s*=\s*\$blockedReason' -or
    $sessionStartScript -notmatch 'systemMessage\s*=\s*\$blockedReason') {
    throw 'Codex SessionStart Hook must stop the turn with a visible reason when Master context loading fails.'
}
$missingWorkspaceRoot = Join-Path $masterRoot '__missing_axms_workspace__'
$blockedOutput = @(& $sessionStartScriptPath -WorkspaceRoot $missingWorkspaceRoot) -join "`n"
$blockedResult = $blockedOutput | ConvertFrom-Json
if ($blockedResult.continue -ne $false -or
    $blockedResult.stopReason -notmatch '^MASTER CONTEXT BLOCKED:' -or
    $blockedResult.systemMessage -ne $blockedResult.stopReason) {
    throw 'Codex SessionStart Hook failure response must be fail-closed JSON.'
}

foreach ($claudeSettingsRelative in @(
    'templates/workspace/claude/settings.windows.json',
    'templates/workspace/claude/settings.unix.json'
)) {
    $claudeSettings = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot $claudeSettingsRelative) | ConvertFrom-Json
    $claudeHookEventNames = @($claudeSettings.hooks.PSObject.Properties.Name)
    $claudeSessionStartRules = @($claudeSettings.hooks.SessionStart)
    if ($claudeHookEventNames.Count -ne 1 -or
        $claudeHookEventNames[0] -ne 'SessionStart' -or
        $claudeSessionStartRules.Count -ne 1 -or
        $claudeSessionStartRules[0].matcher -ne '^(startup|resume|clear|compact)$') {
        throw "Claude Hook template must contain only the approved SessionStart lifecycle rule: $claudeSettingsRelative"
    }
    $claudeSessionStartCommands = @($claudeSessionStartRules[0].hooks)
    if ($claudeSessionStartCommands.Count -ne 1 -or
        $claudeSessionStartCommands[0].type -ne 'command' -or
        $claudeSessionStartCommands[0].command -notmatch 'session-start\.ps1' -or
        $claudeSessionStartCommands[0].timeout -ne 30) {
        throw "Claude SessionStart must call the shared AXMS loader once: $claudeSettingsRelative"
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
if ($workspaceAgentTemplate -notmatch 'Master plus all three Source repositories') {
    throw 'Workspace AGENTS template must make four-repository synchronization the default pull scope.'
}
$masterAgents = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'AGENTS.md')
if ($workspaceAgentTemplate -notmatch 'bootstrap-workspace\.ps1 -SyncLlmHooks' -or
    $masterAgents -notmatch 'bootstrap-workspace\.ps1 -SyncLlmHooks') {
    throw 'Master and Workspace AGENTS policies must require automatic Codex and Claude Hook synchronization after Master updates.'
}
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
    $operatingPolicy -notmatch 'Main-Promotion: manual-team-lead-only' -or
    $operatingPolicy -notmatch 'Commit: <type>\(<slice-id-or-work-slug>/<github-id>\): <한글 변경 결과>' -or
    $operatingPolicy -notmatch 'PR: \[<slice-id-or-work-slug>\]\[<github-id>\] <한글 완료 결과>') {
    throw 'Master operating policy must enforce worker-task version matching before implementation.'
}
$pullRequestTemplate = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot '.github/PULL_REQUEST_TEMPLATE.md')
foreach ($requiredHeading in @('## 결과', '## 변경', '## 검증', '## 연결·영향', '## 확인')) {
    if ($pullRequestTemplate -notmatch [regex]::Escape($requiredHeading)) {
        throw "Master PR template is missing the common Korean heading: $requiredHeading"
    }
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
$parseTargets = @(
    Get-ChildItem -File -LiteralPath (Join-Path $masterRoot 'scripts') -Filter '*.ps1'
) + @(
    Get-Item -LiteralPath (Join-Path $masterRoot 'templates/workspace/codex/hooks/session-start.ps1')
)
foreach ($scriptFile in $parseTargets) {
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
Write-Host 'PASS: minimal fail-closed Codex and Claude SessionStart Hooks parsed and validated'
Write-Host 'PASS: managed local-LLM policy, dev-only PR policy, and Claude routing'
Write-Host 'PASS: four canonical repository remotes'
Write-Host 'PASS: all PowerShell scripts parsed'
Write-Host 'PASS: no forbidden destructive command patterns'
Write-Host 'PASS: no source repository copy inside Master'
