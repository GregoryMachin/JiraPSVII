#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Test-JiraCloudServer" -Tag 'Unit' {
        BeforeEach {
            $script:JiraServerMetadata = @{}
        }

        It "uses explicit Cloud metadata without auto-detection" {
            $script:JiraServerMetadata = @{ DeploymentType = 'Cloud' }
            Mock Get-JiraServerInformation -ModuleName JiraPS { throw 'auto-detection should not run' }

            Test-JiraCloudServer | Should -BeTrue
            Should -Invoke -CommandName Get-JiraServerInformation -ModuleName JiraPS -Exactly -Times 0 -Scope It
        }

        It "uses explicit Data Center metadata without auto-detection" {
            $script:JiraServerMetadata = @{ DeploymentType = 'DataCenter' }
            Mock Get-JiraServerInformation -ModuleName JiraPS { throw 'auto-detection should not run' }

            Test-JiraCloudServer | Should -BeFalse
            Should -Invoke -CommandName Get-JiraServerInformation -ModuleName JiraPS -Exactly -Times 0 -Scope It
        }

        It "preserves legacy auto-detection when no metadata is configured" {
            Mock Get-JiraServerInformation -ModuleName JiraPS {
                [AtlassianPS.JiraPS.ServerInfo]@{ DeploymentType = 'Cloud' }
            }

            Test-JiraCloudServer | Should -BeTrue
            Should -Invoke -CommandName Get-JiraServerInformation -ModuleName JiraPS -Exactly -Times 1 -Scope It
        }

        It "surfaces auto-detection failures instead of assuming Server" {
            Mock Get-JiraServerInformation -ModuleName JiraPS {
                throw 'Unable to determine Jira deployment type from /rest/api/2/serverInfo.'
            }

            { Test-JiraCloudServer } | Should -Throw '*Unable to determine Jira deployment type*'
        }
    }
}
