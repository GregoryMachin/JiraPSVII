function Expand-Result {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        $InputObject,

        [String[]]
        $Container = $script:PagingContainers
    )

    process {
        foreach ($container in $Container) {
            if ($InputObject -and $InputObject.PSObject.Properties[$container]) {
                Write-DebugMessage "Extracting data from [$container] containter"
                $InputObject.$container
            }
        }
    }
}
