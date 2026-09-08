[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Profile,

    [int]$FeatureNumber = 0,

    [string]$BackendSourceRoot,

    [ValidateRange(1, 10000)]
    [int]$ChunkNumber = 1,

    [string]$PreviousChunkSha256,

    [string]$ExpectedBundleSha256,

    [ValidateRange(8192, 24576)]
    [int]$MaxContextBytes = 16384,

    [ValidateRange(32768, 1048576)]
    [int]$MaxBundleBytes = 131072
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-Utf8ByteCount {
    param([Parameter(Mandatory = $true)][string]$Text)
    return [Text.Encoding]::UTF8.GetByteCount($Text)
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

try {
    $masterRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
    $allowedProfiles = @('Product', 'Git', 'Runtime', 'Database', 'AiFeature', 'TeamLead', 'Master')
    $selectedProfiles = [System.Collections.Generic.List[string]]::new()
    $seenProfiles = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($profileArgument in @($Profile)) {
        foreach ($requestedProfile in @($profileArgument -split ',')) {
            $requestedProfile = $requestedProfile.Trim()
            $canonicalMatches = @($allowedProfiles | Where-Object { $_ -ieq $requestedProfile })
            if ($canonicalMatches.Count -eq 0) {
                throw "Invalid Profile '$requestedProfile'. Allowed values: $($allowedProfiles -join ', ')."
            }
            $canonicalProfile = $canonicalMatches[0]
            if ($seenProfiles.Add($canonicalProfile)) {
                $selectedProfiles.Add($canonicalProfile)
            }
        }
    }
    if ($selectedProfiles.Count -eq 0) {
        throw 'At least one Profile is required.'
    }
    $profileLabel = $selectedProfiles -join ','
    $includesDatabase = $selectedProfiles -contains 'Database'

    if (-not $includesDatabase -and $BackendSourceRoot) {
        throw 'BackendSourceRoot is accepted only when Profile includes Database.'
    }

    $backendPolicyDocument = $null
    if ($includesDatabase) {
        if (-not $BackendSourceRoot) {
            throw 'Database Profile requires an explicit absolute BackendSourceRoot.'
        }
        if (-not [IO.Path]::IsPathRooted($BackendSourceRoot)) {
            throw 'BackendSourceRoot must be an absolute path.'
        }
        if (-not (Test-Path -LiteralPath $BackendSourceRoot -PathType Container)) {
            throw "BackendSourceRoot does not exist: $BackendSourceRoot"
        }

        $BackendSourceRoot = (Resolve-Path -LiteralPath $BackendSourceRoot).Path
        if (-not (Test-Path -LiteralPath (Join-Path $BackendSourceRoot '.git'))) {
            throw "BackendSourceRoot is not a Git checkout or Worktree: $BackendSourceRoot"
        }
        $backendPolicyPath = Join-Path $BackendSourceRoot 'docs/DATABASE_MIGRATION_POLICY_v0.2.md'
        if (-not (Test-Path -LiteralPath $backendPolicyPath -PathType Leaf)) {
            throw 'Required Backend database policy is missing: docs/DATABASE_MIGRATION_POLICY_v0.2.md'
        }
        $backendPolicyContent = [IO.File]::ReadAllText($backendPolicyPath, [Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($backendPolicyContent)) {
            throw 'Required Backend database policy is empty: docs/DATABASE_MIGRATION_POLICY_v0.2.md'
        }
        $backendPolicyDocument = [pscustomobject]@{
            RelativePath = 'backend-source/docs/DATABASE_MIGRATION_POLICY_v0.2.md'
            Bytes = Get-Utf8ByteCount -Text $backendPolicyContent
            Sha256 = Get-TextSha256 -Text $backendPolicyContent
            Content = $backendPolicyContent
        }
    }

    $backendPolicyRelativePath = 'backend-source/docs/DATABASE_MIGRATION_POLICY_v0.2.md'
    $profileDocuments = [System.Collections.Generic.List[string]]::new()
    $seenDocuments = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($profileName in $selectedProfiles) {
        $profileDocumentPaths = switch ($profileName) {
            'Product' {
                @(
                    'docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md'
                    'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md'
                )
            }
            'Git' {
                @(
                    'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md'
                    'docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md'
                )
            }
            'Runtime' {
                @(
                    'docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md'
                    'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'
                )
            }
            'Database' {
                @(
                    'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md'
                    'docs/team/FLYWAY_RESERVATION_LEDGER.md'
                    'docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md'
                    $backendPolicyRelativePath
                )
            }
            'AiFeature' {
                if ($FeatureNumber -notin @(2, 3, 4, 5, 6)) {
                    throw 'AiFeature requires -FeatureNumber 2, 3, 4, 5, or 6.'
                }
                $featureDocument = @{
                    2 = 'docs/product/ai-core/02_DOMAIN_RAG_REPLACEMENT.md'
                    3 = 'docs/product/ai-core/03_RAG_QUALITY.md'
                    4 = 'docs/product/ai-core/04_LIMITED_LLM_DEVOPS.md'
                    5 = 'docs/product/ai-core/05_NATURAL_LANGUAGE_CMS.md'
                    6 = 'docs/product/ai-core/06_ORCHESTRATION_CONTROL.md'
                }[$FeatureNumber]
                @(
                    'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md'
                    'docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md'
                    'docs/product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md'
                    $featureDocument
                )
            }
            'TeamLead' {
                @('docs/team/TEAM_LEAD_PROTOCOL_v0.1.md')
            }
            'Master' {
                @(
                    'docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md'
                    'docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md'
                    'docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md'
                )
            }
        }
        foreach ($relativePath in $profileDocumentPaths) {
            $normalizedPath = $relativePath.Replace('\', '/')
            if ($seenDocuments.Add($normalizedPath)) {
                $profileDocuments.Add($normalizedPath)
            }
        }
    }

    $documents = [System.Collections.Generic.List[object]]::new()
    foreach ($relativePath in $profileDocuments) {
        if ($relativePath -eq $backendPolicyRelativePath) {
            $documents.Add($backendPolicyDocument)
            continue
        }
        $path = Join-Path $masterRoot $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Required context document is missing: $relativePath"
        }

        $content = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw "Required context document is empty: $relativePath"
        }

        $documents.Add([pscustomobject]@{
            RelativePath = $relativePath.Replace('\', '/')
            Bytes = Get-Utf8ByteCount -Text $content
            Sha256 = Get-TextSha256 -Text $content
            Content = $content
        })
    }

    $contentBuilder = [Text.StringBuilder]::new()
    foreach ($document in $documents) {
        [void]$contentBuilder.AppendLine("===== BEGIN $($document.RelativePath) =====")
        [void]$contentBuilder.AppendLine($document.Content.TrimEnd())
        [void]$contentBuilder.AppendLine("===== END $($document.RelativePath) =====")
        [void]$contentBuilder.AppendLine()
    }

    # Reserve room for the deterministic receipt and document fingerprints.
    $chunkContentLimit = $MaxContextBytes - 4096
    $chunks = [System.Collections.Generic.List[string]]::new()
    $currentChunk = [Text.StringBuilder]::new()
    $reader = [IO.StringReader]::new($contentBuilder.ToString())
    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            $unit = $line + "`n"
            $unitBytes = Get-Utf8ByteCount -Text $unit
            if ($unitBytes -gt $chunkContentLimit) {
                throw "A context line exceeds the bounded chunk size; document must be split at a stable heading. bytes=$unitBytes"
            }

            $candidateBytes = Get-Utf8ByteCount -Text ($currentChunk.ToString() + $unit)
            if ($currentChunk.Length -gt 0 -and $candidateBytes -gt $chunkContentLimit) {
                $chunks.Add($currentChunk.ToString())
                $currentChunk.Length = 0
            }
            [void]$currentChunk.Append($unit)
        }
    }
    finally {
        $reader.Dispose()
    }
    if ($currentChunk.Length -gt 0) {
        $chunks.Add($currentChunk.ToString())
    }
    if ($chunks.Count -eq 0) {
        throw "No context content was produced for Profile=$profileLabel."
    }
    $bundleText = $chunks -join ''
    $bundleBytes = Get-Utf8ByteCount -Text $bundleText
    if ($bundleBytes -gt $MaxBundleBytes) {
        throw "Context bundle exceeds the safety limit; bytes=$bundleBytes; max=$MaxBundleBytes."
    }
    $bundleHash = Get-TextSha256 -Text $bundleText
    if ($ChunkNumber -gt $chunks.Count) {
        throw "ChunkNumber is out of range for Profile=$profileLabel; requested=$ChunkNumber; available=1..$($chunks.Count)."
    }
    if ($ChunkNumber -eq 1 -and ($PreviousChunkSha256 -or $ExpectedBundleSha256)) {
        throw 'PreviousChunkSha256 and ExpectedBundleSha256 must be omitted for ChunkNumber=1.'
    }
    if ($ChunkNumber -gt 1) {
        if (-not $ExpectedBundleSha256 -or $ExpectedBundleSha256 -notmatch '^[0-9a-fA-F]{64}$') {
            throw "ChunkNumber=$ChunkNumber requires the first Receipt bundleSha256."
        }
        if ($ExpectedBundleSha256 -ne $bundleHash) {
            throw "ExpectedBundleSha256 does not match the current document bundle for Profile=$profileLabel."
        }
        $expectedPreviousHash = Get-TextSha256 -Text ($chunks[$ChunkNumber - 2])
        if (-not $PreviousChunkSha256 -or $PreviousChunkSha256 -notmatch '^[0-9a-fA-F]{64}$') {
            throw "ChunkNumber=$ChunkNumber requires the previous Receipt chunkSha256."
        }
        if ($PreviousChunkSha256 -ne $expectedPreviousHash) {
            throw "PreviousChunkSha256 does not match ChunkNumber=$($ChunkNumber - 1) for Profile=$Profile."
        }
    }

    $receipt = [Text.StringBuilder]::new()
    [void]$receipt.AppendLine('TASK CONTEXT RECEIPT v1')
    [void]$receipt.AppendLine('status=PASS')
    [void]$receipt.AppendLine("profile=$profileLabel")
    if ($selectedProfiles -contains 'AiFeature') {
        [void]$receipt.AppendLine("featureNumber=$FeatureNumber")
    }
    if ($includesDatabase) {
        [void]$receipt.AppendLine("backendSourceRoot=$BackendSourceRoot")
        [void]$receipt.AppendLine("backendPolicySha256=$($backendPolicyDocument.Sha256)")
    }
    [void]$receipt.AppendLine("chunk=$ChunkNumber/$($chunks.Count)")
    [void]$receipt.AppendLine("complete=$(if ($ChunkNumber -eq $chunks.Count) { 'true' } else { 'false' })")
    [void]$receipt.AppendLine("bundleBytes=$bundleBytes")
    [void]$receipt.AppendLine("bundleSha256=$bundleHash")
    [void]$receipt.AppendLine("chunkSha256=$(Get-TextSha256 -Text ($chunks[$ChunkNumber - 1]))")
    [void]$receipt.AppendLine('documents:')
    foreach ($document in $documents) {
        [void]$receipt.AppendLine("- $($document.RelativePath); bytes=$($document.Bytes); sha256=$($document.Sha256)")
    }
    [void]$receipt.AppendLine()
    [void]$receipt.Append($chunks[$ChunkNumber - 1])

    $payload = $receipt.ToString()
    $payloadBytes = Get-Utf8ByteCount -Text $payload
    if ($payloadBytes -gt $MaxContextBytes) {
        throw "Context receipt exceeds the safety limit; bytes=$payloadBytes; max=$MaxContextBytes."
    }

    Write-Output $payload
}
catch {
    [Console]::Error.WriteLine("TASK CONTEXT BLOCKED: $($_.Exception.Message)")
    exit 1
}
