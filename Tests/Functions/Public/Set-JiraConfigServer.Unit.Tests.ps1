#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Set-JiraConfigServer" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            #endregion Definitions

            #region Mocks
            # No mocks needed for this simple function
            #endregion Mocks
        }

        BeforeEach {
            $script:serverConfig = Join-Path $TestDrive 'server_config'
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Set-JiraConfigServer
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Server'; type = 'Object' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "stores the server address in the module session" {
                Set-JiraConfigServer -Server $jiraServer

                $script:JiraServerUrl | Should -Be "$jiraServer/"
            }

            It "stores the server address in a config file" {
                $script:serverConfig | Should -Exist

                Get-Content $script:serverConfig | Should -Be "$jiraServer/"
            }

            It "accepts an AtlassianPS.Configuration-shaped server entry from the pipeline" {
                [PSCustomObject]@{
                    Uri                = 'https://example.atlassian.net/'
                    Type               = 'Jira'
                    Product            = 'Jira'
                    DeploymentType     = 'Cloud'
                    AuthenticationType = 'OAuth'
                    CloudId            = '00000000-0000-0000-0000-000000000000'
                } | Set-JiraConfigServer

                $script:JiraServerUrl | Should -Be 'https://example.atlassian.net/'
                $script:JiraServerMetadata.DeploymentType | Should -Be 'Cloud'
                $script:JiraServerMetadata.AuthenticationType | Should -Be 'OAuth'
                $script:JiraServerMetadata.CloudId | Should -Be '00000000-0000-0000-0000-000000000000'
                Get-Content $script:serverConfig | Should -Be 'https://example.atlassian.net/'
            }
        }

        Describe "Input Validation" {

            It "throws an error when a relative url is used" {
                { Set-JiraConfigServer -Server 'jira.domain.com' } | Should -Throw 'Server must be an absolute URI (e.g., https://jira.domain.com/)'
            }

            It "rejects non-Jira configuration entries" {
                $entry = [PSCustomObject]@{
                    Uri     = 'https://example.atlassian.net/'
                    Type    = 'Confluence'
                    Product = 'Confluence'
                }

                { Set-JiraConfigServer -Server $entry } | Should -Throw '*only accepts Jira*'
            }

            It "rejects conflicting OAuth and Data Center metadata" {
                $entry = [PSCustomObject]@{
                    Uri                = 'https://jira.example.com/'
                    Type               = 'Jira'
                    Product            = 'Jira'
                    DeploymentType     = 'DataCenter'
                    AuthenticationType = 'OAuth'
                }

                { Set-JiraConfigServer -Server $entry } | Should -Throw '*OAuth requires DeploymentType Cloud*'
            }

            It "rejects non-HTTPS Cloud configuration" {
                $entry = [PSCustomObject]@{
                    Uri            = 'http://example.atlassian.net/'
                    Type           = 'Jira'
                    Product        = 'Jira'
                    DeploymentType = 'Cloud'
                }

                { Set-JiraConfigServer -Server $entry } | Should -Throw '*Cloud configuration requires an HTTPS*'
            }

            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
