#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraJqlApproximateCount" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            Mock Test-JiraJql -ModuleName JiraPSVII {
                [AtlassianPSVII.JiraPSVII.JqlValidationResult]@{
                    Query   = $Query
                    IsValid = ($Query -ne 'invalid query')
                    Errors  = [String[]]@($(if ($Query -eq 'invalid query') { 'Invalid JQL' }))
                }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $Method -eq 'Post' -and $URI -eq '/rest/api/3/search/approximate-count'
            } {
                $queryText = ($Body | ConvertFrom-Json).jql
                $count = switch ($queryText) {
                    'project = EMPTY' { 0 }
                    'project = LARGE' { 5000000000 }
                    default { 42 }
                }
                [PSCustomObject]@{ count = $count }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
            Mock Invoke-WebRequest -ModuleName JiraPSVII {
                throw 'Commands must use Invoke-JiraMethod instead of calling Invoke-WebRequest directly.'
            }
        }

        It "validates first and returns a typed permission-scoped approximate count" {
            $result = Get-JiraJqlApproximateCount -Query 'project = TEST'

            $result.GetType().FullName | Should -Be 'AtlassianPSVII.JiraPSVII.JqlApproximateCountResult'
            $result.Count | Should -Be 42
            $result.IsValid | Should -BeTrue
            $result.IsApproximate | Should -BeTrue
            $result.PermissionScoped | Should -BeTrue
            Should -Invoke Test-JiraJql -ModuleName JiraPSVII -Exactly 1
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                $URI -eq '/rest/api/3/search/approximate-count'
            }
        }

        It "does not call the count endpoint for invalid JQL" {
            $result = Get-JiraJqlApproximateCount -Query 'invalid query'

            $result.IsValid | Should -BeFalse
            $result.Count | Should -BeNullOrEmpty
            $result.Errors | Should -Contain 'Invalid JQL'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0
        }

        It "supports zero and counts larger than Int32" {
            $results = Get-JiraJqlApproximateCount -Query 'project = EMPTY', 'project = LARGE'

            $results[0].Count | Should -Be 0
            $results[1].Count | Should -Be 5000000000
            $results[1].Count.GetType().FullName | Should -Be 'System.Int64'
        }

        It "keeps account-ID and Unicode JQL in the JSON body rather than the URI" {
            $queryText = 'assignee = "557058:12345678-1234-1234-1234-123456789abc" AND summary ~ "Māori"'

            Get-JiraJqlApproximateCount -Query $queryText

            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                ($Body | ConvertFrom-Json).jql -eq $queryText -and
                $URI -eq '/rest/api/3/search/approximate-count' -and
                $URI -notmatch '557058|Māori'
            }
        }

        It "uses Invoke-JiraMethod so shared 429 and 503 retry policy remains active" {
            Get-JiraJqlApproximateCount -Query 'project = TEST'

            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                $Method -eq 'Post' -and $URI -eq '/rest/api/3/search/approximate-count'
            }
            Should -Invoke Invoke-WebRequest -ModuleName JiraPSVII -Exactly 0
        }

        It "propagates permission failures" {
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $URI -eq '/rest/api/3/search/approximate-count'
            } { throw 'Forbidden' }

            { Get-JiraJqlApproximateCount -Query 'project = TEST' } | Should -Throw -ExpectedMessage '*Forbidden*'
        }

        It "rejects Data Center explicitly without validating or counting" {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            { Get-JiraJqlApproximateCount -Query 'project = TEST' } | Should -Throw -ExpectedMessage '*only on Jira Cloud*'
            Should -Invoke Test-JiraJql -ModuleName JiraPSVII -Exactly 0
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0
        }
    }
}
