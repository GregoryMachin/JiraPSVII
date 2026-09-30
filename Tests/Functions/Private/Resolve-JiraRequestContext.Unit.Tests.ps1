#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Resolve-JiraRequestContext" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            function script:Invoke-ResolveJiraRequestContext {
                [CmdletBinding(SupportsPaging)]
                param(
                    [Parameter(Mandatory)]
                    [Uri]
                    $Uri,

                    [Hashtable]
                    $GetParameter = @{},

                    [ValidateRange(1, [int]::MaxValue)]
                    [int]
                    $DefaultPageSize = 25
                )

                Resolve-JiraRequestContext -Uri $Uri -GetParameter $GetParameter -DefaultPageSize $DefaultPageSize -Cmdlet $PSCmdlet
            }
        }

        BeforeEach {
            $script:JiraServerMetadata = @{}
        }

        It "resolves a relative URI against the configured Jira server and applies default page size" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPSVII' { 'https://jira.example.com' }

            $result = Invoke-ResolveJiraRequestContext -Uri '/rest/api/2/search'

            $result.Uri.AbsoluteUri | Should -Be 'https://jira.example.com/rest/api/2/search'
            $result.PaginatedUri.AbsoluteUri | Should -Match '\?maxResults=25$'
        }

        It "merges URI query and -GetParameter with caller values taking precedence" {
            $result = Invoke-ResolveJiraRequestContext -Uri 'https://jira.example.com/rest/api/2/search?jql=fromUri' -GetParameter @{ jql = 'fromArg'; expand = 'names' }

            $result.Uri.Query | Should -BeNullOrEmpty
            $result.PaginatedUri.AbsoluteUri | Should -Match 'jql=fromArg'
            $result.PaginatedUri.AbsoluteUri | Should -Match 'expand=names'
            $result.PaginatedUri.AbsoluteUri | Should -Match 'maxResults=25'
        }

        It "applies paging overrides from the caller cmdlet" {
            $result = Invoke-ResolveJiraRequestContext -Uri 'https://jira.example.com/rest/api/2/search' -First 5 -Skip 2

            $result.PaginatedUri.AbsoluteUri | Should -Match 'maxResults=5'
            $result.PaginatedUri.AbsoluteUri | Should -Match 'startAt=2'
        }

        It "preserves existing maxResults when -First is larger" {
            $result = Invoke-ResolveJiraRequestContext -Uri 'https://jira.example.com/rest/api/2/search?maxResults=10' -First 25

            $result.PaginatedUri.AbsoluteUri | Should -Match 'maxResults=10'
        }

        It "throws for relative URIs that do not start with '/'" {
            { Invoke-ResolveJiraRequestContext -Uri 'hello' } | Should -Throw -ExpectedMessage "*must start with '/'*"
        }

        It "throws when a relative URI is used without a configured Jira server" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPSVII' { $null }

            { Invoke-ResolveJiraRequestContext -Uri '/rest/api/2/search' } | Should -Throw -ExpectedMessage "*no Jira server is configured*"
        }

        It "throws when resolving a relative URI still results in a non-absolute URI" {
            Mock Get-JiraConfigServer -ModuleName 'JiraPSVII' { 'jira.example.com' }

            { Invoke-ResolveJiraRequestContext -Uri '/rest/api/2/search' } | Should -Throw -ExpectedMessage "*must be an absolute URI*"
        }

        It "routes relative OAuth requests through api.atlassian.com and the configured Cloud ID" {
            $script:JiraServerMetadata = @{
                DeploymentType     = 'Cloud'
                AuthenticationType = 'OAuth'
                CloudId            = '11223344-a1b2-3b33-c444-def123456789'
            }
            Mock Get-JiraConfigServer -ModuleName 'JiraPSVII' { 'https://example.atlassian.net' }

            $result = Invoke-ResolveJiraRequestContext -Uri '/rest/api/3/myself'

            $result.Uri.AbsoluteUri | Should -Be 'https://api.atlassian.com/ex/jira/11223344-a1b2-3b33-c444-def123456789/rest/api/3/myself'
        }

        It "routes relative scoped API-token requests through api.atlassian.com and the configured Cloud ID" {
            $script:JiraServerMetadata = @{
                DeploymentType     = 'Cloud'
                AuthenticationType = 'ApiToken'
                CloudId            = '11223344-a1b2-3b33-c444-def123456789'
            }
            Mock Get-JiraConfigServer -ModuleName 'JiraPSVII' { 'https://example.atlassian.net' }

            $result = Invoke-ResolveJiraRequestContext -Uri '/rest/api/3/project/search'

            $result.Uri.AbsoluteUri | Should -Be 'https://api.atlassian.com/ex/jira/11223344-a1b2-3b33-c444-def123456789/rest/api/3/project/search'
        }

        It "rejects an absolute OAuth request to a non-Atlassian host" {
            $script:JiraServerMetadata = @{
                DeploymentType     = 'Cloud'
                AuthenticationType = 'OAuth'
                CloudId            = '11223344-a1b2-3b33-c444-def123456789'
            }

            { Invoke-ResolveJiraRequestContext -Uri 'https://attacker.example/rest/api/3/myself' } |
                Should -Throw '*restricted to the configured Jira Cloud ID*'
        }

        It "rejects an absolute OAuth request for a different Cloud ID" {
            $script:JiraServerMetadata = @{
                DeploymentType     = 'Cloud'
                AuthenticationType = 'OAuth'
                CloudId            = '11223344-a1b2-3b33-c444-def123456789'
            }

            { Invoke-ResolveJiraRequestContext -Uri 'https://api.atlassian.com/ex/jira/aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee/rest/api/3/myself' } |
                Should -Throw '*restricted to the configured Jira Cloud ID*'
        }

        It "permits the Atlassian accessible-resources endpoint during an OAuth session" {
            $script:JiraServerMetadata = @{
                DeploymentType     = 'Cloud'
                AuthenticationType = 'OAuth'
                CloudId            = '11223344-a1b2-3b33-c444-def123456789'
            }

            $result = Invoke-ResolveJiraRequestContext -Uri 'https://api.atlassian.com/oauth/token/accessible-resources'

            $result.Uri.AbsoluteUri | Should -Be 'https://api.atlassian.com/oauth/token/accessible-resources'
        }

        It "rejects token values in URI query parameters" -TestCases @(
            @{ Uri = 'https://jira.example.com/rest/api/3/myself?access_token=secret'; GetParameter = @{} }
            @{ Uri = 'https://jira.example.com/rest/api/3/myself'; GetParameter = @{ OAuthAccessToken = 'secret' } }
            @{ Uri = 'https://jira.example.com/rest/api/3/myself'; GetParameter = @{ Authorization = 'Bearer secret' } }
        ) {
            param($Uri, $GetParameter)

            { Invoke-ResolveJiraRequestContext -Uri $Uri -GetParameter $GetParameter } |
                Should -Throw '*tokens are not permitted in URI query parameters*'
        }

        It "does not mistake nextPageToken for an authentication token" {
            $result = Invoke-ResolveJiraRequestContext -Uri 'https://jira.example.com/rest/api/3/search/jql' -GetParameter @{ nextPageToken = 'page-token' }

            $result.PaginatedUri.AbsoluteUri | Should -Match 'nextPageToken=page-token'
        }
    }
}
