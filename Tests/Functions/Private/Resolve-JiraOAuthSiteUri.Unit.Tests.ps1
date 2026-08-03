#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraOAuthSiteUri" -Tag 'Unit' {
        It "normalizes a trusted Atlassian Cloud site URL" {
            (Resolve-JiraOAuthSiteUri -SiteUrl 'https://Example.atlassian.net').AbsoluteUri |
                Should -Be 'https://example.atlassian.net/'
        }

        It "rejects untrusted site URLs" -TestCases @(
            @{ Value = 'http://example.atlassian.net' }
            @{ Value = 'https://example.atlassian.net.attacker.example' }
            @{ Value = 'https://user@example.atlassian.net' }
            @{ Value = 'https://example.atlassian.net:8443' }
            @{ Value = 'https://example.atlassian.net/wiki' }
            @{ Value = 'https://example.atlassian.net/?token=secret' }
        ) {
            param($Value)

            { Resolve-JiraOAuthSiteUri -SiteUrl $Value } | Should -Throw '*OAuth site URLs must be HTTPS root URLs*'
        }
    }
}
