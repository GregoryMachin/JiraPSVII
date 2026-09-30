#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2'; MaximumVersion = '6.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPSVII {
    Describe 'Set-JiraIssueProperty' -Tag Unit {
        BeforeAll { Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }; Mock Invoke-JiraMethod -ModuleName JiraPSVII { [pscustomobject]@{ complete = $true } } }
        It 'sets JSON-safe values through the Cloud v3 route' { $result = Set-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -Value @{ complete = $true }; $result.Key | Should -Be 'automation.state'; Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties/automation.state' -and $Method -eq 'PUT' -and $RawBody -and $Body -eq '{"complete":true}' } }
        It 'serializes array values as JSON' { Set-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.steps -Value @('build', 'test'); Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties/automation.steps' -and $Method -eq 'PUT' -and $Body -eq '["build","test"]' } }
        It 'honors WhatIf' { Set-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -Value $true -WhatIf; Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 }
        It 'rejects secret-like data keys' { { Set-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -Value @{ apiToken = 'not-a-secret' } -ErrorAction Stop } | Should -Throw '*appears to contain a secret*' }
        It 'rejects values over 32 KiB' { { Set-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state -Value ('x' * 32769) -ErrorAction Stop } | Should -Throw '*32,768*' }
    }
}
