function Remove-JiraFilterPermission {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ByFilterId' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByFilterObject' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if (@($Filter).Count -gt 1) {
                    $exception = ([System.ArgumentException]"Invalid Parameter")
                    $errorId = 'ParameterType.TooManyFilters'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "Only one Filter can be passed at a time."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                elseif (@($_.FilterPermissions).Count -lt 1) {
                    $exception = ([System.ArgumentException]"Invalid Type for Parameter")
                    $errorId = 'ParameterType.FilterWithoutPermission'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $_
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "The Filter provided does not contain any Permission to delete."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [PSTypeName('AtlassianPSVII.JiraPSVII.Filter')]
        $Filter,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByFilterId' )]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [UInt32]
        $FilterId,

        # TODO: [Parameter( Position = 1, ParameterSetName = 'ByFilterObject')]
        [Parameter( Position = 1, Mandatory, ParameterSetName = 'ByFilterId')]
        [ValidateNotNullOrEmpty()]
        [UInt32[]]
        $PermissionId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential
        $resourceUri = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/filter/{0}/permission/{1}' -IsCloud $isCloud
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        switch ($PSCmdlet.ParameterSetName) {
            "ByFilterObject" {
                $PermissionId = $Filter.FilterPermissions.Id
            }
            "ByFilterId" {
                $Filter = Get-JiraFilter -Id $FilterId -Credential $Credential
            }
        }

        foreach ($_permissionId in $PermissionId) {
            if (-not $Filter.Id) {
                throw [System.ArgumentException]::new('Filter ID is required to remove filter permissions.')
            }
            $parameter = @{
                URI        = $resourceUri -f $Filter.Id, $_permissionId
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess("filter $($Filter.Id) permission $_permissionId", "Remove Permission")) {
                Invoke-JiraMethod @parameter
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
