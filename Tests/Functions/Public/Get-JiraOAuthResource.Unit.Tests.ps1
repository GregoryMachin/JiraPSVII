#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraOAuthResource" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            $script:testToken = ConvertTo-SecureString 'oauth-token-secret' -AsPlainText -Force
            $script:wireResources = @(
                [PSCustomObject]@{
                    id        = '11223344-a1b2-3b33-c444-def123456789'
                    name      = 'One'
                    url       = 'https://one.atlassian.net'
                    scopes    = @('read:jira-work')
                    avatarUrl = 'https://avatar-management--avatars.us-west-2.prod.public.atl-paas.net/one.png'
                }
                [PSCustomObject]@{
                    id        = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'
                    name      = 'Two'
                    url       = 'https://two.atlassian.net'
                    scopes    = @('read:jira-user')
                    avatarUrl = $null
                }
            )

            Mock Get-JiraSession -ModuleName JiraPS {
                [AtlassianPS.JiraPS.Session]@{
                    WebSession         = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
                    AuthenticationType = 'OAuth'
                    CloudId            = '11223344-a1b2-3b33-c444-def123456789'
                }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and $Uri -eq 'https://api.atlassian.com/oauth/token/accessible-resources'
            } { $wireResources }
            Mock Invoke-JiraMethod -ModuleName JiraPS { throw "Unidentified call to Invoke-JiraMethod: $Method $Uri" }
            Mock Invoke-WebRequest -ModuleName JiraPS { throw 'Get-JiraOAuthResource must use Invoke-JiraMethod.' }
        }

        BeforeEach {
            $script:JiraOAuthResourceCache = $null
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command Get-JiraOAuthResource
            }

            It "has parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = 'OAuthAccessToken'; type = 'SecureString' }
                @{ parameter = 'CloudId'; type = 'String' }
                @{ parameter = 'SiteName'; type = 'String' }
                @{ parameter = 'SiteUrl'; type = 'Uri' }
                @{ parameter = 'CacheExpiry'; type = 'TimeSpan' }
                @{ parameter = 'BypassCache'; type = 'SwitchParameter' }
            ) {
                param($parameter, $type)

                $command | Should -HaveParameter $parameter
                $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
            }
        }

        Describe "Discovery and selection" {
            It "discovers typed resources with an explicit access token" {
                $result = @(Get-JiraOAuthResource -OAuthAccessToken $testToken)

                $result | Should -HaveCount 2
                $result[0] | Should -BeOfType [AtlassianPS.JiraPS.OAuthResource]
                $result[0].CloudId | Should -Be $wireResources[0].id
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $Uri -eq 'https://api.atlassian.com/oauth/token/accessible-resources' -and
                    $Headers.Authorization -eq 'Bearer oauth-token-secret'
                }
            }

            It "selects one site by Cloud ID" {
                $result = Get-JiraOAuthResource -OAuthAccessToken $testToken -CloudId $wireResources[1].id

                $result.Url.Host | Should -Be 'two.atlassian.net'
            }

            It "selects one site by URL" {
                $result = Get-JiraOAuthResource -OAuthAccessToken $testToken -SiteUrl 'https://ONE.atlassian.net'

                $result.CloudId | Should -Be $wireResources[0].id
            }

            It "rejects duplicate display-name selection" {
                $duplicateResources = @(
                    $wireResources[0]
                    [PSCustomObject]@{
                        id = $wireResources[1].id; name = 'One'; url = $wireResources[1].url; scopes = @()
                    }
                )
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Uri -eq 'https://api.atlassian.com/oauth/token/accessible-resources'
                } { $duplicateResources }

                { Get-JiraOAuthResource -OAuthAccessToken $testToken -SiteName 'One' } |
                    Should -Throw '*More than one accessible Jira OAuth resource matched*'
            }

            It "returns no objects when the token has no accessible resources" {
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Uri -eq 'https://api.atlassian.com/oauth/token/accessible-resources'
                } { @() }

                @(Get-JiraOAuthResource -OAuthAccessToken $testToken) | Should -HaveCount 0
            }

            It "rejects multiple selectors before making a request" {
                { Get-JiraOAuthResource -OAuthAccessToken $testToken -CloudId $wireResources[0].id -SiteName One } |
                    Should -Throw '*Specify only one OAuth resource selector*'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 0
            }
        }

        Describe "Cache and revoked access" {
            It "caches only validated non-secret site metadata" {
                $null = Get-JiraOAuthResource

                $script:JiraOAuthResourceCache.Data | Should -HaveCount 2
                $script:JiraOAuthResourceCache.Data[0] | Should -BeOfType [AtlassianPS.JiraPS.OAuthResource]
                ($script:JiraOAuthResourceCache | ConvertTo-Json -Depth 5) | Should -Not -Match 'oauth-token-secret|Authorization'
            }

            It "does not make explicit-token metadata reusable by the current session" {
                $script:JiraOAuthResourceCache = @{
                    Data   = [AtlassianPS.JiraPS.OAuthResource[]]@()
                    Expiry = (Get-Date).AddMinutes(5)
                }

                Get-JiraOAuthResource -OAuthAccessToken $testToken | Should -HaveCount 2

                $script:JiraOAuthResourceCache | Should -BeNullOrEmpty
            }

            It "uses unexpired metadata for the current OAuth session" {
                $script:JiraOAuthResourceCache = @{
                    Data   = [AtlassianPS.JiraPS.OAuthResource[]]@(
                        [AtlassianPS.JiraPS.OAuthResource]@{
                            CloudId = $wireResources[0].id; Name = 'Cached'; Url = 'https://one.atlassian.net/'
                        }
                    )
                    Expiry = (Get-Date).AddMinutes(5)
                }

                $result = Get-JiraOAuthResource

                $result.Name | Should -Be 'Cached'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 0
            }

            It "refreshes expired metadata with the current OAuth session" {
                $script:JiraOAuthResourceCache = @{
                    Data   = [AtlassianPS.JiraPS.OAuthResource[]]@()
                    Expiry = (Get-Date).AddSeconds(-1)
                }

                Get-JiraOAuthResource -CacheExpiry ([TimeSpan]::FromMinutes(7)) | Should -HaveCount 2

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1
                $script:JiraOAuthResourceCache.Expiry | Should -BeGreaterThan (Get-Date).AddMinutes(6)
            }

            It "bypasses unexpired metadata when requested" {
                $script:JiraOAuthResourceCache = @{
                    Data   = [AtlassianPS.JiraPS.OAuthResource[]]@()
                    Expiry = (Get-Date).AddMinutes(5)
                }

                Get-JiraOAuthResource -BypassCache | Should -HaveCount 2

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1
            }

            It "clears stale metadata and propagates revoked-token failures" {
                $script:JiraOAuthResourceCache = @{ Data = @('stale'); Expiry = (Get-Date).AddMinutes(5) }
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Uri -eq 'https://api.atlassian.com/oauth/token/accessible-resources'
                } { throw 'Unauthorized: token expired or revoked' }

                { Get-JiraOAuthResource -OAuthAccessToken $testToken } | Should -Throw '*expired or revoked*'
                $script:JiraOAuthResourceCache | Should -BeNullOrEmpty
            }
        }

        Describe "Security" {
            It "requires an explicit token or current OAuth session" {
                Mock Get-JiraSession -ModuleName JiraPS { $null }

                { Get-JiraOAuthResource } | Should -Throw '*Provide OAuthAccessToken or create an OAuth session*'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 0
            }

            It "does not return cached metadata without a current OAuth session" {
                $script:JiraOAuthResourceCache = @{
                    Data   = [AtlassianPS.JiraPS.OAuthResource[]]@(
                        [AtlassianPS.JiraPS.OAuthResource]@{
                            CloudId = $wireResources[0].id; Name = 'Cached'; Url = 'https://one.atlassian.net/'
                        }
                    )
                    Expiry = (Get-Date).AddMinutes(5)
                }
                Mock Get-JiraSession -ModuleName JiraPS { $null }

                { Get-JiraOAuthResource } | Should -Throw '*Provide OAuthAccessToken or create an OAuth session*'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 0
            }

            It "rejects malformed server resource metadata" {
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Uri -eq 'https://api.atlassian.com/oauth/token/accessible-resources'
                } {
                    [PSCustomObject]@{
                        id = $wireResources[0].id; name = 'Bad'; url = 'https://attacker.example'; scopes = @()
                    }
                }

                { Get-JiraOAuthResource -OAuthAccessToken $testToken } |
                    Should -Throw '*OAuth site URLs must be HTTPS root URLs*'
                $script:JiraOAuthResourceCache | Should -BeNullOrEmpty
            }

            It "does not disclose the token in debug output" {
                $debugOutput = Get-JiraOAuthResource -OAuthAccessToken $testToken -Debug 5>&1 | Out-String

                $debugOutput | Should -Not -Match 'oauth-token-secret'
            }

            It "uses shared transport rather than calling Invoke-WebRequest directly" {
                $null = Get-JiraOAuthResource -OAuthAccessToken $testToken

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1
                Should -Invoke Invoke-WebRequest -ModuleName JiraPS -Exactly 0
            }
        }
    }
}
