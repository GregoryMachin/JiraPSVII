#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "New-JiraUser" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testEmail = "$testUsername@example.com"
            $script:testDisplayName = 'Test User'

            # Trimmed from this example JSON: expand, groups, avatarURL
            $script:testJson = @"
{
    "self": "$jiraServer/rest/api/2/user?username=testUser",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "$testDisplayName",
    "active": true
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'POST' -and $URI -eq "/rest/api/2/user" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJson
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name New-JiraUser
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'UserName'; type = 'String' }
                    @{ parameter = 'EmailAddress'; type = 'String' }
                    @{ parameter = 'DisplayName'; type = 'String' }
                    @{ parameter = 'Notify'; type = 'Boolean' }
                    @{ parameter = 'Product'; type = 'String[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
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
            It "Creates a user in JIRA and returns a result" {
                $newResult = New-JiraUser -UserName $testUsername -EmailAddress $testEmail -DisplayName $testDisplayName
                $newResult | Should -Not -BeNullOrEmpty
            }

            It "Uses ConvertTo-JiraUser to beautify output" {
                Mock ConvertTo-JiraUser {}
                New-JiraUser -UserName $testUsername -EmailAddress $testEmail -DisplayName $testDisplayName
                Should -Invoke 'ConvertTo-JiraUser' -ModuleName JiraPSVII -Exactly 1
            }

            It "uses REST API v3 and the Cloud products contract" {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'POST' -and $URI -eq '/rest/api/3/user' } {
                    ConvertFrom-Json $testJson
                }

                New-JiraUser -UserName $testUsername -EmailAddress $testEmail -Product jira-software | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $bodyObject = $Body | ConvertFrom-Json
                    $Method -eq 'POST' -and
                    $URI -eq '/rest/api/3/user' -and
                    $bodyObject.emailAddress -eq $testEmail -and
                    $bodyObject.products -contains 'jira-software' -and
                    -not $bodyObject.PSObject.Properties['name']
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
