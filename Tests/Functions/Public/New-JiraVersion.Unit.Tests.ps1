#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "New-JiraVersion" -Tag 'Unit' {
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
    "self" : "$jiraServer/rest/api/2/version/$versionID",
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
                Write-MockDebugInfo 'Get-JiraProject'
                $Projects = ConvertFrom-Json $JiraProjectData
                $Projects | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Project') }
                $Projects | Where-Object { $_.Key -in $projectKey }
            }

            Mock Get-JiraVersion -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraVersion'
                $Version = [PSCustomObject]@{
                    Name        = "v1"
                    Description = "My Desccription"
                    Project     = (Get-JiraProject -Project $projectKey)
                    ReleaseDate = (Get-Date "2017-12-01")
                    StartDate   = (Get-Date "2017-01-01")
                    RestUrl     = "$jiraServer/rest/api/2/version/$versionID"
                }
                $Version.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Version')
                $Version
            }

            Mock ConvertTo-JiraVersion -ModuleName JiraPSVII {
                Write-MockDebugInfo 'ConvertTo-JiraVersion'
                $result = New-Object -TypeName PSObject -Property @{
                    Id      = $InputObject.Id
                    Name    = $InputObject.name
                    Project = $InputObject.projectId
                    self    = "$jiraServer/rest/api/2/version/$($InputObject.self)"
                }
                $result.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Version')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/*/version" } {
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
                $script:command = Get-Command -Name New-JiraVersion
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'InputObject'; type = 'Version' }
                    @{ parameter = 'Name'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'Archived'; type = 'Boolean' }
                    @{ parameter = 'Released'; type = 'Boolean' }
                    @{ parameter = 'ReleaseDate'; type = 'DateTime' }
                    @{ parameter = 'StartDate'; type = 'DateTime' }
                    @{ parameter = 'Project'; type = 'Project' }
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
            It "creates a Version from a Version Object" {
                $version = Get-JiraVersion -Project $projectKey
                $results = $version | New-JiraVersion -ErrorAction Stop
                $results | Should -Not -BeNullOrEmpty
                $results.PSObject.TypeNames[0] | Should -Be "AtlassianPSVII.JiraPSVII.Version"
                Should -Invoke 'Invoke-JiraMethod' -Times 1 -Exactly -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/2/version" }
                Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -Exactly -ModuleName JiraPSVII
            }
            It "creates a Version using parameters" {
                $results = New-JiraVersion -Name $versionName -Project $projectKey -ErrorAction Stop
                $results | Should -Not -BeNullOrEmpty
                $results.PSObject.TypeNames[0] | Should -Be "AtlassianPSVII.JiraPSVII.Version"
                Should -Invoke 'Invoke-JiraMethod' -Times 1 -Exactly -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/2/version" }
                Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -Exactly -ModuleName JiraPSVII
            }
            It "creates a Version using splatting" {
                $password = (ConvertTo-SecureString -AsPlainText -Force -String "password")
                $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("username", $password)
                $splat = @{
                    Name        = "v1"
                    Description = "A Description"
                    Archived    = $false
                    Released    = $true
                    ReleaseDate = "2017-12-01"
                    StartDate   = "2017-01-01"
                    Project     = (Get-JiraProject -Project $projectKey)
                    Credential  = $credentials
                }
                $results = New-JiraVersion @splat -ErrorAction Stop
                $results | Should -Not -BeNullOrEmpty
                $results.PSObject.TypeNames[0] | Should -Be "AtlassianPSVII.JiraPSVII.Version"
                Should -Invoke 'Invoke-JiraMethod' -Times 1 -Exactly -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Post' -and $URI -like "/rest/api/2/version" }
                Should -Invoke 'ConvertTo-JiraVersion' -Times 1 -Exactly -ModuleName JiraPSVII
            }
        }

        Describe "Cloud Deployment" {
            BeforeEach {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Post' -and $URI -eq '/rest/api/3/version'
                } {
                    ConvertFrom-Json $testJsonOne
                }
            }

            It "uses REST API v3 for version creation" {
                New-JiraVersion -Name $versionName -Project $projectKey | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/3/version'
                }
            }

            It "does not send a create request with WhatIf" {
                New-JiraVersion -Name $versionName -Project $projectKey -WhatIf

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0 -ParameterFilter {
                    $URI -eq '/rest/api/3/version'
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
