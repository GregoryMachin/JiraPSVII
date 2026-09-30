function Remove-JiraRemoteLink {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( ConfirmImpact = 'High', SupportsShouldProcess )]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPSVII.JiraPSVII.Issue]
        $Issue,

        [Parameter( Mandatory )]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int[]]
        $LinkId,

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
        $resourceURi = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/issue/{0}/remotelink/{1}' -IsCloud $isCloud

        if ($Force) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] -Force was passed. Backing up current ConfirmPreference [$ConfirmPreference] and setting to None"
            $oldConfirmPreference = $ConfirmPreference
            $ConfirmPreference = 'None'
        }
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Issue [$Issue]"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential
        if (-not $issueObj.Key) {
            throw [System.ArgumentException]::new('Issue key is required to remove a remote link.')
        }
        $issuePathSegment = [Uri]::EscapeDataString([string]$issueObj.Key)

        foreach ($_link in $LinkId) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_link]"
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_link [$_link]"

            $parameter = @{
                URI        = $resourceURi -f $issuePathSegment, $_link
                Method     = "DELETE"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($PSCmdlet.ShouldProcess("$($issueObj.Key) remote link $_link", 'Remove Remote Link')) {
                Invoke-JiraMethod @parameter
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
