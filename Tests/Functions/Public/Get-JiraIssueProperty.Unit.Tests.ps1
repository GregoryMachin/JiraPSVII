#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPS {
    Describe 'Get-JiraIssueProperty' -Tag Unit {
        BeforeAll {
            Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties' } { [pscustomobject]@{ keys = @([pscustomobject]@{ key = 'automation.state' }) } }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties/automation.state' } { [pscustomobject]@{ key = 'automation.state'; value = @{ complete = $true } } }
        }
        It 'lists typed property keys through the Cloud v3 route' { $result = Get-JiraIssueProperty -Issue TEST-1; $result.Key | Should -Be 'automation.state'; $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPS.JiraPS.EntityProperty' }
        It 'gets an exact property through an escaped route segment' { (Get-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state).Value.complete | Should -BeTrue }
        It 'uses the Data Center v2 route' { Mock Test-JiraCloudServer -ModuleName JiraPS { $false }; Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter { $URI -eq '/rest/api/2/issue/TEST-1/properties' } { [pscustomobject]@{ keys = @() } }; Get-JiraIssueProperty -Issue TEST-1 | Should -BeNullOrEmpty }
        It 'rejects unsafe property keys' { { Get-JiraIssueProperty -Issue TEST-1 -PropertyKey '../secret' -ErrorAction Stop } | Should -Throw }
    }
}
