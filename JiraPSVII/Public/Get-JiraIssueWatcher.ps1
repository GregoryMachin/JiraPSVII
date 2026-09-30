function Get-JiraIssueWatcher {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPSVII.JiraPSVII.Issue]
        $Issue,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential

        foreach ($issue in $issueObj) {
            $parameter = @{
                URI        = "{0}/watchers" -f $issue.RestURL
                Method     = "GET"
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
            if ($result = Invoke-JiraMethod @parameter) {
                $result.watchers | ConvertTo-JiraUser
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
