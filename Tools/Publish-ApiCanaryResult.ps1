#requires -version 5.1

<#
.SYNOPSIS
    Converts a Pester NUnit results file into machine-readable API canary results.

.DESCRIPTION
    Used by .github/workflows/api_canary.yml (Phase 9 Task 60) after each scheduled
    canary run. Parses every `test-case` in the Pester-produced NUnit 2.5 XML report
    and formats one AtlassianPS.Standards.ConvertTo-ApiCanaryResult record per test
    case, then writes the array as a single JSON file for the workflow to upload as
    an artifact.

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
    Calls AtlassianPS.Standards' ConvertTo-ApiCanaryResult (imported via the version
    Tools/build.requirements.psd1 pins), rather than duplicating its schema by hand:
    this repository's pin now points at a locally built AtlassianPS.Standards release
    that actually contains it. Message/Metadata are passed through empty, since
    neither carries anything sensitive here; that function's redaction only matters
    once a caller starts passing real diagnostic text or metadata through them.
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

Import-Module AtlassianPS.Standards -Force -ErrorAction Stop

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

        ConvertTo-AtlassianPSApiCanaryResult `
            -Repository $Repository `
            -Operation $testCase.name `
            -DeploymentType $DeploymentType `
            -Status $status `
            -StartedAt $startedAt `
            -CompletedAt $completedAt
    }
)

$results | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutputPath -Encoding utf8
Write-Verbose "Wrote $($results.Count) canary result(s) to '$OutputPath'."
