#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2'; MaximumVersion = '6.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPSVII {
    Describe 'Get-JiraIssueProperty' -Tag Unit {
        BeforeAll {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties' } { [pscustomobject]@{ keys = @([pscustomobject]@{ key = 'automation.state' }) } }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/issue/TEST-1/properties/automation.state' } { [pscustomobject]@{ key = 'automation.state'; value = @{ complete = $true } } }
        }
        It 'lists typed property keys through the Cloud v3 route' { $result = Get-JiraIssueProperty -Issue TEST-1; $result.Key | Should -Be 'automation.state'; $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPSVII.JiraPSVII.EntityProperty' }
        It 'gets an exact property through an escaped route segment' { (Get-JiraIssueProperty -Issue TEST-1 -PropertyKey automation.state).Value.complete | Should -BeTrue }
        It 'uses the Data Center v2 route' { Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }; Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/2/issue/TEST-1/properties' } { [pscustomobject]@{ keys = @() } }; Get-JiraIssueProperty -Issue TEST-1 | Should -BeNullOrEmpty }
        It 'rejects unsafe property keys' { { Get-JiraIssueProperty -Issue TEST-1 -PropertyKey '../secret' -ErrorAction Stop } | Should -Throw }
    }
}
