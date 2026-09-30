function Remove-JiraIssueBulk {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByIssue')]
    [OutputType([AtlassianPSVII.JiraPSVII.SubmittedBulkOperation], [AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest])]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByIssue')]
        [ValidateNotNullOrEmpty()]
        [Alias('IssueId', 'Key')]
        [Object[]]
        $Issue,

        [Parameter(Mandatory, ParameterSetName = 'ByRequest')]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest]
        $Request,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $SkipNotification,

        [Switch]
        $ValidateOnly
    )

    process {
        if ($PsCmdlet.ParameterSetName -eq 'ByRequest') {
            $bulkRequest = $Request
        }
        else {
            $bulkRequest = [AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest]@{
                SelectedIssueIdsOrKeys = Resolve-JiraBulkIssueIdOrKey -Issue $Issue -CallerName $MyInvocation.MyCommand.Name
                SendBulkNotification   = -not $SkipNotification
            }
        }

        $payload = $bulkRequest.ToJiraPayload()
        if ($ValidateOnly) {
            Write-Output $bulkRequest
            return
        }

        if (-not (Test-JiraCloudServer -Credential $Credential)) {
            $errorParameter = @{
                Cmdlet       = $PSCmdlet
                Exception    = [System.NotSupportedException]::new('Remove-JiraIssueBulk uses Jira Cloud issue bulk operations and is not supported against Jira Server or Data Center.')
                ErrorId      = 'OperationNotSupported.JiraCloudOnly'
                Category     = [System.Management.Automation.ErrorCategory]::NotImplemented
                TargetObject = $bulkRequest
            }
            ThrowError @errorParameter
        }

        $target = '{0} issue(s)' -f @($bulkRequest.SelectedIssueIdsOrKeys).Count
        if ($PSCmdlet.ShouldProcess($target, 'Permanently delete Jira issues in bulk')) {
            $result = Invoke-JiraMethod `
                -URI '/rest/api/3/bulk/issues/delete' `
                -Method POST `
                -Body (ConvertTo-Json -InputObject $payload -Depth 30) `
                -Credential $Credential

            Write-Output (ConvertTo-JiraSubmittedBulkOperation -InputObject $result)
        }
    }
}
