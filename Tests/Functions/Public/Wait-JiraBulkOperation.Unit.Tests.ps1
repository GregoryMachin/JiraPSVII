#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Wait-JiraBulkOperation' -Tag 'Unit' {
        BeforeEach {
            $script:JiraLastResponseTelemetry = $null
            $script:poll = 0
            $script:retried = $false
            Mock Start-Sleep -ModuleName JiraPS {}
            Mock Write-Progress -ModuleName JiraPS {}
        }

        It 'polls until complete and reports progress' {
            Mock Get-JiraBulkOperationProgress -ModuleName JiraPS {
                if (-not $script:poll) { $script:poll = 0 }
                $script:poll++
                if ($script:poll -eq 1) {
                    [AtlassianPS.JiraPS.BulkOperationProgress]@{ TaskId = '10641'; Status = [AtlassianPS.JiraPS.BulkOperationStatus]::RUNNING; ProgressPercent = 50 }
                }
                else {
                    [AtlassianPS.JiraPS.BulkOperationProgress]@{ TaskId = '10641'; Status = [AtlassianPS.JiraPS.BulkOperationStatus]::COMPLETE; ProgressPercent = 100 }
                }
            }

            $result = Wait-JiraBulkOperation -TaskId '10641' -PollIntervalSeconds 1

            $result.Status | Should -Be ([AtlassianPS.JiraPS.BulkOperationStatus]::COMPLETE)
            Should -Invoke Start-Sleep -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Seconds -eq 1 }
            Should -Invoke Write-Progress -ModuleName JiraPS -ParameterFilter { $PercentComplete -eq 50 }
        }

        It 'returns a complete result with partial failures without masking them' {
            Mock Get-JiraBulkOperationProgress -ModuleName JiraPS {
                $failures = [System.Collections.Generic.Dictionary[string, string[]]]::new([System.StringComparer]::Ordinal)
                $failures['10002'] = @('No edit permission.')
                [AtlassianPS.JiraPS.BulkOperationProgress]@{
                    TaskId = '10641'; Status = [AtlassianPS.JiraPS.BulkOperationStatus]::COMPLETE
                    FailedAccessibleIssues = $failures
                    InvalidOrInaccessibleIssueCount = 1
                }
            }

            $result = Wait-JiraBulkOperation -TaskId '10641'

            $result.HasPartialFailures | Should -BeTrue
            $result.FailedAccessibleIssues['10002'] | Should -Be 'No edit permission.'
        }

        It 'honors Retry-After telemetry when choosing the next poll delay' {
            $script:JiraLastResponseTelemetry = [PSCustomObject]@{ RetryAfterSeconds = 4 }
            Mock Get-JiraBulkOperationProgress -ModuleName JiraPS {
                if (-not $script:retried) { $script:retried = $true; return [AtlassianPS.JiraPS.BulkOperationProgress]@{ TaskId = '10641'; Status = [AtlassianPS.JiraPS.BulkOperationStatus]::RUNNING } }
                [AtlassianPS.JiraPS.BulkOperationProgress]@{ TaskId = '10641'; Status = [AtlassianPS.JiraPS.BulkOperationStatus]::COMPLETE }
            }

            $null = Wait-JiraBulkOperation -TaskId '10641' -PollIntervalSeconds 1

            Should -Invoke Start-Sleep -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $Seconds -eq 4 }
        }

        It 'stops after the configured bounded poll count without cancelling the task' {
            Mock Get-JiraBulkOperationProgress -ModuleName JiraPS {
                [AtlassianPS.JiraPS.BulkOperationProgress]@{ TaskId = '10641'; Status = [AtlassianPS.JiraPS.BulkOperationStatus]::RUNNING }
            }

            { Wait-JiraBulkOperation -TaskId '10641' -MaxPollCount 1 -ErrorAction Stop } | Should -Throw '*was not cancelled*'
            Should -Invoke Start-Sleep -ModuleName JiraPS -Exactly -Times 0
        }

        It 'returns a failed terminal state without retrying the original operation' {
            Mock Get-JiraBulkOperationProgress -ModuleName JiraPS {
                [AtlassianPS.JiraPS.BulkOperationProgress]@{ TaskId = '10641'; Status = [AtlassianPS.JiraPS.BulkOperationStatus]::FAILED }
            }

            $result = Wait-JiraBulkOperation -TaskId '10641'

            $result.Status | Should -Be ([AtlassianPS.JiraPS.BulkOperationStatus]::FAILED)
            Should -Invoke Get-JiraBulkOperationProgress -ModuleName JiraPS -Exactly -Times 1
        }
    }
}
