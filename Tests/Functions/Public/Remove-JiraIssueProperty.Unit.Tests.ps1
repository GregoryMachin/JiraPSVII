#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2'; MaximumVersion = '6.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPSVII {
    Describe 'Remove-JiraIssueProperty' -Tag Unit {
        BeforeAll { Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }; Mock Invoke-JiraMethod -ModuleName JiraPSVII {} }
        It 'deletes an issue property through the Cloud v3 route' { Remove-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -Confirm:$false; Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties/automation.state' -and $Method -eq 'DELETE' } }
        It 'honors WhatIf' { Remove-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -WhatIf; Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 }
    }
}
