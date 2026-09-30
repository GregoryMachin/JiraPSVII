#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe 'Get-JiraBulkOperationProgress' -Tag 'Unit' {
        BeforeAll {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $Method -eq 'GET' -and $URI -eq '/rest/api/3/bulk/queue/10641'
            } {
                [PSCustomObject]@{ taskId = '10641'; status = 'COMPLETE'; progressPercent = 100; processedAccessibleIssues = @(10001); totalIssueCount = 1 }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII { throw 'Unidentified call to Invoke-JiraMethod' }
        }

        It 'uses the Cloud bulk queue route and returns typed progress' {
            $result = Get-JiraBulkOperationProgress -TaskId '10641'

            $result | Should -BeOfType 'AtlassianPSVII.JiraPSVII.BulkOperationProgress'
            $result.Status | Should -Be ([AtlassianPSVII.JiraPSVII.BulkOperationStatus]::COMPLETE)
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                $Method -eq 'GET' -and $URI -eq '/rest/api/3/bulk/queue/10641'
            }
        }

        It 'accepts submitted bulk operations from the pipeline' {
            [AtlassianPSVII.JiraPSVII.SubmittedBulkOperation]@{ TaskId = '10641' } | Get-JiraBulkOperationProgress | Should -Not -BeNullOrEmpty
        }

        It 'rejects task identifiers that could alter the route' {
            { Get-JiraBulkOperationProgress -TaskId '../10641' -ErrorAction Stop } | Should -Throw
        }

        It 'rejects Jira Server or Data Center before requesting task details' {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            { Get-JiraBulkOperationProgress -TaskId '10641' -ErrorAction Stop } | Should -Throw '*not supported against Jira Server or Data Center*'
        }
    }
}
