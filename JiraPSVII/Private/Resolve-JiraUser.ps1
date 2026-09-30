function Resolve-JiraUser {
    [CmdletBinding()]
    [OutputType( [AtlassianPSVII.JiraPSVII.User] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.UserTransformation()]
        [AtlassianPSVII.JiraPSVII.User]
        $InputObject,

        [Switch]
        $Exact,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        $isCloud = Test-JiraCloudServer -Credential $Credential
    }

    process {
        if ($InputObject.RestUrl -and (-not $isCloud -or $InputObject.AccountId)) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$InputObject as object"
            return $InputObject
        }

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve User to object"

        if ($isCloud -and $InputObject.AccountId) {
            return (Get-JiraUser -AccountId $InputObject.AccountId -Exact:$Exact -Credential $Credential -ErrorAction Stop)
        }

        # Legacy compatibility: if the caller handed us a stub user whose
        # Name slot looks like a Cloud accountId (24 hex chars or the modern
        # `<namespace>:<uuid>` shape), route through /accountId so the GET
        # works without first pre-classifying the input string.
        if ($isCloud -and $InputObject.Name -and (
                $InputObject.Name -match '^[A-Za-z0-9]{24}$' -or
                $InputObject.Name -match '^[A-Za-z0-9]+:[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$'
            )) {
            return (Get-JiraUser -AccountId $InputObject.Name -Exact:$Exact -Credential $Credential -ErrorAction Stop)
        }

        if ($InputObject.Name) {
            if ($isCloud -and $Exact) {
                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Jira Cloud exact user resolution requires accountId."),
                    'CloudUserAccountId.Required',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $InputObject
                )
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }

            return (Get-JiraUser -UserName $InputObject.Name -Exact:$Exact -Credential $Credential -ErrorAction Stop)
        }

        $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord (
            ([System.ArgumentException]"Cannot resolve user: neither AccountId nor Name is set."),
            'ParameterValue.NotJiraUser',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $InputObject
        )
        $PSCmdlet.ThrowTerminatingError($errorItem)
    }
}
