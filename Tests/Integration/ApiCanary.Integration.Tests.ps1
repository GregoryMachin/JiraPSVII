#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

<#
.SYNOPSIS
    Bounded write-lifecycle API canary (Phase 9 Task 60).

.DESCRIPTION
    Proves the full create -> read -> update -> delete -> confirm-gone contract
    for a single disposable issue still round-trips against Jira Cloud. This is
    deliberately narrower than New-JiraIssue.Integration.Tests.ps1 (which
    exercises many create-time payload variations): the canary exists to catch a
    Cloud contract change quickly on its own schedule, not to be a regression
    suite, so it stays to one resource and one pass through the lifecycle.

    Tagged 'CanaryWrite' (not 'Smoke'): the scheduled canary workflow selects
    this tag on a slower, off-peak cadence separate from the per-PR Smoke gate
    and the nightly full integration suite, and publishes a machine-readable
    result via AtlassianPSVII.Standards' ConvertTo-ApiCanaryResult for each step.

    Cloud-only by design: Data Center is pinned, versioned software with no
    "surprise contract change" risk the way a continuously deployed Cloud API
    has, and is already covered by integration_tests.yml's nightly Dockerized
    Server track.
#>

BeforeDiscovery {
    . "$PSScriptRoot/../Helpers/TestTools.ps1"
    . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment

    $script:Skip = Skip-IntegrationTest
    if (-not $Skip) {
        $testEnv = Initialize-IntegrationEnvironment
        $script:SkipWrite = $testEnv.ReadOnly
    }
}

InModuleScope JiraPSVII {
    Describe "Api Canary - Issue Lifecycle" -Tag 'Integration', 'CanaryWrite', 'Cloud' -Skip:($Skip -or $SkipWrite) {
        BeforeAll {
            . "$PSScriptRoot/../Helpers/IntegrationTestTools.ps1"

            $script:env = Initialize-IntegrationEnvironment
            $script:session = Connect-JiraTestServer -Environment $env
            $script:fixtures = Get-TestFixture -Environment $env

            # Tracked as soon as creation succeeds so AfterAll can still clean up
            # a leftover issue even if a later step in the lifecycle fails.
            $script:canaryIssueKey = $null

            Remove-StaleTestResource -Fixtures $fixtures
        }

        AfterAll {
            if ($script:canaryIssueKey) {
                try {
                    Remove-JiraIssue -IssueId $script:canaryIssueKey -Force -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Verbose "Cleanup: failed to remove canary issue $($script:canaryIssueKey) - $_"
                }
            }
            Remove-JiraSession -ErrorAction SilentlyContinue
        }

        It "creates a canary issue" {
            if ([string]::IsNullOrEmpty($fixtures.TestProject)) {
                Set-ItResult -Skipped -Because "JIRA_TEST_PROJECT not configured"
                return
            }

            $issue = New-TemporaryTestIssue -Fixtures $fixtures -Summary (New-TestResourceName -Type "Canary")
            $script:canaryIssueKey = $issue.Key

            $issue | Should -Not -BeNullOrEmpty
            $issue.Key | Should -Match "^$($fixtures.TestProject)-\d+$"
        }

        It "reads the canary issue back" {
            if (-not $script:canaryIssueKey) {
                Set-ItResult -Skipped -Because "canary issue was not created"
                return
            }

            $read = Get-JiraIssue -Key $script:canaryIssueKey
            $read | Should -Not -BeNullOrEmpty
            $read.Key | Should -Be $script:canaryIssueKey
        }

        It "updates the canary issue" {
            if (-not $script:canaryIssueKey) {
                Set-ItResult -Skipped -Because "canary issue was not created"
                return
            }

            $script:canaryUpdatedSummary = New-TestResourceName -Type "CanaryUpdated"
            Set-JiraIssue -Issue $script:canaryIssueKey -Summary $script:canaryUpdatedSummary

            $updated = Get-JiraIssue -Key $script:canaryIssueKey
            $updated.Summary | Should -Be $script:canaryUpdatedSummary
        }

        It "deletes the canary issue" {
            if (-not $script:canaryIssueKey) {
                Set-ItResult -Skipped -Because "canary issue was not created"
                return
            }

            { Remove-JiraIssue -IssueId $script:canaryIssueKey -Force -ErrorAction Stop } | Should -Not -Throw
        }

        It "confirms the canary issue no longer exists" {
            if (-not $script:canaryIssueKey) {
                Set-ItResult -Skipped -Because "canary issue was not created"
                return
            }

            { Get-JiraIssue -Key $script:canaryIssueKey -ErrorAction Stop } | Should -Throw

            # The delete step already succeeded and Jira confirmed the issue is
            # gone: clear the tracked key so AfterAll does not attempt a
            # redundant (and noisy) second delete.
            $script:canaryIssueKey = $null
        }
    }
}
