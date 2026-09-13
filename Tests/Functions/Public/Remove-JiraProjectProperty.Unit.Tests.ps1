#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPS {
    Describe 'Remove-JiraProjectProperty' -Tag Unit {
        BeforeAll { Mock Test-JiraCloudServer -ModuleName JiraPS { $true }; Mock Invoke-JiraMethod -ModuleName JiraPS {} }
        It 'deletes a project property through Cloud v3' { Remove-JiraProjectProperty -Project TEST -PropertyKey automation.state -Confirm:$false; Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $URI -eq '/rest/api/3/project/TEST/properties/automation.state' -and $Method -eq 'DELETE' } }
        It 'honors WhatIf' { Remove-JiraProjectProperty -Project TEST -PropertyKey automation.state -WhatIf; Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 }
    }
}
