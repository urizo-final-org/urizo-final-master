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
    '.github/CODEOWNERS',
    '.github/PULL_REQUEST_TEMPLATE.md',
    'AX-Module-Studio.code-workspace',
    'docs/README.md',
    'docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md',
    'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md',
    'docs/product/ai-core/02_DOMAIN_RAG_REPLACEMENT.md',
    'docs/product/ai-core/03_RAG_QUALITY.md',
    'docs/product/ai-core/04_LIMITED_LLM_DEVOPS.md',
    'docs/product/ai-core/05_NATURAL_LANGUAGE_CMS.md',
    'docs/product/ai-core/06_ORCHESTRATION_CONTROL.md',
    'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md',
    'docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md',
    'docs/architecture/TECH_STACK_AND_RATIONALE_v0.1.md',
    'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md',
    'docs/team/TEAM_LEAD_PROTOCOL_v0.1.md',
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
    'templates/workspace/codex/hooks/post-pull-context.ps1',
    'templates/workspace/claude/settings.windows.json',
    'templates/workspace/claude/settings.unix.json',
    'templates/workspace/githooks/pre-push',
    '.agents/skills/axms-team-lead/SKILL.md',
    'scripts/preflight-workspace.ps1',
    'scripts/bootstrap-workspace.ps1',
    'scripts/sync-workspace.ps1',
    'scripts/start-feature-work.ps1',
    'scripts/ensure-shared-backend-local-state.ps1',
    'scripts/prepare-dev-pr.ps1',
    'scripts/pre-push-pull-gate.ps1',
    'scripts/health-workspace.ps1',
    'scripts/start-local-cms.ps1',
    'scripts/start-frontend-live.ps1',
    'scripts/rebuild-local-service.ps1',
    'scripts/validate-master-scaffold.ps1'
)

foreach ($relative in $required) {
    $path = Join-Path $masterRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required scaffold file is missing: $relative"
    }
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json
if (@($manifest.repositories).Count -ne 5) {
    throw 'Repository manifest must contain exactly five sibling repositories.'
}
$expectedRemotes = @(
    'https://github.com/urizo-final-org/urizo-final-master.git',
    'https://github.com/urizo-final-org/urizo-final-frontend.git',
    'https://github.com/urizo-final-org/urizo-final-backend.git',
    'https://github.com/urizo-final-org/urizo-final-orchestrator.git',
    'https://github.com/urizo-final-org/urizo-final-mcp-server.git'
)
foreach ($remote in $expectedRemotes) {
    if ($remote -notin @($manifest.repositories.remote)) {
        throw "Canonical remote is missing from manifest: $remote"
    }
}

if ($manifest.publishedBaseline.status -ne 'remote-published') {
    throw 'Manifest published baseline must be marked remote-published.'
}
$sourceNames = @(
    'urizo-final-frontend',
    'urizo-final-backend',
    'urizo-final-orchestrator',
    'urizo-final-mcp-server'
)
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
    if (@($workspace.folders).Count -ne 5) {
        throw "Workspace template must contain five folders: $workspaceFile"
    }
}

$hookTemplatePath = Join-Path $masterRoot 'templates/workspace/codex/hooks.json'
$hookConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $hookTemplatePath | ConvertFrom-Json
$hookEventNames = @($hookConfig.hooks.PSObject.Properties.Name)
$sessionStartRules = @($hookConfig.hooks.SessionStart)
if ($hookEventNames.Count -ne 2 -or
    $hookEventNames -notcontains 'SessionStart' -or
    $hookEventNames -notcontains 'PostToolUse' -or
    $sessionStartRules.Count -ne 2 -or
    $sessionStartRules[0].matcher -ne '^(startup|clear|compact)$' -or
    $sessionStartRules[1].matcher -ne '^resume$') {
    throw 'Codex Hook template must split full lifecycle loading from compact resume checkpoints.'
}
$fullSessionCommand = @($sessionStartRules[0].hooks)
$resumeSessionCommand = @($sessionStartRules[1].hooks)
if ($fullSessionCommand.Count -ne 1 -or
    $fullSessionCommand[0].type -ne 'command' -or
    $fullSessionCommand[0].command -notmatch 'session-start\.ps1.+-Mode Full.+24576' -or
    $fullSessionCommand[0].commandWindows -notmatch 'session-start\.ps1.+-Mode Full.+24576' -or
    $fullSessionCommand[0].additionalContextLimit -ne 24576 -or
    $resumeSessionCommand.Count -ne 1 -or
    $resumeSessionCommand[0].type -ne 'command' -or
    $resumeSessionCommand[0].command -notmatch 'session-start\.ps1.+-Mode Checkpoint.+4096' -or
    $resumeSessionCommand[0].commandWindows -notmatch 'session-start\.ps1.+-Mode Checkpoint.+4096' -or
    $resumeSessionCommand[0].additionalContextLimit -ne 4096) {
    throw 'Codex SessionStart Hook must use bounded full and checkpoint commands on both operating systems.'
}
$postToolUseRules = @($hookConfig.hooks.PostToolUse)
$postToolUseCommands = @(if ($postToolUseRules.Count -eq 1) { @($postToolUseRules[0].hooks) } else { @() })
if ($postToolUseRules.Count -ne 1 -or
    $postToolUseRules[0].matcher -notmatch 'Bash' -or
    $postToolUseRules[0].matcher -notmatch 'exec_command' -or
    $postToolUseCommands.Count -ne 1 -or
    $postToolUseCommands[0].type -ne 'command' -or
    $postToolUseCommands[0].command -notmatch 'post-pull-context\.ps1' -or
    $postToolUseCommands[0].commandWindows -notmatch 'post-pull-context\.ps1' -or
    $postToolUseCommands[0].additionalContextLimit -ne 24576) {
    throw 'Codex PostToolUse Hook must inspect shell commands with enough room for a conditional full refresh.'
}
$sessionStartScriptPath = Join-Path $masterRoot 'templates/workspace/codex/hooks/session-start.ps1'
$sessionStartScript = Get-Content -Raw -Encoding UTF8 -LiteralPath $sessionStartScriptPath
if ($sessionStartScript -notmatch 'continue\s*=\s*\$false' -or
    $sessionStartScript -notmatch 'stopReason\s*=\s*\$blockedReason' -or
    $sessionStartScript -notmatch 'systemMessage\s*=\s*\$blockedReason') {
    throw 'Codex SessionStart Hook must stop the turn with a visible reason when Master context loading fails.'
}
if ($sessionStartScript -notmatch "ValidateSet\('Full', 'Checkpoint'\)" -or
    $sessionStartScript -notmatch 'AXMS CONTEXT CHECKPOINT v2' -or
    $sessionStartScript -notmatch 'Get-FileFingerprint' -or
    $sessionStartScript -match 'AI FEATURE SESSION CONTEXT|auth status --active|Next candidate|Tracked PR sync') {
    throw 'SessionStart Hook must provide fingerprinted bounded checkpoints without GitHub or AI-ledger scans.'
}
$missingWorkspaceRoot = Join-Path $masterRoot '__missing_axms_workspace__'
$blockedOutput = @(& $sessionStartScriptPath -WorkspaceRoot $missingWorkspaceRoot -Mode Full -Reason Lifecycle -MaxContextBytes 24576) -join "`n"
$blockedResult = $blockedOutput | ConvertFrom-Json
if ($blockedResult.continue -ne $false -or
    $blockedResult.stopReason -notmatch '^MASTER CONTEXT BLOCKED:' -or
    $blockedResult.systemMessage -ne $blockedResult.stopReason) {
    throw 'Codex SessionStart Hook failure response must be fail-closed JSON.'
}
$postPullScriptPath = Join-Path $masterRoot 'templates/workspace/codex/hooks/post-pull-context.ps1'
$postPullScript = Get-Content -Raw -Encoding UTF8 -LiteralPath $postPullScriptPath
if ($postPullScript -notmatch '\bgit\(' -and $postPullScript -notmatch 'gitPullPattern') {
    throw 'Post-pull Hook must detect Git pull from tool input.'
}
if ($postPullScript -notmatch 'session-start\.ps1' -or
    $postPullScript -notmatch '\$PSScriptRoot' -or
    $postPullScript -notmatch 'agentsChanged' -or
    $postPullScript -notmatch '-Mode Full' -or
    $postPullScript -notmatch '-Mode Checkpoint' -or
    $postPullScript -match 'Find-WorkspaceRoot|sync-workspace\.ps1') {
    throw 'Post-pull Hook must choose checkpoint or full mode from actual Pull output and reuse the shared loader.'
}

$testWorkspaceRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-hook-validation-" + [Guid]::NewGuid().ToString('N'))
try {
New-Item -ItemType Directory -Path (Join-Path $testWorkspaceRoot 'urizo-final-master') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $masterRoot 'templates/workspace/AGENTS.md') -Destination (Join-Path $testWorkspaceRoot 'AGENTS.md')
Copy-Item -LiteralPath (Join-Path $masterRoot 'AGENTS.md') -Destination (Join-Path $testWorkspaceRoot 'urizo-final-master/AGENTS.md')

$checkpointOutput = @(& $sessionStartScriptPath -WorkspaceRoot $testWorkspaceRoot -Mode Checkpoint -Reason Resume -MaxContextBytes 4096) -join "`n"
$checkpointBytes = [Text.Encoding]::UTF8.GetByteCount($checkpointOutput)
if ($checkpointOutput -notmatch '^AXMS CONTEXT CHECKPOINT v2: reason=Resume' -or
    $checkpointOutput -match '===== BEGIN' -or
    $checkpointOutput -notmatch 'Before implementation:' -or
    $checkpointOutput -notmatch 'Before PR:' -or
    $checkpointBytes -gt 4096) {
    throw "Checkpoint mode must stay below 4096 bytes and repeat both Git gates; bytes=$checkpointBytes"
}

$fullOutput = @(& $sessionStartScriptPath -WorkspaceRoot $testWorkspaceRoot -Mode Full -Reason Lifecycle -MaxContextBytes 24576) -join "`n"
$fullBytes = [Text.Encoding]::UTF8.GetByteCount($fullOutput)
if ($fullOutput -notmatch '^MASTER CONTEXT PASS' -or
    $fullOutput -notmatch '===== BEGIN urizo-final-master/AGENTS\.md =====' -or
    $fullOutput -match '===== BEGIN AGENTS\.md =====' -or
    $fullOutput -match 'AI FEATURE SESSION CONTEXT|Next candidate|auth status --active' -or
    $fullBytes -gt 24576) {
    throw "Full mode must load Master without duplicating Workspace AGENTS or dynamic ledger state; bytes=$fullBytes"
}

function Invoke-PostPullValidationCase {
    param(
        [Parameter(Mandatory = $true)]$HookInput
    )

    $inputJson = $HookInput | ConvertTo-Json -Depth 12 -Compress
    $powerShellExecutable = (Get-Process -Id $PID).Path
    return @($inputJson | & $powerShellExecutable -NoProfile -File $postPullScriptPath -WorkspaceRoot $testWorkspaceRoot -ContextLoaderPath $sessionStartScriptPath) -join "`n"
}

$directPullOutput = Invoke-PostPullValidationCase -HookInput ([ordered]@{
    tool_input = [ordered]@{ cmd = 'git pull --ff-only' }
    tool_response = [ordered]@{ exit_code = 0; output = 'Already up to date.' }
})
if ($directPullOutput -notmatch '^AXMS CONTEXT CHECKPOINT v2: reason=Pull' -or $directPullOutput -match '===== BEGIN') {
    throw 'A successful ordinary Git pull must emit only the compact checkpoint.'
}

$functionsExecPullInput = 'const r = await tools.exec_command({ cmd: "git pull --ff-only", workdir: "C:\\repo" }); text(JSON.stringify(r));'
$functionsExecSuccessResponse = [ordered]@{
    output = @(
        [ordered]@{ type = 'input_text'; text = 'Script completed' },
        [ordered]@{ type = 'input_text'; text = '{"exit_code":0,"output":"Already up to date.\\n"}' }
    )
}
$functionsExecPullOutput = Invoke-PostPullValidationCase -HookInput ([ordered]@{
    tool_input = $functionsExecPullInput
    tool_response = $functionsExecSuccessResponse
})
if ($functionsExecPullOutput -notmatch '^AXMS CONTEXT CHECKPOINT v2: reason=Pull' -or $functionsExecPullOutput -match '===== BEGIN') {
    throw 'A successful Git pull nested in functions.exec must emit only the compact checkpoint.'
}

$agentsPullOutput = Invoke-PostPullValidationCase -HookInput ([ordered]@{
    tool_input = [ordered]@{ cmd = 'git pull --ff-only' }
    tool_response = [ordered]@{ exit_code = 0; output = ' AGENTS.md | 4 ++--' }
})
if ($agentsPullOutput -notmatch '^MASTER CONTEXT PASS' -or
    $agentsPullOutput -notmatch '===== BEGIN urizo-final-master/AGENTS\.md =====') {
    throw 'A successful Git pull that changes AGENTS.md must emit one full canonical refresh.'
}

$functionsExecSearchOutput = Invoke-PostPullValidationCase -HookInput ([ordered]@{
    tool_input = 'const r = await tools.exec_command({ cmd: "rg -n \"git pull\" .", workdir: "C:\\repo" }); text(r.output);'
    tool_response = $functionsExecSuccessResponse
})
if (-not [string]::IsNullOrWhiteSpace($functionsExecSearchOutput)) {
    throw 'Post-pull Hook must not treat a Git-pull search string as an executed Git pull.'
}

$functionsExecFailedPullOutput = Invoke-PostPullValidationCase -HookInput ([ordered]@{
    tool_input = $functionsExecPullInput
    tool_response = [ordered]@{
        output = @(
            [ordered]@{ type = 'input_text'; text = 'Script completed' },
            [ordered]@{ type = 'input_text'; text = '{"exit_code":1,"output":"Pull failed.\\n"}' }
        )
    }
})
if (-not [string]::IsNullOrWhiteSpace($functionsExecFailedPullOutput)) {
    throw 'Post-pull Hook must not reload context after a failed Git pull nested in functions.exec.'
}
}
finally {
    if (Test-Path -LiteralPath $testWorkspaceRoot) {
        Remove-Item -LiteralPath $testWorkspaceRoot -Recurse -Force
    }
}

foreach ($claudeSettingsRelative in @(
    'templates/workspace/claude/settings.windows.json',
    'templates/workspace/claude/settings.unix.json'
)) {
    $claudeSettings = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot $claudeSettingsRelative) | ConvertFrom-Json
    $claudeHookEventNames = @($claudeSettings.hooks.PSObject.Properties.Name)
    $claudeSessionStartRules = @($claudeSettings.hooks.SessionStart)
    if ($claudeHookEventNames.Count -ne 2 -or
        $claudeHookEventNames -notcontains 'SessionStart' -or
        $claudeHookEventNames -notcontains 'PostToolUse' -or
        $claudeSessionStartRules.Count -ne 2 -or
        $claudeSessionStartRules[0].matcher -ne '^(startup|clear|compact)$' -or
        $claudeSessionStartRules[1].matcher -ne '^resume$') {
        throw "Claude Hook template must split full lifecycle loading from compact resume checkpoints: $claudeSettingsRelative"
    }
    $claudeFullCommand = @($claudeSessionStartRules[0].hooks)
    $claudeResumeCommand = @($claudeSessionStartRules[1].hooks)
    if ($claudeFullCommand.Count -ne 1 -or
        $claudeFullCommand[0].type -ne 'command' -or
        $claudeFullCommand[0].command -notmatch 'session-start\.ps1.+-Mode Full.+24576' -or
        $claudeFullCommand[0].timeout -ne 30 -or
        $claudeResumeCommand.Count -ne 1 -or
        $claudeResumeCommand[0].type -ne 'command' -or
        $claudeResumeCommand[0].command -notmatch 'session-start\.ps1.+-Mode Checkpoint.+4096' -or
        $claudeResumeCommand[0].timeout -ne 30) {
        throw "Claude SessionStart must call the shared bounded loader in both modes: $claudeSettingsRelative"
    }
    $claudePostToolUseRules = @($claudeSettings.hooks.PostToolUse)
    $claudePostToolUseCommands = @(if ($claudePostToolUseRules.Count -eq 1) { @($claudePostToolUseRules[0].hooks) } else { @() })
    if ($claudePostToolUseRules.Count -ne 1 -or
        $claudePostToolUseRules[0].matcher -notmatch 'Bash' -or
        $claudePostToolUseCommands.Count -ne 1 -or
        $claudePostToolUseCommands[0].type -ne 'command' -or
        $claudePostToolUseCommands[0].command -notmatch 'post-pull-context\.ps1' -or
        $claudePostToolUseCommands[0].timeout -ne 30) {
        throw "Claude PostToolUse must call the shared Git-pull context detector once: $claudeSettingsRelative"
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
if ($workspaceAgentTemplate -notmatch 'Master plus all four Source repositories') {
    throw 'Workspace AGENTS template must make five-repository synchronization the default pull scope.'
}
$masterAgents = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'AGENTS.md')
$fullSyncAliases = @('전체 Git 최신화', '워크스페이스 최신화')
foreach ($pullAlias in $fullSyncAliases) {
    if ($workspaceAgentTemplate -notmatch [regex]::Escape($pullAlias) -or
        $masterAgents -notmatch [regex]::Escape($pullAlias)) {
        throw "Master and Workspace AGENTS policies must route explicit full synchronization through sync-workspace.ps1: $pullAlias"
    }
}
if ($workspaceAgentTemplate -notmatch 'PostToolUse' -or
    $masterAgents -notmatch 'PostToolUse' -or
    $workspaceAgentTemplate -notmatch '적용 모드를 LLM이 판단' -or
    $masterAgents -notmatch '적용 대상을 판단') {
    throw 'Master and Workspace AGENTS policies must checkpoint successful Git pulls and leave runtime-mode selection to the LLM.'
}
if ($workspaceAgentTemplate -notmatch 'start-feature-work\.ps1' -or
    $masterAgents -notmatch 'start-feature-work\.ps1' -or
    $workspaceAgentTemplate -notmatch 'prepare-dev-pr\.ps1' -or
    $masterAgents -notmatch 'prepare-dev-pr\.ps1' -or
    $workspaceAgentTemplate -notmatch 'pre-push' -or
    $masterAgents -notmatch 'pre-push') {
    throw 'Master and Workspace AGENTS policies must route pre-work Pull and pre-PR fetch through enforced gates.'
}
if ($workspaceAgentTemplate -notmatch 'bootstrap-workspace\.ps1 -SyncLlmHooks' -or
    $masterAgents -notmatch 'bootstrap-workspace\.ps1 -SyncLlmHooks') {
    throw 'Master and Workspace AGENTS policies must require automatic Codex and Claude Hook synchronization after Master updates.'
}
$syncWorkspaceScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/sync-workspace.ps1')
if ($syncWorkspaceScript -notmatch 'bootstrap-workspace\.ps1' -or
    $syncWorkspaceScript -notmatch '-SyncLlmHooks' -or
    $syncWorkspaceScript -notmatch '\.codex/hooks/session-start\.ps1' -or
    $syncWorkspaceScript -notmatch 'Get-InstructionFingerprint' -or
    $syncWorkspaceScript -notmatch "'Checkpoint'.*'Full'|'Full'.*'Checkpoint'" -or
    $syncWorkspaceScript -notmatch 'ACTIVE SESSION CONTEXT REFRESH PASS' -or
    $syncWorkspaceScript -notmatch 'LOCAL RUNTIME CONTEXT PASS' -or
    $workspaceAgentTemplate -notmatch 'LOCAL RUNTIME CONTEXT PASS' -or
    $masterAgents -notmatch 'LOCAL RUNTIME CONTEXT PASS') {
    throw 'Workspace synchronization must install Hooks and select full versus checkpoint refresh from instruction fingerprints.'
}
if ($syncWorkspaceScript -notmatch "Status 'PRESERVED'" -or
    $syncWorkspaceScript -notmatch '\$hookRefreshDeferred' -or
    $syncWorkspaceScript -notmatch 'HOOK AND CONTEXT REFRESH DEFERRED' -or
    $syncWorkspaceScript -match 'Master did not reach a current clean dev state\. Source working trees were not updated' -or
    $masterAgents -notmatch '관계없는 깨끗한 Source' -or
    $workspaceAgentTemplate -notmatch '관계없는 깨끗한 Source') {
    throw 'Workspace synchronization must preserve dirty canonical work, continue unrelated clean repositories, and defer shared Hook refresh.'
}
$syncFastForwardCommands = @([regex]::Matches($syncWorkspaceScript, "@\('merge'[^\r\n]*"))
if ($syncWorkspaceScript -match "(?im)@\('(reset|stash|rebase)'" -or
    @($syncFastForwardCommands | Where-Object { $_.Value -notmatch "'--ff-only'" }).Count -gt 0) {
    throw 'Workspace synchronization must not reset, stash, rebase, or perform a non-fast-forward merge.'
}

$syncFixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-sync-validation-" + [Guid]::NewGuid().ToString('N'))
try {
    $syncFixtureWorkspace = Join-Path $syncFixtureRoot 'workspace'
    $syncFixtureRemoteRoot = Join-Path $syncFixtureRoot 'remotes'
    $syncFixtureSeedRoot = Join-Path $syncFixtureRoot 'seeds'
    New-Item -ItemType Directory -Path $syncFixtureWorkspace, $syncFixtureRemoteRoot, $syncFixtureSeedRoot -Force | Out-Null

    function Invoke-SyncFixtureGitRaw {
        param([Parameter(Mandatory = $true)][string[]]$Arguments)

        $previousErrorAction = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = @(& git @Arguments 2>&1)
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorAction
        }
        if ($exitCode -ne 0) {
            throw "Sync fixture Git command failed: git=$($Arguments -join ' '); output=$($output -join ' ')"
        }
        return @($output | ForEach-Object { $_.ToString() })
    }

    function Invoke-SyncFixtureGit {
        param(
            [Parameter(Mandatory = $true)][string]$RepositoryPath,
            [Parameter(Mandatory = $true)][string[]]$Arguments
        )

        $gitArguments = @('-c', "safe.directory=$RepositoryPath", '-C', $RepositoryPath) + $Arguments
        return @(Invoke-SyncFixtureGitRaw -Arguments $gitArguments)
    }

    $syncFixtureRepositories = @(
        [ordered]@{ name = 'urizo-final-master'; relativePath = 'urizo-final-master'; remote = (Join-Path $syncFixtureRemoteRoot 'urizo-final-master.git') },
        [ordered]@{ name = 'urizo-final-frontend'; relativePath = 'urizo-final-frontend'; remote = (Join-Path $syncFixtureRemoteRoot 'urizo-final-frontend.git') },
        [ordered]@{ name = 'urizo-final-backend'; relativePath = 'urizo-final-backend'; remote = (Join-Path $syncFixtureRemoteRoot 'urizo-final-backend.git') }
    )
    $syncFixtureManifest = [ordered]@{
        branches = [ordered]@{ integration = 'dev' }
        repositories = $syncFixtureRepositories
    }

    foreach ($fixtureRepository in $syncFixtureRepositories) {
        $fixtureRemote = [string]$fixtureRepository.remote
        $fixtureSeed = Join-Path $syncFixtureSeedRoot $fixtureRepository.name
        $fixtureCanonical = Join-Path $syncFixtureWorkspace $fixtureRepository.relativePath
        Invoke-SyncFixtureGitRaw -Arguments @('init', '--bare', $fixtureRemote) | Out-Null
        Invoke-SyncFixtureGitRaw -Arguments @('init', '-b', 'dev', $fixtureSeed) | Out-Null
        Invoke-SyncFixtureGit -RepositoryPath $fixtureSeed -Arguments @('config', 'user.name', 'AXMS Validation') | Out-Null
        Invoke-SyncFixtureGit -RepositoryPath $fixtureSeed -Arguments @('config', 'user.email', 'axms-validation@example.invalid') | Out-Null
        Set-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureSeed 'AGENTS.md') -Value "fixture instructions: $($fixtureRepository.name)"
        Set-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureSeed 'tracked.txt') -Value 'baseline'

        if ($fixtureRepository.name -eq 'urizo-final-master') {
            $fixtureScripts = Join-Path $fixtureSeed 'scripts'
            New-Item -ItemType Directory -Path $fixtureScripts -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $masterRoot 'scripts/sync-workspace.ps1') -Destination (Join-Path $fixtureScripts 'sync-workspace.ps1')
            @'
[CmdletBinding()]
param(
    [string]$WorkspaceRoot,
    [switch]$SyncLlmHooks,
    [switch]$WhatIf
)
Set-Content -Encoding UTF8 -LiteralPath (Join-Path $WorkspaceRoot 'hook-refresh.marker') -Value 'updated'
'@ | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureScripts 'bootstrap-workspace.ps1')
            $syncFixtureManifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureSeed 'repository-manifest.json')
        }

        Invoke-SyncFixtureGit -RepositoryPath $fixtureSeed -Arguments @('add', '.') | Out-Null
        Invoke-SyncFixtureGit -RepositoryPath $fixtureSeed -Arguments @('commit', '-m', 'fixture baseline') | Out-Null
        Invoke-SyncFixtureGit -RepositoryPath $fixtureSeed -Arguments @('remote', 'add', 'origin', $fixtureRemote) | Out-Null
        Invoke-SyncFixtureGit -RepositoryPath $fixtureSeed -Arguments @('push', '-u', 'origin', 'dev') | Out-Null
        Invoke-SyncFixtureGitRaw -Arguments @('clone', '--branch', 'dev', $fixtureRemote, $fixtureCanonical) | Out-Null
    }

    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $syncFixtureWorkspace 'AGENTS.md') -Value 'fixture workspace instructions'
    $fixtureFrontendSeed = Join-Path $syncFixtureSeedRoot 'urizo-final-frontend'
    Add-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureFrontendSeed 'tracked.txt') -Value 'remote update'
    Invoke-SyncFixtureGit -RepositoryPath $fixtureFrontendSeed -Arguments @('add', 'tracked.txt') | Out-Null
    Invoke-SyncFixtureGit -RepositoryPath $fixtureFrontendSeed -Arguments @('commit', '-m', 'fixture remote update') | Out-Null
    Invoke-SyncFixtureGit -RepositoryPath $fixtureFrontendSeed -Arguments @('push', 'origin', 'dev') | Out-Null
    $expectedFrontendHead = (Invoke-SyncFixtureGit -RepositoryPath $fixtureFrontendSeed -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()

    $fixtureMaster = Join-Path $syncFixtureWorkspace 'urizo-final-master'
    $fixtureBackend = Join-Path $syncFixtureWorkspace 'urizo-final-backend'
    Add-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureMaster 'tracked.txt') -Value 'master local work'
    Add-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureBackend 'tracked.txt') -Value 'backend local work'
    $masterContentBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureMaster 'tracked.txt')
    $backendContentBefore = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureBackend 'tracked.txt')
    $backendHeadBefore = (Invoke-SyncFixtureGit -RepositoryPath $fixtureBackend -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
    $hookMarker = Join-Path $syncFixtureWorkspace 'hook-refresh.marker'
    Set-Content -Encoding UTF8 -LiteralPath $hookMarker -Value 'original'

    $powerShellExecutable = (Get-Process -Id $PID).Path
    $syncFixtureOutput = @(& $powerShellExecutable -NoProfile -File (Join-Path $fixtureMaster 'scripts/sync-workspace.ps1') -WorkspaceRoot $syncFixtureWorkspace -ApproveNetwork -AsJson 2>&1)
    $syncFixtureExitCode = $LASTEXITCODE
    if ($syncFixtureExitCode -ne 0) {
        throw "Scope-aware sync fixture failed: exit=$syncFixtureExitCode; output=$($syncFixtureOutput -join ' ')"
    }
    $syncFixtureSummary = ($syncFixtureOutput -join "`n") | ConvertFrom-Json
    $masterSyncResult = @($syncFixtureSummary.results | Where-Object Repository -eq 'urizo-final-master')
    $frontendSyncResult = @($syncFixtureSummary.results | Where-Object Repository -eq 'urizo-final-frontend')
    $backendSyncResult = @($syncFixtureSummary.results | Where-Object Repository -eq 'urizo-final-backend')
    $frontendHeadAfter = (Invoke-SyncFixtureGit -RepositoryPath (Join-Path $syncFixtureWorkspace 'urizo-final-frontend') -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
    $backendHeadAfter = (Invoke-SyncFixtureGit -RepositoryPath $fixtureBackend -Arguments @('rev-parse', 'HEAD') | Select-Object -First 1).Trim()
    $masterDirty = @(Invoke-SyncFixtureGit -RepositoryPath $fixtureMaster -Arguments @('status', '--porcelain=v1')).Count
    $backendDirty = @(Invoke-SyncFixtureGit -RepositoryPath $fixtureBackend -Arguments @('status', '--porcelain=v1')).Count
    $masterContentAfter = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureMaster 'tracked.txt')
    $backendContentAfter = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $fixtureBackend 'tracked.txt')
    $hookMarkerValue = (Get-Content -Raw -Encoding UTF8 -LiteralPath $hookMarker).Trim()

    if ($masterSyncResult.Count -ne 1 -or $masterSyncResult[0].Status -ne 'PRESERVED' -or
        $frontendSyncResult.Count -ne 1 -or $frontendSyncResult[0].Action -notmatch 'FAST_FORWARDED' -or
        $backendSyncResult.Count -ne 1 -or $backendSyncResult[0].Status -ne 'PRESERVED' -or
        $frontendHeadAfter -ne $expectedFrontendHead -or
        $backendHeadAfter -ne $backendHeadBefore -or
        $masterDirty -eq 0 -or $backendDirty -eq 0 -or
        $masterContentAfter -ne $masterContentBefore -or $backendContentAfter -ne $backendContentBefore -or
        $syncFixtureSummary.preserved -ne 2 -or
        $syncFixtureSummary.hookRefreshDeferred -ne $true -or
        $syncFixtureSummary.activeContextReloaded -ne $false -or
        $hookMarkerValue -ne 'original') {
        throw 'Scope-aware sync must preserve dirty Master and Source work, continue a clean Source fast-forward, and leave Hooks unchanged.'
    }

    $fixtureFrontend = Join-Path $syncFixtureWorkspace 'urizo-final-frontend'
    Invoke-SyncFixtureGit -RepositoryPath $fixtureFrontend -Arguments @('remote', 'set-url', 'origin', (Join-Path $syncFixtureRemoteRoot 'unexpected.git')) | Out-Null
    $blockedFixtureOutput = @(& $powerShellExecutable -NoProfile -File (Join-Path $fixtureMaster 'scripts/sync-workspace.ps1') -WorkspaceRoot $syncFixtureWorkspace -ApproveNetwork -AsJson 2>&1)
    $blockedFixtureExitCode = $LASTEXITCODE
    $blockedFixtureSummary = ($blockedFixtureOutput -join "`n") | ConvertFrom-Json
    $blockedFrontendResult = @($blockedFixtureSummary.results | Where-Object Repository -eq 'urizo-final-frontend')
    if ($blockedFixtureExitCode -ne 2 -or
        $blockedFixtureSummary.blocked -ne 1 -or
        $blockedFrontendResult.Count -ne 1 -or $blockedFrontendResult[0].Status -ne 'BLOCKED' -or
        $blockedFixtureSummary.hookRefreshDeferred -ne $true) {
        throw 'Scope-aware sync must finish independent repository checks but retain exit code 2 when a repository is BLOCKED.'
    }
    $global:LASTEXITCODE = 0
}
finally {
    if (Test-Path -LiteralPath $syncFixtureRoot) {
        $resolvedSyncFixtureRoot = [IO.Path]::GetFullPath($syncFixtureRoot)
        $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedSyncFixtureRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove sync fixture outside the temp root: $resolvedSyncFixtureRoot"
        }
        Remove-Item -LiteralPath $resolvedSyncFixtureRoot -Recurse -Force
    }
}
Write-Host 'PASS: scope-aware sync preserves dirty work, continues clean Sources, defers Hooks, and retains blocked exit semantics'

$bootstrapWorkspaceScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/bootstrap-workspace.ps1')
if ($bootstrapWorkspaceScript -notmatch 'GetExtension\(\$Target\)' -or
    $bootstrapWorkspaceScript -notmatch 'UTF8Encoding\]::new\(\$writeUtf8Bom\)' -or
    $bootstrapWorkspaceScript -notmatch 'core\.hooksPath' -or
    $bootstrapWorkspaceScript -notmatch 'axms\.workspaceRoot' -or
    $bootstrapWorkspaceScript -notmatch 'refusing to overwrite') {
    throw 'Workspace bootstrap must preserve PowerShell encoding and install the managed Git Hook without overwriting an unrelated hooksPath.'
}
$startFeatureWorkScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/start-feature-work.ps1')
$sharedBackendLocalStateScriptPath = Join-Path $masterRoot 'scripts/ensure-shared-backend-local-state.ps1'
$sharedBackendLocalStateScript = Get-Content -Raw -Encoding UTF8 -LiteralPath $sharedBackendLocalStateScriptPath
$prepareDevPrScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/prepare-dev-pr.ps1')
$prePushPullGateScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/pre-push-pull-gate.ps1')
$prePushHook = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'templates/workspace/githooks/pre-push')
if ($startFeatureWorkScript -notmatch '@\(''pull'', ''--ff-only'', ''origin'', \$integrationBranch\)' -or
    $startFeatureWorkScript -notmatch '@\(''worktree'', ''add''' -or
    $startFeatureWorkScript -notmatch 'CANONICAL CHECKOUT PRESERVED' -or
    $startFeatureWorkScript -notmatch '\$branch -ne \$integrationBranch -or \$canonicalIsDirty' -or
    $startFeatureWorkScript -notmatch '\.worktrees/\.g' -or
    $startFeatureWorkScript -notmatch '\$safeName\.Length -gt 48' -or
    $startFeatureWorkScript -notmatch 'Canonical checkout changed while the isolated dev Pull gate was running' -or
    $startFeatureWorkScript -notmatch '@\(''worktree'', ''remove''' -or
    $startFeatureWorkScript -notmatch 'ensure-shared-backend-local-state\.ps1' -or
    $sharedBackendLocalStateScript -notmatch "'Junction'" -or
    $sharedBackendLocalStateScript -notmatch "'SymbolicLink'" -or
    $sharedBackendLocalStateScript -notmatch 'independent \.local/secrets exists' -or
    $sharedBackendLocalStateScript -match 'Copy-Item|Remove-Item' -or
    $prepareDevPrScript -notmatch '@\(''fetch'', ''origin'', \$integrationBranch\)' -or
    $prepareDevPrScript -match '\$canonicalPath|\$temporaryPullWorktree|CANONICAL DIRTY PRESERVED' -or
    $prepareDevPrScript -match '@\(''pull''|@\(''worktree'', ''add''|@\(''worktree'', ''remove''' -or
    $prepareDevPrScript -notmatch '@\(''merge-base'', ''--is-ancestor''' -or
    $prepareDevPrScript -notmatch 'axms-pull-gates' -or
    $prePushPullGateScript -match '@\(''pull''' -or
    $prePushPullGateScript -notmatch 'refs/heads/dev' -or
    $prePushPullGateScript -notmatch 'refs/heads/main' -or
    $prePushPullGateScript -notmatch 'Stale pre-PR dev receipt' -or
    $prePushHook -notmatch 'pre-push-pull-gate\.ps1') {
    throw 'The pre-work gate must preserve canonical work, while the pre-PR gate fetches dev directly from its Feature Worktree and pre-push stays network-free.'
}

$sharedLocalFixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-shared-local-validation-" + [Guid]::NewGuid().ToString('N'))
try {
    $fixtureCanonical = Join-Path $sharedLocalFixtureRoot 'canonical-backend'
    $fixtureWorktree = Join-Path $sharedLocalFixtureRoot 'feature-backend'
    $fixtureBlockedWorktree = Join-Path $sharedLocalFixtureRoot 'blocked-backend'
    $fixtureCanonicalSecrets = Join-Path $fixtureCanonical '.local\secrets'
    New-Item -ItemType Directory -Path $fixtureCanonicalSecrets, $fixtureWorktree, $fixtureBlockedWorktree -Force | Out-Null
    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $fixtureCanonicalSecrets 'fixture-token') -Value 'dummy-fixture-only'

    & $sharedBackendLocalStateScriptPath -CanonicalBackendRoot $fixtureCanonical -WorktreeRoot $fixtureWorktree | Out-Null
    & $sharedBackendLocalStateScriptPath -CanonicalBackendRoot $fixtureCanonical -WorktreeRoot $fixtureWorktree | Out-Null
    $fixtureSecretsItem = Get-Item -LiteralPath (Join-Path $fixtureWorktree '.local\secrets') -Force
    if (-not $fixtureSecretsItem.Target -or
        -not (Test-Path -LiteralPath (Join-Path $fixtureWorktree '.local\secrets\fixture-token') -PathType Leaf)) {
        throw 'Backend Feature Worktree must reuse canonical .local/secrets without copying secret values.'
    }

    $blockedSecrets = Join-Path $fixtureBlockedWorktree '.local\secrets'
    New-Item -ItemType Directory -Path $blockedSecrets -Force | Out-Null
    Set-Content -Encoding UTF8 -LiteralPath (Join-Path $blockedSecrets 'preserve.marker') -Value 'preserve'
    $independentLocalBlocked = $false
    try {
        & $sharedBackendLocalStateScriptPath -CanonicalBackendRoot $fixtureCanonical -WorktreeRoot $fixtureBlockedWorktree | Out-Null
    }
    catch {
        $independentLocalBlocked = $_.Exception.Message -match 'BACKEND LOCAL STATE BLOCKED'
    }
    if (-not $independentLocalBlocked -or
        -not (Test-Path -LiteralPath (Join-Path $blockedSecrets 'preserve.marker') -PathType Leaf)) {
        throw 'Existing independent Backend .local/secrets must be preserved and block Worktree reuse.'
    }
}
finally {
    if (Test-Path -LiteralPath $sharedLocalFixtureRoot) {
        $resolvedFixtureRoot = [IO.Path]::GetFullPath($sharedLocalFixtureRoot)
        $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedFixtureRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove shared-local fixture outside the temp root: $resolvedFixtureRoot"
        }
        Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
    }
}
Write-Host 'PASS: Backend Feature Worktrees share canonical secrets and preserve conflicting secret directories'
$startLocalScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/start-local-cms.ps1')
$rebuildLocalServiceScript = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/rebuild-local-service.ps1')
if ($workspaceAgentTemplate -notmatch 'start-local-cms\.ps1 -Profile spring-core -ApproveLocalMutation' -or
    $workspaceAgentTemplate -notmatch '-Profile full' -or
    $masterAgents -notmatch 'scripts/start-local-cms\.ps1' -or
    $masterAgents -notmatch 'Frontend-only' -or
    $masterAgents -notmatch 'LOCAL RUNTIME CONTEXT PASS: mode=' -or
    $startLocalScript -notmatch 'BackendSourceRoot' -or
    $startLocalScript -notmatch 'FrontendSourceRoot' -or
    $startLocalScript -notmatch 'OrchestratorSourceRoot' -or
    $startLocalScript -notmatch 'McpSourceRoot' -or
    $startLocalScript -notmatch '\$backendRunnerRoot = if \(\$sourceBindingRequested\)' -or
    $startLocalScript -notmatch "Get-SourceBinding -RepositoryName 'urizo-final-master'" -or
    $startLocalScript -notmatch "Get-SourceBinding -RepositoryName 'urizo-final-backend'" -or
    $startLocalScript -notmatch 'RUNTIME SOURCE BINDING' -or
    $startLocalScript -notmatch 'RUNTIME SOURCE VERIFIED' -or
    $startLocalScript -notmatch 'RequireCleanSourceBindings' -or
    $startLocalScript -notmatch 'rev-parse HEAD') {
    throw 'Master local startup must route natural-language intent to spring-core/full and bind every active Source worktree explicitly.'
}
if ($workspaceAgentTemplate -notmatch 'rebuild-local-service\.ps1' -or
    $workspaceAgentTemplate -notmatch 'SourceRoot <활성 Service Worktree>' -or
    $masterAgents -notmatch 'rebuild-local-service\.ps1' -or
    $rebuildLocalServiceScript -notmatch "ValidateSet\('spring-app', 'frontend', 'coding-runtime', 'mcp-server'\)" -or
    $rebuildLocalServiceScript -notmatch 'SourceRoot') {
    throw 'Master isolated-service routing must use the allowlisted partial-rebuild wrapper and an explicit active Source worktree.'
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
$teamLeadProtocol = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/team/TEAM_LEAD_PROTOCOL_v0.1.md')
$structureContract = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md')
$teamLeadSkill = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot '.agents/skills/axms-team-lead/SKILL.md')
if ($masterAgents -notmatch '## 팀장 세션 프로토콜' -or
    $workspaceAgentTemplate -notmatch '## 팀장 세션 프로토콜' -or
    $teamLeadProtocol -notmatch '팀장 프로토콜로 전환할까요\?' -or
    $teamLeadProtocol -notmatch 'PLAN PASS' -or
    $teamLeadProtocol -notmatch 'TEAM TRACK PASS' -or
    $teamLeadProtocol -notmatch 'TEAM PLAN APPROVED' -or
    $teamLeadProtocol -notmatch 'TEAM DISPATCH PASS' -or
    $teamLeadProtocol -notmatch 'TEAM DISPATCH BLOCKED' -or
    $teamLeadProtocol -notmatch 'TEAM MONITOR PASS' -or
    $teamLeadProtocol -notmatch '독립 Work ID가 둘 이상이면 `MULTI TRACK`' -or
    $teamLeadProtocol -notmatch '이 작업계획과 세션 배정으로 진행할까요\?' -or
    $teamLeadProtocol -notmatch '`TEAM DISPATCH PASS` 전에는 시작하지 않는다' -or
    -not $teamLeadProtocol.Contains('사용자 재배정 없이 해당 Worktree를 직접 수정해 작업자를 대체하지 않는다') -or
    $teamLeadProtocol -notmatch 'STRUCTURE BLOCKED' -or
    $teamLeadProtocol -notmatch 'PROFILE PLAN PASS' -or
    $teamLeadProtocol -notmatch 'PROFILE PLAN ALTERNATIVE' -or
    $teamLeadProtocol -notmatch 'MODEL PROFILE BLOCKED' -or
    $teamLeadProtocol -notmatch 'PROFILE REQUEST' -or
    $teamLeadProtocol -notmatch 'PROFILE ATTEST' -or
    $teamLeadProtocol -notmatch 'PROFILE RUNTIME' -or
    $teamLeadProtocol -notmatch 'readback을 제공하지 않는다' -or
    $teamLeadProtocol -notmatch '사용자 가시성 표' -or
    $teamLeadProtocol -notmatch '역할 프로필.*실제 모델.*추론 수준.*속도' -or
    $teamLeadProtocol -notmatch 'SIMPLE PASS' -or
    $teamLeadProtocol -notmatch 'GUARDRAIL PASS' -or
    $teamLeadProtocol -notmatch '상태 변화마다.*작업 범위.*Git Diff' -or
    $teamLeadProtocol -notmatch '위반.*즉시 중단' -or
    $teamLeadProtocol -notmatch 'prepare-dev-pr\.ps1 -ApproveNetwork' -or
    $teamLeadProtocol -notmatch 'Push·PR은 별도 승인 전 금지' -or
    $teamLeadProtocol -notmatch '프로필 검토 세션 생성' -or
    $teamLeadProtocol -notmatch '예비 승인' -or
    $teamLeadProtocol -notmatch 'PLAN 전용 세션' -or
    $teamLeadProtocol -notmatch '최종 작업계획' -or
    $teamLeadProtocol -notmatch '최종 작업 승인 전 Source 수정은 금지한다' -or
    $teamLeadProtocol -notmatch 'create_thread' -or
    $teamLeadProtocol -notmatch 'send_message_to_thread' -or
    $teamLeadProtocol -notmatch '승인 `model`과 `thinking`' -or
    $teamLeadProtocol -notmatch '자동 fallback은 금지한다' -or
    $teamLeadProtocol -notmatch '@팀장 종료' -or
    $structureContract -notmatch '하위 작업 기록' -or
    $structureContract -notmatch 'STRUCTURE BLOCKED' -or
    $teamLeadSkill -notmatch 'TEAM_LEAD_PROTOCOL_v0\.1\.md' -or
    $teamLeadSkill -notmatch 'TEAM TRACK PASS' -or
    $teamLeadSkill -notmatch 'TEAM PLAN APPROVED' -or
    $teamLeadSkill -notmatch 'TEAM DISPATCH PASS' -or
    $teamLeadSkill -notmatch 'TEAM DISPATCH BLOCKED' -or
    $teamLeadSkill -notmatch 'TEAM MONITOR PASS' -or
    $teamLeadSkill -notmatch 'PROFILE PLAN PASS' -or
    $teamLeadSkill -notmatch 'PROFILE PLAN ALTERNATIVE' -or
    $teamLeadSkill -notmatch 'MODEL PROFILE BLOCKED' -or
    $teamLeadSkill -notmatch 'PROFILE REQUEST' -or
    $teamLeadSkill -notmatch 'PROFILE ATTEST' -or
    $teamLeadSkill -notmatch 'PROFILE RUNTIME' -or
    $teamLeadSkill -notmatch 'no independent runtime model/thinking readback' -or
    $teamLeadSkill -notmatch 'role profile, concrete model, reasoning level, and speed' -or
    $teamLeadSkill -notmatch 'SIMPLE PASS' -or
    $teamLeadSkill -notmatch 'GUARDRAIL PASS' -or
    $teamLeadSkill -notmatch 'every state change.*scope and Git Diff' -or
    $teamLeadSkill -notmatch 'violated, stop the affected session immediately' -or
    $teamLeadSkill -notmatch 'prepare-dev-pr\.ps1 -ApproveNetwork' -or
    $teamLeadSkill -notmatch 'before separate user approval' -or
    $teamLeadSkill -notmatch '프로필 검토 세션 생성' -or
    $teamLeadSkill -notmatch 'preliminary approval' -or
    $teamLeadSkill -notmatch 'PLAN-only' -or
    $teamLeadSkill -notmatch 'final work plan' -or
    $teamLeadSkill -notmatch 'no Source mutation' -or
    $teamLeadSkill -notmatch 'create_thread' -or
    $teamLeadSkill -notmatch 'send_message_to_thread' -or
    $teamLeadSkill -notmatch 'approved `model` and `thinking`' -or
    $teamLeadSkill -notmatch 'automatic fallback' -or
    $teamLeadSkill -notmatch 'Two or more independent Work IDs are always `MULTI TRACK`' -or
    $teamLeadSkill -notmatch '이 작업계획과 세션 배정으로 진행할까요\?' -or
    $teamLeadSkill -notmatch 'Do not silently replace workers with the lead session or hidden helpers' -or
    $bootstrapWorkspaceScript -notmatch '\.agents/skills/axms-team-lead/SKILL\.md' -or
    $bootstrapWorkspaceScript -notmatch 'WorkspaceRoot.*\.agents/skills/axms-team-lead/SKILL\.md') {
    throw 'Master must define the approval-gated lightweight team-lead protocol and AI Core structure contract.'
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
$aiWorktreePattern = '(?s)Source.{0,80}Work ID.{0,200}Worktree'
if ($masterAgents -notmatch $aiWorktreePattern -or
    $workspaceAgentTemplate -notmatch $aiWorktreePattern -or
    $operatingPolicy -notmatch $aiWorktreePattern) {
    throw 'Master, Workspace, and operating policies must require a Work ID-specific independent Worktree for AI Source implementation.'
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
    Get-Item -LiteralPath (Join-Path $masterRoot 'templates/workspace/codex/hooks/post-pull-context.ps1')
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
    '(?im)^\s*(?:&\s+)?git\s+(reset|clean|stash|checkout|switch|rebase)\b',
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

$nonPullGateScriptText = (Get-ChildItem -File -LiteralPath (Join-Path $masterRoot 'scripts') -Filter '*.ps1' |
    Where-Object { $_.Name -notin @('validate-master-scaffold.ps1', 'start-feature-work.ps1') } |
    ForEach-Object { Get-Content -Raw -Encoding UTF8 -LiteralPath $_.FullName }) -join "`n"
if ($nonPullGateScriptText -match "(?im)git\s+pull|@\('pull'") {
    throw 'Network-mutating Git pull is allowed only in the pre-work gate script.'
}

foreach ($forbiddenDirectory in @(
        'urizo-final-frontend',
        'urizo-final-backend',
        'urizo-final-orchestrator',
        'urizo-final-mcp-server')) {
    if (Test-Path -LiteralPath (Join-Path $masterRoot $forbiddenDirectory)) {
        throw "Source repository copy is forbidden inside Master: $forbiddenDirectory"
    }
}

Write-Host "PASS: $($required.Count) required files"
Write-Host 'PASS: manifest and both workspace JSON files parsed'
Write-Host 'PASS: bounded full/checkpoint context with conditional AGENTS refresh after direct/functions.exec Git pull'
Write-Host 'PASS: enforced pre-work Pull and pre-PR fetch gates with read-only pre-push receipt validation'
Write-Host 'PASS: managed local-LLM policy, dev-only PR policy, and Claude routing'
Write-Host 'PASS: five canonical repository remotes'
Write-Host 'PASS: all PowerShell scripts parsed'
Write-Host 'PASS: no forbidden destructive command patterns'
Write-Host 'PASS: no source repository copy inside Master'
