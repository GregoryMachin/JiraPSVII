#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Resolve-JiraResponseTelemetry" -Tag 'Unit' {
        BeforeEach {
            $script:JiraLastResponseTelemetry = $null
        }

        It "parses request id, retry, rate-limit, deprecation, and sunset headers case-insensitively" {
            $response = [PSCustomObject]@{
                Headers = @{
                    'x-arequestid'                 = "req-123`r`nignored"
                    'retry-after'                  = '10'
                    'x-ratelimit-limit'            = '500'
                    'x-ratelimit-remaining'        = '25'
                    'x-ratelimit-fillrate'         = '50'
                    'x-ratelimit-interval-seconds' = '60'
                    'x-ratelimit-reset'            = '2026-07-29T00:00:00Z'
                    'ratelimit-reason'             = 'jira-cost-based'
                    'deprecation'                  = 'true'
                    'sunset'                       = 'Wed, 01 Nov 2026 00:00:00 GMT'
                    'deprecation-link'             = '<https://developer.atlassian.com/>; rel="deprecation"'
                    'authorization'                = 'Bearer secret'
                }
            }

            $telemetry = Resolve-JiraResponseTelemetry -InputObject $response -WarningAction SilentlyContinue

            $telemetry.RequestId | Should -Be 'req-123 ignored'
            $telemetry.RetryAfterSeconds | Should -Be 10
            $telemetry.RateLimit.Limit | Should -Be '500'
            $telemetry.RateLimit.Remaining | Should -Be '25'
            $telemetry.RateLimit.Reason | Should -Be 'jira-cost-based'
            $telemetry.Deprecation | Should -Be 'true'
            $telemetry.Sunset | Should -Be 'Wed, 01 Nov 2026 00:00:00 GMT'
            $telemetry.DeprecationLink | Should -Match 'developer.atlassian.com'
            ($telemetry | Out-String) | Should -Not -Match 'secret'
            $script:JiraLastResponseTelemetry.RequestId | Should -Be 'req-123 ignored'
        }

        It "does not throw for malformed Retry-After dates" {
            $response = [PSCustomObject]@{
                Headers = @{
                    'Retry-After' = 'not-a-date'
                }
            }

            { Resolve-JiraResponseTelemetry -InputObject $response } | Should -Not -Throw
            $script:JiraLastResponseTelemetry.RetryAfterSeconds | Should -BeNullOrEmpty
        }

        It "emits warnings for sunset and deprecation metadata without following links" {
            $response = [PSCustomObject]@{
                Headers = @{
                    'Sunset'           = 'Wed, 01 Nov 2026 00:00:00 GMT'
                    'Deprecation'      = 'true'
                    'Deprecation-Link' = 'https://developer.atlassian.com/deprecation'
                }
            }

            $null = Resolve-JiraResponseTelemetry -InputObject $response -WarningVariable warnings

            @($warnings).Count | Should -Be 2
            ($warnings | Out-String) | Should -Match 'Sunset'
            ($warnings | Out-String) | Should -Match 'deprecation'
        }
    }
}
