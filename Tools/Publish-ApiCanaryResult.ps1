#requires -version 5.1

<#
.SYNOPSIS
    Converts a Pester NUnit results file into machine-readable API canary results.

.DESCRIPTION
    Used by .github/workflows/api_canary.yml (Phase 9 Task 60) after each scheduled
    canary run. Parses every `test-case` in the Pester-produced NUnit 2.5 XML report
    and formats one canary result record (matching AtlassianPS.Standards'
    ConvertTo-ApiCanaryResult schema; see .NOTES for why that function itself isn't
    called) per test case, then writes the array as a single JSON file for the
    workflow to upload as an artifact.

    The NUnit report only carries each test case's own duration (`time`, in seconds),
    not an absolute start timestamp, so StartedAtUtc/CompletedAtUtc are reconstructed
    by accumulating durations forward from the report's own recorded start
    (`test-results/@date` + `@time`). This is internally consistent (ordering and
    relative timing between test cases is exact) but is not independently
    wall-clock-verified against the actual HTTP request timestamps -- sufficient for
    the pass/fail/duration signal a canary needs, not forensic-grade tracing.

.PARAMETER ResultXmlPath
    Path to the NUnit 2.5 XML file produced by Invoke-Build -Task TestIntegration
    (Tests/Invoke-ParallelPester.ps1's merged -OutputPath).

.PARAMETER Repository
    Repository name recorded on every canary result, for example 'JiraPS'.

.PARAMETER DeploymentType
    'Cloud' or 'DataCenter', recorded on every canary result.

.PARAMETER OutputPath
    Path to write the resulting JSON array to.

.NOTES
    This intentionally does NOT call AtlassianPS.Standards' ConvertTo-ApiCanaryResult,
    even though that function already exists for exactly this purpose and produces the
    same schema this script emits by hand below: it was added to AtlassianPS.Standards'
    source but has never been published (still listed under "Unreleased" in that
    repository's own CHANGELOG.md, and every downstream repository, including this one,
    still pins the last published release, 0.1.11, in Tools/build.requirements.psd1,
    which predates it). Depending on it here would make this workflow fail with
    "command not found" on every run until someone actually publishes a new
    AtlassianPS.Standards release and bumps this repository's pin -- a real, live
    PowerShell Gallery publish this environment has no credentials to perform, the same
    constraint recorded against Phase 8 Task 57.

    Once AtlassianPS.Standards ships a release containing ConvertTo-ApiCanaryResult and
    this repository's pin is updated to that version, replace the manual object
    construction below with a call to ConvertTo-AtlassianPSApiCanaryResult -AsJson (its
    Message/Metadata redaction is the only capability this hand-built version lacks;
    Message is passed through empty here to avoid needing it).
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$ResultXmlPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$Repository,

    [Parameter(Mandatory)]
    [ValidateSet('Cloud', 'DataCenter')]
    [String]$DeploymentType,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$OutputPath
)

if (-not (Test-Path -LiteralPath $ResultXmlPath -PathType Leaf)) {
    Write-Warning "Canary result XML '$ResultXmlPath' was not found (the test run likely failed before producing output). Writing an empty result set."
    '[]' | Set-Content -LiteralPath $OutputPath -Encoding utf8
    return
}

[xml]$nunit = Get-Content -LiteralPath $ResultXmlPath -Raw
$reportRoot = $nunit.'test-results'
$reportStart = [DateTimeOffset]::Parse("$($reportRoot.date)T$($reportRoot.time)")

$testCases = @($nunit.SelectNodes('//test-case'))
Write-Verbose "Found $($testCases.Count) test case(s) in '$ResultXmlPath'."

$cursor = $reportStart
$results = @(
    foreach ($testCase in $testCases) {
        $durationSeconds = [Double]$testCase.time
        $startedAt = $cursor
        $completedAt = $startedAt.AddSeconds($durationSeconds)
        $cursor = $completedAt

        $status = switch ($testCase.result) {
            'Success' { 'Passed' }
            'Ignored' { 'Skipped' }
            default { 'Failed' }
        }

        # Mirrors AtlassianPS.Standards' ConvertTo-ApiCanaryResult schema exactly (see the
        # .NOTES above for why this doesn't just call that function). Message/Metadata
        # redaction is that function's only capability this omits; neither field carries
        # anything sensitive here, so both are left empty rather than reimplementing
        # redaction logic that already exists once it can actually be depended on.
        [PSCustomObject][Ordered]@{
            SchemaVersion        = '1.0'
            Repository           = $Repository
            Operation            = $testCase.name
            DeploymentType       = $DeploymentType
            Status               = $status
            StartedAtUtc         = $startedAt.ToUniversalTime().ToString('o')
            CompletedAtUtc       = $completedAt.ToUniversalTime().ToString('o')
            DurationMilliseconds = [Int64][Math]::Round(($completedAt - $startedAt).TotalMilliseconds, 0, [MidpointRounding]::AwayFromZero)
            Message              = ''
            Metadata             = @{}
        }
    }
)

$results | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutputPath -Encoding utf8
Write-Verbose "Wrote $($results.Count) canary result(s) to '$OutputPath'."
