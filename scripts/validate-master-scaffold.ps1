[CmdletBinding()]
param(
    [switch]$PublicOnly,

    [string]$BackendSourceRoot
)

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
    'scripts/load-task-context.ps1',
    'scripts/compare-context-routing.ps1',
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
    $sessionStartScript -notmatch 'load-task-context\.ps1' -or
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
    $checkpointOutput -notmatch 'load-task-context\.ps1' -or
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

$fixtureSourceRoot = Join-Path $testWorkspaceRoot 'urizo-final-backend'
New-Item -ItemType Directory -Path $fixtureSourceRoot -Force | Out-Null
$fixtureSourceContent = "# Fixture Backend Rules`n" + ('x' * 12000)
Set-Content -LiteralPath (Join-Path $fixtureSourceRoot 'AGENTS.md') -Encoding UTF8 -NoNewline -Value $fixtureSourceContent
Push-Location $fixtureSourceRoot
try {
    $sourceFullOutput = @(& $sessionStartScriptPath -WorkspaceRoot $testWorkspaceRoot -Mode Full -Reason Lifecycle -MaxContextBytes 24576) -join "`n"
}
finally {
    Pop-Location
}
$sourceFullBytes = [Text.Encoding]::UTF8.GetByteCount($sourceFullOutput)
if ($sourceFullOutput -notmatch '===== BEGIN urizo-final-backend/AGENTS\.md =====' -or
    $sourceFullBytes -gt 24576) {
    throw "Full mode must preserve room for a 12KB Source AGENTS file; bytes=$sourceFullBytes"
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

$taskContextLoaderPath = Join-Path $masterRoot 'scripts/load-task-context.ps1'
$validationPowerShell = (Get-Process -Id $PID).Path
function Get-ValidationTextSha256 {
    param([Parameter(Mandatory = $true)][string]$Text)

    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = $hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
    }
    finally {
        $hasher.Dispose()
    }
    return ($hash | ForEach-Object { $_.ToString('x2') }) -join ''
}

function Get-ExpectedTaskContextValidation {
    param(
        [Parameter(Mandatory = $true)][string[]]$RelativePaths,
        [string]$RootPath = $masterRoot,
        [string]$BackendPolicyPath
    )

    $documentLines = [System.Collections.Generic.List[string]]::new()
    $contentBuilder = [Text.StringBuilder]::new()
    foreach ($relativePath in $RelativePaths) {
        $documentPath = if ($relativePath -eq 'backend-source/docs/DATABASE_MIGRATION_POLICY_v0.2.md') {
            if (-not $BackendPolicyPath) {
                throw 'Expected context validation requires BackendPolicyPath for the Backend policy.'
            }
            $BackendPolicyPath
        }
        else {
            Join-Path $RootPath $relativePath
        }
        $content = [IO.File]::ReadAllText($documentPath, [Text.Encoding]::UTF8)
        $normalizedPath = $relativePath.Replace('\', '/')
        $bytes = [Text.Encoding]::UTF8.GetByteCount($content)
        $sha256 = Get-ValidationTextSha256 -Text $content
        $documentLines.Add("- $normalizedPath; bytes=$bytes; sha256=$sha256")
        [void]$contentBuilder.AppendLine("===== BEGIN $normalizedPath =====")
        [void]$contentBuilder.AppendLine($content.TrimEnd())
        [void]$contentBuilder.AppendLine("===== END $normalizedPath =====")
        [void]$contentBuilder.AppendLine()
    }

    $chunkContentLimit = 16384 - 4096
    $chunkHashes = [System.Collections.Generic.List[string]]::new()
    $chunkTexts = [System.Collections.Generic.List[string]]::new()
    $chunkBuilder = [Text.StringBuilder]::new()
    $reader = [IO.StringReader]::new($contentBuilder.ToString())
    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            $unit = $line + "`n"
            $candidateBytes = [Text.Encoding]::UTF8.GetByteCount($chunkBuilder.ToString() + $unit)
            if ($chunkBuilder.Length -gt 0 -and $candidateBytes -gt $chunkContentLimit) {
                $chunkText = $chunkBuilder.ToString()
                $chunkTexts.Add($chunkText)
                $chunkHashes.Add((Get-ValidationTextSha256 -Text $chunkText))
                $chunkBuilder.Length = 0
            }
            [void]$chunkBuilder.Append($unit)
        }
    }
    finally {
        $reader.Dispose()
    }
    if ($chunkBuilder.Length -gt 0) {
        $chunkText = $chunkBuilder.ToString()
        $chunkTexts.Add($chunkText)
        $chunkHashes.Add((Get-ValidationTextSha256 -Text $chunkText))
    }
    $bundleText = $chunkTexts -join ''

    return [pscustomobject]@{
        BundleHash = Get-ValidationTextSha256 -Text $bundleText
        BundleBytes = [Text.Encoding]::UTF8.GetByteCount($bundleText)
        ChunkHashes = @($chunkHashes)
        DocumentLines = @($documentLines)
    }
}

function Invoke-TaskContextLoaderValidation {
    param(
        [Parameter(Mandatory = $true)][string[]]$Profile,
        [int]$FeatureNumber = 0,
        [int]$ChunkNumber = 1,
        [string]$PreviousChunkSha256,
        [string]$ExpectedBundleSha256,
        [string]$LoaderPath,
        [string]$BackendRoot
    )

    if (-not $LoaderPath) {
        $LoaderPath = $taskContextLoaderPath
    }
    $arguments = @('-NoProfile')
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        $arguments += @('-ExecutionPolicy', 'Bypass')
    }
    $arguments += @(
        '-File', $LoaderPath,
        '-Profile', ($Profile -join ','),
        '-ChunkNumber', $ChunkNumber,
        '-MaxContextBytes', 16384
    )
    if ($FeatureNumber -gt 0) {
        $arguments += @('-FeatureNumber', $FeatureNumber)
    }
    if ($BackendRoot) {
        $arguments += @('-BackendSourceRoot', $BackendRoot)
    }
    if ($PreviousChunkSha256) {
        $arguments += @('-PreviousChunkSha256', $PreviousChunkSha256)
    }
    if ($ExpectedBundleSha256) {
        $arguments += @('-ExpectedBundleSha256', $ExpectedBundleSha256)
    }
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $validationPowerShell @arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    return [pscustomobject]@{
        ExitCode = $exitCode
        Text = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    }
}

$backendPolicyPath = $null
if (-not $BackendSourceRoot -or -not [IO.Path]::IsPathRooted($BackendSourceRoot)) {
    throw 'Scaffold validation requires an explicit absolute BackendSourceRoot.'
}
$BackendSourceRoot = (Resolve-Path -LiteralPath $BackendSourceRoot).Path
$backendPolicyPath = Join-Path $BackendSourceRoot 'docs/DATABASE_MIGRATION_POLICY_v0.2.md'
if (-not (Test-Path -LiteralPath $backendPolicyPath -PathType Leaf)) {
    throw 'Scaffold validation requires Backend docs/DATABASE_MIGRATION_POLICY_v0.2.md.'
}

$taskContextCases = @(
    [pscustomobject]@{ Profile = 'Product'; FeatureNumber = 0; BackendRoot = $null; Documents = @('docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md', 'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md') }
    [pscustomobject]@{ Profile = 'Git'; FeatureNumber = 0; BackendRoot = $null; Documents = @('docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md', 'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md') }
    [pscustomobject]@{ Profile = 'Runtime'; FeatureNumber = 0; BackendRoot = $null; Documents = @('docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md', 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md') }
    [pscustomobject]@{ Profile = 'Database'; FeatureNumber = 0; BackendRoot = $BackendSourceRoot; Documents = @('docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md', 'docs/team/FLYWAY_RESERVATION_LEDGER.md', 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md', 'backend-source/docs/DATABASE_MIGRATION_POLICY_v0.2.md') }
    [pscustomobject]@{ Profile = 'TeamLead'; FeatureNumber = 0; BackendRoot = $null; Documents = @('docs/team/TEAM_LEAD_PROTOCOL_v0.1.md') }
    [pscustomobject]@{ Profile = 'Master'; FeatureNumber = 0; BackendRoot = $null; Documents = @('docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md', 'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md', 'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md') }
    [pscustomobject]@{ Profile = @('Runtime', 'Database', 'Git'); FeatureNumber = 0; BackendRoot = $BackendSourceRoot; Documents = @('docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md', 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md', 'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md', 'docs/team/FLYWAY_RESERVATION_LEDGER.md', 'backend-source/docs/DATABASE_MIGRATION_POLICY_v0.2.md', 'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md') }
    [pscustomobject]@{ Profile = @('Master', 'Git'); FeatureNumber = 0; BackendRoot = $null; Documents = @('docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md', 'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md', 'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md', 'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md') }
)
if (-not $PublicOnly) {
    $taskContextCases += @(
        [pscustomobject]@{ Profile = 'AiFeature'; FeatureNumber = 2; BackendRoot = $null; Documents = @('docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md', 'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md', 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md', 'docs/product/ai-core/02_DOMAIN_RAG_REPLACEMENT.md') }
        [pscustomobject]@{ Profile = 'AiFeature'; FeatureNumber = 3; BackendRoot = $null; Documents = @('docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md', 'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md', 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md', 'docs/product/ai-core/03_RAG_QUALITY.md') }
        [pscustomobject]@{ Profile = 'AiFeature'; FeatureNumber = 4; BackendRoot = $null; Documents = @('docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md', 'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md', 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md', 'docs/product/ai-core/04_LIMITED_LLM_DEVOPS.md') }
        [pscustomobject]@{ Profile = 'AiFeature'; FeatureNumber = 5; BackendRoot = $null; Documents = @('docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md', 'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md', 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md', 'docs/product/ai-core/05_NATURAL_LANGUAGE_CMS.md') }
        [pscustomobject]@{ Profile = 'AiFeature'; FeatureNumber = 6; BackendRoot = $null; Documents = @('docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md', 'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md', 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md', 'docs/product/ai-core/06_ORCHESTRATION_CONTROL.md') }
    )
}
$profileBundles = @{}
foreach ($case in $taskContextCases) {
    $profileList = @($case.Profile)
    $profileLabel = $profileList -join ','
    $expectedArguments = @{ RelativePaths = $case.Documents }
    if ($profileList -contains 'Database') {
        $expectedArguments.BackendPolicyPath = $backendPolicyPath
    }
    $expected = Get-ExpectedTaskContextValidation @expectedArguments
    $first = Invoke-TaskContextLoaderValidation -Profile $profileList -FeatureNumber $case.FeatureNumber -ChunkNumber 1 -BackendRoot $case.BackendRoot
    $chunkMatch = [regex]::Match($first.Text, '(?m)^chunk=1/(?<total>[0-9]+)$')
    $bundleMatch = [regex]::Match($first.Text, '(?m)^bundleSha256=(?<hash>[0-9a-f]{64})$')
    if ($first.ExitCode -ne 0 -or
        $first.Text -notmatch '^TASK CONTEXT RECEIPT v1' -or
        $first.Text -notmatch '(?m)^status=PASS$' -or
        $first.Text -notmatch "(?m)^profile=$([regex]::Escape($profileLabel))$" -or
        $first.Text -notmatch '===== BEGIN ' -or
        $first.Text -notmatch 'sha256=[0-9a-f]{64}' -or
        $first.Text -notmatch '(?m)^chunkSha256=[0-9a-f]{64}$' -or
        $first.Text -notmatch "(?m)^bundleBytes=$($expected.BundleBytes)$" -or
        -not $chunkMatch.Success -or
        -not $bundleMatch.Success -or
        $bundleMatch.Groups['hash'].Value -ne $expected.BundleHash -or
        [Text.Encoding]::UTF8.GetByteCount($first.Text) -gt 16384) {
        throw "Task context loader did not return a bounded first Chunk: Profile=$profileLabel; FeatureNumber=$($case.FeatureNumber)"
    }
    if ($profileList -contains 'Database' -and
        ($first.Text -notmatch "(?m)^backendSourceRoot=$([regex]::Escape($BackendSourceRoot))$" -or
         $first.Text -notmatch '(?m)^backendPolicySha256=[0-9a-f]{64}$')) {
        throw 'Database context Receipt must identify the explicit Backend Source root and policy fingerprint.'
    }

    $totalChunks = [int]$chunkMatch.Groups['total'].Value
    $bundleHash = $bundleMatch.Groups['hash'].Value
    if ($totalChunks -ne $expected.ChunkHashes.Count) {
        throw "Task context loader returned the wrong Chunk count: Profile=$profileLabel; expected=$($expected.ChunkHashes.Count); actual=$totalChunks"
    }
    $receiptHeader = $first.Text.Substring(0, $first.Text.IndexOf('===== BEGIN '))
    $actualDocumentLines = @([regex]::Matches($receiptHeader, '(?m)^- .+; bytes=[0-9]+; sha256=[0-9a-f]{64}$') | ForEach-Object { $_.Value })
    if ($actualDocumentLines.Count -ne $expected.DocumentLines.Count) {
        throw "Task context loader returned the wrong document count: Profile=$profileLabel"
    }
    foreach ($documentIndex in 0..($expected.DocumentLines.Count - 1)) {
        if ($actualDocumentLines[$documentIndex] -ne $expected.DocumentLines[$documentIndex]) {
            throw "Task context loader returned the wrong document mapping or fingerprint: Profile=$profileLabel; index=$documentIndex"
        }
    }
    $last = $null
    $previousChunkHash = $null
    $emittedBundleBuilder = [Text.StringBuilder]::new()
    foreach ($chunkNumber in 1..$totalChunks) {
        $chunk = if ($chunkNumber -eq 1) {
            $first
        }
        else {
            Invoke-TaskContextLoaderValidation -Profile $profileList -FeatureNumber $case.FeatureNumber -ChunkNumber $chunkNumber -PreviousChunkSha256 $previousChunkHash -ExpectedBundleSha256 $bundleHash -BackendRoot $case.BackendRoot
        }
        $receiptSeparatorIndex = $chunk.Text.IndexOf("`n`n")
        if ($receiptSeparatorIndex -lt 0) {
            throw "Task context loader did not separate the Receipt from its body: Profile=$profileLabel; Chunk=$chunkNumber/$totalChunks"
        }
        $chunkBody = $chunk.Text.Substring($receiptSeparatorIndex + 2)
        $recalculatedChunkHash = Get-ValidationTextSha256 -Text $chunkBody
        [void]$emittedBundleBuilder.Append($chunkBody)
        $chunkHashMatch = [regex]::Match($chunk.Text, '(?m)^chunkSha256=(?<hash>[0-9a-f]{64})$')
        $expectedComplete = if ($chunkNumber -eq $totalChunks) { 'true' } else { 'false' }
        if ($chunk.ExitCode -ne 0 -or
            $chunk.Text -notmatch "(?m)^chunk=$chunkNumber/$totalChunks$" -or
            $chunk.Text -notmatch "(?m)^complete=$expectedComplete$" -or
            $chunk.Text -notmatch "(?m)^bundleSha256=$bundleHash$" -or
            $chunk.Text -notmatch "(?m)^chunkSha256=$($expected.ChunkHashes[$chunkNumber - 1])$" -or
            $recalculatedChunkHash -ne $expected.ChunkHashes[$chunkNumber - 1] -or
            -not $chunkHashMatch.Success -or
            [Text.Encoding]::UTF8.GetByteCount($chunk.Text) -gt 16384) {
            throw "Task context loader sequence is incomplete or inconsistent: Profile=$profileLabel; FeatureNumber=$($case.FeatureNumber); Chunk=$chunkNumber/$totalChunks"
        }
        $previousChunkHash = $chunkHashMatch.Groups['hash'].Value
        $last = $chunk
    }
    if ($last.ExitCode -ne 0 -or
        $last.Text -notmatch "(?m)^chunk=$totalChunks/$totalChunks$" -or
        $last.Text -notmatch '(?m)^complete=true$' -or
        $last.Text -notmatch '===== END ' -or
        [Text.Encoding]::UTF8.GetByteCount($last.Text) -gt 16384) {
        throw "Task context loader did not return a bounded final Chunk: Profile=$profileLabel; FeatureNumber=$($case.FeatureNumber)"
    }
    if ((Get-ValidationTextSha256 -Text $emittedBundleBuilder.ToString()) -ne $bundleHash) {
        throw "Task context loader emitted bodies that do not reconstruct the advertised bundle: Profile=$profileLabel"
    }
    $profileBundles[$profileLabel] = $emittedBundleBuilder.ToString()
}

function Test-RequiredProfileRule {
    param(
        [Parameter(Mandatory = $true)][string]$Bundle,
        [Parameter(Mandatory = $true)]$Rule
    )

    $beginMarker = "===== BEGIN $($Rule.OwnerPath) ====="
    $endMarker = "===== END $($Rule.OwnerPath) ====="
    $beginIndex = $Bundle.IndexOf($beginMarker, [StringComparison]::Ordinal)
    $endIndex = $Bundle.IndexOf($endMarker, [StringComparison]::Ordinal)
    if ($beginIndex -lt 0 -or $endIndex -le $beginIndex) {
        return $false
    }
    $ownerSection = $Bundle.Substring($beginIndex, ($endIndex + $endMarker.Length) - $beginIndex)
    foreach ($clause in $Rule.Clauses) {
        if ($ownerSection -notmatch $clause) {
            return $false
        }
    }
    return $true
}

$requiredProfileRules = @(
    [pscustomobject]@{ Id = 'RUNTIME-CHANGE-SCOPE'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-CHANGE-SCOPE', 'staged·unstaged·untracked', 'origin/dev.+현재 Work ID Commit', '다른 Work ID.+범위에 넣지 않는다', '함께 보고 정한다', '확정한 Profile·Service·SourceRoot만', '모호함이 남으면 추측하지 않고 한 번 질문'); WeakeningPattern = '함께 보고 정한다'; WeakeningReplacement = '선택적으로 본다' }
    [pscustomobject]@{ Id = 'RUNTIME-HMR-BAN'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-HMR-BAN', 'package\.json.+Lockfile.+Dockerfile.+Vite·Nginx', 'Backend·Orchestrator·\s*MCP Server', 'HMR을 사용하지 않고.+full'); WeakeningPattern = 'HMR을 사용하지 않고'; WeakeningReplacement = 'HMR을 사용할 수 있고' }
    [pscustomobject]@{ Id = 'RUNTIME-FULL-REBUILD'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-FULL-REBUILD', '전체 동기화에서 Source가 하나라도 갱신', '전체·로컬 재기동을', '명시하면 `full -Rebuild -ApproveNetwork`', '네 활성 SourceRoot', '여러 Source 변경', '전체 재빌드 요청', 'DB·Flyway·Compose·Network·Secret 영향', 'Frontend 비-Live 변경', 'BackendSourceRoot', 'FrontendSourceRoot', 'OrchestratorSourceRoot', 'McpSourceRoot', 'Rebuild 없는 기존 Image 기동으로 약화하지 않는다'); WeakeningPattern = 'Rebuild 없는 기존 Image 기동으로 약화하지 않는다'; WeakeningReplacement = 'Rebuild 없는 기존 Image 기동도 허용한다' }
    [pscustomobject]@{ Id = 'RUNTIME-ISOLATED-HEALTH'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-ISOLATED-HEALTH', '건강한 Profile의 단일 Service만', '선택한 Profile 전체 Health를 확인', 'coding-runtime.+mcp-server.+격리 갱신', 'full.+에서만 허용', 'DB·Flyway·Volume Service는 대상에서 제외', 'DB·Volume을 변경하지 않는다'); WeakeningPattern = '선택한 Profile 전체 Health를 확인한다'; WeakeningReplacement = '해당 Service 상태만 확인한다' }
    [pscustomobject]@{ Id = 'RUNTIME-FAIL-CLOSEOUT'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-FAIL-CLOSEOUT', '같은 원인이 두 번 실패', 'PARTIAL.+NOT VERIFIED', '정확한 재현 명령', '세 번째 재시도를 중단'); WeakeningPattern = '세 번째 재시도를 중단'; WeakeningReplacement = '세 번째 재시도를 계속' }
    [pscustomobject]@{ Id = 'RUNTIME-SERIAL-INTEGRATION'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-SERIAL-INTEGRATION', 'Source 구현·단위 테스트는 병렬', '공유 DB·Volume', 'full.+Flyway.+한 번에 하나만 직렬 실행'); WeakeningPattern = '한 번에 하나만 직렬 실행한다'; WeakeningReplacement = '병렬 실행할 수 있다' }
    [pscustomobject]@{ Id = 'DATABASE-FLYWAY-LIMIT'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('DATABASE-FLYWAY-LIMIT', 'Migration·Schema 변경 검증 또는 공식.+full.+필요할 때만 실행', '후보 SHA 조합을 고정하기 전에는 단위·계약·정적 검증을 우선', '코드 수정마다.+full.+Flyway를 반복하지 않는다', '세 번째 실행은 팀장 승인', 'Repair/Clean.+DB 초기화.+History 수정.+Volume 삭제'); WeakeningPattern = '필요할 때만 실행한다'; WeakeningReplacement = '언제든 실행할 수 있다' }
    [pscustomobject]@{ Id = 'RUNTIME-LOCAL-WRAPPER'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-LOCAL-WRAPPER', 'start-local-cms\.ps1', 'ApproveLocalMutation', 'CMS-only는 `spring-core`', 'MCP Server를 포함한 `full`', '이미 정상이고 반영할 Source 변경이 없으면 기존 Container를 재사용하고 즉시 종료', 'Image가 없으면 Network 승인', 'spring-core.+Coding Runtime과 MCP Server를 성공 조건에서 제외', '임의 Docker 명령으로 우회하지 않는다'); WeakeningPattern = '임의 Docker 명령으로 우회하지 않는다'; WeakeningReplacement = '임의 Docker 명령으로 우회할 수 있다' }
    [pscustomobject]@{ Id = 'RUNTIME-FRONTEND-LIVE'; Profiles = @('Runtime', 'Database'); OwnerPath = 'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'; Clauses = @('RUNTIME-FRONTEND-LIVE', '사용자가 Frontend-only 반영을 명시', '`src`', '`public`', '`index\.html`', 'CMS가 건강할 때만', '한 번에 하나의 활성 Work ID', 'Worktree 전환 전에 기존 Watch를 종료', 'Git·Secret·`node_modules`', 'RestoreImageOnly', 'PR 전에는 Watch를', '종료하고 실제 Image Build', 'Frontend 테스트·타입 검사와 전체 Health'); WeakeningPattern = 'CMS가 건강할 때만'; WeakeningReplacement = 'CMS 상태와 관계없이' }
    [pscustomobject]@{ Id = 'GIT-ADMIN-MERGE-GATE'; Profiles = @('Git'); OwnerPath = 'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md'; Clauses = @('GIT-ADMIN-MERGE-GATE', 'tmdwns0531', 'Merge가 명시적으로', '승인됐으며 PR Base가 `dev`', 'Head SHA', 'mergeable=MERGEABLE', '필수 리뷰로만', 'gh pr merge --merge --admin', '경우에만'); WeakeningPattern = '경우에만'; WeakeningReplacement = '경우에도' }
    [pscustomobject]@{ Id = 'GIT-MERGED-CLEANUP-GATE'; Profiles = @('Git'); OwnerPath = 'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md'; Clauses = @('GIT-MERGED-CLEANUP-GATE`: 현재 Work ID의 PR Base가 `dev`', 'GitHub에서 병합', 'origin/dev.+조상', 'Worktree는 깨끗할 때만', '열린 PR.+미병합 Branch.+추가 Commit.+Dirty·Diverged·local-only', '확인한 뒤에만'); WeakeningPattern = '확인한 뒤에만'; WeakeningReplacement = '확인 전에도' }
    [pscustomobject]@{ Id = 'BACKEND-DB-PR-SEVEN'; Profiles = @('Database'); OwnerPath = 'backend-source/docs/DATABASE_MIGRATION_POLICY_v0.2.md'; Clauses = @('PR 전 필수 검증', '빈 Core DB에서 Head까지 Upgrade', 'origin/dev.+새 Head까지 Upgrade', 'flyway_schema_history.+단일 성공 History', '미적용 Revision 0건·변경 0건', 'Runtime Role의 DDL 시도 실패', '자동 DDL 0건', 'Extension·Index·Constraint 존재 확인'); WeakeningPattern = 'PR 전 필수 검증'; WeakeningReplacement = 'PR 전 선택 검증' }
    [pscustomobject]@{ Id = 'TEAMLEAD-ACTIVATION'; Profiles = @('TeamLead'); OwnerPath = 'docs/team/TEAM_LEAD_PROTOCOL_v0.1.md'; Clauses = @('Simple is best', '팀장 역할 전환을 승인', '팀장 프로토콜로 전환할까요\?', '승인 전에는'); WeakeningPattern = '승인 전에는'; WeakeningReplacement = '승인 전에도' }
)

foreach ($rule in $requiredProfileRules) {
    foreach ($profile in $rule.Profiles) {
        $bundle = $profileBundles[$profile]
        if (-not $bundle -or -not (Test-RequiredProfileRule -Bundle $bundle -Rule $rule)) {
            throw "Required Profile rule is missing or unreachable: id=$($rule.Id); profile=$profile; owner=$($rule.OwnerPath)"
        }
        $deletedRule = $bundle.Replace($rule.Clauses[0], 'REMOVED_REQUIRED_RULE')
        if (Test-RequiredProfileRule -Bundle $deletedRule -Rule $rule) {
            throw "Required Profile rule deletion was not detected: id=$($rule.Id); profile=$profile"
        }
        $weakenedRule = $bundle.Replace($rule.WeakeningPattern, $rule.WeakeningReplacement)
        if ($weakenedRule -eq $bundle -or (Test-RequiredProfileRule -Bundle $weakenedRule -Rule $rule)) {
            throw "Required Profile rule weakening was not detected: id=$($rule.Id); profile=$profile"
        }
        $unreachableRule = $bundle.Replace("===== BEGIN $($rule.OwnerPath) =====", '===== BEGIN omitted-owner.md =====')
        if (Test-RequiredProfileRule -Bundle $unreachableRule -Rule $rule) {
            throw "Required Profile owner omission was not detected: id=$($rule.Id); profile=$profile"
        }
    }
}

$gitCleanupRule = @($requiredProfileRules | Where-Object Id -eq 'GIT-MERGED-CLEANUP-GATE')[0]
$gitCleanupBundle = $profileBundles['Git']
$gitCleanupWithoutBase = $gitCleanupBundle.Replace(
    'GIT-MERGED-CLEANUP-GATE`: 현재 Work ID의 PR Base가 `dev`이고',
    'GIT-MERGED-CLEANUP-GATE`: 현재 Work ID의 PR이'
)
if ($gitCleanupWithoutBase -eq $gitCleanupBundle -or
    $gitCleanupWithoutBase -notmatch '(?s)GIT-ADMIN-MERGE-GATE.*?PR Base가 `dev`' -or
    (Test-RequiredProfileRule -Bundle $gitCleanupWithoutBase -Rule $gitCleanupRule)) {
    throw 'Merged cleanup validation must reject a missing cleanup PR Base=dev condition while preserving the admin-merge condition.'
}

if ($PublicOnly) {
    $syntheticAiRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-public-ai-context-" + [Guid]::NewGuid().ToString('N'))
    try {
        $syntheticAiScript = Join-Path $syntheticAiRoot 'scripts/load-task-context.ps1'
        $syntheticAiCore = Join-Path $syntheticAiRoot 'docs/product/ai-core'
        $syntheticAiTeam = Join-Path $syntheticAiRoot 'docs/team'
        New-Item -ItemType Directory -Path (Split-Path -Parent $syntheticAiScript), $syntheticAiCore, $syntheticAiTeam -Force | Out-Null
        Copy-Item -LiteralPath $taskContextLoaderPath -Destination $syntheticAiScript
        Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md') -Destination $syntheticAiTeam
        Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md') -Destination (Split-Path -Parent $syntheticAiCore)
        Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md') -Destination $syntheticAiCore
        $syntheticAiDocuments = @(
            [pscustomobject]@{ Number = 2; Name = '02_DOMAIN_RAG_REPLACEMENT.md' }
            [pscustomobject]@{ Number = 3; Name = '03_RAG_QUALITY.md' }
            [pscustomobject]@{ Number = 4; Name = '04_LIMITED_LLM_DEVOPS.md' }
            [pscustomobject]@{ Number = 5; Name = '05_NATURAL_LANGUAGE_CMS.md' }
            [pscustomobject]@{ Number = 6; Name = '06_ORCHESTRATION_CONTROL.md' }
        )
        foreach ($syntheticDocument in $syntheticAiDocuments) {
            [IO.File]::WriteAllText(
                (Join-Path $syntheticAiCore $syntheticDocument.Name),
                "# Synthetic assigned AI feature $($syntheticDocument.Number)`n",
                [Text.UTF8Encoding]::new($false)
            )
        }
        foreach ($selectedDocument in $syntheticAiDocuments) {
            $syntheticAi = Invoke-TaskContextLoaderValidation -Profile 'AiFeature' -FeatureNumber $selectedDocument.Number -ChunkNumber 1 -LoaderPath $syntheticAiScript
            if ($syntheticAi.ExitCode -ne 0 -or
                $syntheticAi.Text -notmatch 'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0\.1\.md' -or
                $syntheticAi.Text -notmatch [regex]::Escape("docs/product/ai-core/$($selectedDocument.Name)")) {
                throw "Public-only validation did not preserve the synthetic AiFeature routing contract: feature=$($selectedDocument.Number)"
            }
            foreach ($unselectedDocument in @($syntheticAiDocuments | Where-Object Number -ne $selectedDocument.Number)) {
                if ($syntheticAi.Text -match [regex]::Escape("docs/product/ai-core/$($unselectedDocument.Name)")) {
                    throw "Public-only validation loaded an unselected synthetic AiFeature document: selected=$($selectedDocument.Number); unexpected=$($unselectedDocument.Number)"
                }
            }
        }
    }
    finally {
        if (Test-Path -LiteralPath $syntheticAiRoot) {
            $resolvedSyntheticAiRoot = [IO.Path]::GetFullPath($syntheticAiRoot)
            $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
            if (-not $resolvedSyntheticAiRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Refusing to remove public-only AiFeature fixture outside the temp root: $resolvedSyntheticAiRoot"
            }
            Remove-Item -LiteralPath $resolvedSyntheticAiRoot -Recurse -Force
        }
    }
}

$invalidAiContext = Invoke-TaskContextLoaderValidation -Profile 'AiFeature'
if ($invalidAiContext.ExitCode -eq 0 -or $invalidAiContext.Text -notmatch 'TASK CONTEXT BLOCKED:') {
    throw 'AiFeature context loading must fail closed without a valid FeatureNumber.'
}

$missingBackendRoot = Invoke-TaskContextLoaderValidation -Profile 'Database'
if ($missingBackendRoot.ExitCode -eq 0 -or
    $missingBackendRoot.Text -notmatch 'TASK CONTEXT BLOCKED:.*explicit absolute BackendSourceRoot') {
    throw 'Database context loading must fail closed without BackendSourceRoot.'
}
$missingMultiBackendRoot = Invoke-TaskContextLoaderValidation -Profile @('Runtime', 'Database', 'Git')
if ($missingMultiBackendRoot.ExitCode -eq 0 -or
    $missingMultiBackendRoot.Text -notmatch 'TASK CONTEXT BLOCKED:.*explicit absolute BackendSourceRoot') {
    throw 'A multi-Profile context including Database must fail closed without BackendSourceRoot.'
}

$missingBackendPolicyRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-missing-backend-policy-" + [Guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $missingBackendPolicyRoot -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $missingBackendPolicyRoot '.git'), "gitdir: validation-only`n", [Text.UTF8Encoding]::new($false))
    $missingBackendPolicy = Invoke-TaskContextLoaderValidation -Profile 'Database' -BackendRoot $missingBackendPolicyRoot
    if ($missingBackendPolicy.ExitCode -eq 0 -or
        $missingBackendPolicy.Text -notmatch 'TASK CONTEXT BLOCKED:.*Required Backend database policy is missing') {
        throw 'Database context loading must fail closed when the exact Backend policy is missing.'
    }
}
finally {
    if (Test-Path -LiteralPath $missingBackendPolicyRoot) {
        $resolvedMissingBackendPolicyRoot = [IO.Path]::GetFullPath($missingBackendPolicyRoot)
        $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedMissingBackendPolicyRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove missing Backend policy fixture outside the temp root: $resolvedMissingBackendPolicyRoot"
        }
        Remove-Item -LiteralPath $resolvedMissingBackendPolicyRoot -Recurse -Force
    }
}

$wrongProfileBackendRoot = Invoke-TaskContextLoaderValidation -Profile 'Git' -BackendRoot $BackendSourceRoot
if ($wrongProfileBackendRoot.ExitCode -eq 0 -or
    $wrongProfileBackendRoot.Text -notmatch 'TASK CONTEXT BLOCKED:.*accepted only when Profile includes Database') {
    throw 'BackendSourceRoot must not be accepted by non-Database Profiles.'
}

$invalidMultiProfile = Invoke-TaskContextLoaderValidation -Profile @('Git', 'Unknown')
if ($invalidMultiProfile.ExitCode -eq 0 -or
    $invalidMultiProfile.Text -notmatch "TASK CONTEXT BLOCKED:.*Invalid Profile 'Unknown'") {
    throw 'A multi-Profile context must fail closed when any requested Profile is invalid.'
}

$invalidChunk = Invoke-TaskContextLoaderValidation -Profile 'Product' -ChunkNumber 9999
if ($invalidChunk.ExitCode -eq 0 -or $invalidChunk.Text -notmatch 'TASK CONTEXT BLOCKED:.*ChunkNumber is out of range') {
    throw 'Task context loading must fail closed for a missing Chunk.'
}

$outOfOrderChunk = Invoke-TaskContextLoaderValidation -Profile 'Git' -ChunkNumber 2
if ($outOfOrderChunk.ExitCode -eq 0 -or $outOfOrderChunk.Text -notmatch 'TASK CONTEXT BLOCKED:.*requires the first Receipt bundleSha256') {
    throw 'Task context loading must fail closed for an out-of-order Chunk.'
}

$gitFirstForOrder = Invoke-TaskContextLoaderValidation -Profile 'Git' -ChunkNumber 1
$gitBundleForOrder = [regex]::Match($gitFirstForOrder.Text, '(?m)^bundleSha256=(?<hash>[0-9a-f]{64})$').Groups['hash'].Value
$wrongPreviousChunk = Invoke-TaskContextLoaderValidation -Profile 'Git' -ChunkNumber 2 -ExpectedBundleSha256 $gitBundleForOrder -PreviousChunkSha256 ('0' * 64)
if ($wrongPreviousChunk.ExitCode -eq 0 -or
    $wrongPreviousChunk.Text -notmatch 'TASK CONTEXT BLOCKED:.*PreviousChunkSha256 does not match ChunkNumber=1') {
    throw 'Task context loading must fail closed for an incorrect previous Chunk hash.'
}

$mutableContextRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-context-mutable-" + [Guid]::NewGuid().ToString('N'))
try {
    $mutableLoaderPath = Join-Path $mutableContextRoot 'scripts/load-task-context.ps1'
    $mutableTeamPath = Join-Path $mutableContextRoot 'docs/team'
    $mutableWorkspacePath = Join-Path $mutableContextRoot 'docs/workspace'
    New-Item -ItemType Directory -Path (Split-Path -Parent $mutableLoaderPath), $mutableTeamPath, $mutableWorkspacePath -Force | Out-Null
    Copy-Item -LiteralPath $taskContextLoaderPath -Destination $mutableLoaderPath
    Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md') -Destination $mutableTeamPath
    Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md') -Destination $mutableTeamPath
    Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md') -Destination $mutableWorkspacePath
    $mutableBootstrapPath = Join-Path $mutableWorkspacePath 'MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md'
    Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md') -Destination $mutableBootstrapPath

    $mutableFirst = Invoke-TaskContextLoaderValidation -Profile @('Master', 'Git') -ChunkNumber 1 -LoaderPath $mutableLoaderPath
    $mutableBundleHash = [regex]::Match($mutableFirst.Text, '(?m)^bundleSha256=(?<hash>[0-9a-f]{64})$').Groups['hash'].Value
    $mutableChunkHash = [regex]::Match($mutableFirst.Text, '(?m)^chunkSha256=(?<hash>[0-9a-f]{64})$').Groups['hash'].Value
    if ($mutableFirst.ExitCode -ne 0 -or -not $mutableBundleHash -or -not $mutableChunkHash) {
        throw 'Mutable context fixture could not produce its first Receipt.'
    }
    [IO.File]::AppendAllText($mutableBootstrapPath, "`nvalidation-only bundle mutation`n", [Text.UTF8Encoding]::new($false))
    $staleBundleChunk = Invoke-TaskContextLoaderValidation -Profile @('Master', 'Git') -ChunkNumber 2 -PreviousChunkSha256 $mutableChunkHash -ExpectedBundleSha256 $mutableBundleHash -LoaderPath $mutableLoaderPath
    if ($staleBundleChunk.ExitCode -eq 0 -or
        $staleBundleChunk.Text -notmatch 'TASK CONTEXT BLOCKED:.*ExpectedBundleSha256 does not match the current document bundle') {
        throw 'Multi-Profile context loading must fail closed when documents change between Chunks.'
    }
}
finally {
    if (Test-Path -LiteralPath $mutableContextRoot) {
        $resolvedMutableRoot = [IO.Path]::GetFullPath($mutableContextRoot)
        $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedMutableRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove mutable-context fixture outside the temp root: $resolvedMutableRoot"
        }
        Remove-Item -LiteralPath $resolvedMutableRoot -Recurse -Force
    }
}

$oversizedContextRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-context-oversized-" + [Guid]::NewGuid().ToString('N'))
try {
    $oversizedLoaderPath = Join-Path $oversizedContextRoot 'scripts/load-task-context.ps1'
    $oversizedProductPath = Join-Path $oversizedContextRoot 'docs/product'
    $oversizedTeamPath = Join-Path $oversizedContextRoot 'docs/team'
    New-Item -ItemType Directory -Path (Split-Path -Parent $oversizedLoaderPath), $oversizedProductPath, $oversizedTeamPath -Force | Out-Null
    Copy-Item -LiteralPath $taskContextLoaderPath -Destination $oversizedLoaderPath
    Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md') -Destination $oversizedProductPath
    $oversizedBuilder = [Text.StringBuilder]::new()
    foreach ($lineNumber in 1..10000) {
        [void]$oversizedBuilder.AppendLine("validation context line $lineNumber")
    }
    [IO.File]::WriteAllText(
        (Join-Path $oversizedTeamPath 'LLM_PROJECT_STATUS_SNAPSHOT.md'),
        $oversizedBuilder.ToString(),
        [Text.UTF8Encoding]::new($false)
    )
    $oversizedBundle = Invoke-TaskContextLoaderValidation -Profile 'Product' -ChunkNumber 1 -LoaderPath $oversizedLoaderPath
    if ($oversizedBundle.ExitCode -eq 0 -or
        $oversizedBundle.Text -notmatch 'TASK CONTEXT BLOCKED:.*Context bundle exceeds the safety limit') {
        throw 'Task context loading must fail closed when the complete bundle exceeds its safety limit.'
    }
}
finally {
    if (Test-Path -LiteralPath $oversizedContextRoot) {
        $resolvedOversizedRoot = [IO.Path]::GetFullPath($oversizedContextRoot)
        $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedOversizedRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove oversized-context fixture outside the temp root: $resolvedOversizedRoot"
        }
        Remove-Item -LiteralPath $resolvedOversizedRoot -Recurse -Force
    }
}

$missingContextRoot = Join-Path ([IO.Path]::GetTempPath()) ("axms-context-missing-" + [Guid]::NewGuid().ToString('N'))
try {
    $missingContextScripts = Join-Path $missingContextRoot 'scripts'
    $missingContextProduct = Join-Path $missingContextRoot 'docs/product'
    New-Item -ItemType Directory -Path $missingContextScripts, $missingContextProduct -Force | Out-Null
    Copy-Item -LiteralPath $taskContextLoaderPath -Destination (Join-Path $missingContextScripts 'load-task-context.ps1')
    Copy-Item -LiteralPath (Join-Path $masterRoot 'docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md') `
        -Destination (Join-Path $missingContextProduct 'AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md')

    $missingDocumentArguments = @('-NoProfile')
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
        $missingDocumentArguments += @('-ExecutionPolicy', 'Bypass')
    }
    $missingDocumentArguments += @('-File', (Join-Path $missingContextScripts 'load-task-context.ps1'), '-Profile', 'Product')
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $missingDocumentOutput = @(& $validationPowerShell @missingDocumentArguments 2>&1)
        $missingDocumentExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    $missingDocumentText = ($missingDocumentOutput | ForEach-Object { $_.ToString() }) -join "`n"
    if ($missingDocumentExit -eq 0 -or
        $missingDocumentText -notmatch 'TASK CONTEXT BLOCKED:.*Required context document is missing: docs/team/LLM_PROJECT_STATUS_SNAPSHOT\.md') {
        throw 'Task context loading must fail closed when a required document is missing.'
    }
}
finally {
    if (Test-Path -LiteralPath $missingContextRoot) {
        $resolvedMissingRoot = [IO.Path]::GetFullPath($missingContextRoot)
        $resolvedTempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedMissingRoot.StartsWith($resolvedTempRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove missing-context fixture outside the temp root: $resolvedMissingRoot"
        }
        Remove-Item -LiteralPath $resolvedMissingRoot -Recurse -Force
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
$masterAgentsPath = Join-Path $masterRoot 'AGENTS.md'
$masterAgents = Get-Content -Raw -Encoding UTF8 -LiteralPath $masterAgentsPath
$masterAgentsBytes = [Text.Encoding]::UTF8.GetByteCount($masterAgents)
$instructionRouting = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md')
$taskContextLoader = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'scripts/load-task-context.ps1')
if ($masterAgentsBytes -gt 10240 -or
    $masterAgents -notmatch 'Markdown 링크는 문서 본문을 자동으로 불러오지 않는다' -or
    $masterAgents -notmatch 'load-task-context\.ps1' -or
    $masterAgents -notmatch 'Profile을 입력 순서대로 한 번 호출' -or
    $masterAgents -notmatch '같은 정규화 경로는 첫 등장 한 번만 출력' -or
    $masterAgents -notmatch 'TASK CONTEXT BLOCKED' -or
    $masterAgents -notmatch 'chunk=1/N' -or
    $instructionRouting -notmatch 'ordinary Markdown link is routing text, not an import' -or
    $instructionRouting -notmatch 'TASK CONTEXT PASS' -or
    $instructionRouting -notmatch 'complete=true' -or
    $instructionRouting -notmatch 'ExpectedBundleSha256' -or
    $instructionRouting -notmatch '128 KiB' -or
    $instructionRouting -notmatch 'BackendSourceRoot' -or
    $instructionRouting -notmatch 'There is no parent-directory search or implicit canonical fallback' -or
    $instructionRouting -notmatch 'first occurrence of each normalized document path once' -or
    $instructionRouting -notmatch 'one-Profile call keeps the existing body and Receipt contract' -or
    $workspaceAgentTemplate -notmatch 'Profile 목록을.+입력 순서대로 한 번 전달' -or
    $taskContextLoader -notmatch '\[string\[\]\]\$Profile' -or
    $taskContextLoader -notmatch '\$allowedProfiles' -or
    $taskContextLoader -notmatch '\$seenDocuments' -or
    $taskContextLoader -notmatch 'BackendSourceRoot' -or
    $taskContextLoader -notmatch 'backend-source/docs/DATABASE_MIGRATION_POLICY_v0\.2\.md' -or
    $taskContextLoader -notmatch 'backendPolicySha256' -or
    $taskContextLoader -notmatch 'TASK CONTEXT RECEIPT v1' -or
    $taskContextLoader -notmatch 'PreviousChunkSha256' -or
    $taskContextLoader -notmatch 'ExpectedBundleSha256' -or
    $taskContextLoader -notmatch 'MaxBundleBytes' -or
    $taskContextLoader -notmatch 'TASK CONTEXT BLOCKED') {
    throw "Master task-context routing must be fail-closed and AGENTS.md must stay at or below 10240 bytes; bytes=$masterAgentsBytes"
}
$requiredMasterRules = [ordered]@{
    'five repository boundary' = 'Master, Frontend, Backend, Orchestrator, MCP Server'
    'Master common document owner' = 'Master 공통 기준과 공통 문서는 Min Seungjun'
    'assigned AI document owner' = 'AI 핵심 기능 담당자는 배정된 상세 문서만 수정'
    'simple scope' = 'Simple is best'
    'scope expansion approval' = '범위를 넘는.+승인'
    'Git as implementation truth' = 'Git이 구현 상태의 기준'
    'dirty and local-only preservation' = 'Dirty·Diverged·local-only'
    'destructive action ban' = '자동 Reset, Clean, Stash, Checkout, Rebase, 충돌 해결, DB 초기화, Flyway Repair/Clean, Volume 삭제를 금지'
    'secret protection' = 'Secret 값을 Prompt, Chat, 명령, Log, Commit, PR에 넣지 않는다'
    'privileged and external access approval' = 'Network, 로그인/MFA, 관리자 권한, 설치, 재부팅, Cloud/Prod/SSH는 명시적 승인 후 수행'
    'external action approval' = 'Notion 쓰기, Git Push, PR 생성·Merge, 배포는 각각 현재 요청에서 승인된 경우에만 수행'
    'fail closed context' = 'MASTER CONTEXT BLOCKED'
    'bounded task loader' = 'load-task-context\.ps1'
    'latest dev feature worktree' = '최신 `origin/dev` 기반 독립 Worktree'
    'pre-work gate' = 'start-feature-work\.ps1'
    'pre-PR gate' = 'prepare-dev-pr\.ps1'
    'AI work loads Git policy' = '(?m)^\| AI 2~6 .+\| `AiFeature`, `Git` \|'
    'Flyway self-reservation exception' = 'FLYWAY_RESERVATION_LEDGER\.md`의 자기 작업 예약 행'
    'shared contract conflict check' = '공개 계약, API, Schema, App Shell, Compose.+진행 중인 의존 작업'
    'dev-only PR' = 'Every agent-created pull request.+targets `dev`'
    'direct push ban' = '`dev`와 `main` 직접 Push'
    'unmerged work preservation' = '열린 PR, 미병합 Branch, 병합 후 추가 Commit, Dirty Worktree를 자동 삭제하지 않는다'
    'document change is not Git approval' = '문서 변경은 Commit, Push, PR, Merge를 자동으로 승인하지 않는다'
    'runtime mode selection' = '(?s)`full`.*`frontend-live`.*`isolated`'
    'unsafe partial runtime update ban' = 'DB·Flyway·Compose·Network·Secret 영향 또는 여러 Source 변경은 부분 갱신하지 않는다'
    'third integration run approval' = '세 번째 실행은 팀장 승인이 필요'
    'team-lead activation approval' = '전환 승인을 한 번 요청'
    'other owner document protection' = '다른 담당자의 문서는 수정하지 않는다'
    'functional claim evidence' = '기능 claim은 실행한 테스트, 코드로 확인한 경계, 미검증 항목을 구분'
    'final Git status' = '완료 직전에 Git 상태를 다시 확인'
}
foreach ($rule in $requiredMasterRules.GetEnumerator()) {
    if ($masterAgents -notmatch $rule.Value) {
        throw "Reduced Master AGENTS is missing a required invariant: $($rule.Key)"
    }
}
$fullSyncAliases = @('전체 Git 최신화', '워크스페이스 최신화')
foreach ($pullAlias in $fullSyncAliases) {
    if ($workspaceAgentTemplate -notmatch [regex]::Escape($pullAlias) -or
        $masterAgents -notmatch [regex]::Escape($pullAlias)) {
        throw "Master and Workspace AGENTS policies must route explicit full synchronization through sync-workspace.ps1: $pullAlias"
    }
}
if ($workspaceAgentTemplate -notmatch 'PostToolUse' -or
    $workspaceAgentTemplate -notmatch '적용 모드를 LLM이 판단' -or
    $masterAgents -notmatch '(?s)`full`.*`frontend-live`.*`isolated`') {
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
$releaseCloseout = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/product/ai-core/AI_CORE_RELEASE_CLOSEOUT.md')
if ($statusSnapshot -notmatch 'Snapshot-Version:' -or
    $statusSnapshot -notmatch 'MASTER UPDATE COMPLETE' -or
    $statusSnapshot -notmatch 'MASTER CONTEXT PASS') {
    throw 'LLM project-status snapshot must define the versioned team-lead handoff and local recognition handshake.'
}
function Test-SnapshotCloseoutConflict {
    param(
        [Parameter(Mandatory = $true)][string]$Snapshot,
        [Parameter(Mandatory = $true)][string]$Closeout
    )

    $snapshotHeader = ($Snapshot -split '(?m)^##\s', 2)[0]
    $closeoutHeader = ($Closeout -split '(?m)^##\s', 2)[0]
    $currentBasisMatch = [regex]::Match(
        $Snapshot,
        '(?ms)^## 현재 기준[^\r\n]*\r?\n(?<body>.*?)(?=^##\s|\z)'
    )
    $currentBasis = if ($currentBasisMatch.Success) { $currentBasisMatch.Groups['body'].Value } else { '' }

    $closeoutIsOpen = $closeoutHeader -match '(?m)^> 상태: `OPEN`\r?$'
    $snapshotClaimsCurrentDone =
        $snapshotHeader -match '(?m)^> Snapshot-Version:\s*`[^`\r\n]*closeout-done[^`\r\n]*`\s*\r?$' -or
        $currentBasis -match '(?m)^- 현재 상태:[^\r\n]*DONE'
    return $closeoutIsOpen -and $snapshotClaimsCurrentDone
}
$syntheticOpenCloseout = "# Closeout`r`n`r`n> 상태: ``OPEN```r`n"
$syntheticDoneCloseout = "# Closeout`r`n`r`n> 상태: ``DONE```r`n"
$syntheticCurrentDoneSnapshot = "# Snapshot`r`n`r`n> Snapshot-Version: ``v-test-closeout-done```r`n`r`n## 현재 기준`r`n`r`n- 현재 상태: DONE`r`n"
$syntheticPastDoneCitationSnapshot = "# Snapshot`r`n`r`n> Snapshot-Version: ``v-test-closeout-open```r`n`r`n## 현재 기준`r`n`r`n- 현재 상태: OPEN`r`n`r`n## 과거 기록`r`n`r`n> Snapshot-Version: ``v-old-closeout-done```r`n`r`n``29 / 29 DONE```r`n"
if (-not (Test-SnapshotCloseoutConflict -Snapshot $syntheticCurrentDoneSnapshot -Closeout $syntheticOpenCloseout) -or
    (Test-SnapshotCloseoutConflict -Snapshot $syntheticPastDoneCitationSnapshot -Closeout $syntheticOpenCloseout) -or
    (Test-SnapshotCloseoutConflict -Snapshot $syntheticCurrentDoneSnapshot -Closeout $syntheticDoneCloseout) -or
    (Test-SnapshotCloseoutConflict -Snapshot $statusSnapshot -Closeout $releaseCloseout)) {
    throw 'Snapshot and Closeout must not claim current DONE while Closeout remains OPEN.'
}
$docsIndex = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/README.md')
$rootReadme = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'README.md')
$setupPrompt = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md')
$workPrompt = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/onboarding/TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md')
$techStack = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/architecture/TECH_STACK_AND_RATIONALE_v0.1.md')
$futureConsiderations = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md')
if ($docsIndex -notmatch 'AI_CORE_RELEASE_CLOSEOUT\.md' -or
    $docsIndex -notmatch 'validate-master-scaffold\.ps1 -PublicOnly -BackendSourceRoot' -or
    $rootReadme -notmatch 'Profile Runtime,Database,Git' -or
    $setupPrompt -notmatch 'load-task-context\.ps1' -or
    $setupPrompt -notmatch 'Profile Product,Git,Runtime,Master' -or
    $setupPrompt -notmatch 'Database -BackendSourceRoot' -or
    $workPrompt -notmatch 'Runtime.+Database.+Git' -or
    $workPrompt -notmatch 'BackendSourceRoot' -or
    $techStack -notmatch 'Windows PowerShell 5\.1·PowerShell 7' -or
    $techStack -notmatch '## MCP Server' -or
    $futureConsiderations -notmatch '현재 완료 상태가 아니다') {
    throw 'Public routing links and current-state labels must remain reachable without loading personal AI documents.'
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
    $teamLeadProtocol -notmatch 'Codex·Orca 호스트 어댑터' -or
    $teamLeadProtocol -notmatch 'orca orchestration worker-start' -or
    $teamLeadProtocol -notmatch 'worker-start --model <model> --effort <thinking>' -or
    $teamLeadProtocol -notmatch 'launch\.requested' -or
    $teamLeadProtocol -notmatch 'launch\.effective' -or
    $teamLeadProtocol -notmatch '`--terminal`과 `--model`·`--effort`' -or
    $teamLeadProtocol -notmatch 'start-feature-work\.ps1' -or
    $teamLeadProtocol -notmatch 'worker_done' -or
    $teamLeadProtocol -notmatch 'worker-release' -or
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
    $teamLeadSkill -notmatch 'orca orchestration worker-start --model <model> --effort <thinking>' -or
    $teamLeadSkill -notmatch 'launch\.requested' -or
    $teamLeadSkill -notmatch 'launch\.effective' -or
    $teamLeadSkill -notmatch 'cannot combine `--terminal` reuse with `--model` or `--effort`' -or
    $teamLeadSkill -notmatch 'start-feature-work\.ps1' -or
    $teamLeadSkill -notmatch 'check --wait' -or
    $teamLeadSkill -notmatch 'worker_done' -or
    $teamLeadSkill -notmatch 'worker-release' -or
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
Write-Host 'PASS: bounded fail-closed task-context Profiles with ordered Chunk bodies and bundle integrity'
Write-Host "PASS: $($requiredProfileRules.Count) owner-scoped Profile rules reject deletion, weakening, and owner omission"
if ($PublicOnly) {
    Write-Host 'PASS: public-only validation uses synthetic AI 2~6 documents and does not read assigned personal document bodies'
}
Write-Host 'PASS: enforced pre-work Pull and pre-PR fetch gates with read-only pre-push receipt validation'
Write-Host 'PASS: managed local-LLM policy, dev-only PR policy, and Claude routing'
Write-Host "PASS: reduced Master AGENTS preserves $($requiredMasterRules.Count) inline invariants within 10240 bytes"
Write-Host 'PASS: five canonical repository remotes'
Write-Host 'PASS: all PowerShell scripts parsed'
Write-Host 'PASS: no forbidden destructive command patterns'
Write-Host 'PASS: no source repository copy inside Master'
