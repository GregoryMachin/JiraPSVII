function Add-JiraFilterPermission {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ByInputObject' )]
    # [OutputType( [JiraPSVII.FilterPermission] )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('AtlassianPSVII.JiraPSVII.Filter')]
        $Filter,

        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()]
        [UInt32[]]
        $Id,

        [Parameter( Mandatory )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Group', 'Project', 'ProjectRole', 'Authenticated', 'Global')]
        [String]$Type,

        [Parameter()]
        [String]$Value,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential
        $resourceURi = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/filter/{0}/permission' -IsCloud $isCloud
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $Filter = Get-JiraFilter -Id $Id -Credential $Credential
        }

        $body = @{
            type = $Type.ToLower()
        }
        switch ($Type) {
            "Group" {
                $body["groupname"] = $Value
            }
            "Project" {
                $body["projectId"] = $Value
            }
            "ProjectRole" {
                $body["projectRoleId"] = $Value
            }
            "Authenticated" { }
            "Global" { }
        }

        foreach ($_filter in $Filter) {
            if (-not $_filter.Id) {
                throw [System.ArgumentException]::new('Filter ID is required to add filter permissions.')
            }
            $parameter = @{
                URI        = $resourceURi -f $_filter.Id
                Method     = "POST"
                Body       = ConvertTo-Json $body
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($_filter.Name, "Add Permission [$Type - $Value]")) {
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraFilter -InputObject $_filter -FilterPermissions $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
