function Clear-JiraCache {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('All', 'Fields', 'IssueTypes', 'OAuthResources', 'Priorities', 'Statuses', 'ServerInfo')]
        [string]$Type = 'All'
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (-not $script:JiraCache -and -not $script:JiraOAuthResourceCache) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] No cache to clear"
            return
        }

        if ($Type -eq 'All') {
            $count = if ($script:JiraCache) { $script:JiraCache.Count } else { 0 }
            $script:JiraCache = @{}
            $script:JiraOAuthResourceCache = $null
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cleared all $count cached items"
        }
        elseif ($Type -eq 'OAuthResources') {
            $script:JiraOAuthResourceCache = $null
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cleared OAuth resource metadata"
        }
        else {
            $keysToRemove = @(
                if ($script:JiraCache) {
                    $script:JiraCache.Keys | Where-Object { $_ -like "${Type}:*" }
                }
            )
            foreach ($key in $keysToRemove) {
                $script:JiraCache.Remove($key)
            }
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Cleared $($keysToRemove.Count) cached items for type '$Type'"
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function complete"
    }
}
