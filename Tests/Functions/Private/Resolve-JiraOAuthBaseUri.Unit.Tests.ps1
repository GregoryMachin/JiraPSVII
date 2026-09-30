#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Resolve-JiraOAuthBaseUri" -Tag 'Unit' {
        It "constructs the fixed Atlassian Jira OAuth base route" {
            $result = Resolve-JiraOAuthBaseUri -CloudId '11223344-a1b2-3b33-c444-def123456789'

            $result | Should -BeOfType [Uri]
            $result.AbsoluteUri | Should -Be 'https://api.atlassian.com/ex/jira/11223344-a1b2-3b33-c444-def123456789'
        }

        It "normalizes UUID casing" {
            (Resolve-JiraOAuthBaseUri -CloudId 'AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE').AbsoluteUri |
                Should -Be 'https://api.atlassian.com/ex/jira/aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
        }

        It "rejects invalid Cloud IDs" -TestCases @(
            @{ Value = 'not-a-uuid' }
            @{ Value = '../other-site' }
            @{ Value = '11223344a1b23b33c444def123456789' }
        ) {
            param($Value)

            { Resolve-JiraOAuthBaseUri -CloudId $Value } | Should -Throw '*CloudId must be a UUID*'
        }
    }
}
