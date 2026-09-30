function ConvertTo-JiraStatus {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Status])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Status"

            $props = @{
                'ID'          = ConvertTo-JiraNullableInt64 $i.id
                'Name'        = $i.name
                'Description' = $i.description
                'IconUrl'     = [uri]$i.iconUrl
                'RestUrl'     = [uri]$i.self
            }

            if ($i.statusCategory) {
                $props.StatusCategory = [AtlassianPSVII.JiraPSVII.StatusCategory]@{
                    ID        = ConvertTo-JiraNullableInt64 $i.statusCategory.id
                    Key       = $i.statusCategory.key
                    Name      = $i.statusCategory.name
                    ColorName = $i.statusCategory.colorName
                    RestUrl   = [uri]$i.statusCategory.self
                }
            }

            [AtlassianPSVII.JiraPSVII.Status]$props
        }
    }
}
