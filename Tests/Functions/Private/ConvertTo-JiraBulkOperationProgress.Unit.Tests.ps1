#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2'; MaximumVersion = '6.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe 'ConvertTo-JiraBulkOperationProgress' -Tag 'Unit' {
        It 'converts complete operations including structured partial failures' {
            $input = [PSCustomObject]@{
                taskId                          = '10641'
                status                          = 'COMPLETE'
                progressPercent                 = 100
                submittedBy                     = [PSCustomObject]@{ accountId = 'abc123'; displayName = 'Bulk User'; active = $true }
                created                         = 1704110400000
                started                         = 1704110460000
                updated                         = 1704110520000
                processedAccessibleIssues       = @(10001, 10002)
                failedAccessibleIssues          = @{ '10003' = @('The issue is locked.', 'A required field is missing.') }
                invalidOrInaccessibleIssueCount = 1
                totalIssueCount                 = 4
            }

            $result = ConvertTo-JiraBulkOperationProgress -InputObject $input

            $result | Should -BeOfType 'AtlassianPSVII.JiraPSVII.BulkOperationProgress'
            $result.TaskId | Should -Be '10641'
            $result.Status | Should -Be ([AtlassianPSVII.JiraPSVII.BulkOperationStatus]::COMPLETE)
            $result.ProcessedAccessibleIssues | Should -Be @(10001, 10002)
            $result.FailedAccessibleIssues['10003'] | Should -Be @('The issue is locked.', 'A required field is missing.')
            $result.InvalidOrInaccessibleIssueCount | Should -Be 1
            $result.HasPartialFailures | Should -BeTrue
            $result.SubmittedBy.AccountId | Should -Be 'abc123'
        }

        It 'preserves an empty partial-failure map for running operations' {
            $result = ConvertTo-JiraBulkOperationProgress -InputObject ([PSCustomObject]@{
                    taskId = '10642'; status = 'RUNNING'; progressPercent = 65
                })

            $result.FailedAccessibleIssues | Should -Not -BeNullOrEmpty
            $result.FailedAccessibleIssues.Count | Should -Be 0
            $result.HasPartialFailures | Should -BeFalse
        }

        It 'does not fail if Jira adds an unknown future status' {
            $result = ConvertTo-JiraBulkOperationProgress -InputObject ([PSCustomObject]@{ taskId = '10643'; status = 'QUEUED' })

            $result.Status | Should -BeNullOrEmpty
        }
    }
}
