function ConvertTo-JiraBulkOperationProgress {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.BulkOperationProgress])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            if ($null -eq $item) { continue }

            $failedIssues = [System.Collections.Generic.Dictionary[string, string[]]]::new([System.StringComparer]::Ordinal)
            $failedIssueSource = $item.failedAccessibleIssues
            if ($failedIssueSource -is [System.Collections.IDictionary]) {
                foreach ($entry in $failedIssueSource.GetEnumerator()) {
                    if ($null -ne $entry.Key) {
                        $failedIssues[[String]$entry.Key] = [String[]]@($entry.Value | ForEach-Object { [String]$_ })
                    }
                }
            }
            elseif ($failedIssueSource) {
                foreach ($property in $failedIssueSource.PSObject.Properties) {
                    $failedIssues[$property.Name] = [String[]]@($property.Value | ForEach-Object { [String]$_ })
                }
            }

            $status = $null
            if ($item.status) {
                try {
                    $status = [AtlassianPSVII.JiraPSVII.BulkOperationStatus][System.Enum]::Parse(
                        [AtlassianPSVII.JiraPSVII.BulkOperationStatus],
                        [String]$item.status,
                        $true)
                }
                catch {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Jira returned an unknown bulk-operation status '$($item.status)'."
                }
            }

            [AtlassianPSVII.JiraPSVII.BulkOperationProgress]@{
                TaskId                          = [String]$item.taskId
                Status                          = $status
                ProgressPercent                 = if ($null -ne $item.progressPercent) { [Convert]::ToInt32($item.progressPercent) } else { $null }
                SubmittedBy                     = if ($item.submittedBy) { ConvertTo-JiraUser -InputObject $item.submittedBy } else { $null }
                Created                         = if ($null -ne $item.created) { [Convert]::ToInt64($item.created) } else { $null }
                Started                         = if ($null -ne $item.started) { [Convert]::ToInt64($item.started) } else { $null }
                Updated                         = if ($null -ne $item.updated) { [Convert]::ToInt64($item.updated) } else { $null }
                ProcessedAccessibleIssues       = if ($null -ne $item.processedAccessibleIssues) { [Int64[]]@($item.processedAccessibleIssues) } else { $null }
                FailedAccessibleIssues          = $failedIssues
                InvalidOrInaccessibleIssueCount = if ($null -ne $item.invalidOrInaccessibleIssueCount) { [Convert]::ToInt32($item.invalidOrInaccessibleIssueCount) } else { $null }
                TotalIssueCount                 = if ($null -ne $item.totalIssueCount) { [Convert]::ToInt32($item.totalIssueCount) } else { $null }
            }
        }
    }
}
