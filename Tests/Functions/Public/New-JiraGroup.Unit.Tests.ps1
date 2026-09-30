#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "New-JiraGroup" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testGroupName = 'testGroup'

            $script:testJson = @"
{
    "name": "$testGroupName",
    "self": "$jiraServer/rest/api/2/group?groupname=$testGroupName",
    "users": {
        "size": 0,
        "items": [],
        "max-results": 50,
        "start-index": 0,
        "end-index": 0
    },
    "expand": "users"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'POST' -and $URI -eq "/rest/api/2/group" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJson
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }

            Mock ConvertTo-JiraGroup { $InputObject }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name New-JiraGroup
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'GroupName'; type = 'String[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }

                It "has an alias '<alias>' for parameter '<parameter>'" -TestCases @(
                    @{ parameter = 'GroupName'; alias = 'Name' }
                ) {
                    param($parameter, $alias)
                    $command.Parameters[$parameter].Aliases | Should -Contain $alias
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Creates a group in JIRA and returns a result" {
                $newResult = New-JiraGroup -GroupName $testGroupName
                $newResult | Should -Not -BeNullOrEmpty
                Should -Invoke 'ConvertTo-JiraGroup' -ModuleName JiraPSVII -Exactly 1
            }

            It "uses REST API v3 when creating a group on Cloud" {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'POST' -and $URI -eq '/rest/api/3/group' } {
                    ConvertFrom-Json $testJson
                }

                New-JiraGroup -GroupName $testGroupName | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $Method -eq 'POST' -and $URI -eq '/rest/api/3/group'
                }
            }

            # It "Outputs a JiraPSVII.Group object" {
            #     $newResult = New-JiraGroup -GroupName $testGroupName
            #     (Get-Member -InputObject $newResult).TypeName | Should -Be 'JiraPSVII.Group'
            #     $newResult.Name | Should -Be $testGroupName
            #     $newResult.RestUrl | Should -Be "$jiraServer/rest/api/2/group?groupname=$testGroupName"
            # }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
