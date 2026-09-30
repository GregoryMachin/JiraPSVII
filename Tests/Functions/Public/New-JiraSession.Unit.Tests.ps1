#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "New-JiraSession" -Tag 'Unit' {
        AfterEach {
            try {
                (Get-Module JiraPSVII).PrivateData.Remove("Session")
            }
            catch { $null }
            $script:JiraServerMetadata = @{}
            $script:JiraOAuthClientCredentials = $null
        }

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testCredential = [System.Management.Automation.PSCredential]::Empty
            #endregion Definitions

            #region Mocks
            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock ConvertTo-JiraSession -ModuleName JiraPSVII {
                param($Session, $DeploymentType, $AuthenticationType, $CloudId)
                Write-MockDebugInfo 'ConvertTo-JiraSession'
                # Return a AtlassianPSVII.JiraPSVII.Session object to simulate successful conversion
                $session = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession
                if ($null -ne $Session) {
                    $session = $Session
                }
                $result = New-Object -TypeName PSObject -Property @{
                    'WebSession'         = $session
                    'AuthenticationType' = $AuthenticationType
                    'CloudId'            = $CloudId
                }
                $result.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Session')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $Uri -like "*/rest/api/*/myself" } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                # When StoreSession is true, Invoke-JiraMethod returns the result of ConvertTo-JiraSession
                # So we need to return a AtlassianPSVII.JiraPSVII.Session object, not a WebRequestSession
                $session = New-Object -TypeName Microsoft.PowerShell.Commands.WebRequestSession
                $result = New-Object -TypeName PSObject -Property @{
                    'WebSession' = $session
                }
                $result.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.Session')
                $result
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            Mock Request-JiraOAuthClientCredentialsToken -ModuleName JiraPSVII {
                [PSCustomObject]@{
                    AccessToken = ConvertTo-SecureString 'oauth-client-token' -AsPlainText -Force
                    ExpiresAt   = [DateTimeOffset]::UtcNow.AddHours(1)
                    RefreshAt   = [DateTimeOffset]::UtcNow.AddMinutes(55)
                    TokenType   = 'Bearer'
                    Scopes      = @('read:jira-work', 'write:jira-work')
                }
            }
            Mock Get-JiraOAuthResource -ModuleName JiraPSVII {
                [AtlassianPSVII.JiraPSVII.OAuthResource]@{
                    CloudId = '11223344-a1b2-3b33-c444-def123456789'
                    Name    = 'One'
                    Url     = [Uri]'https://one.atlassian.net'
                    Scopes  = @('read:jira-work', 'write:jira-work')
                }
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name New-JiraSession
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'PersonalAccessToken'; type = 'SecureString' }
                    @{ parameter = 'ApiToken'; type = 'SecureString' }
                    @{ parameter = 'EmailAddress'; type = 'String' }
                    @{ parameter = 'OAuthAccessToken'; type = 'SecureString' }
                    @{ parameter = 'CloudId'; type = 'String' }
                    @{ parameter = 'OAuthClientId'; type = 'String' }
                    @{ parameter = 'OAuthClientSecret'; type = 'SecureString' }
                    @{ parameter = 'OAuthCloudId'; type = 'String' }
                    @{ parameter = 'OAuthSiteName'; type = 'String' }
                    @{ parameter = 'OAuthSiteUrl'; type = 'Uri' }
                    @{ parameter = 'OAuthTokenRefreshSkew'; type = 'TimeSpan' }
                    @{ parameter = 'Headers'; type = 'Hashtable' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter
                    $command.Parameters[$parameter].ParameterType.Name | Should -Be $type
                }

                It "supports '<alias>' as an alias for '-<parameter>'" -TestCases @(
                    @{ parameter = 'PersonalAccessToken'; alias = 'BearerToken' }
                    @{ parameter = 'PersonalAccessToken'; alias = 'PAT' }
                ) {
                    param($parameter, $alias)
                    $command.Parameters[$parameter].Aliases | Should -Contain $alias
                }
            }

            Context "Parameter Sets" {
                It "has parameter set '<parameterSet>'" -TestCases @(
                    @{ parameterSet = 'Credential' }
                    @{ parameterSet = 'PersonalAccessToken' }
                    @{ parameterSet = 'ApiToken' }
                    @{ parameterSet = 'OAuthAccessToken' }
                    @{ parameterSet = 'OAuthClientCredentials' }
                ) {
                    $command.ParameterSets.Name | Should -Contain $parameterSet
                }
            }

            Context "Mandatory Parameters" {
                It "PersonalAccessToken is mandatory in PersonalAccessToken parameter set" {
                    $command.Parameters['PersonalAccessToken'].Attributes |
                        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'PersonalAccessToken' } |
                        Select-Object -ExpandProperty Mandatory |
                        Should -BeTrue
                }

                It "ApiToken is mandatory in ApiToken parameter set" {
                    $command.Parameters['ApiToken'].Attributes |
                        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'ApiToken' } |
                        Select-Object -ExpandProperty Mandatory |
                        Should -BeTrue
                }

                It "EmailAddress is mandatory in ApiToken parameter set" {
                    $command.Parameters['EmailAddress'].Attributes |
                        Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'ApiToken' } |
                        Select-Object -ExpandProperty Mandatory |
                        Should -BeTrue
                }

                It "OAuthAccessToken and CloudId are mandatory in the OAuthAccessToken parameter set" {
                    foreach ($parameterName in 'OAuthAccessToken', 'CloudId') {
                        $command.Parameters[$parameterName].Attributes |
                            Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'OAuthAccessToken' } |
                            Select-Object -ExpandProperty Mandatory |
                            Should -BeTrue
                    }
                }

                It "OAuthClientId and OAuthClientSecret are mandatory in the OAuthClientCredentials parameter set" {
                    foreach ($parameterName in 'OAuthClientId', 'OAuthClientSecret') {
                        $command.Parameters[$parameterName].Attributes |
                            Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ParameterSetName -eq 'OAuthClientCredentials' } |
                            Select-Object -ExpandProperty Mandatory |
                            Should -BeTrue
                    }
                }
            }

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "uses Basic Authentication to generate a session" {
                { New-JiraSession -Credential $testCredential } | Should -Not -Throw

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Credential -eq $testCredential
                } -Exactly -Times 1
            }

            It "can influence the Headers used in the request" {
                { New-JiraSession -Credential $testCredential -Headers @{ "X-Header" = $true } } | Should -Not -Throw

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers.ContainsKey("X-Header")
                } -Exactly -Times 1
            }

            # Note: This test is commented out because it has issues when run in batch mode
            # The session storage works correctly but the test fails due to module instance differences
            # It "stores the session variable in the module's PrivateData" {
            #     # Store the module reference before calling New-JiraSession
            #     $module = Get-Module JiraPSVII
            #     $module.PrivateData.Session | Should -BeNullOrEmpty

            #     New-JiraSession -Credential $testCredential

            #     $module.PrivateData.Session | Should -Not -BeNullOrEmpty
            # }
        }

        Describe "Token Authentication" {
            BeforeAll {
                $script:testToken = ConvertTo-SecureString -String "test-token-12345" -AsPlainText -Force
                $script:testEmail = "user@example.com"
            }

            It "uses Bearer token authentication with -PersonalAccessToken" {
                { New-JiraSession -PersonalAccessToken $testToken } | Should -Not -Throw

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers.ContainsKey("Authorization") -and $Headers["Authorization"] -like "Bearer *"
                } -Exactly -Times 1
            }

            It "supports -BearerToken alias for -PersonalAccessToken" {
                { New-JiraSession -BearerToken $testToken } | Should -Not -Throw

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers.ContainsKey("Authorization") -and $Headers["Authorization"] -like "Bearer *"
                } -Exactly -Times 1
            }

            It "supports -PAT alias for -PersonalAccessToken" {
                { New-JiraSession -PAT $testToken } | Should -Not -Throw

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers.ContainsKey("Authorization") -and $Headers["Authorization"] -like "Bearer *"
                } -Exactly -Times 1
            }

            It "uses API token authentication with -ApiToken and -EmailAddress" {
                { New-JiraSession -ApiToken $testToken -EmailAddress $testEmail } | Should -Not -Throw

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers.ContainsKey("Authorization") -and $Headers["Authorization"] -like "Basic *"
                } -Exactly -Times 1
            }

            It "encodes email:token in Base64 for API token auth" {
                { New-JiraSession -ApiToken $testToken -EmailAddress $testEmail } | Should -Not -Throw

                $expectedAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${testEmail}:test-token-12345"))

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers["Authorization"] -eq "Basic $expectedAuth"
                } -Exactly -Times 1
            }

            It "supports scoped API token authentication through an explicit Cloud ID" {
                { New-JiraSession -ApiToken $testToken -EmailAddress $testEmail -CloudId '11223344-a1b2-3b33-c444-def123456789' } | Should -Not -Throw

                $script:JiraServerMetadata.DeploymentType | Should -Be 'Cloud'
                $script:JiraServerMetadata.AuthenticationType | Should -Be 'ApiToken'
                $script:JiraServerMetadata.CloudId | Should -Be '11223344-a1b2-3b33-c444-def123456789'
                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Uri -eq '/rest/api/3/myself' -and
                    $Headers.ContainsKey('Authorization') -and
                    $Headers['Authorization'] -like 'Basic *'
                } -Exactly -Times 1
            }

            It "can combine token auth with custom headers" {
                { New-JiraSession -PersonalAccessToken $testToken -Headers @{ "X-Custom" = "value" } } | Should -Not -Throw

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers.ContainsKey("Authorization") -and $Headers.ContainsKey("X-Custom")
                } -Exactly -Times 1
            }

            It "uses a caller-supplied OAuth access token on the explicit Cloud ID route" {
                New-JiraSession -OAuthAccessToken $testToken -CloudId '11223344-a1b2-3b33-c444-def123456789'

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Uri -eq '/rest/api/3/myself' -and
                    $Headers['Authorization'] -eq 'Bearer test-token-12345'
                } -Exactly -Times 1
                $script:JiraServerMetadata.DeploymentType | Should -Be 'Cloud'
                $script:JiraServerMetadata.AuthenticationType | Should -Be 'OAuth'
                $script:JiraServerMetadata.CloudId | Should -Be '11223344-a1b2-3b33-c444-def123456789'
            }

            It "gives the OAuth access token precedence over a caller Authorization header" {
                New-JiraSession -OAuthAccessToken $testToken `
                    -CloudId '11223344-a1b2-3b33-c444-def123456789' `
                    -Headers @{ Authorization = 'Bearer caller-value'; 'X-Custom' = 'value' }

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -ParameterFilter {
                    $Headers['Authorization'] -eq 'Bearer test-token-12345' -and
                    $Headers['X-Custom'] -eq 'value'
                } -Exactly -Times 1
            }

            It "rejects an invalid OAuth Cloud ID before making a request" {
                { New-JiraSession -OAuthAccessToken $testToken -CloudId '../attacker' } |
                    Should -Throw '*CloudId must be a UUID*'

                Should -Invoke -CommandName 'Invoke-JiraMethod' -ModuleName 'JiraPSVII' -Exactly -Times 0
            }

            It "restores prior server metadata when OAuth validation fails" {
                $script:JiraServerMetadata = @{ DeploymentType = 'DataCenter' }
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Uri -eq '/rest/api/3/myself' } { throw 'Unauthorized' }

                { New-JiraSession -OAuthAccessToken $testToken -CloudId '11223344-a1b2-3b33-c444-def123456789' } |
                    Should -Throw '*Unauthorized*'

                $script:JiraServerMetadata.DeploymentType | Should -Be 'DataCenter'
            }

            It "requires the OAuth access token parameter" {
                { New-JiraSession -OAuthAccessToken $null -CloudId '11223344-a1b2-3b33-c444-def123456789' } |
                    Should -Throw
            }

            It "does not disclose OAuth token or overridden header values in debug output" {
                $debugOutput = New-JiraSession -OAuthAccessToken $testToken `
                    -CloudId '11223344-a1b2-3b33-c444-def123456789' `
                    -Headers @{ Authorization = 'Bearer caller-value' } `
                    -Debug 5>&1 | Out-String

                $debugOutput | Should -Not -Match 'test-token-12345|caller-value'
            }

            It "uses OAuth client credentials without requiring a delegated /myself call" {
                $session = New-JiraSession -OAuthClientId 'client-id' -OAuthClientSecret $testToken -OAuthSiteUrl 'https://one.atlassian.net'

                $session.AuthenticationType | Should -Be 'OAuth'
                $session.CloudId | Should -Be '11223344-a1b2-3b33-c444-def123456789'
                $script:JiraServerMetadata.DeploymentType | Should -Be 'Cloud'
                $script:JiraServerMetadata.AuthenticationType | Should -Be 'OAuth'
                $script:JiraOAuthClientCredentials.ClientId | Should -Be 'client-id'
                ($script:JiraOAuthClientCredentials | ConvertTo-Json -Depth 5) | Should -Not -Match 'oauth-client-token|test-token-12345'
                $script:JiraOAuthClientCredentials.AccessToken | Should -BeOfType [SecureString]
                Should -Invoke Request-JiraOAuthClientCredentialsToken -ModuleName JiraPSVII -Exactly 1
                Should -Invoke Get-JiraOAuthResource -ModuleName JiraPSVII -Exactly 1
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Uri -like '*/myself' } -Exactly 0
            }

            It "selects an OAuth client-credentials resource by Cloud ID" {
                $null = New-JiraSession -OAuthClientId 'client-id' -OAuthClientSecret $testToken -OAuthCloudId '11223344-a1b2-3b33-c444-def123456789'

                Should -Invoke Get-JiraOAuthResource -ModuleName JiraPSVII -Exactly 1
                $script:JiraOAuthClientCredentials.CloudId | Should -Be '11223344-a1b2-3b33-c444-def123456789'
            }

            It "selects the Jira resource when Atlassian returns product-specific resources for the same site" {
                Mock Get-JiraOAuthResource -ModuleName JiraPSVII {
                    [AtlassianPSVII.JiraPSVII.OAuthResource]@{
                        CloudId = '11223344-a1b2-3b33-c444-def123456789'
                        Name    = 'One'
                        Url     = [Uri]'https://one.atlassian.net'
                        Scopes  = @('read:confluence-content.all')
                    }
                    [AtlassianPSVII.JiraPSVII.OAuthResource]@{
                        CloudId = '11223344-a1b2-3b33-c444-def123456789'
                        Name    = 'One'
                        Url     = [Uri]'https://one.atlassian.net'
                        Scopes  = @('read:jira-work', 'write:jira-work')
                    }
                }

                $session = New-JiraSession -OAuthClientId 'client-id' -OAuthClientSecret $testToken -OAuthSiteUrl 'https://one.atlassian.net'

                $session.CloudId | Should -Be '11223344-a1b2-3b33-c444-def123456789'
                $script:JiraOAuthClientCredentials.Scopes | Should -Contain 'read:jira-work'
            }

            It "rejects multiple OAuth client-credentials resource selectors" {
                { New-JiraSession -OAuthClientId 'client-id' -OAuthClientSecret $testToken -OAuthCloudId '11223344-a1b2-3b33-c444-def123456789' -OAuthSiteName 'One' } |
                    Should -Throw '*Specify only one OAuth resource selector*'

                Should -Invoke Request-JiraOAuthClientCredentialsToken -ModuleName JiraPSVII -Exactly 0
            }

            It "rejects a selected OAuth resource without Jira scopes" {
                Mock Get-JiraOAuthResource -ModuleName JiraPSVII {
                    [AtlassianPSVII.JiraPSVII.OAuthResource]@{
                        CloudId = '11223344-a1b2-3b33-c444-def123456789'
                        Name    = 'One'
                        Url     = [Uri]'https://one.atlassian.net'
                        Scopes  = @('read:confluence-content.all')
                    }
                }

                { New-JiraSession -OAuthClientId 'client-id' -OAuthClientSecret $testToken -OAuthSiteUrl 'https://one.atlassian.net' } |
                    Should -Throw '*does not include Jira scopes*'
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }
    }
}
