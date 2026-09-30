function Remove-JiraGroupMember {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( SupportsShouldProcess, ConfirmImpact = 'High' )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.GroupTransformation()]
        [Alias('GroupName')]
        [AtlassianPSVII.JiraPSVII.Group[]]
        $Group,

        [Parameter( Mandatory )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPSVII.JiraPSVII.User[]]
        $User,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $PassThru,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $resourceURi = ConvertTo-JiraRestApiV3Url -Url "/rest/api/2/group/user" -IsCloud $isCloud

        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        foreach ($_group in $Group) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_group]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_group [$_group]"

            foreach ($_user in $User) {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing user"
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing user input"

                $userObj = Resolve-JiraUser -InputObject $_user -Exact -Credential $Credential -ErrorAction Stop
                if ($isCloud -and -not $userObj.AccountId) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Jira Cloud group membership requires accountId."),
                        'CloudUserAccountId.Required',
                        [System.Management.Automation.ErrorCategory]::InvalidArgument,
                        $userObj
                    )
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                $userIdentifier = if ($isCloud -and $userObj.AccountId) { $userObj.AccountId } else { $userObj.Name }

                if ($isCloud -and $_group.Id) {
                    $getParameter = @{ groupId = $_group.Id }
                }
                else {
                    $getParameter = @{ groupname = $_group.Name }
                }

                if ($isCloud) {
                    $getParameter['accountId'] = $userIdentifier
                }
                else {
                    $getParameter['username'] = $userIdentifier
                }
                $target = if ($_group.Name) { $_group.Name } else { $_group.Id }
                $parameter = @{
                    URI          = $resourceURi
                    Method       = "DELETE"
                    GetParameter = $getParameter
                    Credential   = $Credential
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                if ($PSCmdlet.ShouldProcess($target, "Remove $($userObj.DisplayName) from group")) {
                    Invoke-JiraMethod @parameter
                }
            }

            if ($PassThru) {
                Write-Output $_group
            }
        }
    }

    end {
        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Restoring ConfirmPreference to [$oldConfirmPreference]"
            $ConfirmPreference = $oldConfirmPreference
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
