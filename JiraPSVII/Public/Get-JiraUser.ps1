function Get-JiraUser {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( DefaultParameterSetName = 'Self' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByUserName' )]
        [AllowEmptyString()]
        [Alias('User', 'Name')]
        [String[]]
        $UserName,

        [Parameter( Position = 0, Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByAccountId' )]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $AccountId,

        [Parameter( Position = 0, Mandatory, ParameterSetName = 'ByInputObject' )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.UserTransformation()]
        [AtlassianPSVII.JiraPSVII.User[]]
        $InputObject,

        [Parameter( ParameterSetName = 'ByInputObject' )]
        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [Switch]$Exact,

        [Switch]
        $IncludeInactive,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateRange(1, 1000)]
        [UInt32]
        $MaxResults = 50,

        [Parameter( ParameterSetName = 'ByUserName' )]
        [Parameter( ParameterSetName = 'ByAccountId' )]
        [ValidateNotNullOrEmpty()]
        [UInt64]
        $Skip = 0,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $selfResourceUri = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/myself" -IsCloud $isCloud
        $searchResourceUri = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/user/search" -IsCloud $isCloud
        $exactResourceUri = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/user" -IsCloud $isCloud
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        $ParameterSetName = ''
        switch ($PsCmdlet.ParameterSetName) {
            'ByInputObject' {
                if ($isCloud) {
                    $lookupValue = foreach ($inputUser in $InputObject) {
                        if ($inputUser.AccountId) {
                            $inputUser.AccountId
                        }
                        elseif ($inputUser.Name -match '^[A-Za-z0-9]{24}$' -or
                            $inputUser.Name -match '^[A-Za-z0-9]+:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$') {
                            $inputUser.Name
                        }
                        else {
                            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                                ([System.ArgumentException]"Jira Cloud exact user lookup requires accountId."),
                                'CloudUserAccountId.Required',
                                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                                $inputUser
                            )
                            $PSCmdlet.ThrowTerminatingError($errorItem)
                        }
                    }
                }
                else {
                    $lookupValue = foreach ($inputUser in $InputObject) { $inputUser.Name }
                }
                $ParameterSetName = 'ByLookupValue'
                $Exact = $true
            }
            'ByAccountId' {
                $lookupValue = $AccountId
                $ParameterSetName = 'ByLookupValue'
                $Exact = $true
            }
            'ByUserName' {
                $lookupValue = $UserName
                $ParameterSetName = 'ByLookupValue'

                if ($isCloud -and $Exact) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Jira Cloud exact user lookup requires accountId."),
                        'CloudUserAccountId.Required',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $UserName
                    )
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
            }
            'Self' { $ParameterSetName = 'Self' }
        }

        switch ($ParameterSetName) {
            "Self" {
                $resourceURi = $selfResourceUri

                $parameter = @{
                    URI        = $resourceURi
                    Method     = "GET"
                    Credential = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                if ($isCloud -and $result.accountId) {
                    Get-JiraUser -AccountId $result.accountId -Exact -Credential $Credential
                }
                elseif ($result.Name) {
                    Get-JiraUser -UserName $result.Name -Exact -Credential $Credential
                }
                else {
                    Write-Output (ConvertTo-JiraUser -InputObject $result)
                }
            }
            "ByLookupValue" {
                foreach ($user in $lookupValue) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing user lookup"

                    $resourceURi = if ($Exact) { $exactResourceUri } else { $searchResourceUri }
                    $getParameter = @{}
                    if ($Exact) {
                        $identifierParameterName = if ($isCloud) { 'accountId' } else { 'username' }
                        $getParameter[$identifierParameterName] = $user
                        $getParameter['expand'] = 'groups'
                    }
                    else {
                        $searchParameterName = if ($isCloud) { 'query' } else { 'username' }
                        $getParameter[$searchParameterName] = $user
                        if (-not $isCloud) {
                            $getParameter['includeInactive'] = [bool]$IncludeInactive
                        }
                        $getParameter['maxResults'] = $MaxResults
                        $getParameter['startAt'] = $Skip
                    }

                    $parameter = @{
                        URI          = $resourceURi
                        Method       = "GET"
                        GetParameter = $getParameter
                        Credential   = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    if ($users = Invoke-JiraMethod @parameter) {
                        foreach ($item in $users) {
                            if ($Exact) {
                                $result = $item
                            }
                            elseif ($isCloud -and $item.accountId) {
                                $parameter = @{
                                    URI          = $exactResourceUri
                                    Method       = 'GET'
                                    GetParameter = @{ accountId = $item.accountId; expand = 'groups' }
                                    Credential   = $Credential
                                }
                                $result = Invoke-JiraMethod @parameter
                            }
                            elseif (-not $isCloud -and $item.name) {
                                $parameter = @{
                                    URI          = $exactResourceUri
                                    Method       = 'GET'
                                    GetParameter = @{ username = $item.name; expand = 'groups' }
                                    Credential   = $Credential
                                }
                                $result = Invoke-JiraMethod @parameter
                            }
                            else {
                                $result = $item
                            }

                            Write-Output (ConvertTo-JiraUser -InputObject $result)
                        }
                    }
                    else {
                        $errorMessage = @{
                            Category         = "ObjectNotFound"
                            CategoryActivity = "Searching for user"
                            Message          = "No results when searching for user $user"
                        }
                        Write-Error @errorMessage
                    }
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
