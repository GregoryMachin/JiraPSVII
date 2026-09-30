function Remove-JiraUser {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPSVII.JiraPSVII.User]
        $User,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        $resourceURi = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/user' -IsCloud $isCloud

        if ($Force) {
            Write-DebugMessage "[Remove-JiraGroup] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        $userObj = Resolve-JiraUser -InputObject $User -Exact -Credential $Credential -ErrorAction Stop

        if ($isCloud -and -not $userObj.AccountId) {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.ArgumentException]"Jira Cloud user removal requires accountId."),
                'CloudUserAccountId.Required',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $userObj
            )
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        $identifierParameterName = if ($isCloud) { 'accountId' } else { 'username' }
        $userIdentifier = if ($isCloud) { $userObj.AccountId } else { $userObj.Name }
        $parameter = @{
            URI          = $resourceURi
            Method       = "DELETE"
            GetParameter = @{ $identifierParameterName = $userIdentifier }
            Credential   = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($userObj.DisplayName, 'Remove user')) {
            Invoke-JiraMethod @parameter
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
