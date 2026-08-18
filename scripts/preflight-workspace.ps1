[CmdletBinding()]
param(
    [string]$WorkspaceRoot,

    [switch]$SkipRuntime,

    [switch]$AsJson,

    [switch]$FailOnWarning
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
if (-not $WorkspaceRoot) {
    $WorkspaceRoot = Split-Path -Parent $masterRoot
}
if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
    throw "Workspace root does not exist: $WorkspaceRoot"
}
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path

$manifestPath = Join-Path $masterRoot 'repository-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw 'repository-manifest.json is missing.'
}
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

function Get-HostPlatform {
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        return 'Windows'
    }
    if ($IsWindows) { return 'Windows' }
    if ($IsMacOS) { return 'macOS' }
    if ($IsLinux) { return 'Linux' }
    return 'Unknown'
}

$hostPlatform = Get-HostPlatform

function Add-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Area,
        [Parameter(Mandatory = $true)][string]$Item,
        [Parameter(Mandatory = $true)][ValidateSet('PASS', 'WARN', 'BLOCKED')][string]$Status,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:results.Add([pscustomobject]@{
        Area = $Area
        Item = $Item
        Status = $Status
        Detail = $Detail
    })
}

function Invoke-GitReadOnly {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $previousOptionalLocks = $env:GIT_OPTIONAL_LOCKS
    $previousErrorAction = $ErrorActionPreference
    try {
        $env:GIT_OPTIONAL_LOCKS = '0'
        $ErrorActionPreference = 'Continue'
        $output = & git -c "safe.directory=$RepositoryPath" -C $RepositoryPath @Arguments 2>$null
        $exitCode = $LASTEXITCODE
    }
    finally {
        $env:GIT_OPTIONAL_LOCKS = $previousOptionalLocks
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        throw "Git read failed in ${RepositoryPath}: git $($Arguments -join ' ')"
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output) }
}

function Find-DockerCli {
    $candidates = [System.Collections.Generic.List[string]]::new()
    $command = Get-Command docker -ErrorAction SilentlyContinue
    if ($command) {
        $candidates.Add($command.Source)
    }
    if ($hostPlatform -eq 'Windows' -and $env:LOCALAPPDATA) {
        $candidates.Add((Join-Path $env:LOCALAPPDATA 'Programs/DockerDesktop/resources/bin/docker.exe'))
    }
    if ($hostPlatform -eq 'Windows') {
        $candidates.Add('C:\Program Files\Docker\Docker\resources\bin\docker.exe')
    }
    return $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

function Invoke-DockerReadOnly {
    param(
        [Parameter(Mandatory = $true)][string]$DockerPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $DockerPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output) }
}

Add-Result -Area 'Host' -Item 'Operating system' -Status 'PASS' -Detail $hostPlatform
$powerShellVersion = $PSVersionTable.PSVersion.ToString()
$minimumPowerShellOk = if ($hostPlatform -eq 'Windows') {
    $PSVersionTable.PSVersion.Major -ge 5
}
else {
    $PSVersionTable.PSVersion.Major -ge 7
}
if ($minimumPowerShellOk) {
    Add-Result -Area 'Host' -Item 'PowerShell' -Status 'PASS' -Detail "version=$powerShellVersion"
}
else {
    Add-Result -Area 'Host' -Item 'PowerShell' -Status 'BLOCKED' -Detail "version=$powerShellVersion; macOS/Linux require PowerShell 7"
}

if (Test-Path -LiteralPath (Join-Path $WorkspaceRoot '.git')) {
    Add-Result -Area 'Workspace' -Item '.git boundary' -Status 'BLOCKED' -Detail 'The shared parent workspace is a Git repository.'
}
else {
    Add-Result -Area 'Workspace' -Item '.git boundary' -Status 'PASS' -Detail 'The shared parent workspace has no .git.'
}

foreach ($repository in $manifest.repositories) {
    $repositoryPath = Join-Path $WorkspaceRoot $repository.relativePath
    if (-not (Test-Path -LiteralPath $repositoryPath -PathType Container)) {
        Add-Result -Area 'Git' -Item $repository.name -Status 'BLOCKED' -Detail "Missing expected sibling: $repositoryPath"
        continue
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repositoryPath '.git'))) {
        Add-Result -Area 'Git' -Item $repository.name -Status 'BLOCKED' -Detail 'Folder exists but is not the expected Git checkout.'
        continue
    }

    try {
        $remote = (Invoke-GitReadOnly -RepositoryPath $repositoryPath -Arguments @('remote', 'get-url', 'origin')).Output -join ''
        $branch = (Invoke-GitReadOnly -RepositoryPath $repositoryPath -Arguments @('branch', '--show-current')).Output -join ''
        $headResult = Invoke-GitReadOnly -RepositoryPath $repositoryPath -Arguments @('rev-parse', '--verify', 'HEAD') -AllowFailure
        $head = if ($headResult.ExitCode -eq 0) { $headResult.Output -join '' } else { 'UNBORN' }
        $statusLines = (Invoke-GitReadOnly -RepositoryPath $repositoryPath -Arguments @('status', '--porcelain=v1')).Output
        $changedCount = @($statusLines | Where-Object { $_ }).Count
    }
    catch {
        Add-Result -Area 'Git' -Item $repository.name -Status 'BLOCKED' -Detail $_.Exception.Message
        continue
    }

    if ($remote -ne $repository.remote) {
        Add-Result -Area 'Git' -Item $repository.name -Status 'BLOCKED' -Detail "Origin mismatch: $remote"
        continue
    }

    $state = "origin=$remote; branch=$branch; head=$head; changed=$changedCount"
    if ($head -eq 'UNBORN' -or $changedCount -gt 0) {
        Add-Result -Area 'Git' -Item $repository.name -Status 'WARN' -Detail $state
    }
    else {
        Add-Result -Area 'Git' -Item $repository.name -Status 'PASS' -Detail $state
    }
}

if (-not $SkipRuntime) {
    $docker = Find-DockerCli
    if (-not $docker) {
        Add-Result -Area 'Runtime' -Item 'Docker CLI' -Status 'BLOCKED' -Detail 'Docker Desktop CLI was not found in PATH or approved installation paths.'
    }
    else {
        $versionResult = Invoke-DockerReadOnly -DockerPath $docker -Arguments @('version', '--format', '{{.Server.Version}}')
        if ($versionResult.ExitCode -ne 0) {
            Add-Result -Area 'Runtime' -Item 'Docker Engine' -Status 'BLOCKED' -Detail 'Docker CLI exists but the engine is unavailable.'
        }
        else {
            $serverVersion = ($versionResult.Output | Select-Object -Last 1) -join ''
            Add-Result -Area 'Runtime' -Item 'Docker Engine' -Status 'PASS' -Detail "server=$serverVersion"
            $backendPath = Join-Path $WorkspaceRoot 'urizo-final-backend'
            $composeFile = Join-Path $backendPath 'compose.dev.yaml'
            if (-not (Test-Path -LiteralPath $composeFile -PathType Leaf)) {
                Add-Result -Area 'Runtime' -Item 'Compose' -Status 'BLOCKED' -Detail 'Backend compose.dev.yaml is missing.'
            }
            else {
                $composeResult = Invoke-DockerReadOnly -DockerPath $docker -Arguments @('compose', '-f', $composeFile, '--profile', 'full', 'ps', '-a')
                if ($composeResult.ExitCode -ne 0) {
                    Add-Result -Area 'Runtime' -Item 'Compose' -Status 'WARN' -Detail 'Compose state could not be read.'
                }
                else {
                    $serviceLineCount = @($composeResult.Output | Where-Object { $_ -match 'axms-' }).Count
                    Add-Result -Area 'Runtime' -Item 'Compose' -Status 'PASS' -Detail "state readable; matching rows=$serviceLineCount"
                }
            }

            foreach ($endpoint in @('/', '/nginx-health', '/api/health', '/api/readiness')) {
                $uri = "http://127.0.0.1:18080$endpoint"
                try {
                    $response = Invoke-WebRequest -UseBasicParsing -Uri $uri -TimeoutSec 5
                    $statusCode = [int]$response.StatusCode
                }
                catch {
                    $statusCode = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
                }
                if ($statusCode -eq 200) {
                    Add-Result -Area 'HTTP' -Item $endpoint -Status 'PASS' -Detail 'HTTP 200'
                }
                else {
                    Add-Result -Area 'HTTP' -Item $endpoint -Status 'WARN' -Detail "HTTP $statusCode"
                }
            }
        }
    }
}

$summary = [pscustomobject]@{
    observedAt = [DateTimeOffset]::Now.ToString('o')
    workspaceRoot = $WorkspaceRoot
    counts = [pscustomobject]@{
        pass = @($results | Where-Object Status -eq 'PASS').Count
        warn = @($results | Where-Object Status -eq 'WARN').Count
        blocked = @($results | Where-Object Status -eq 'BLOCKED').Count
    }
    results = $results
}

if ($AsJson) {
    $summary | ConvertTo-Json -Depth 6
}
else {
    $results | Format-Table -AutoSize -Wrap
    "PASS=$($summary.counts.pass) WARN=$($summary.counts.warn) BLOCKED=$($summary.counts.blocked)"
}

if ($summary.counts.blocked -gt 0) {
    exit 2
}
if ($FailOnWarning -and $summary.counts.warn -gt 0) {
    exit 1
}
