#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2'; MaximumVersion = '6.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPSVII {
    Describe 'Remove-JiraProjectProperty' -Tag Unit {
        BeforeAll { Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }; Mock Invoke-JiraMethod -ModuleName JiraPSVII {} }
        It 'deletes a project property through Cloud v3' { Remove-JiraProjectProperty -Project TEST -PropertyKey automation.state -Confirm:$false; Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/project/TEST/properties/automation.state' -and $Method -eq 'DELETE' } }
        It 'honors WhatIf' { Remove-JiraProjectProperty -Project TEST -PropertyKey automation.state -WhatIf; Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 }
    }
}
