#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Move-JiraVersion" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:versionID1 = 16840
            $script:versionID2 = 16940
            $script:projectKey = 'LDD'
            $script:projectId = '12101'

            $script:JiraProjectData = @"
[
    {
        "Key" : "$projectKey",
        "Id": "$projectId"
    },
    {
        "Key" : "foo",
        "Id": "99"
    }
]
"@
            #endregion

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Get-JiraProject -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraProject' 'Project'
                $Projects = ConvertFrom-Json $JiraProjectData
                $Projects.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Project')
                $Projects | Where-Object { $_.Key -in $Project }
            }

            Mock Get-JiraVersion -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraVersion' 'Id'
                foreach ($_id in $Id) {
                    $Version = [PSCustomObject]@{
                        Id          = $_Id
                        Name        = "v1"
                        Description = "My Desccription"
                        Project     = (Get-JiraProject -Project $projectKey)
                        ReleaseDate = (Get-Date "2017-12-01")
                        StartDate   = (Get-Date "2017-01-01")
                        RestUrl     = "$jiraServer/rest/api/2/version/$_Id"
                    }
                    $Version.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Version')
                    $Version
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'POST' -and $URI -like "/rest/api/*/version/$versionID1/move" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'POST' -and $URI -like "/rest/api/*/version/$versionID2/move" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Move-JiraVersion
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Version'; type = 'AtlassianPSVII.JiraPSVII.Version' }
                    @{ parameter = 'Position'; type = 'String' }
                    @{ parameter = 'After'; type = 'AtlassianPSVII.JiraPSVII.Version' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }

                It "supports ShouldProcess" {
                    $command.Parameters.Keys | Should -Contain 'WhatIf'
                    $command.Parameters.Keys | Should -Contain 'Confirm'
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "ByPosition behavior checking" {
                It 'moves a Version using its ID and Last Position' {
                    { Move-JiraVersion -Version $versionID1 -Position Last -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match '"position":\s*"Last"'
                    }
                }
                It 'moves a Version using its ID and Earlier Position' {
                    { Move-JiraVersion -Version $versionID1 -Position Earlier -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match '"position":\s*"Earlier"'
                    }
                }
                It 'moves a Version using a AtlassianPSVII.JiraPSVII.Version object and Later Position' {
                    {
                        $version = Get-JiraVersion -Id $versionID2
                        Move-JiraVersion -Version $version -Position Later -ErrorAction Stop
                    } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 1 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID2/move" -and
                        $Body -match '"position":\s*"Later"'
                    }
                }
                It 'moves a Version using AtlassianPSVII.JiraPSVII.Version object and First Position' {
                    {
                        $version = Get-JiraVersion -Id $versionID2
                        Move-JiraVersion -Version $version -Position First -ErrorAction Stop
                    } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 1 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID2/move" -and
                        $Body -match '"position":\s*"First"'
                    }
                }
                It 'moves a Version using AtlassianPSVII.JiraPSVII.Version object over pipeline and First Position' {
                    {
                        $version = Get-JiraVersion -Id $versionID2
                        $version | Move-JiraVersion -Position First -ErrorAction Stop
                    } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 1 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID2/move" -and
                        $Body -match '"position":\s*"First"'
                    }
                }
                It 'moves a Version using its ID over pipeline and First Position' {
                    {
                        $versionID1 | Move-JiraVersion -Position First -ErrorAction Stop
                    } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match '"position":\s*"First"'
                    }
                }

                It 'rejects a name-only Version stub where an ID is required' {
                    { Move-JiraVersion -Version ([AtlassianPSVII.JiraPSVII.Version]::new('My Version')) -Position Last -ErrorAction Stop } |
                        Should -Throw '*version ID*'

                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 0 -ModuleName JiraPSVII -ParameterFilter {
                        $Method -eq 'POST'
                    }
                }
            }
            Context "ByAfter behavior checking" {
                It 'moves a Version using its ID and other Version ID' {
                    $restUrl = (Get-JiraVersion -Id $versionID2).RestUrl
                    { Move-JiraVersion -Version $versionID1 -After $versionID2 -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 2 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match """after"":\s*""$restUrl"""
                    }
                }
                It 'moves a Version using AtlassianPSVII.JiraPSVII.Version object and other Version ID' {
                    $restUrl = (Get-JiraVersion -Id $versionID2).RestUrl
                    $version1 = Get-JiraVersion -Id $versionID1
                    { Move-JiraVersion -Version $version1 -After $versionID2 -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 3 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match """after"":\s*""$restUrl"""
                    }
                }
                It 'moves a Version using its ID and other Version AtlassianPSVII.JiraPSVII.Version object' {
                    $version2 = Get-JiraVersion -Id $versionID2
                    { Move-JiraVersion -Version $versionID1 -After $version2 -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 1 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match """after"":\s*""$($version2.RestUrl)"""
                    }
                }
                It 'moves a Version using its ID over pipeline and other Version AtlassianPSVII.JiraPSVII.Version object' {
                    $version2 = Get-JiraVersion -Id $versionID2
                    { $versionID1 | Move-JiraVersion -After $version2 -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 1 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match """after"":\s*""$($version2.RestUrl)"""
                    }
                }
                It 'moves a Version using AtlassianPSVII.JiraPSVII.Version object over pipeline and other Version AtlassianPSVII.JiraPSVII.Version object' {
                    $version1 = Get-JiraVersion -Id $versionID1
                    $version2 = Get-JiraVersion -Id $versionID2
                    { $version1 | Move-JiraVersion -After $version2 -ErrorAction Stop } | Should -Not -Throw
                    Should -Invoke -CommandName 'Get-JiraVersion' -Times 2 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Get-JiraConfigServer' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter {
                        $Method -eq 'POST' -and
                        $URI -like "/rest/api/2/version/$versionID1/move" -and
                        $Body -match """after"":\s*""$($version2.RestUrl)"""
                    }
                }

                It 'rejects a name-only After version when RestUrl and ID are both absent' {
                    { Move-JiraVersion -Version $versionID1 -After ([AtlassianPSVII.JiraPSVII.Version]::new('My Version')) -ErrorAction Stop } |
                        Should -Throw '*version ID*'

                    Should -Invoke -CommandName 'Invoke-JiraMethod' -Times 0 -ModuleName JiraPSVII -ParameterFilter {
                        $Method -eq 'POST'
                    }
                }
            }
        }

        Describe "Cloud Deployment" {
            BeforeEach {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Post' -and $URI -eq "/rest/api/3/version/$versionID1/move"
                } { }
            }

            It "uses REST API v3 for version movement" {
                Move-JiraVersion -Version $versionID1 -Position Last

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq "/rest/api/3/version/$versionID1/move"
                }
            }

            It "does not send a move request with WhatIf" {
                Move-JiraVersion -Version $versionID1 -Position Last -WhatIf

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0 -ParameterFilter {
                    $URI -eq "/rest/api/3/version/$versionID1/move"
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
