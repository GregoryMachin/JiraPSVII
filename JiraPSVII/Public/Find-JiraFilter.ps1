function Find-JiraFilter {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( DefaultParameterSetName = 'ByAccountId', SupportsPaging )]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'ByAccountId', ValueFromPipelineByPropertyName)]
        [string]$AccountId,

        [Parameter(ParameterSetName = 'ByOwner', ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPSVII.JiraPSVII.User]
        $Owner,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$GroupName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
        [AtlassianPSVII.JiraPSVII.Project]
        $Project,

        [Validateset('description', 'favourite', 'favouritedCount', 'jql', 'owner', 'searchUrl', 'sharePermissions', 'subscriptions', 'viewUrl')]
        [String[]]
        $Fields = @('description', 'favourite', 'favouritedCount', 'jql', 'owner', 'searchUrl', 'sharePermissions', 'subscriptions', 'viewUrl'),

        [Validateset('description', 'favourite_count', 'is_favourite', 'id', 'name', 'owner')]
        [string]$Sort,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential
        $searchURi = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/filter/search' -IsCloud $isCloud

        [String]$Fields = $Fields -join ','
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"
        $parameter = @{
            URI          = $searchURi
            Method       = 'GET'
            GetParameter = @{
                expand = $Fields
            }
            Paging       = $true
            Credential   = $Credential
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('AccountId')) {
            $parameter['GetParameter']['accountId'] = $AccountId
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByOwner') {
            $userObj = Resolve-JiraUser -InputObject $Owner -Exact -Credential $Credential -ErrorAction Stop
            if ($isCloud) {
                $parameter['GetParameter']['accountId'] = $userObj.AccountId
            }
            else {
                $parameter['GetParameter']['owner'] = $userObj.Name
            }
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('GroupName')) {
            $parameter['GetParameter']['groupName'] = $GroupName
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Project')) {
            if ($Project.Id) {
                # Caller passed a Project that already had its numeric ID
                # (either a real object or a numeric scalar coerced by the
                # transformer); use it directly and skip the lookup.
                $parameter['GetParameter']['projectId'] = $Project.Id
            }
            else {
                $projectObj = Get-JiraProject -Project $Project.Key -Credential $Credential -ErrorAction Stop
                $parameter['GetParameter']['projectId'] = $projectObj.Id
            }
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Sort')) {
            $parameter['GetParameter']['orderBy'] = $Sort
        }
        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $parameter[$_] = $PSCmdlet.PagingParameters.$_
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Name')) {
            foreach ($_name in $Name) {
                $parameter['GetParameter']['filterName'] = $_name
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

                Write-Output (Invoke-JiraMethod @parameter | ConvertTo-JiraFilter)
            }
        }
        else {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

            Write-Output (Invoke-JiraMethod @parameter | ConvertTo-JiraFilter)
        }

    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
