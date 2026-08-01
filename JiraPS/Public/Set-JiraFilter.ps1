function Set-JiraFilter {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNullOrEmpty()]
        [PSTypeName('AtlassianPS.JiraPS.Filter')]
        $InputObject,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $JQL,

        [Parameter()]
        [Alias('Favourite')]
        [Bool]
        $Favorite,

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

        if (@($InputObject).Count -ne 1) {
            throw [System.ArgumentException]::new('Only one filter can be updated at a time. Pass multiple filters through the pipeline.')
        }

        $requestBody = @{}
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Name")) {
            $requestBody["name"] = $Name
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Description")) {
            $requestBody["description"] = $Description
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("JQL")) {
            $requestBody["jql"] = $JQL
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Favorite")) {
            $requestBody["favourite"] = $Favorite
        }

        if ($requestBody.Keys.Count) {
            if (-not $InputObject.Id) {
                throw [System.ArgumentException]::new('Filter ID is required to update a filter.')
            }
            $parameter = @{
                URI        = $resourceUri -f $InputObject.Id
                Method     = "PUT"
                Body       = ConvertTo-Json -InputObject $requestBody
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess($InputObject.Name, "Update Filter")) {
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraFilter -InputObject $result)
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
