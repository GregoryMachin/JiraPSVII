#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "New-JiraWebRequestSplat" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        }

        AfterEach {
            $script:JiraServerMetadata = @{}
            $script:JiraOAuthClientCredentials = $null
        }

        It "defaults ContentType only when a body is supplied" {
            Mock Get-JiraSession -ModuleName 'JiraPS' { $null }

            $withBody = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/issue' -Method Post -Headers @{} -Body '{}' -DefaultContentType 'application/json; charset=utf-8'
            $withoutBody = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/issue' -Method Post -Headers @{} -InFile './attachment.bin' -DefaultContentType 'application/json; charset=utf-8'

            $withBody.ContentType | Should -Be 'application/json; charset=utf-8'
            $withoutBody.ContainsKey('ContentType') | Should -BeFalse
        }

        It "honors explicit Content-Type header and removes it from Headers" {
            Mock Get-JiraSession -ModuleName 'JiraPS' { $null }

            $headers = @{
                'Content-Type' = 'text/plain'
                'X-Trace'      = 'abc123'
            }
            $result = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/issue' -Method Post -Headers $headers -Body '{}'

            $result.ContentType | Should -Be 'text/plain'
            $result.Headers['X-Trace'] | Should -Be 'abc123'
            $result.Headers.ContainsKey('Content-Type') | Should -BeFalse
        }

        It "uses SessionVariable and drops WebSession when -StoreSession is set" {
            Mock Get-JiraSession -ModuleName 'JiraPS' {
                [PSCustomObject]@{
                    WebSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
                }
            }

            $result = New-JiraWebRequestSplat -Uri 'https://jira.example.com/rest/api/2/myself' -Method Get -Headers @{} -StoreSession

            $result.SessionVariable | Should -Be 'newSessionVar'
            $result.ContainsKey('WebSession') | Should -BeFalse
        }

        It "renews OAuth client-credentials tokens and adds the Authorization header" {
            $webSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
            Mock Get-JiraSession -ModuleName 'JiraPS' {
                [PSCustomObject]@{
                    WebSession         = $webSession
                    AuthenticationType = 'OAuth'
                    CloudId            = '11223344-a1b2-3b33-c444-def123456789'
                }
            }
            Mock Request-JiraOAuthClientCredentialsToken -ModuleName 'JiraPS' {
                [PSCustomObject]@{
                    AccessToken = ConvertTo-SecureString 'renewed-token' -AsPlainText -Force
                    ExpiresAt   = [DateTimeOffset]::UtcNow.AddHours(1)
                    RefreshAt   = [DateTimeOffset]::UtcNow.AddMinutes(55)
                    TokenType   = 'Bearer'
                    Scopes      = @('read:jira-work')
                }
            }

            $script:JiraServerMetadata = @{
                DeploymentType     = 'Cloud'
                AuthenticationType = 'OAuth'
                CloudId            = '11223344-a1b2-3b33-c444-def123456789'
            }
            $script:JiraOAuthClientCredentials = @{
                ClientId     = 'client-id'
                ClientSecret = ConvertTo-SecureString 'client-secret' -AsPlainText -Force
                AccessToken  = $null
                ExpiresAt    = [DateTimeOffset]::UtcNow.AddMinutes(-1)
                RefreshAt    = [DateTimeOffset]::UtcNow.AddMinutes(-5)
                RefreshSkew  = [TimeSpan]::FromMinutes(5)
            }

            $result = New-JiraWebRequestSplat -Uri 'https://api.atlassian.com/ex/jira/11223344-a1b2-3b33-c444-def123456789/rest/api/3/project/search' -Method Get -Headers @{}

            $result.Headers.Authorization | Should -Be 'Bearer renewed-token'
            $webSession.Headers.Authorization | Should -Be 'Bearer renewed-token'
            Should -Invoke Request-JiraOAuthClientCredentialsToken -ModuleName JiraPS -Exactly 1
        }
    }
}
