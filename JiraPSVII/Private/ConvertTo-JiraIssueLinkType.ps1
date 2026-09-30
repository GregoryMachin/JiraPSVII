function ConvertTo-JiraIssueLinkType {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.IssueLinkType])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.IssueLinkType"

            $props = @{
                'ID'          = $i.id
                'Name'        = $i.name
                'InwardText'  = $i.inward
                'OutwardText' = $i.outward
                'RestUrl'     = [uri]$i.self
            }

            [AtlassianPSVII.JiraPSVII.IssueLinkType]$props
        }
    }
}
