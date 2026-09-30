#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "New-JiraFilter" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:responseFilter = @"
{
    "self": "$jiraServer/rest/api/2/filter/12844",
    "id": "12844",
    "name": "{0}",
    "jql": "{1}",
    "favourite": false
}
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraFilter -ModuleName JiraPSVII {
                Write-MockDebugInfo 'ConvertTo-JiraFilter'
                $i = (ConvertFrom-Json $responseFilter)
                $i.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Filter')
                $i | Add-Member -MemberType AliasProperty -Name 'RestURL' -Value 'self'
                $i
            }

            Mock Get-JiraFilter -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraFilter'
                ConvertTo-JiraFilter
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/*/filter" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                ConvertFrom-Json $responseFilter
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name New-JiraFilter
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Name'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'JQL'; type = 'String' }
                    @{ parameter = 'Favorite'; type = 'SwitchParameter' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }

                It "has an alias '<alias>' for parameter '<parameter>'" -TestCases @(
                    @{ parameter = 'Favorite'; alias = 'Favourite' }
                ) {
                    param($parameter, $alias)
                    $command.Parameters[$parameter].Aliases | Should -Contain $alias
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Invokes the Jira API to create a filter" {
                {
                    $newData = @{
                        Name        = "myName"
                        Description = "myDescription"
                        JQL         = "myJQL"
                        Favorite    = $true
                    }
                    New-JiraFilter @newData
                } | Should -Not -Throw

                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'Post' -and
                    $URI -like '*/rest/api/*/filter' -and
                    $Body -match "`"name`":\s*`"myName`"" -and
                    $Body -match "`"description`":\s*`"myDescription`"" -and
                    $Body -match "`"jql`":\s*`"myJQL`"" -and
                    $Body -match "`"favourite`":\s*true"
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "-Name and -JQL" {
                    {
                        $parameter = @{
                            Name = "newName"
                            JQL  = "newJQL"
                        }
                        New-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1
                }
                It "-Name and -Description and -JQL" {
                    {
                        $parameter = @{
                            Name        = "newName"
                            Description = "newDescription"
                            JQL         = "newJQL"
                        }
                        New-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1
                }
                It "-Name and -Description and -JQL and -Favorite" {
                    {
                        $parameter = @{
                            Name        = "newName"
                            Description = "newDescription"
                            JQL         = "newJQL"
                            Favorite    = $true
                        }
                        New-JiraFilter @parameter
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1
                }
                It "maps the properties of an object to the parameters" {
                    { Get-JiraFilter "12345" | New-JiraFilter } | Should -Not -Throw
                }
            }
            Context "Negative cases" {
                # TODO: Add negative input validation tests
            }
        }

        Describe "Cloud Deployment" {
            BeforeEach {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            }

            It "uses REST API v3 for filter creation" {
                New-JiraFilter -Name 'Cloud filter' -JQL 'project = TEST'

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $Method -eq 'Post' -and $URI -eq '/rest/api/3/filter'
                }
            }

            It "does not create a filter with WhatIf" {
                New-JiraFilter -Name 'Cloud filter' -JQL 'project = TEST' -WhatIf

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0
            }
        }
    }
}
