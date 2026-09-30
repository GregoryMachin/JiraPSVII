function Get-JiraIssueWorklog {
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

        $isCloud = Test-JiraCloudServer -Credential $Credential
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential
        $issueRestUrl = ConvertTo-JiraRestApiV3Url -Url $issueObj.RestUrl -IsCloud $isCloud

        $parameter = @{
            URI          = "{0}/worklog" -f $issueRestUrl
            Method       = "GET"
            GetParameter = @{
                maxResults = $script:DefaultPageSize
                expand     = 'properties'
            }
            OutputType   = "JiraWorklogItem"
            Paging       = $true
            Credential   = $Credential
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        Invoke-JiraMethod @parameter
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
