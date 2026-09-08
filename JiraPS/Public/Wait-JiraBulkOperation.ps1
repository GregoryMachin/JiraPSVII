function Wait-JiraBulkOperation {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.BulkOperationProgress])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')]
        [String]
        $TaskId,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateRange(1, 60)]
        [Int]
        $PollIntervalSeconds = 5,

        [ValidateRange(1, 86400)]
        [Int]
        $TimeoutSec = 900,

        [ValidateRange(1, 10000)]
        [Int]
        $MaxPollCount = 180,

        [Int]
        $ProgressId = 1
    )

    process {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $pollCount = 0
        try {
            do {
                $progress = Get-JiraBulkOperationProgress -TaskId $TaskId -Credential $Credential
                $pollCount++

                $percentComplete = if ($null -ne $progress.ProgressPercent) { [Math]::Min(100, [Math]::Max(0, $progress.ProgressPercent)) } else { 0 }
                $status = if ($progress.Status) { $progress.Status.ToString() } else { 'UNKNOWN' }
                Write-Progress -Id $ProgressId -Activity "Waiting for Jira bulk operation $TaskId" -Status $status -PercentComplete $percentComplete

                if ($progress.Status -in @([AtlassianPS.JiraPS.BulkOperationStatus]::COMPLETE, [AtlassianPS.JiraPS.BulkOperationStatus]::FAILED, [AtlassianPS.JiraPS.BulkOperationStatus]::NOT_FOUND)) {
                    Write-Output $progress
                    return
                }

                if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSec -or $pollCount -ge $MaxPollCount) {
                    throw [System.TimeoutException]::new("Jira bulk operation '$TaskId' did not reach a terminal state within the configured polling limit. The operation was not cancelled.")
                }

                $delay = $PollIntervalSeconds
                if ($null -ne $script:JiraLastResponseTelemetry -and $null -ne $script:JiraLastResponseTelemetry.RetryAfterSeconds) {
                    $delay = [Math]::Max($delay, [Int]$script:JiraLastResponseTelemetry.RetryAfterSeconds)
                }

                $remainingSeconds = [Math]::Ceiling($TimeoutSec - $stopwatch.Elapsed.TotalSeconds)
                if ($remainingSeconds -le 0) {
                    throw [System.TimeoutException]::new("Jira bulk operation '$TaskId' did not reach a terminal state within $TimeoutSec seconds. The operation was not cancelled.")
                }
                Start-Sleep -Seconds ([Math]::Min($delay, $remainingSeconds))
            } while ($true)
        }
        finally {
            Write-Progress -Id $ProgressId -Activity "Waiting for Jira bulk operation $TaskId" -Completed
        }
    }
}
