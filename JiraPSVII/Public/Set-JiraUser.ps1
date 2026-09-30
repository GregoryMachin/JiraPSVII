function Set-JiraUser {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( SupportsShouldProcess, DefaultParameterSetName = 'ByNamedParameters' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.UserTransformation()]
        [Alias('UserName')]
        [AtlassianPSVII.JiraPSVII.User]
        $User,

        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [ValidateNotNullOrEmpty()]
        [String]
        $DisplayName,

        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                if ($_ -match '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$') {
                    return $true
                }
                else {
                    $exception = ([System.ArgumentException]"Invalid Argument") #fix code highlighting]
                    $errorId = 'ParameterValue.NotEmail'
                    $errorCategory = 'InvalidArgument'
                    $errorTarget = $Issue
                    $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
                    $errorItem.ErrorDetails = "The value provided does not look like an email address."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                    return $false
                }
            }
        )]
        [String]
        $EmailAddress,

        [Parameter( ParameterSetName = 'ByNamedParameters' )]
        [Boolean]
        $Active,

        [Parameter( Position = 1, Mandatory, ParameterSetName = 'ByHashtable' )]
        [Hashtable]
        $Property,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $PassThru
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential

        if ($isCloud) {
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                ([System.PlatformNotSupportedException]"Jira Cloud does not expose a REST API v3 user profile update operation."),
                'CloudUserUpdate.NotSupported',
                [System.Management.Automation.ErrorCategory]::NotImplemented,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($errorItem)
        }

        $resourceURi = '/rest/api/2/user'
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        $userObj = Resolve-JiraUser -InputObject $User -Exact -Credential $Credential -ErrorAction Stop

        $requestBody = @{}

        switch ($PSCmdlet.ParameterSetName) {
            'ByNamedParameters' {
                if (-not ($DisplayName -or $EmailAddress -or $PSBoundParameters.ContainsKey('Active'))) {
                    $errorMessage = @{
                        Category         = "InvalidArgument"
                        CategoryActivity = "Validating Arguments"
                        Message          = "The parameters provided do not change the User. No action will be performed"
                    }
                    Write-Error @errorMessage
                    return
                }

                if ($DisplayName) {
                    $requestBody.displayName = $DisplayName
                }

                if ($EmailAddress) {
                    $requestBody.emailAddress = $EmailAddress
                }

                if ($PSBoundParameters.ContainsKey('Active')) {
                    $requestBody.active = $Active
                }
            }
            'ByHashtable' {
                $requestBody = $Property
            }
        }

        $parameter = @{
            URI          = $resourceURi
            Method       = "PUT"
            GetParameter = @{ username = $userObj.Name }
            Body         = ConvertTo-Json -InputObject $requestBody -Depth 4
            Credential   = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        if ($PSCmdlet.ShouldProcess($UserObj.DisplayName, "Updating user")) {
            $result = Invoke-JiraMethod @parameter

            if ($PassThru) {
                if ($userObj.AccountId -or $userObj.Name) {
                    $refreshUser = [AtlassianPSVII.JiraPSVII.User]@{
                        AccountId = $userObj.AccountId
                        Name      = $userObj.Name
                    }
                    Write-Output (Resolve-JiraUser -InputObject $refreshUser -Exact -Credential $Credential -ErrorAction Stop)
                }
                else {
                    Write-Output (ConvertTo-JiraUser -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
