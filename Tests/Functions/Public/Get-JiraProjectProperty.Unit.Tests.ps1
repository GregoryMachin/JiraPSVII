#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2'; MaximumVersion = '6.999' }
BeforeDiscovery { . "$PSScriptRoot/../../Helpers/TestTools.ps1"; $script:moduleToTest = Initialize-TestEnvironment }
InModuleScope JiraPSVII {
    Describe 'Get-JiraProjectProperty' -Tag Unit {
        BeforeAll { Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }; Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/project/TEST/properties' } { [pscustomobject]@{ keys = @([pscustomobject]@{ key = 'automation.state' }) } }; Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/project/TEST/properties/automation.state' } { [pscustomobject]@{ key = 'automation.state'; value = 'ready' } } }
        It 'lists typed property keys through the Cloud v3 route' { (Get-JiraProjectProperty -Project TEST).Key | Should -Be 'automation.state' }
        It 'gets a property by key' { (Get-JiraProjectProperty -Project TEST -PropertyKey automation.state).Value | Should -Be 'ready' }
        It 'uses the Data Center v2 route' { Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }; Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/2/project/TEST/properties' } { [pscustomobject]@{ keys = @() } }; Get-JiraProjectProperty -Project TEST | Should -BeNullOrEmpty }
    }
}
