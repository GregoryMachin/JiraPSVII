function ConvertTo-JiraTransition {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Transition])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Transition"

            $props = @{
                'ID'           = ConvertTo-JiraNullableInt64 $i.id
                'Name'         = $i.name
                'ResultStatus' = ConvertTo-JiraStatus -InputObject $i.to
            }

            [AtlassianPSVII.JiraPSVII.Transition]$props
        }
    }
}
