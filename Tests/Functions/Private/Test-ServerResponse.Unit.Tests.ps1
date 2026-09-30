#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Test-ServerResponse" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:sleepSeconds = $null
            Mock Start-Sleep -ModuleName JiraPSVII {
                $script:sleepSeconds = $Seconds
            }
        }

        BeforeEach {
            $script:sleepSeconds = $null
        }

        Describe "Rate Limit Handling (HTTP 429)" {
            It "returns `$true when status code is 429 and retries remain" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3
                $result | Should -BeTrue
            }

            It "sleeps before signaling retry" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -JitterFactor 1

                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPSVII -Exactly -Times 1
            }

            It "respects the Retry-After header with jitter applied" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{ 'Retry-After' = '10' }
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -JitterFactor 1

                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPSVII -Exactly -Times 1
                $script:sleepSeconds | Should -Be 10
            }

            It "uses exponential backoff with jitter when Retry-After is absent" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -JitterFactor 1
                $script:sleepSeconds | Should -Be 20

                $null = Test-ServerResponse -InputObject $response -RetryCount 1 -MaxRetries 3 -JitterFactor 1
                $script:sleepSeconds | Should -Be 40

                $null = Test-ServerResponse -InputObject $response -RetryCount 2 -MaxRetries 3 -JitterFactor 1
                $script:sleepSeconds | Should -Be 60
            }

            It "caps delay at 60 seconds maximum" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{ 'Retry-After' = '120' }
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -JitterFactor 1

                $script:sleepSeconds | Should -Be 60
            }

            It "handles malformed Retry-After values by falling back to exponential backoff" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{ 'Retry-After' = 'not-a-date' }
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -JitterFactor 1

                $script:sleepSeconds | Should -Be 20
            }

            It "does not signal retry when max retries are exhausted" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response -RetryCount 3 -MaxRetries 3
                $result | Should -BeNullOrEmpty
            }

            It "does not sleep when max retries are exhausted" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 3 -MaxRetries 3

                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPSVII -Exactly -Times 0
            }

            It "emits a warning on 429" {
                $response = [PSCustomObject]@{
                    StatusCode = 429
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match '429'
            }
        }

        Describe "Service Unavailable Handling (HTTP 503)" {
            It "returns `$true when status code is 503 and retries remain" {
                $response = [PSCustomObject]@{
                    StatusCode = 503
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3
                $result | Should -BeTrue
            }

            It "sleeps before signaling retry for 503" {
                $response = [PSCustomObject]@{
                    StatusCode = 503
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3

                Should -Invoke -CommandName Start-Sleep -ModuleName JiraPSVII -Exactly -Times 1
            }

            It "emits a warning on 503" {
                $response = [PSCustomObject]@{
                    StatusCode = 503
                    Headers    = @{}
                }

                $null = Test-ServerResponse -InputObject $response -RetryCount 0 -MaxRetries 3 -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Match '503'
            }

            It "does not signal retry for 503 when max retries are exhausted" {
                $response = [PSCustomObject]@{
                    StatusCode = 503
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response -RetryCount 3 -MaxRetries 3
                $result | Should -BeNullOrEmpty
            }
        }

        Describe "Non-Recoverable Responses" {
            It "returns nothing for a successful response" {
                $response = [PSCustomObject]@{
                    StatusCode = 200
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response
                $result | Should -BeNullOrEmpty
            }

            It "returns nothing for a 500 error (not recoverable)" {
                $response = [PSCustomObject]@{
                    StatusCode = 500
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response
                $result | Should -BeNullOrEmpty
            }

            It "returns nothing for a 404 error" {
                $response = [PSCustomObject]@{
                    StatusCode = 404
                    Headers    = @{}
                }

                $result = Test-ServerResponse -InputObject $response
                $result | Should -BeNullOrEmpty
            }

            It "returns nothing for a null response" {
                $result = Test-ServerResponse -InputObject $null
                $result | Should -BeNullOrEmpty
            }
        }
    }
}
