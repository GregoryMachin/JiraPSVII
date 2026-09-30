function ConvertTo-JiraWorklogItem {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Worklogitem])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Worklogitem"

            $props = @{
                'ID'         = ConvertTo-JiraNullableInt64 $i.id
                'Visibility' = $i.visibility
                'Comment'    = ConvertFrom-AtlassianDocumentFormat -InputObject $i.comment
                'RestUrl'    = [uri]$i.self
            }

            if ($i.author) {
                $props.Author = ConvertTo-JiraUser -InputObject $i.author
            }

            if ($i.updateAuthor) {
                $props.UpdateAuthor = ConvertTo-JiraUser -InputObject $i.updateAuthor
            }

            if ($i.created) {
                $props.Created = ConvertTo-JiraDateTimeOffsetValue $i.created
            }

            if ($i.updated) {
                $props.Updated = ConvertTo-JiraDateTimeOffsetValue $i.updated
            }

            if ($i.started) {
                $props.Started = ConvertTo-JiraDateTimeOffsetValue $i.started
            }

            if ($i.timeSpent) {
                $props.TimeSpent = $i.timeSpent
            }

            if ($i.timeSpentSeconds) {
                $props.TimeSpentSeconds = $i.timeSpentSeconds
            }

            if ($i.properties) {
                $props.Properties = [object[]]@($i.properties)
            }

            [AtlassianPSVII.JiraPSVII.Worklogitem]$props
        }
    }
}
