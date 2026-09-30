function ConvertTo-JiraProjectRole {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.ProjectRole])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.ProjectRole"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'Actors'      = $i.actors
                'RestUrl'     = [uri]$i.self
            }

            [AtlassianPSVII.JiraPSVII.ProjectRole]$props
        }
    }
}
