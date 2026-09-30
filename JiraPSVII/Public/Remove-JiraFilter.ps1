function Remove-JiraFilter {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( ConfirmImpact = "Medium", SupportsShouldProcess, DefaultParameterSetName = 'ByInputObject' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('AtlassianPSVII.JiraPSVII.Filter')]
        $InputObject,

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
        $resourceUri = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/filter/{0}' -IsCloud $isCloud
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        if ($PSCmdlet.ParameterSetName -eq 'ById') {
            $InputObject = foreach ($_id in $Id) {
                Get-JiraFilter -Id $_id -Credential $Credential
            }
        }

        foreach ($filter in $InputObject) {
            if (-not $filter.Id) {
                throw [System.ArgumentException]::new('Filter ID is required to remove a filter.')
            }
            $parameter = @{
                URI        = $resourceUri -f $filter.Id
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($filter.Name, "Deleting Filter")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
