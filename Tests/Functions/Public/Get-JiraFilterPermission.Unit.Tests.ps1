#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraFilterPermission" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = "https://jira.example.com"

            $script:sampleResponse = @"
{
  "id": 10000,
  "type": "global"
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
            }

            Mock Get-JiraFilter -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraFilter' 'Id'
                foreach ($_id in $Id) {
                    $basicFilter = New-Object -TypeName PSCustomObject -Property @{
                        Id      = $_id
                        RestUrl = "$jiraServer/rest/api/2/filter/$_id"
                    }
                    $basicFilter.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Filter')
                    $basicFilter
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -like "/rest/api/*/filter/*/permission" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $sampleResponse
            }

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
            Context "Behavior testing" {
                It "Retrieves the permissions of a Filter by Object" {
                    { Get-JiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/23456/permission'
                    }
                }

                It "Retrieves the permissions of a Filter by Id" {
                    { 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                        $Method -eq 'Get' -and
                        $URI -like '*/rest/api/*/filter/23456/permission'
                    }
                }
            }

            Context "Input testing" {
                It "finds the filter by Id" {
                    { Get-JiraFilterPermission -Id 23456 } | Should -Not -Throw

                    Should -Invoke Get-JiraFilter -ModuleName JiraPSVII -Exactly -Times 1
                }

                It "does not accept negative Ids" {
                    { Get-JiraFilterPermission -Id -1 } | Should -Throw -ExpectedMessage "*'Id'*"
                }

                It "can process multiple Ids" {
                    { Get-JiraFilterPermission -Id 23456, 23456 } | Should -Not -Throw

                    Should -Invoke Get-JiraFilter -ModuleName JiraPSVII -Exactly -Times 1
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 2
                }

                It "allows for the filter to be passed over the pipeline" {
                    { Get-JiraFilter -Id 23456 | Get-JiraFilterPermission } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1
                }

                It "can only process one Filter objects" {
                    $filter = @()
                    $filter += Get-JiraFilter -Id 23456
                    $filter += Get-JiraFilter -Id 23456

                    { Get-JiraFilterPermission -Filter $filter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 2
                }

                It "resolves positional parameters" {
                    { Get-JiraFilterPermission 23456 } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1

                    $filter = Get-JiraFilter -Id 23456
                    { Get-JiraFilterPermission $filter } | Should -Not -Throw

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 2
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }

        Describe "Cloud Deployment" {
            BeforeEach {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            }

            It "uses REST API v3 for filter permission reads" {
                Get-JiraFilterPermission -Id 23456

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $Method -eq 'Get' -and $URI -eq '/rest/api/3/filter/23456/permission'
                }
            }

            It "propagates Jira permission failures" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and $URI -eq '/rest/api/3/filter/23456/permission'
                } { throw 'Forbidden' }

                { Get-JiraFilterPermission -Id 23456 } | Should -Throw -ExpectedMessage '*Forbidden*'
            }
        }
    }
}
