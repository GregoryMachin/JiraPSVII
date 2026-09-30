#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Test-JiraJql" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $Method -eq 'Post' -and $URI -eq '/rest/api/3/jql/parse'
            } {
                $bodyObject = $Body | ConvertFrom-Json
                [PSCustomObject]@{
                    queries = @(
                        foreach ($queryText in $bodyObject.queries) {
                            if ($queryText -eq 'invalid query') {
                                [PSCustomObject]@{ errors = @("Expected an operator but got 'query'.") }
                            }
                            else {
                                [PSCustomObject]@{
                                    query     = $queryText
                                    structure = [PSCustomObject]@{ where = [PSCustomObject]@{ operator = '=' } }
                                }
                            }
                        }
                    )
                }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
        }

        It "returns typed structured results for valid and invalid JQL" {
            $results = Test-JiraJql -Query 'project = TEST', 'invalid query'

            @($results) | Should -HaveCount 2
            $results[0].GetType().FullName | Should -Be 'AtlassianPSVII.JiraPSVII.JqlValidationResult'
            $results[0].IsValid | Should -BeTrue
            $results[0].Errors | Should -BeNullOrEmpty
            $results[1].IsValid | Should -BeFalse
            $results[1].Errors[0] | Should -Match 'Expected an operator'
        }

        It "preserves account IDs, Unicode, and injection-like text only in the JSON body" {
            $queries = @(
                'assignee = "557058:12345678-1234-1234-1234-123456789abc"'
                'summary ~ "Māori 日本語"'
                'summary ~ "x\" } ; DELETE FROM issues; --"'
            )

            $results = Test-JiraJql -Query $queries -Validation Warn

            $results.Query | Should -Be $queries
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                $URI -eq '/rest/api/3/jql/parse' -and
                $GetParameter.validation -eq 'warn' -and
                ($Body | ConvertFrom-Json).queries[2] -eq $queries[2] -and
                $URI -notmatch 'DELETE|Māori|557058'
            }
        }

        It "batches pipeline input into one parse request" {
            'project = A', 'project = B' | Test-JiraJql | Should -HaveCount 2

            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1
        }

        It "propagates permission and authentication failures" {
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $URI -eq '/rest/api/3/jql/parse'
            } { throw 'Unauthorized' }

            { Test-JiraJql -Query 'project = TEST' } | Should -Throw -ExpectedMessage '*Unauthorized*'
        }

        It "rejects Data Center explicitly without making a request" {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            { Test-JiraJql -Query 'project = TEST' } | Should -Throw -ExpectedMessage '*only on Jira Cloud*'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0
        }
    }
}
