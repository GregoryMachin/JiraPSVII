#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "ConvertTo-JiraOAuthResource" -Tag 'Unit' {
        It "converts validated accessible-resource metadata to a typed object" {
            $result = [PSCustomObject]@{
                id        = '11223344-a1b2-3b33-c444-def123456789'
                name      = 'Example site'
                url       = 'https://example.atlassian.net'
                scopes    = @('read:jira-work', 'read:jira-user')
                avatarUrl = 'https://avatar-management--avatars.us-west-2.prod.public.atl-paas.net/site.png'
            } | ConvertTo-JiraOAuthResource

            $result | Should -BeOfType [AtlassianPSVII.JiraPSVII.OAuthResource]
            $result.CloudId | Should -Be '11223344-a1b2-3b33-c444-def123456789'
            $result.Url.AbsoluteUri | Should -Be 'https://example.atlassian.net/'
            $result.Scopes | Should -Be @('read:jira-work', 'read:jira-user')
        }

        It "rejects a malformed Cloud ID returned by the server" {
            $resource = [PSCustomObject]@{ id = '../other'; name = 'Bad'; url = 'https://example.atlassian.net'; scopes = @() }

            { $resource | ConvertTo-JiraOAuthResource } | Should -Throw '*CloudId must be a UUID*'
        }

        It "rejects a non-Atlassian site URL returned by the server" {
            $resource = [PSCustomObject]@{
                id     = '11223344-a1b2-3b33-c444-def123456789'
                name   = 'Bad'
                url    = 'https://attacker.example'
                scopes = @()
            }

            { $resource | ConvertTo-JiraOAuthResource } | Should -Throw '*OAuth site URLs must be HTTPS root URLs*'
        }
    }
}
