#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Set-JiraVersion" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:versionName = '1.0.0.0'
            $script:versionID = '16840'
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
            $script:testJsonOne = @"
{
    "self" : "/rest/api/2/version/$versionID",
    "id" : $versionID,
    "description" : "$versionName",
    "name" : "$versionName",
    "archived" : "False",
    "released" : "False",
    "projectId" : "12101"
}
"@
            #endregion Definitions

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
                Write-MockDebugInfo 'Get-JiraVersion' 'Project', 'Name'
                ConvertTo-JiraVersion -InputObject (ConvertFrom-Json $testJsonOne)
            }

            Mock ConvertTo-JiraVersion -ModuleName JiraPSVII {
                Write-MockDebugInfo 'ConvertTo-JiraVersion' 'InputObject'
                $result = New-Object -TypeName PSObject -Property @{
                    Id      = $InputObject.Id
                    Name    = $InputObject.name
                    Project = $InputObject.projectId
                    RestUrl = $InputObject.self
                }
                $result.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Version')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Put' -and $URI -like "/rest/api/*/version/$versionID" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $testJsonOne
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
                $script:command = Get-Command -Name Set-JiraVersion
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Version'; type = 'AtlassianPSVII.JiraPSVII.Version[]' }
                    @{ parameter = 'Name'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'Archived'; type = 'Boolean' }
                    @{ parameter = 'Released'; type = 'Boolean' }
                    @{ parameter = 'ReleaseDate'; type = 'DateTime' }
                    @{ parameter = 'StartDate'; type = 'DateTime' }
                    @{ parameter = 'Project'; type = 'AtlassianPSVII.JiraPSVII.Project' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Version Update" {
                It "sets an Issue's Version Name" {
                    $version = Get-JiraVersion -Project $projectKey -Name $versionName
                    $results = Set-JiraVersion -Version $version -Name "NewName" -ErrorAction Stop
                    $results | Should -Not -BeNullOrEmpty
                    $results.PSObject.TypeNames[0] | Should -Be 'AtlassianPSVII.JiraPSVII.Version'
                    Should -Invoke 'Get-JiraVersion' -Times 2 -ModuleName JiraPSVII -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke 'ConvertTo-JiraVersion' -Times 3 -ModuleName JiraPSVII -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "/rest/api/*/version/$versionID" }
                }

                It "sets an Issue's Version Name using the pipeline" {
                    $results = Get-JiraVersion -Project $projectKey | Set-JiraVersion -Name "NewName" -ErrorAction Stop
                    $results | Should -Not -BeNullOrEmpty
                    $results.PSObject.TypeNames[0] | Should -Be 'AtlassianPSVII.JiraPSVII.Version'
                    Should -Invoke 'Get-JiraVersion' -Times 2 -ModuleName JiraPSVII -Exactly
                    Should -Invoke 'Get-JiraProject' -Times 0 -ModuleName JiraPSVII -Exactly
                    Should -Invoke 'ConvertTo-JiraVersion' -Times 3 -ModuleName JiraPSVII -Exactly
                    Should -Invoke 'Invoke-JiraMethod' -Times 1 -ModuleName JiraPSVII -Exactly -ParameterFilter { $Method -eq 'Put' -and $URI -like "/rest/api/*/version/$versionID" }
                }

                It "rejects a name-only Version stub where an ID is required" {
                    { Set-JiraVersion -Version ([AtlassianPSVII.JiraPSVII.Version]::new('My Version')) -Name 'NewName' -ErrorAction Stop } |
                        Should -Throw '*version ID*'

                    Should -Invoke 'Invoke-JiraMethod' -Times 0 -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Put' }
                }
            }
        }

        Describe "Cloud Deployment" {
            BeforeEach {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Put' -and $URI -eq "/rest/api/3/version/$versionID"
                } {
                    ConvertFrom-Json $testJsonOne
                }
            }

            It "uses REST API v3 instead of a returned legacy self link" {
                Set-JiraVersion -Version $versionID -Name 'Cloud name' | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq "/rest/api/3/version/$versionID"
                }
            }

            It "does not send an update request with WhatIf" {
                Set-JiraVersion -Version $versionID -Name 'Cloud name' -WhatIf

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0 -ParameterFilter {
                    $URI -eq "/rest/api/3/version/$versionID"
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
