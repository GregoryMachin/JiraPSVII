#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraProject" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:projectKey = 'IT'
            $script:projectId = '10003'
            $script:projectName = 'Information Technology'
            $script:projectKey2 = 'TEST'
            $script:projectId2 = '10004'
            $script:projectName2 = 'Test Project'
            $script:inaccessibleProjectKey = 'HIDDEN'

            $script:restResultAll = @"
[
    {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    },
    {
        "self": "$jiraServer/rest/api/2/project/10121",
        "id": "$projectId2",
        "key": "$projectKey2",
        "name": "$projectName2",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    }
]
"@

            $script:restResultOne = @"
[
    {
        "self": "$jiraServer/rest/api/2/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName",
        "projectCategory": {
            "self": "$jiraServer/rest/api/2/projectCategory/10000",
            "id": "10000",
            "description": "All Project Catagories",
            "name": "All Project"
        }
    }
]
"@
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Test-JiraCloudServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Test-JiraCloudServer'
                $false
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and "$URI" -eq "/rest/api/2/project" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultAll
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and "$URI" -in @("/rest/api/2/project/$projectKey", "/rest/api/2/project/$projectId") } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $restResultOne
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
                $script:command = Get-Command -Name Get-JiraProject
            }

            Context "Parameter Types" {
                It "opts into SupportsPaging" {
                    $command.Parameters.Keys | Should -Contain 'First'
                    $command.Parameters.Keys | Should -Contain 'Skip'
                    $command.Parameters.Keys | Should -Contain 'IncludeTotalCount'
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Returns all projects if called with no parameters" {
                $allResults = Get-JiraProject
                $allResults | Should -Not -BeNullOrEmpty
                @($allResults).Count | Should -Be (ConvertFrom-Json -InputObject $restResultAll).Count

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and
                    "$URI" -eq "/rest/api/2/project" -and
                    $GetParameter['expand'] -eq 'description,lead,issueTypes,url,projectKeys' -and
                    $GetParameter['maxResults'] -eq $script:DefaultPageSize -and
                    -not $Paging
                } -Exactly -Times 1
            }

            It "Returns details about specific projects if the project key is supplied" {
                $oneResult = Get-JiraProject -Project $projectKey
                $oneResult | Should -Not -BeNullOrEmpty
                @($oneResult) | Should -HaveCount 1
            }

            It "Returns details about specific projects if the project ID is supplied" {
                $oneResult = Get-JiraProject -Project $projectId
                $oneResult | Should -Not -BeNullOrEmpty
                @($oneResult) | Should -HaveCount 1
            }

            It "Provides the key of the project" {
                $oneResult = Get-JiraProject -Project $projectKey
                $oneResult.Key | Should -Be $projectKey
            }

            It "Provides the ID of the project" {
                $oneResult = Get-JiraProject -Project $projectKey
                $oneResult.Id | Should -Be $projectId
            }

            It "Uses the direct lookup route for project keys and IDs" {
                $null = Get-JiraProject -Project $projectKey, $projectId

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and
                    "$URI" -eq "/rest/api/2/project/$projectKey" -and
                    $GetParameter['expand'] -eq 'description,lead,issueTypes,url,projectKeys' -and
                    -not $Paging
                } -Exactly -Times 1

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and
                    "$URI" -eq "/rest/api/2/project/$projectId" -and
                    $GetParameter['expand'] -eq 'description,lead,issueTypes,url,projectKeys' -and
                    -not $Paging
                } -Exactly -Times 1

                Should -Invoke Test-JiraCloudServer -ModuleName JiraPSVII -Exactly -Times 0
            }

            It "Emits stable Jira project typed output" {
                $allResults = Get-JiraProject

                foreach ($projectResult in $allResults) {
                    $projectResult.PSObject.TypeNames | Should -Contain 'AtlassianPSVII.JiraPSVII.Project'
                }
            }

            Context "Jira Cloud collection search" {
                BeforeEach {
                    Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }

                    Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and "$URI" -eq "/rest/api/3/project/search" } {
                        Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                        ConvertFrom-Json $restResultAll
                    }
                }

                It "Uses the v3 project search endpoint with shared pagination" {
                    $allResults = Get-JiraProject -PageSize 2

                    $allResults | Should -HaveCount 2
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        $Method -eq 'Get' -and
                        "$URI" -eq "/rest/api/3/project/search" -and
                        $Paging -eq $true -and
                        $GetParameter['maxResults'] -eq 2 -and
                        $GetParameter['expand'] -eq 'description,lead,issueTypes,url,projectKeys'
                    } -Exactly -Times 1

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        "$URI" -eq "/rest/api/2/project"
                    } -Exactly -Times 0
                }

                It "Forwards -First and -Skip to the shared paginator" {
                    $null = Get-JiraProject -First 1 -Skip 1

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        "$URI" -eq "/rest/api/3/project/search" -and
                        $Paging -eq $true -and
                        $First -eq 1 -and
                        $Skip -eq 1
                    } -Exactly -Times 1
                }

                It "Preserves direct lookup behavior on Jira Cloud" {
                    $null = Get-JiraProject -Project $projectKey

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        "$URI" -eq "/rest/api/2/project/$projectKey" -and
                        -not $Paging
                    } -Exactly -Times 1

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        "$URI" -eq "/rest/api/3/project/search"
                    } -Exactly -Times 0

                    Should -Invoke Test-JiraCloudServer -ModuleName JiraPSVII -Exactly -Times 0
                }

                It "Returns only projects present in permission-filtered search results" {
                    $visibleResult = @"
[
    {
        "self": "$jiraServer/rest/api/3/project/10003",
        "id": "$projectId",
        "key": "$projectKey",
        "name": "$projectName"
    }
]
"@
                    Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and "$URI" -eq "/rest/api/3/project/search" } {
                        ConvertFrom-Json $visibleResult
                    }

                    $result = Get-JiraProject

                    $result | Should -HaveCount 1
                    $result.Key | Should -Be $projectKey
                    $result.Key | Should -Not -Contain $inaccessibleProjectKey
                }

                It "Returns projects from every page yielded by Invoke-JiraMethod" {
                    Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and "$URI" -eq "/rest/api/3/project/search" } {
                        ConvertFrom-Json $restResultAll
                    }

                    $result = Get-JiraProject -PageSize 1

                    $result | Should -HaveCount 2
                    $result.Key | Should -Contain $projectKey
                    $result.Key | Should -Contain $projectKey2
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
