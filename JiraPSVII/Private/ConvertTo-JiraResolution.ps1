function ConvertTo-JiraResolution {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Resolution])]
    param(
        [Parameter(ValueFromPipeline)]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Resolution"

            $props = @{
                ID          = $i.id
                Name        = $i.name
                Description = $i.description
                RestUrl     = [uri]$i.self
            }

            [AtlassianPSVII.JiraPSVII.Resolution]$props
        }
    }
}
