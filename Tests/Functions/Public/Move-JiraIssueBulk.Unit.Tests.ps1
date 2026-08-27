#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Move-JiraIssueBulk' -Tag 'Unit' {
        BeforeAll {
            Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'POST' -and $URI -eq '/rest/api/3/bulk/issues/move'
            } { [PSCustomObject]@{ taskId = '10642' } }
        }

        It 'submits a typed Cloud bulk move using explicit target project and type' {
            $result = Move-JiraIssueBulk -Issue 'SCRUM-1', 'SCRUM-2' -TargetProject 'DEST' -TargetIssueType '10001'

            $result | Should -BeOfType 'AtlassianPS.JiraPS.SubmittedBulkOperation'
            $result.TaskId | Should -Be '10642'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                $payload = $Body | ConvertFrom-Json
                $Method -eq 'POST' -and $URI -eq '/rest/api/3/bulk/issues/move' -and
                $payload.targetToSourcesMapping.'DEST,10001'.issueIdsOrKeys -contains 'SCRUM-1' -and
                $payload.targetToSourcesMapping.'DEST,10001'.inferFieldDefaults -eq $true
            }
        }

        It 'includes an explicit target parent in the mapping key' {
            Move-JiraIssueBulk -Issue 'SCRUM-1' -TargetProject 'DEST' -TargetIssueType '10002' -TargetParent '10003'

            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                ($Body | ConvertFrom-Json).targetToSourcesMapping.'DEST,10002,10003'.issueIdsOrKeys -contains 'SCRUM-1'
            }
        }

        It 'returns the typed request without submitting when validation only is requested' {
            $result = Move-JiraIssueBulk -Issue 'SCRUM-1' -TargetProject 'DEST' -TargetIssueType '10001' -ValidateOnly

            $result | Should -BeOfType 'AtlassianPS.JiraPS.BulkIssueMoveRequest'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 -ParameterFilter { $Method -eq 'POST' }
        }

        It 'supports WhatIf without submitting' {
            Move-JiraIssueBulk -Issue 'SCRUM-1' -TargetProject 'DEST' -TargetIssueType '10001' -WhatIf

            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 -ParameterFilter { $Method -eq 'POST' }
        }

        It 'rejects wildcard issue selection' {
            { Move-JiraIssueBulk -Issue 'SCRUM-*' -TargetProject 'DEST' -TargetIssueType '10001' -ErrorAction Stop } |
                Should -Throw '*Wildcard issue selection is not supported*'
        }

        It 'rejects Jira Server or Data Center before submitting' {
            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }

            { Move-JiraIssueBulk -Issue 'SCRUM-1' -TargetProject 'DEST' -TargetIssueType '10001' -ErrorAction Stop } |
                Should -Throw '*not supported against Jira Server or Data Center*'
        }
    }
}
