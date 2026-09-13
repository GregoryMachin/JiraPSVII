#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPS {
    Describe 'Remove-JiraIssueProperty' -Tag Unit {
        BeforeAll { Mock Test-JiraCloudServer -ModuleName JiraPS { $true }; Mock Invoke-JiraMethod -ModuleName JiraPS {} }
        It 'deletes an issue property through the Cloud v3 route' { Remove-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -Confirm:$false; Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties/automation.state' -and $Method -eq 'DELETE' } }
        It 'honors WhatIf' { Remove-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -WhatIf; Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 }
    }
}
