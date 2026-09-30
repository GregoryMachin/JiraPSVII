#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraComponent" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:projectKey = 'TEST'
            $script:projectId = '10004'
            $script:componentId = '10001'
            $script:componentName = 'Component 1'
            $script:componentId2 = '10002'
            $script:componentName2 = 'Component 2'

            $script:restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/component/$componentId",
        "id": "$componentId",
        "name": "$componentName",
        "project": "$projectKey",
        "projectId": "$projectId"
    },
    {
        "self": "$jiraServer/rest/api/2/component/$componentId2",
        "id": "$componentId2",
        "name": "$componentName2",
        "project": "$projectKey",
        "projectId": "$projectId"
    }
]
"@

            $script:restResultOne = @"
[
    {
        "self": "$jiraServer/rest/api/2/component/$componentId",
        "id": "$componentId",
        "name": "$componentName",
        "project": "$projectKey",
        "projectId": "$projectId"
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/component/$componentId" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/project/$projectKey/components" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultAll
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
                It "opts into SupportsPaging for project component collections" {
                    $command = Get-Command -Name Get-JiraComponent
                    $command.Parameters.Keys | Should -Contain 'First'
                    $command.Parameters.Keys | Should -Contain 'Skip'
                    $command.Parameters.Keys | Should -Contain 'IncludeTotalCount'
                    $command | Should -HaveParameter 'PageSize' -Type UInt32
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Returns details about specific components if the component ID is supplied" {
                $oneResult = Get-JiraComponent -Id $componentId
                $oneResult | Should -Not -BeNullOrEmpty
                @($oneResult) | Should -HaveCount 1
                $oneResult.Id | Should -Be $componentId
            }

            It "Provides the Id of the component" {
                $oneResult = Get-JiraComponent -Id $componentId
                $oneResult.Id | Should -Be $componentId
            }

            It "retains the unpaginated Data Center project-components route" {
                $components = Get-JiraComponent -Project $projectKey

                $components | Should -HaveCount 2
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -eq "/rest/api/2/project/$projectKey/components" -and
                    -not $Paging
                }
            }

            Context "Jira Cloud" {
                BeforeEach {
                    Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }

                    Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        $Method -eq 'Get' -and $URI -eq "/rest/api/3/component/$componentId"
                    } {
                        ConvertFrom-Json $restResultOne
                    }

                    Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        $Method -eq 'Get' -and $URI -eq "/rest/api/3/project/$projectKey/component"
                    } {
                        ConvertFrom-Json $restResultAll
                    }
                }

                It "uses REST API v3 for direct component lookup" {
                    Get-JiraComponent -ComponentId $componentId | Should -HaveCount 1

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                        $URI -eq "/rest/api/3/component/$componentId" -and -not $Paging
                    }
                }

                It "uses the paged REST API v3 project component route" {
                    $components = Get-JiraComponent -Project $projectKey -PageSize 25

                    $components | Should -HaveCount 2
                    $components[0] | Should -BeOfType [AtlassianPSVII.JiraPSVII.Component]
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                        $URI -eq "/rest/api/3/project/$projectKey/component" -and
                        $Paging -and
                        $GetParameter.maxResults -eq 25
                    }
                }

                It "forwards First and Skip to shared paging" {
                    Get-JiraComponent -Project $projectKey -First 1 -Skip 1 | Out-Null

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                        $URI -eq "/rest/api/3/project/$projectKey/component" -and
                        $Paging -and
                        $First -eq 1 -and
                        $Skip -eq 1
                    }
                }

                It "propagates project browse permission failures" {
                    Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        $Method -eq 'Get' -and $URI -eq '/rest/api/3/project/FORBIDDEN/component'
                    } {
                        throw [System.UnauthorizedAccessException]::new('Browse projects permission is required.')
                    }

                    { Get-JiraComponent -Project 'FORBIDDEN' -ErrorAction Stop } |
                        Should -Throw -ExceptionType ([System.UnauthorizedAccessException])
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
