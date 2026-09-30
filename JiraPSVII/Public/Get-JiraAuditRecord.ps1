function Get-JiraAuditRecord {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding(SupportsPaging)]
    [OutputType([AtlassianPSVII.JiraPSVII.AuditRecord])]
    param(
        [Parameter()]
        [DateTimeOffset]
        $From = ([DateTimeOffset]::UtcNow.AddDays(-1)),

        [Parameter()]
        [DateTimeOffset]
        $To = [DateTimeOffset]::UtcNow,

        [Parameter()]
        [ValidateRange(1, 1000)]
        [UInt32]
        $PageSize = 100,

        [Parameter()]
        [ValidateRange(0, [UInt32]::MaxValue)]
        [UInt32]
        $Offset = 0,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        if ($From -gt $To) {
            throw [System.ArgumentException]::new('From must be earlier than or equal to To.', 'From')
        }

        # Audit records remain a v2 contract on both Jira Cloud and Data Center.
        $resourceUri = '/rest/api/2/auditing/record'
        $fromMilliseconds = $From.ToUniversalTime().ToUnixTimeMilliseconds()
        $toMilliseconds = $To.ToUniversalTime().ToUnixTimeMilliseconds()
        $currentOffset = [Int64]$Offset + [Int64]$PSCmdlet.PagingParameters.Skip
        $first = [UInt64]$PSCmdlet.PagingParameters.First
        $remaining = if ($first -eq [UInt64]::MaxValue) { [Int64]::MaxValue } else { [Int64]$first }
        $observedTotal = $null
    }

    process {
        do {
            if ($remaining -le 0) { break }
            $limit = [Int32][Math]::Min([Int64]$PageSize, $remaining)
            $parameter = @{
                URI          = $resourceUri
                Method       = 'GET'
                GetParameter = @{ offset = $currentOffset; limit = $limit; from = $fromMilliseconds; to = $toMilliseconds }
                Credential   = $Credential
            }
            $response = Invoke-JiraMethod @parameter
            $records = @($response.records)
            if ($null -ne $response.total) { $observedTotal = [Int64]$response.total }
            if ($records.Count -eq 0) { break }

            foreach ($record in $records) {
                ConvertTo-JiraAuditRecord -InputObject $record
                $remaining--
                if ($remaining -le 0) { break }
            }

            $currentOffset += $records.Count
            if ($records.Count -lt $limit) { break }
            if ($null -ne $response.total -and $currentOffset -ge [Int64]$response.total) { break }
        } while ($true)
    }

    end {
        if ($PSCmdlet.PagingParameters.IncludeTotalCount -and $null -ne $observedTotal) {
            $PSCmdlet.PagingParameters.NewTotalCount($observedTotal, 1.0)
        }
    }
}
