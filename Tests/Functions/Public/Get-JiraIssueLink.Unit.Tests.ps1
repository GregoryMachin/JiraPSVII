#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraIssueLink" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueLinkId = 1234

            # We don't care about anything except for the id
            $script:resultsJson = @"
{
    "id": "$issueLinkId",
    "self": "",
    "type": {},
    "inwardIssue": {},
    "outwardIssue": {}
}
"@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "/rest/api/2/issueLink/1234" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json $resultsJson
            }

            Mock Get-JiraIssue -ModuleName JiraPSVII -ParameterFilter { $Key -eq "TEST-01" } {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                # We don't care about the content of any field except for the id
                $obj = [PSCustomObject]@{
                    "id"          = $issueLinkId
                    "type"        = "foo"
                    "inwardIssue" = "bar"
                }
                $obj.PSObject.TypeNames.Insert(0, 'JiraPSVII.IssueLink')
                return [PSCustomObject]@{
                    issueLinks = @(
                        $obj
                    )
                }
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Get-JiraIssueLink
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = "Id"; type = "Int32[]" }
                    @{ parameter = "Credential"; type = "System.Management.Automation.PSCredential" }
                ) {
                    $command | Should -HaveParameter $parameter
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Returns details about specific issuelink" {
                $result = Get-JiraIssueLink -Id $issueLinkId
                $result | Should -Not -BeNullOrEmpty
                @($result) | Should -HaveCount 1
            }

            It "Provides the key of the project" {
                $result = Get-JiraIssueLink -Id $issueLinkId
                $result.Id | Should -Be $issueLinkId
            }

            It "Accepts input from pipeline" {
                $result = (Get-JiraIssue -Key TEST-01).issuelinks | Get-JiraIssueLink
                $result.Id | Should -Be $issueLinkId
            }

            It 'Fails if input from the pipeline is of the wrong type' {
                { [PSCustomObject]@{id = $issueLinkId } | Get-JiraIssueLink } | Should -Throw -ExpectedMessage "*Invalid Parameter*"
            }

            It "uses v3 for Cloud" {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $URI -eq '/rest/api/3/issueLink/1234'
                } { ConvertFrom-Json $resultsJson }

                $null = Get-JiraIssueLink -Id $issueLinkId

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/3/issueLink/1234'
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
