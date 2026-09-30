function Get-JiraProjectRole {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.ProjectRole])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
        [AtlassianPSVII.JiraPSVII.Project[]]
        $Project,

        [Parameter()]
        [Alias('Id')]
        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32[]]
        $RoleId,

        [Parameter()]
        [Switch]
        $ExcludeInactiveUsers,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential
        $collectionUri = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/project/{0}/role' -IsCloud $isCloud
        $detailUri = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/project/{0}/role/{1}' -IsCloud $isCloud
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        foreach ($_project in $Project) {
            $projectIdentifier = if ($_project.Key) { $_project.Key } else { $_project.Id }
            if (-not $projectIdentifier) {
                throw [System.ArgumentException]::new('Project key or ID is required to retrieve project roles.')
            }
            $projectPathSegment = [Uri]::EscapeDataString([string]$projectIdentifier)

            $roleIds = if ($PSBoundParameters.ContainsKey('RoleId')) {
                $RoleId
            }
            else {
                $roleMap = Invoke-JiraMethod -URI ($collectionUri -f $projectPathSegment) -Method Get -Credential $Credential
                foreach ($roleProperty in $roleMap.PSObject.Properties) {
                    $roleUrl = [string]$roleProperty.Value
                    if ($roleUrl -notmatch '/role/(?<id>\d+)/?$') {
                        throw [System.Security.SecurityException]::new("Jira returned an invalid project-role URL for '$($roleProperty.Name)'.")
                    }
                    [UInt32]$Matches.id
                }
            }

            foreach ($_roleId in $roleIds) {
                $parameter = @{
                    URI        = $detailUri -f $projectPathSegment, $_roleId
                    Method     = 'Get'
                    Credential = $Credential
                }
                if ($ExcludeInactiveUsers) {
                    $parameter.GetParameter = @{ excludeInactiveUsers = $true }
                }

                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter
                Write-Output (ConvertTo-JiraProjectRole -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
