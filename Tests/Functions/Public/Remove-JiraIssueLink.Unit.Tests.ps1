#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Remove-JiraIssueLink" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueLinkId = 1234
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssueLink -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraIssueLink' 'Id'
                [AtlassianPSVII.JiraPSVII.IssueLink]@{
                    Id = $issueLinkId
                }
            }

            Mock Get-JiraIssue -ModuleName JiraPSVII -ParameterFilter { $Key -eq "TEST-01" } {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                # We don't care about the content of any field except for the id of the issuelinks
                $issue = [AtlassianPSVII.JiraPSVII.Issue]@{
                    Key        = 'TEST-01'
                    IssueLinks = [AtlassianPSVII.JiraPSVII.IssueLink[]]@(
                        [AtlassianPSVII.JiraPSVII.IssueLink]::new('1234')
                    )
                }
                return $issue
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                if ($InputObject.Key -eq 'TEST-01') {
                    return [AtlassianPSVII.JiraPSVII.Issue]@{
                        Key        = 'TEST-01'
                        IssueLinks = [AtlassianPSVII.JiraPSVII.IssueLink[]]@(
                            [AtlassianPSVII.JiraPSVII.IssueLink]::new('1234')
                        )
                    }
                }
                $InputObject
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Delete' -and $URI -like "/rest/api/*/issueLink/1234" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
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
                $script:command = Get-Command -Name Remove-JiraIssueLink
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'IssueLink'; type = 'AtlassianPSVII.JiraPSVII.IssueLink[]' }
                    @{ parameter = 'Issue'; type = 'AtlassianPSVII.JiraPSVII.Issue[]' }
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
            Context "Issue Link Deletion" {
                It "Accepts typed Issue and IssueLink objects" {
                    $issueLink = Get-JiraIssueLink -Id 1234
                    $issue = Get-JiraIssue -Key TEST-01
                    { Remove-JiraIssueLink -IssueLink $issueLink } | Should -Not -Throw
                    { Remove-JiraIssueLink -Issue $issue } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 2
                }

                It "Accepts a AtlassianPSVII.JiraPSVII.Issue object over the pipeline" {
                    { Get-JiraIssue -Key TEST-01 | Remove-JiraIssueLink } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }

                It "Resolves string stubs passed to -Issue" {
                    { Remove-JiraIssueLink -Issue 'TEST-01' } | Should -Not -Throw
                    Should -Invoke -CommandName Resolve-JiraIssueObject -Exactly -Times 1 -ParameterFilter { $InputObject.Key -eq 'TEST-01' }
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }

                It "Accepts an AtlassianPSVII.JiraPSVII.IssueLink over the pipeline" {
                    { Get-JiraIssueLink -Id 1234 | Remove-JiraIssueLink } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                # TODO: Add positive input validation tests
            }

            Context "Negative cases" {
                It "Validates pipeline input" {
                    { @{ id = 1 } | Remove-JiraIssueLink -ErrorAction Stop } | Should -Throw -ExpectedMessage "*Cannot convert value of type*IssueLink*"
                }
            }
        }
    }
}
