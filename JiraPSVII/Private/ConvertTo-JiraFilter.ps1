function ConvertTo-JiraFilter {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Filter])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject,

        [PSObject[]]
        $FilterPermissions
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Filter"

            $hash = @{
                ID              = $i.id
                Name            = $i.name
                JQL             = $i.jql
                RestUrl         = [uri]$i.self
                ViewUrl         = [uri]$i.viewUrl
                SearchUrl       = [uri]$i.searchUrl
                Favourite       = if ($null -ne $i.favourite) { [System.Convert]::ToBoolean($i.favourite) } else { $false }
                SharePermission = $i.sharePermissions
                SharedUser      = $i.sharedUsers
                Subscription    = $i.subscriptions
            }

            if ($FilterPermissions) {
                $hash.FilterPermissions = [AtlassianPSVII.JiraPSVII.FilterPermission[]]@(ConvertTo-JiraFilterPermission ($FilterPermissions))
            }
            elseif ($i.sharePermissions) {
                # Intentional: Jira's raw sharePermissions payload is kept
                # below for compatibility and also projected into the new
                # typed FilterPermissions slot.
                $hash.FilterPermissions = [AtlassianPSVII.JiraPSVII.FilterPermission[]]@(ConvertTo-JiraFilterPermission ($i.sharePermissions))
            }
            else {
                $hash.FilterPermissions = [AtlassianPSVII.JiraPSVII.FilterPermission[]]@()
            }

            if ($i.description) { $hash.Description = $i.description }

            if ($i.owner) { $hash.Owner = ConvertTo-JiraUser -InputObject $i.owner }

            $result = [AtlassianPSVII.JiraPSVII.Filter]$hash

            $result | Add-Member -MemberType AliasProperty -Name 'Favorite' -Value 'Favourite' -Force

            $result
        }
    }
}
