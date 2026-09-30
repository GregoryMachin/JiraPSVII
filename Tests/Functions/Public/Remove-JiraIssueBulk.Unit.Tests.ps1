#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe 'Remove-JiraIssueBulk' -Tag 'Unit' {
        BeforeAll {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $Method -eq 'POST' -and $URI -eq '/rest/api/3/bulk/issues/delete'
            } { [PSCustomObject]@{ taskId = '10643' } }
        }

        It 'uses high confirmation impact and submits a typed bulk delete request' {
            $command = Get-Command Remove-JiraIssueBulk
            $result = Remove-JiraIssueBulk -Issue 'SCRUM-1', 'SCRUM-2' -Confirm:$false

            ($command.ScriptBlock.Attributes | Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }).ConfirmImpact |
                Should -Be 'High'
            $result | Should -BeOfType 'AtlassianPSVII.JiraPSVII.SubmittedBulkOperation'
            $result.TaskId | Should -Be '10643'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                $payload = $Body | ConvertFrom-Json
                $Method -eq 'POST' -and $URI -eq '/rest/api/3/bulk/issues/delete' -and
                $payload.selectedIssueIdsOrKeys -contains 'SCRUM-1' -and $payload.sendBulkNotification -eq $true
            }
        }

        It 'supports notification suppression and validation only mode' {
            $result = Remove-JiraIssueBulk -Issue 'SCRUM-1' -SkipNotification -ValidateOnly

            $result | Should -BeOfType 'AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest'
            $result.SendBulkNotification | Should -BeFalse
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 -ParameterFilter { $Method -eq 'POST' }
        }

        It 'supports WhatIf without submitting' {
            Remove-JiraIssueBulk -Issue 'SCRUM-1' -WhatIf

            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 -ParameterFilter { $Method -eq 'POST' }
        }

        It 'rejects wildcard issue selection' {
            { Remove-JiraIssueBulk -Issue 'SCRUM-*' -ErrorAction Stop } | Should -Throw '*Wildcard issue selection is not supported*'
        }

        It 'rejects Jira Server or Data Center before submitting' {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            { Remove-JiraIssueBulk -Issue 'SCRUM-1' -Confirm:$false -ErrorAction Stop } |
                Should -Throw '*not supported against Jira Server or Data Center*'
        }
    }
}
