function ConvertTo-JiraAuditRecord {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.AuditRecord])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            if ($null -eq $item) { continue }

            $created = $null
            if ($null -ne $item.created) {
                if ($item.created -is [ValueType] -and $item.created -isnot [DateTime] -and $item.created -isnot [DateTimeOffset]) {
                    $created = [DateTimeOffset]::FromUnixTimeMilliseconds([Convert]::ToInt64($item.created))
                }
                else {
                    $created = ConvertTo-JiraDateTimeOffsetValue -InputObject $item.created
                }
            }

            [AtlassianPS.JiraPS.AuditRecord]@{
                Id                = if ($null -ne $item.id) { [Convert]::ToInt64($item.id) } else { $null }
                Created           = $created
                Category          = if ($null -ne $item.category) { [String]$item.category } else { $null }
                EventSource       = if ($null -ne $item.eventSource) { [String]$item.eventSource } else { $null }
                Summary           = if ($null -ne $item.summary) { [String]$item.summary } else { $null }
                AuthorKey         = if ($null -ne $item.authorKey) { [String]$item.authorKey } else { $null }
                AuthorAccountId   = if ($null -ne $item.authorAccountId) { [String]$item.authorAccountId } else { $null }
                AuthorDisplayName = if ($null -ne $item.authorDisplayName) { [String]$item.authorDisplayName } else { $null }
                RemoteAddress     = if ($null -ne $item.remoteAddress) { [String]$item.remoteAddress } else { $null }
                ObjectItem        = $item.objectItem
                AssociatedItems   = [Object[]]@($item.associatedItems)
                ChangedValues     = [Object[]]@($item.changedValues)
            }
        }
    }
}
