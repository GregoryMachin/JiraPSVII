#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Remove-JiraRemoteLink" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testIssueKey = 'EX-1'

            $script:testLink = @"
{
    "id": 10000,
    "self": "http://www.example.com/jira/rest/api/issue/MKY-1/remotelink/10000",
    "globalId": "system=http://www.mycompany.com/support&id=1",
    "application": {
        "type": "com.acme.tracker",
        "name": "My Acme Tracker"
    },
    "relationship": "causes",
    "object": {
        "url": "http://www.mycompany.com/support?id=1",
        "title": "TSTSUP-111",
        "summary": "Crazy customer support issue",
        "icon": {
            "url16x16": "http://www.mycompany.com/support/ticket.png",
            "title": "Support Ticket"
        }
    }
}
"@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraIssue {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [AtlassianPSVII.JiraPSVII.Issue]@{
                    RestURL = 'https://jira.example.com/rest/api/2/issue/12345'
                    Key     = $testIssueKey
                }
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Get-JiraRemoteLink {
                Write-MockDebugInfo 'Get-JiraRemoteLink' 'Issue'
                $object = ConvertFrom-Json $testLink
                $object.PSObject.TypeNames.Insert(0, 'JiraPSVII.IssueLinkType')
                return $object
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'DELETE' } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                # This REST method should produce no output
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
                $script:command = Get-Command -Name Remove-JiraRemoteLink
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Issue'; type = 'AtlassianPSVII.JiraPSVII.Issue' }
                    @{ parameter = 'LinkId'; type = 'Int32[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'Force'; type = 'Switch' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Remote Link Deletion" {
                It "Accepts a issue key to the -Issue parameter" {
                    { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }

                It "Accepts a AtlassianPSVII.JiraPSVII.Issue object to the -Issue parameter" {
                    $Issue = Get-JiraIssue $testIssueKey
                    { Remove-JiraRemoteLink -Issue $Issue -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }

                It "Accepts pipeline input from Get-JiraIssue" {
                    { Get-JiraIssue $testIssueKey | Remove-JiraRemoteLink -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }

                It "Accepts the output of Get-JiraRemoteLink" {
                    $issue = [AtlassianPSVII.JiraPSVII.Issue]@{ Key = $testIssueKey }
                    $remoteLink = Get-JiraRemoteLink $issue
                    { Remove-JiraRemoteLink -Issue $issue -LinkId $remoteLink.id -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }

                It "Removes a group from JIRA" {
                    { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should -Not -Throw
                    Should -Invoke -CommandName Invoke-JiraMethod -Exactly -Times 1
                }

                It "Provides no output" {
                    Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force | Should -BeNullOrEmpty
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {
                It "rejects non-positive remote link IDs" {
                    { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 0 -Force } | Should -Throw -ExpectedMessage "*'LinkId'*"
                }
            }
        }

        Describe "Deployment routing and safety" {
            It "retains the Data Center REST API v2 route" {
                Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $Method -eq 'Delete' -and $URI -eq "/rest/api/2/issue/$testIssueKey/remotelink/10000"
                }
            }

            Context "Jira Cloud" {
                BeforeEach {
                    Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                }

                It "uses the REST API v3 route" {
                    Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                        $Method -eq 'Delete' -and $URI -eq "/rest/api/3/issue/$testIssueKey/remotelink/10000"
                    }
                }

                It "does not send a delete request with WhatIf" {
                    Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -WhatIf

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0
                }

                It "propagates permission failures" {
                    Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                        $Method -eq 'Delete' -and $URI -eq "/rest/api/3/issue/$testIssueKey/remotelink/10000"
                    } { throw 'Forbidden' }

                    { Remove-JiraRemoteLink -Issue $testIssueKey -LinkId 10000 -Force } | Should -Throw -ExpectedMessage '*Forbidden*'
                }
            }
        }
    }
}
