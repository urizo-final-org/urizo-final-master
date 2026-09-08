[CmdletBinding()]
param(
    [string]$BaselineRef = 'origin/dev',

    [string]$WorkspaceRoot,

    [ValidateRange(1, 90)]
    [int]$MinimumReductionPercent = 40,

    [ValidateRange(1024, 20000)]
    [int]$MinimumFullHeadroomBytes = 4096
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -c "safe.directory=$RepositoryPath" -C $RepositoryPath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -ne 0) {
        $detail = ($output | ForEach-Object { $_.ToString() }) -join ' '
        throw "Git command failed: repository=$RepositoryPath; git $($Arguments -join ' '); $detail"
    }
    return ($output | ForEach-Object { $_.ToString() }) -join "`n"
}

function Find-WorkspaceRoot {
    param([Parameter(Mandatory = $true)][string]$StartPath)

    $cursor = [IO.Path]::GetFullPath($StartPath)
    while ($cursor) {
        if ((Test-Path -LiteralPath (Join-Path $cursor 'AGENTS.md') -PathType Leaf) -and
            (Test-Path -LiteralPath (Join-Path $cursor 'urizo-final-master') -PathType Container) -and
            (Test-Path -LiteralPath (Join-Path $cursor 'urizo-final-backend') -PathType Container)) {
            return $cursor
        }
        $parent = Split-Path -Parent $cursor
        if (-not $parent -or $parent -eq $cursor) {
            break
        }
        $cursor = $parent
    }
    return $null
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $encoding = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText($Path, $Content, $encoding)
}

function ConvertTo-PlatformWorkingTreeText {
    param([Parameter(Mandatory = $true)][string]$Content)

    $normalized = $Content.Replace("`r`n", "`n").Replace("`r", "`n")
    return $normalized.Replace("`n", [Environment]::NewLine)
}

function Get-TextSha256 {
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

function Invoke-FullContextMeasurement {
    param(
        [Parameter(Mandatory = $true)][string]$FixtureRoot,
        [Parameter(Mandatory = $true)][string]$SourceRelativePath,
        [Parameter(Mandatory = $true)][string]$HookPath
    )

    $sourcePath = Join-Path $FixtureRoot $SourceRelativePath
    Push-Location $sourcePath
    try {
        $output = @(& $HookPath -WorkspaceRoot $FixtureRoot -Mode Full -Reason Lifecycle -MaxContextBytes 1048576) -join "`n"
    }
    finally {
        Pop-Location
    }
    return [Text.Encoding]::UTF8.GetByteCount($output)
}

function Initialize-FixtureRepository {
    param([Parameter(Mandatory = $true)][string]$RepositoryPath)

    Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('init', '--initial-branch=dev') | Out-Null
    Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('config', 'user.name', 'AXMS Context Fixture') | Out-Null
    Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('config', 'user.email', 'context-fixture@example.invalid') | Out-Null
    Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('add', 'AGENTS.md') | Out-Null
    Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('commit', '-m', 'fixture context') | Out-Null
    Invoke-GitCapture -RepositoryPath $RepositoryPath -Arguments @('remote', 'add', 'origin', 'https://example.invalid/fixture-source.git') | Out-Null
}

$masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Find-WorkspaceRoot -StartPath $masterRoot
}
if (-not $WorkspaceRoot -or -not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
    throw 'WorkspaceRoot could not be located. Pass the non-Git AX Module Studio parent with -WorkspaceRoot.'
}
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path

$baselineCommit = Invoke-GitCapture -RepositoryPath $masterRoot -Arguments @('rev-parse', "${BaselineRef}^{commit}")
$currentHeadCommit = Invoke-GitCapture -RepositoryPath $masterRoot -Arguments @('rev-parse', 'HEAD^{commit}')
$baselineMaster = ConvertTo-PlatformWorkingTreeText -Content ((Invoke-GitCapture -RepositoryPath $masterRoot -Arguments @('show', "${baselineCommit}:AGENTS.md")) + "`n")
$baselineHook = ConvertTo-PlatformWorkingTreeText -Content ((Invoke-GitCapture -RepositoryPath $masterRoot -Arguments @('show', "${baselineCommit}:templates/workspace/codex/hooks/session-start.ps1")) + "`n")
$currentMaster = ConvertTo-PlatformWorkingTreeText -Content ([IO.File]::ReadAllText((Join-Path $masterRoot 'AGENTS.md'), [Text.Encoding]::UTF8))
$currentHook = ConvertTo-PlatformWorkingTreeText -Content ([IO.File]::ReadAllText((Join-Path $masterRoot 'templates/workspace/codex/hooks/session-start.ps1'), [Text.Encoding]::UTF8))
$baselineMasterBytes = [Text.Encoding]::UTF8.GetByteCount($baselineMaster)
$currentMasterBytes = [Text.Encoding]::UTF8.GetByteCount($currentMaster)
$reductionPercent = [Math]::Round((1 - ($currentMasterBytes / [double]$baselineMasterBytes)) * 100, 1)

if ($currentMasterBytes -ge $baselineMasterBytes -or $reductionPercent -lt $MinimumReductionPercent) {
    throw "Master AGENTS reduction is insufficient: before=$baselineMasterBytes; after=$currentMasterBytes; reduction=${reductionPercent}%; required=${MinimumReductionPercent}%."
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $masterRoot 'repository-manifest.json') | ConvertFrom-Json
$sourceRepositories = @($manifest.repositories | Where-Object { $_.name -ne 'urizo-final-master' })
$fixtureBase = Join-Path ([IO.Path]::GetTempPath()) ("axms-context-compare-" + [Guid]::NewGuid().ToString('N'))
$beforeRoot = Join-Path $fixtureBase 'before'
$afterRoot = Join-Path $fixtureBase 'after'
$beforeHookPath = Join-Path $fixtureBase 'session-start-before.ps1'
$afterHookPath = Join-Path $fixtureBase 'session-start-after.ps1'
$results = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($root in @($beforeRoot, $afterRoot)) {
        New-Item -ItemType Directory -Path (Join-Path $root 'urizo-final-master') -Force | Out-Null
        Write-Utf8NoBom -Path (Join-Path $root 'AGENTS.md') `
            -Content ([IO.File]::ReadAllText((Join-Path $WorkspaceRoot 'AGENTS.md'), [Text.Encoding]::UTF8))
    }
    Write-Utf8NoBom -Path (Join-Path $beforeRoot 'urizo-final-master/AGENTS.md') -Content $baselineMaster
    Write-Utf8NoBom -Path (Join-Path $afterRoot 'urizo-final-master/AGENTS.md') -Content $currentMaster
    Write-Utf8NoBom -Path $beforeHookPath -Content $baselineHook
    Write-Utf8NoBom -Path $afterHookPath -Content $currentHook

    foreach ($repository in $sourceRepositories) {
        $sourceCanonical = [IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $repository.relativePath))
        if (-not (Test-Path -LiteralPath (Join-Path $sourceCanonical '.git'))) {
            throw "Source repository is unavailable for comparison: $sourceCanonical"
        }
        $sourceDevCommit = Invoke-GitCapture -RepositoryPath $sourceCanonical -Arguments @('rev-parse', 'origin/dev^{commit}')
        $sourceAgents = ConvertTo-PlatformWorkingTreeText -Content ((Invoke-GitCapture -RepositoryPath $sourceCanonical -Arguments @('show', "${sourceDevCommit}:AGENTS.md")) + "`n")
        foreach ($root in @($beforeRoot, $afterRoot)) {
            $fixtureSource = Join-Path $root $repository.relativePath
            New-Item -ItemType Directory -Path $fixtureSource -Force | Out-Null
            Write-Utf8NoBom -Path (Join-Path $fixtureSource 'AGENTS.md') -Content $sourceAgents
            Initialize-FixtureRepository -RepositoryPath $fixtureSource
        }

        $beforeBytes = Invoke-FullContextMeasurement -FixtureRoot $beforeRoot -SourceRelativePath $repository.relativePath -HookPath $beforeHookPath
        $afterBytes = Invoke-FullContextMeasurement -FixtureRoot $afterRoot -SourceRelativePath $repository.relativePath -HookPath $afterHookPath
        $headroom = 24576 - $afterBytes
        if ($afterBytes -ge $beforeBytes) {
            throw "Full Hook payload did not improve: source=$($repository.name); before=$beforeBytes; after=$afterBytes."
        }
        if ($afterBytes -gt 24576 -or $headroom -lt $MinimumFullHeadroomBytes) {
            throw "Full Hook payload lacks required headroom: source=$($repository.name); after=$afterBytes; headroom=$headroom; required=$MinimumFullHeadroomBytes."
        }

        $results.Add([pscustomobject]@{
            Source = $repository.name
            SourceDevCommit = $sourceDevCommit
            BeforeBytes = $beforeBytes
            BeforeStatus = if ($beforeBytes -le 24576) { 'PASS' } else { 'BLOCKED' }
            AfterBytes = $afterBytes
            AfterStatus = 'PASS'
            HeadroomBytes = $headroom
            DeltaBytes = $afterBytes - $beforeBytes
        })
    }
}
finally {
    if (Test-Path -LiteralPath $fixtureBase) {
        $resolvedFixture = [IO.Path]::GetFullPath($fixtureBase)
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
        if (-not $resolvedFixture.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove comparison fixture outside the temp root: $resolvedFixture"
        }
        foreach ($fixtureFile in [IO.Directory]::EnumerateFiles($resolvedFixture, '*', [IO.SearchOption]::AllDirectories)) {
            [IO.File]::SetAttributes($fixtureFile, [IO.FileAttributes]::Normal)
        }
        [IO.Directory]::Delete($resolvedFixture, $true)
    }
}

Write-Host 'CONTEXT PAYLOAD BEFORE/AFTER PASS'
Write-Host "baseline.requestedRef=$BaselineRef"
Write-Host "baseline.commit=$baselineCommit"
Write-Host "current.headCommit=$currentHeadCommit"
$comparisonEol = if ([Environment]::NewLine.Length -eq 2) { 'crlf' } else { 'lf' }
Write-Host "comparisonEol=$comparisonEol"
Write-Host "master.beforeBytes=$baselineMasterBytes"
Write-Host "master.afterBytes=$currentMasterBytes"
Write-Host "master.reductionPercent=$reductionPercent"
Write-Host "master.beforeSha256=$(Get-TextSha256 -Text $baselineMaster)"
Write-Host "master.afterSha256=$(Get-TextSha256 -Text $currentMaster)"
Write-Host "hook.beforeSha256=$(Get-TextSha256 -Text $baselineHook)"
Write-Host "hook.afterSha256=$(Get-TextSha256 -Text $currentHook)"
foreach ($result in $results) {
    Write-Host ("source={0}; sourceDevCommit={1}; beforeBytes={2}; beforeStatus={3}; afterBytes={4}; afterStatus={5}; headroomBytes={6}; deltaBytes={7}" -f `
        $result.Source, $result.SourceDevCommit, $result.BeforeBytes, $result.BeforeStatus, $result.AfterBytes, $result.AfterStatus, $result.HeadroomBytes, $result.DeltaBytes)
}
