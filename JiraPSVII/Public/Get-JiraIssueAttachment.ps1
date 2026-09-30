function Get-JiraIssueAttachment {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPSVII.JiraPSVII.Issue]
        $Issue,

        [String]
        $FileName,

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

        if ($issueObj.Attachment) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Found Attachments on the Issue."
            if ($FileName) {
                $attachments = $issueObj.Attachment | Where-Object { $_.Filename -like $FileName }
            }
            else {
                $attachments = $issueObj.Attachment
            }

            ConvertTo-JiraAttachment -InputObject $attachments
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

