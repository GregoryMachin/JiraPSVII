function Get-JiraComponent {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding(SupportsPaging, DefaultParameterSetName = 'ByID')]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'ByProject' )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
        [AtlassianPSVII.JiraPSVII.Project[]]
        $Project,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByID' )]
        [Alias("Id")]
        [Int[]]
        $ComponentId,

        [Parameter( ParameterSetName = 'ByProject' )]
        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential
        $componentResourceUri = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/component/{0}' -IsCloud $isCloud
        $projectComponentResourceUri = if ($isCloud) {
            '/rest/api/3/project/{0}/component'
        }
        else {
            '/rest/api/2/project/{0}/components'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        switch ($PSCmdlet.ParameterSetName) {
            "ByProject" {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_project [$_project]"

                    # The /project/{projectIdOrKey}/components endpoint accepts
                    # either a project key or a numeric ID, so we forward whichever
                    # the typed parameter has populated.
                    $projectIdent = if ($_project.Key) { $_project.Key } else { $_project.ID }
                    $projectPathSegment = [Uri]::EscapeDataString($projectIdent)

                    $parameter = @{
                        URI        = $projectComponentResourceUri -f $projectPathSegment
                        Method     = "GET"
                        Paging     = $isCloud
                        Credential = $Credential
                    }
                    if ($isCloud) {
                        $parameter.GetParameter = @{ maxResults = $PageSize }
                        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                            $parameter[$_] = $PSCmdlet.PagingParameters.$_
                        }
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraComponent -InputObject $result)
                }
            }
            "ByID" {
                foreach ($_id in $ComponentId) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_id]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_id [$_id]"

                    $parameter = @{
                        URI        = $componentResourceUri -f $_id
                        Method     = "GET"
                        Credential = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraComponent -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
