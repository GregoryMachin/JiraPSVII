function ConvertTo-JiraField {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Field])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Field"

            $props = @{
                'ID'          = $i.id
                'Name'        = $i.name
                'Custom'      = [System.Convert]::ToBoolean($i.custom)
                'Orderable'   = [System.Convert]::ToBoolean($i.orderable)
                'Navigable'   = [System.Convert]::ToBoolean($i.navigable)
                'Searchable'  = [System.Convert]::ToBoolean($i.searchable)
                'ClauseNames' = [string[]]@($i.clauseNames)
                'Schema'      = $i.schema
            }

            [AtlassianPSVII.JiraPSVII.Field]$props
        }
    }
}
