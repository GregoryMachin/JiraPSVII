#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Invoke-PaginatedRequest" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            #endregion Definitions
        }

        Describe "Null Response Handling" {
            # When Invoke-JiraMethod returns null during pagination (auth failure,
            # server error, etc.), the function should stop gracefully with a warning
            # instead of crashing with "Cannot bind argument to parameter 'InputObject'".

            BeforeAll {
                # Initial response with results
                $script:initialResponse = [PSCustomObject]@{
                    issues     = @(
                        [PSCustomObject]@{ key = 'TEST-1' }
                        [PSCustomObject]@{ key = 'TEST-2' }
                    )
                    startAt    = 0
                    maxResults = 2
                    total      = 10
                }

                # Mock Invoke-JiraMethod to return null on second call (simulating failure)
                $script:callCount = 0
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    $script:callCount++
                    if ($script:callCount -eq 1) {
                        return $null  # Simulates auth failure or server error
                    }
                    return $null
                }
            }

            BeforeEach {
                $script:callCount = 0
            }

            It "does not throw when Invoke-JiraMethod returns null" {
                $params = @{
                    URI      = "$jiraServer/rest/api/2/search"
                    Method   = 'GET'
                    Response = $initialResponse
                }

                { Invoke-PaginatedRequest @params -WarningAction SilentlyContinue } | Should -Not -Throw
            }

            It "writes a warning when null response is received" {
                $params = @{
                    URI      = "$jiraServer/rest/api/2/search"
                    Method   = 'GET'
                    Response = $initialResponse
                }

                # Capture warnings using -WarningVariable (no $ prefix for target variable)
                $null = Invoke-PaginatedRequest @params -WarningVariable capturedWarnings

                $capturedWarnings | Should -Not -BeNullOrEmpty
                $capturedWarnings | Should -Match 'null response'
            }

            It "stops pagination and returns collected results" {
                # First page has 2 issues, second call returns null
                $script:pageCallCount = 0
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    $script:pageCallCount++
                    if ($script:pageCallCount -gt 1) {
                        return $null
                    }
                    return [PSCustomObject]@{
                        issues     = @([PSCustomObject]@{ key = "TEST-$script:pageCallCount" })
                        startAt    = 0
                        maxResults = 1
                        total      = 5
                    }
                }

                $params = @{
                    URI      = "$jiraServer/rest/api/2/search"
                    Method   = 'GET'
                    Response = [PSCustomObject]@{
                        issues     = @([PSCustomObject]@{ key = 'TEST-0' })
                        startAt    = 0
                        maxResults = 1
                        total      = 5
                    }
                }

                $result = Invoke-PaginatedRequest @params -WarningAction SilentlyContinue

                # Should have the initial result from Response parameter
                $result | Should -Not -BeNullOrEmpty
            }
        }

        Describe "Generalized pagination" {
            BeforeEach {
                $script:capturedGetParameters = @()
                $script:pageIndex = 0
            }

            It "paginates token responses using configurable item and token property names" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    $script:capturedGetParameters += $GetParameter.Clone()
                    [PSCustomObject]@{
                        values        = @([PSCustomObject]@{ id = 2 })
                        nextPageToken = $null
                        isLast        = $true
                    }
                }

                $response = [PSCustomObject]@{
                    values        = @([PSCustomObject]@{ id = 1 })
                    nextPageToken = 'opaque-token-1'
                    isLast        = $false
                }

                $result = Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/3/example" -Response $response -ItemPropertyName values

                $result.id | Should -Be @(1, 2)
                $script:capturedGetParameters[0]['nextPageToken'] | Should -Be 'opaque-token-1'
            }

            It "continues past empty token pages when a continuation token is present" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    $script:pageIndex++
                    if ($script:pageIndex -eq 1) {
                        return [PSCustomObject]@{
                            values        = @([PSCustomObject]@{ id = 2 })
                            nextPageToken = $null
                            isLast        = $true
                        }
                    }
                }

                $response = [PSCustomObject]@{
                    values        = @()
                    nextPageToken = 'next-after-empty'
                    isLast        = $false
                }

                $result = Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/3/example" -Response $response -ItemPropertyName values

                $result.id | Should -Be 2
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -Scope It
            }

            It "stops on repeated token values" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    [PSCustomObject]@{
                        values        = @([PSCustomObject]@{ id = 2 })
                        nextPageToken = 'same-token'
                        isLast        = $false
                    }
                }

                $response = [PSCustomObject]@{
                    values        = @([PSCustomObject]@{ id = 1 })
                    nextPageToken = 'same-token'
                    isLast        = $false
                }

                $result = Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/3/example" -Response $response -ItemPropertyName values -WarningVariable warnings

                $result.id | Should -Be @(1, 2)
                $warnings | Should -Match 'Repeated pagination token'
            }

            It "stops immediately when completion property is true even if a token exists" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    throw 'should not request another page'
                }

                $response = [PSCustomObject]@{
                    issues        = @([PSCustomObject]@{ key = 'TEST-1' })
                    nextPageToken = 'ignored-token'
                    isLast        = $true
                }

                $result = Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/3/search" -Response $response

                $result.key | Should -Be 'TEST-1'
                Should -Invoke -CommandName Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 -Scope It
            }

            It "honors -First across token pages" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    [PSCustomObject]@{
                        values        = @([PSCustomObject]@{ id = 3 }, [PSCustomObject]@{ id = 4 })
                        nextPageToken = 'unused'
                        isLast        = $false
                    }
                }

                $response = [PSCustomObject]@{
                    values        = @([PSCustomObject]@{ id = 1 }, [PSCustomObject]@{ id = 2 })
                    nextPageToken = 'page-2'
                    isLast        = $false
                }

                $result = Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/3/example" -Response $response -ItemPropertyName values -First 3

                $result.id | Should -Be @(1, 2, 3)
            }

            It "honors -Skip across token pages" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    [PSCustomObject]@{
                        values        = @([PSCustomObject]@{ id = 3 }, [PSCustomObject]@{ id = 4 })
                        nextPageToken = $null
                        isLast        = $true
                    }
                }

                $response = [PSCustomObject]@{
                    values        = @([PSCustomObject]@{ id = 1 }, [PSCustomObject]@{ id = 2 })
                    nextPageToken = 'page-2'
                    isLast        = $false
                }

                $result = Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/3/example" -Response $response -ItemPropertyName values -Skip 2

                $result.id | Should -Be @(3, 4)
            }

            It "preserves offset pagination for total-less responses" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    $script:capturedGetParameters += $GetParameter.Clone()
                    [PSCustomObject]@{
                        issues     = @([PSCustomObject]@{ key = 'TEST-3' })
                        startAt    = 2
                        maxResults = 2
                    }
                }

                $response = [PSCustomObject]@{
                    issues     = @([PSCustomObject]@{ key = 'TEST-1' }, [PSCustomObject]@{ key = 'TEST-2' })
                    startAt    = 0
                    maxResults = 2
                }

                $result = Invoke-PaginatedRequest -Uri "$jiraServer/rest/api/2/search" -Response $response

                $result.key | Should -Be @('TEST-1', 'TEST-2', 'TEST-3')
                $script:capturedGetParameters[0]['startAt'] | Should -Be 2
            }

            It "rejects absolute token links that leave the original host" {
                $response = [PSCustomObject]@{
                    values        = @([PSCustomObject]@{ id = 1 })
                    nextPageToken = 'https://evil.example.com/rest/api/3/search?nextPageToken=x'
                    isLast        = $false
                }

                { Invoke-PaginatedRequest -Uri "https://jira.example.com/rest/api/3/search" -Response $response -ItemPropertyName values } |
                    Should -Throw '*untrusted host*'
            }
        }
    }
}
