#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraIssueWorklog" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:issueID = 41701
            $script:issueKey = 'IT-3676'

            $script:restResult = @"
{
    "startAt": 0,
    "maxResults": 1,
    "total": 1,
    "worklogs": [
        {
            "self": "$jiraServer/rest/api/2/issue/$issueID/worklog/90730",
            "id": "90730",
            "comment": "Test comment",
            "created": "2015-05-01T16:24:38.000-0500",
            "updated": "2015-05-01T16:24:38.000-0500",
            "visibility": {
                "type": "role",
                "value": "Developers"
            },
            "timeSpent": "3m",
            "timeSpentSeconds": 180
        }
    ]
}
"@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock Get-JiraIssue -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraIssue' 'Key'
                $object = [AtlassianPSVII.JiraPSVII.Issue]@{
                    ID      = $issueID
                    Key     = $issueKey
                    RestUrl = "$jiraServer/rest/api/2/issue/$issueID"
                }
                return $object
            }

            Mock Resolve-JiraIssueObject -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Resolve-JiraIssueObject' 'InputObject'
                Get-JiraIssue -Key $InputObject.Key
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                (ConvertFrom-Json -InputObject $restResult).worklogs
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
                It "Obtains all Jira worklogs from a Jira issue if the issue key is provided" {
                    $worklogs = Get-JiraIssueWorklog -Issue $issueKey

                    $worklogs | Should -Not -BeNullOrEmpty
                    @($worklogs) | Should -HaveCount 1
                    $worklogs.ID | Should -Be 90730
                    $worklogs.Comment | Should -Be 'Test comment'
                    $worklogs.TimeSpent | Should -Be '3m'
                    $worklogs.TimeSpentSeconds | Should -Be 180

                    # Get-JiraIssue should be called to identify the -Issue parameter
                    Should -Invoke Get-JiraIssue -ModuleName JiraPSVII -Exactly -Times 1

                    # Normally, this would be called once in Get-JiraIssue and a second time in Get-JiraIssueComment, but
                    # since we've mocked Get-JiraIssue out, it will only be called once.
                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1
                }

                It "Obtains all Jira worklogs from a Jira issue if the Jira object is provided" {
                    $issue = Get-JiraIssue -Key $issueKey
                    $worklogs = Get-JiraIssueWorklog -Issue $issue

                    $worklogs | Should -Not -BeNullOrEmpty
                    $worklogs.ID | Should -Be 90730

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1
                }

                It "Handles pipeline input from Get-JiraIssue" {
                    $worklogs = Get-JiraIssue -Key $issueKey | Get-JiraIssueWorklog

                    $worklogs | Should -Not -BeNullOrEmpty
                    $worklogs.ID | Should -Be 90730

                    Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1
                }
            }
        }

        Describe "Deployment routing" {
            It "uses v2 for Data Center and the shared default page size" {
                $null = Get-JiraIssueWorklog -Issue $issueKey

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq "$jiraServer/rest/api/2/issue/$issueID/worklog" -and
                    $GetParameter['maxResults'] -eq $script:DefaultPageSize -and
                    $GetParameter['expand'] -eq 'properties'
                }
            }

            It "uses v3 for Cloud even when the issue object contains a v2 self link" {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $URI -eq "$jiraServer/rest/api/3/issue/$issueID/worklog"
                } { (ConvertFrom-Json -InputObject $restResult).worklogs }

                $null = Get-JiraIssueWorklog -Issue $issueKey

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq "$jiraServer/rest/api/3/issue/$issueID/worklog"
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
