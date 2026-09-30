function ConvertTo-JiraGroup {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Group])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Group"

            $hash = @{
                Name    = $i.name
                Id      = if ($i.groupId) { $i.groupId } elseif ($i.id) { $i.id } else { $null }
                RestUrl = [uri]$i.self
            }

            if ($i.users) {
                if ($null -ne $i.users.size) {
                    $size = 0
                    if ([int]::TryParse([string]$i.users.size, [ref]$size)) {
                        $hash.Size = $size
                    }
                }

                if ($i.users.items) {
                    $allUsers = [System.Collections.Generic.List[AtlassianPSVII.JiraPSVII.User]]::new()
                    $i.users.items.ForEach({ $allUsers.Add((ConvertTo-JiraUser -InputObject $_)) })
                    $hash.Member = $allUsers.ToArray()
                }
            }

            [AtlassianPSVII.JiraPSVII.Group]$hash
        }
    }
}
