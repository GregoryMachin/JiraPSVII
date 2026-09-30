#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Resolve-JiraOAuthResource" -Tag 'Unit' {
        BeforeAll {
            $script:resources = @(
                [AtlassianPSVII.JiraPSVII.OAuthResource]@{
                    CloudId = '11223344-a1b2-3b33-c444-def123456789'
                    Name    = 'Shared name'
                    Url     = 'https://one.atlassian.net/'
                }
                [AtlassianPSVII.JiraPSVII.OAuthResource]@{
                    CloudId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
                    Name    = 'Shared name'
                    Url     = 'https://two.atlassian.net/'
                }
            )
        }

        It "returns no resources for an empty discovery response" {
            @(Resolve-JiraOAuthResource -Resource @()) | Should -HaveCount 0
        }

        It "returns one discovered resource" {
            @(Resolve-JiraOAuthResource -Resource @($resources[0])) | Should -HaveCount 1
        }

        It "returns multiple discovered resources without choosing by response order" {
            @(Resolve-JiraOAuthResource -Resource $resources) | Should -HaveCount 2
        }

        It "selects by exact Cloud ID" {
            (Resolve-JiraOAuthResource -Resource $resources -CloudId $resources[1].CloudId).Url.Host |
                Should -Be 'two.atlassian.net'
        }

        It "selects by normalized site URL" {
            (Resolve-JiraOAuthResource -Resource $resources -SiteUrl 'https://ONE.atlassian.net').CloudId |
                Should -Be $resources[0].CloudId
        }

        It "rejects duplicate display names instead of trusting them as identifiers" {
            { Resolve-JiraOAuthResource -Resource $resources -SiteName 'Shared name' } |
                Should -Throw '*More than one accessible Jira OAuth resource matched*'
        }

        It "reports an unmatched selector" {
            { Resolve-JiraOAuthResource -Resource $resources -SiteName 'Missing' } |
                Should -Throw '*No accessible Jira OAuth resource matched*'
        }

        It "rejects multiple selectors" {
            { Resolve-JiraOAuthResource -Resource $resources -CloudId $resources[0].CloudId -SiteName 'Shared name' } |
                Should -Throw '*Specify only one OAuth resource selector*'
        }
    }
}
