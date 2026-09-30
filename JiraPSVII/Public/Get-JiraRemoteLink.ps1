function Get-JiraRemoteLink {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPSVII.JiraPSVII.Issue]
        $Issue,

        [ValidateRange(1, [Int]::MaxValue)]
        [Int]
        $LinkId,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $isCloud = Test-JiraCloudServer -Credential $Credential
        $resourceUri = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/issue/{0}/remotelink' -IsCloud $isCloud
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$Issue]"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$Issue [$Issue]"

        # Find the proper object for the Issue
        $issueObj = Resolve-JiraIssueObject -InputObject $Issue -Credential $Credential
        if (-not $issueObj.Key) {
            throw [System.ArgumentException]::new('Issue key is required to retrieve remote links.')
        }
        $issuePathSegment = [Uri]::EscapeDataString([string]$issueObj.Key)

        $urlAppendix = ""
        if ($LinkId) {
            $urlAppendix = "/$LinkId"
        }

        $parameter = @{
            URI        = "{0}{1}" -f ($resourceUri -f $issuePathSegment), $urlAppendix
            Method     = "GET"
            Credential = $Credential
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
        $result = Invoke-JiraMethod @parameter

        Write-Output (ConvertTo-JiraLink -InputObject $result)
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
