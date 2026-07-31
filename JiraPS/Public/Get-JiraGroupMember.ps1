function Get-JiraGroupMember {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding( SupportsPaging )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.GroupTransformation()]
        [AtlassianPS.JiraPS.Group[]]
        $Group,

        [Switch]
        $IncludeInactive,

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

        $resourceURi = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/group/member" -IsCloud $isCloud

        if ($PageSize -gt 50) {
            Write-Warning "JIRA's API may not properly support MaxResults values higher than 50 for this method. If you receive inconsistent results, do not pass the MaxResults parameter to this function to return all results."
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            $getParameter = @{ maxResults = $PageSize }
            if ($isCloud -and $_group.Id) {
                $getParameter['groupId'] = $_group.Id
            }
            else {
                $getParameter['groupname'] = $_group.Name
            }

            if ($IncludeInactive) {
                $getParameter['includeInactiveUsers'] = $true
            }

            $parameter = @{
                URI          = $resourceURi
                Method       = "GET"
                GetParameter = $getParameter
                OutputType   = "JiraUser"
                Paging       = $true
                Credential   = $Credential
            }

            # Paging
            ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                $parameter[$_] = $PSCmdlet.PagingParameters.$_
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            Invoke-JiraMethod @parameter
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
