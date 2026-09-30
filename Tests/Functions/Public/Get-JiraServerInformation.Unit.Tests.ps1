#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraServerInformation" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'

            $script:restResult = @"
{
    "baseUrl":"$jiraServer",
    "version":"1000.1323.0",
    "versionNumbers":[1000,1323,0],
    "deploymentType":"Cloud",
    "buildNumber":100062,
    "buildDate":"2017-09-26T00:00:00.000+0200",
    "serverTime":"2017-09-27T09:59:25.520+0200",
    "scmInfo":"f3c60100df073e3576f9741fb7a3dc759b416fde",
    "serverTitle":"JIRA"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/serverInfo" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResult
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                # TODO: Add parameter type validation tests
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            BeforeEach {
                $script:JiraServerInfo = $null
                $script:JiraServerMetadata = @{}
            }

            It "returns the server information" {
                $allResults = Get-JiraServerInformation
                $allResults | Should -Not -BeNullOrEmpty
                @($allResults).Count | Should -Be @(ConvertFrom-Json -InputObject $restResult).Count
            }

            It "answers to the alias 'Get-JiraServerInfo'" {
                $thisAlias = (Get-Alias -Name "Get-JiraServerInfo")
                $thisAlias.ResolvedCommandName | Should -Be "Get-JiraServerInformation"
                $thisAlias.ModuleName | Should -Be "JiraPSVII"
            }

            It "throws an actionable error when auto-detection fails without explicit metadata" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/serverInfo" } {
                    throw 'response-body-that-must-not-leak'
                }

                $errorMessage = $null
                try {
                    Get-JiraServerInformation
                }
                catch {
                    $errorMessage = $_.Exception.Message
                }

                $errorMessage | Should -BeLike '*Configure explicit DeploymentType metadata*'
                $errorMessage | Should -Not -BeLike '*response-body-that-must-not-leak*'
            }

            It "returns explicit deployment metadata when server information cannot be retrieved" {
                $script:JiraServerUrl = [Uri]'https://example.atlassian.net/'
                $script:JiraServerMetadata = @{ DeploymentType = 'Cloud' }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/serverInfo" } {
                    throw 'simulated network failure'
                }

                $serverInfo = Get-JiraServerInformation

                $serverInfo | Should -BeOfType [AtlassianPSVII.JiraPSVII.ServerInfo]
                $serverInfo.DeploymentType | Should -Be 'Cloud'
                $serverInfo.BaseURL | Should -Be 'https://example.atlassian.net/'
            }

            It "uses cached server information before auto-detection" {
                $script:JiraServerInfo = [AtlassianPSVII.JiraPSVII.ServerInfo]@{ DeploymentType = 'DataCenter'; Version = '9.12.0' }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/serverInfo" } {
                    throw 'auto-detection should not run'
                }

                $serverInfo = Get-JiraServerInformation

                $serverInfo.DeploymentType | Should -Be 'DataCenter'
                $serverInfo.Version | Should -Be '9.12.0'
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 -Scope It
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
