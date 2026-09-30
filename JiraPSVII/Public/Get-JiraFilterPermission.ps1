function Get-JiraFilterPermission {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ById' )]
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

        foreach ($_filter in $Filter) {
            if (-not $_filter.Id) {
                throw [System.ArgumentException]::new('Filter ID is required to retrieve filter permissions.')
            }
            $parameter = @{
                URI        = $resourceURi -f $_filter.Id
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            $result = Invoke-JiraMethod @parameter

            Write-Output (ConvertTo-JiraFilter -InputObject $_filter -FilterPermissions $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
