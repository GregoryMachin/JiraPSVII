#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPS {
    Describe 'Set-JiraProjectProperty' -Tag Unit {
        BeforeAll { Mock Test-JiraCloudServer -ModuleName JiraPS { $true }; Mock Invoke-JiraMethod -ModuleName JiraPS { 'ready' } }
        It 'sets a primitive property through Cloud v3' { (Set-JiraProjectProperty -Project TEST -PropertyKey automation.state -Value 'ready').Value | Should -Be 'ready'; Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $URI -eq '/rest/api/3/project/TEST/properties/automation.state' -and $Method -eq 'PUT' -and $Body -eq '"ready"' } }
        It 'honors WhatIf' { Set-JiraProjectProperty -Project TEST -PropertyKey automation.state -Value 'ready' -WhatIf; Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 0 }
        It 'rejects prototype-like values' { { Set-JiraProjectProperty -Project TEST -PropertyKey automation.state -Value @{ '__proto__' = 'unsafe' } -ErrorAction Stop } | Should -Throw '*not allowed*' }
    }
}
