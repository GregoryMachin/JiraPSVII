function Resolve-JiraResponseTelemetry {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [PSObject]
        $InputObject
    )

    $headers = if ($InputObject -and $InputObject.Headers) { $InputObject.Headers } else { $null }

    $telemetry = [PSCustomObject]@{
        RequestId         = Get-JiraResponseHeaderValue -Headers $headers -Name @('X-AREQUESTID', 'X-Atlassian-Request-Id', 'Atlassian-Request-Id')
        RetryAfter        = Get-JiraResponseHeaderValue -Headers $headers -Name 'Retry-After'
        RetryAfterSeconds = $null
        RateLimit         = [PSCustomObject]@{
            Limit           = Get-JiraResponseHeaderValue -Headers $headers -Name 'X-RateLimit-Limit'
            Remaining       = Get-JiraResponseHeaderValue -Headers $headers -Name 'X-RateLimit-Remaining'
            FillRate        = Get-JiraResponseHeaderValue -Headers $headers -Name 'X-RateLimit-FillRate'
            IntervalSeconds = Get-JiraResponseHeaderValue -Headers $headers -Name 'X-RateLimit-Interval-Seconds'
            Reset           = Get-JiraResponseHeaderValue -Headers $headers -Name 'X-RateLimit-Reset'
            NearLimit       = Get-JiraResponseHeaderValue -Headers $headers -Name 'X-RateLimit-NearLimit'
            Reason          = Get-JiraResponseHeaderValue -Headers $headers -Name 'RateLimit-Reason'
        }
        Deprecation       = Get-JiraResponseHeaderValue -Headers $headers -Name 'Deprecation'
        Sunset            = Get-JiraResponseHeaderValue -Headers $headers -Name 'Sunset'
        DeprecationLink   = Get-JiraResponseHeaderValue -Headers $headers -Name @('Deprecation-Link', 'Link')
    }

    if ($telemetry.RetryAfter) {
        [int]$retryAfterSeconds = 0
        if ([int]::TryParse($telemetry.RetryAfter, [ref]$retryAfterSeconds)) {
            $telemetry.RetryAfterSeconds = [Math]::Max(0, $retryAfterSeconds)
        }
        else {
            [DateTimeOffset]$retryAfterDate = [DateTimeOffset]::MinValue
            if ([DateTimeOffset]::TryParse($telemetry.RetryAfter, [ref]$retryAfterDate)) {
                $seconds = [Math]::Ceiling(($retryAfterDate.ToUniversalTime() - [DateTimeOffset]::UtcNow).TotalSeconds)
                $telemetry.RetryAfterSeconds = [Math]::Max(0, [int]$seconds)
            }
        }
    }

    $script:JiraLastResponseTelemetry = $telemetry

    if ($telemetry.Sunset) {
        Write-Warning "[$($MyInvocation.MyCommand.Name)] Jira response includes a Sunset header: $($telemetry.Sunset)"
    }
    if ($telemetry.Deprecation -or $telemetry.DeprecationLink) {
        $message = "[$($MyInvocation.MyCommand.Name)] Jira response includes deprecation metadata."
        if ($telemetry.DeprecationLink) {
            $message += " See: $($telemetry.DeprecationLink)"
        }
        Write-Warning $message
    }

    $telemetry
}
