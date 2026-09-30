function ConvertTo-JiraPriority {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Priority])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Priority"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'StatusColor' = $i.statusColor
                'IconUrl'     = [uri]$i.iconUrl
                'RestUrl'     = [uri]$i.self
            }

            [AtlassianPSVII.JiraPSVII.Priority]$props
        }
    }
}
