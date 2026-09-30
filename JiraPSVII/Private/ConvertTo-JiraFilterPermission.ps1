function ConvertTo-JiraFilterPermission {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.FilterPermission])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.FilterPermission"

            $props = @{
                'ID'      = ConvertTo-JiraNullableInt64 $i.id
                'Type'    = $i.type
                'Group'   = $null
                'Project' = $null
                'Role'    = $null
            }

            if ($i.group) { $props["Group"] = ConvertTo-JiraGroup $i.group }

            if ($i.project) { $props["Project"] = ConvertTo-JiraProject $i.project }

            if ($i.role) { $props["Role"] = ConvertTo-JiraProjectRole $i.role }

            [AtlassianPSVII.JiraPSVII.FilterPermission]$props
        }
    }
}
