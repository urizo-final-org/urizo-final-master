[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryPath,

    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,

    [string]$RemoteName,

    [string]$RemoteUrl
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$AllowFailure
    )

    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -c "safe.directory=$Path" -C $Path @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -ne 0 -and -not $AllowFailure) {
        $detail = ($output | ForEach-Object { $_.ToString() }) -join ' '
        throw "Git command failed in ${Path}: git $($Arguments -join ' '); $detail"
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Output = @($output | ForEach-Object { $_.ToString() }) }
}

function Get-GitValue {
    param([string]$Path, [string[]]$Arguments)
    return ((Invoke-GitCapture -Path $Path -Arguments $Arguments).Output -join '').Trim()
}

function Get-ReceiptName {
    param([Parameter(Mandatory = $true)][string]$Branch)
    $bytes = [Text.Encoding]::UTF8.GetBytes($Branch)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
    return "$hash.json"
}

try {
    $WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
    $RepositoryPath = (Resolve-Path -LiteralPath $RepositoryPath).Path
    $repositoryRoot = [IO.Path]::GetFullPath((Get-GitValue -Path $RepositoryPath -Arguments @('rev-parse', '--show-toplevel')))
    $configuredWorkspace = Get-GitValue -Path $repositoryRoot -Arguments @('config', '--get', 'axms.workspaceRoot')
    if (-not $configuredWorkspace -or
        [IO.Path]::GetFullPath($configuredWorkspace) -ne [IO.Path]::GetFullPath($WorkspaceRoot)) {
        throw 'Repository is not bound to this AXMS workspace. Re-run Master bootstrap with -SyncLlmHooks.'
    }
    $configuredOrigin = Get-GitValue -Path $repositoryRoot -Arguments @('remote', 'get-url', '--push', 'origin')
    if ($RemoteName -ne 'origin' -or ($RemoteUrl -and $RemoteUrl -ne $configuredOrigin)) {
        throw "Feature pushes must use the configured origin remote; remote=$RemoteName; url=$RemoteUrl"
    }

    $pushLines = @([Console]::In.ReadToEnd() -split "`r?`n" | Where-Object { $_.Trim() })
    if ($pushLines.Count -eq 0) {
        throw 'Git supplied no push ref updates, so the Pull gate could not validate the push.'
    }

    $commonGitDir = Get-GitValue -Path $repositoryRoot -Arguments @('rev-parse', '--git-common-dir')
    if (-not [IO.Path]::IsPathRooted($commonGitDir)) {
        $commonGitDir = Join-Path $repositoryRoot $commonGitDir
    }
    $receiptDirectory = Join-Path ([IO.Path]::GetFullPath($commonGitDir)) 'axms-pull-gates'
    $originDev = Get-GitValue -Path $repositoryRoot -Arguments @('rev-parse', 'refs/remotes/origin/dev')
    $zeroSha = '0' * 40

    foreach ($line in $pushLines) {
        $parts = @($line.Trim() -split '\s+')
        if ($parts.Count -ne 4) {
            throw "Unexpected pre-push input: $line"
        }
        $localRef, $localSha, $remoteRef, $remoteSha = $parts
        if ($remoteRef -in @('refs/heads/dev', 'refs/heads/main')) {
            throw "Direct push to $remoteRef is blocked. Open a PR targeting dev."
        }
        if ($localSha -eq $zeroSha) {
            if ($remoteRef -match '^refs/heads/feature/') {
                continue
            }
            throw "Only feature/* branch deletion is allowed by the AXMS workspace Hook: $remoteRef"
        }
        if ($remoteRef -notmatch '^refs/heads/(?<branch>feature/.+)$') {
            if ($remoteRef -match '^refs/tags/') {
                continue
            }
            throw "Only feature/* branch pushes are allowed by the AXMS workspace Hook: $remoteRef"
        }

        $branch = $Matches['branch']
        $receiptPath = Join-Path $receiptDirectory (Get-ReceiptName -Branch $branch)
        if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) {
            throw "Missing pre-PR Pull receipt for $branch. Run urizo-final-master/scripts/prepare-dev-pr.ps1 -ApproveNetwork from the feature Worktree."
        }
        try {
            $receipt = Get-Content -Raw -Encoding UTF8 -LiteralPath $receiptPath | ConvertFrom-Json
        }
        catch {
            throw "Invalid pre-PR Pull receipt. Rerun the Pull gate: $receiptPath"
        }

        if ([int]$receipt.schemaVersion -ne 1 -or
            [string]$receipt.branch -ne $branch -or
            [string]$receipt.head -ne $localSha -or
            [string]$receipt.originDev -ne $originDev -or
            [IO.Path]::GetFullPath([string]$receipt.repositoryRoot) -ne $repositoryRoot) {
            throw "Stale pre-PR Pull receipt for $branch. HEAD or origin/dev changed; rerun prepare-dev-pr.ps1 -ApproveNetwork."
        }
        $ancestor = Invoke-GitCapture -Path $repositoryRoot -Arguments @('merge-base', '--is-ancestor', 'refs/remotes/origin/dev', $localSha) -AllowFailure
        if ($ancestor.ExitCode -ne 0) {
            throw "Push HEAD does not contain current origin/dev for $branch. Integrate dev and rerun the Pull gate."
        }
    }

    Write-Host "PRE-PUSH PULL GATE PASS: remote=$RemoteName; url=$RemoteUrl"
    exit 0
}
catch {
    Write-Error "PRE-PUSH PULL GATE BLOCKED: $($_.Exception.Message)"
    exit 1
}
