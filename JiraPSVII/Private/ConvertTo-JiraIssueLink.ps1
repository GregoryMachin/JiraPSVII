function ConvertTo-JiraIssueLink {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.IssueLink])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.IssueLink"

            $props = @{
                'Id' = ConvertTo-JiraNullableInt64 $i.id
            }

            if ($i.type) {
                $props.Type = ConvertTo-JiraIssueLinkType $i.type
            }

            if ($i.inwardIssue) {
                $props['InwardIssue'] = ConvertTo-JiraIssue $i.inwardIssue
            }

            if ($i.outwardIssue) {
                $props['OutwardIssue'] = ConvertTo-JiraIssue $i.outwardIssue
            }

            [AtlassianPSVII.JiraPSVII.IssueLink]$props
        }
    }
}
