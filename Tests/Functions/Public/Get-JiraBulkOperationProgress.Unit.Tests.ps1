#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Get-JiraBulkOperationProgress' -Tag 'Unit' {
        BeforeAll {
            Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'GET' -and $URI -eq '/rest/api/3/bulk/queue/10641'
            } {
                [PSCustomObject]@{ taskId = '10641'; status = 'COMPLETE'; progressPercent = 100; processedAccessibleIssues = @(10001); totalIssueCount = 1 }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPS { throw 'Unidentified call to Invoke-JiraMethod' }
        }

        It 'uses the Cloud bulk queue route and returns typed progress' {
            $result = Get-JiraBulkOperationProgress -TaskId '10641'

            $result | Should -BeOfType 'AtlassianPS.JiraPS.BulkOperationProgress'
            $result.Status | Should -Be ([AtlassianPS.JiraPS.BulkOperationStatus]::COMPLETE)
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                $Method -eq 'GET' -and $URI -eq '/rest/api/3/bulk/queue/10641'
            }
        }

        It 'accepts submitted bulk operations from the pipeline' {
            [AtlassianPS.JiraPS.SubmittedBulkOperation]@{ TaskId = '10641' } | Get-JiraBulkOperationProgress | Should -Not -BeNullOrEmpty
        }

        It 'rejects task identifiers that could alter the route' {
            { Get-JiraBulkOperationProgress -TaskId '../10641' -ErrorAction Stop } | Should -Throw
        }

        It 'rejects Jira Server or Data Center before requesting task details' {
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            { Get-JiraBulkOperationProgress -TaskId '10641' -ErrorAction Stop } | Should -Throw '*not supported against Jira Server or Data Center*'
        }
    }
}
