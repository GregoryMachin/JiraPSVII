function Move-JiraIssueBulk {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByIssue')]
    [OutputType([AtlassianPS.JiraPS.SubmittedBulkOperation], [AtlassianPS.JiraPS.BulkIssueMoveRequest])]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByIssue')]
        [ValidateNotNullOrEmpty()]
        [Alias('IssueId', 'Key')]
        [Object[]]
        $Issue,

        [Parameter(Mandatory, ParameterSetName = 'ByIssue')]
        [ValidateNotNullOrEmpty()]
        [String]
        $TargetProject,

        [Parameter(Mandatory, ParameterSetName = 'ByIssue')]
        [ValidateNotNullOrEmpty()]
        [String]
        $TargetIssueType,

        [Parameter(ParameterSetName = 'ByIssue')]
        [ValidateNotNullOrEmpty()]
        [String]
        $TargetParent,

        [Parameter(Mandatory, ParameterSetName = 'ByRequest')]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.BulkIssueMoveRequest]
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
            $issueIdsOrKeys = Resolve-JiraBulkIssueIdOrKey -Issue $Issue -CallerName $MyInvocation.MyCommand.Name
            $targetKeyParts = @($TargetProject, $TargetIssueType)
            if ($TargetParent) { $targetKeyParts += $TargetParent }

            $target = [AtlassianPS.JiraPS.BulkIssueMoveTarget]@{
                IssueIdsOrKeys          = $issueIdsOrKeys
                InferClassificationDefaults = $true
                InferFieldDefaults      = $true
                InferStatusDefaults     = $true
                InferSubtaskTypeDefault = $true
            }
            $bulkRequest = [AtlassianPS.JiraPS.BulkIssueMoveRequest]@{
                SendBulkNotification   = -not $SkipNotification
                TargetToSourcesMapping = @{ ($targetKeyParts -join ',') = $target }
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
                Exception    = [System.NotSupportedException]::new('Move-JiraIssueBulk uses Jira Cloud issue bulk operations and is not supported against Jira Server or Data Center.')
                ErrorId      = 'OperationNotSupported.JiraCloudOnly'
                Category     = [System.Management.Automation.ErrorCategory]::NotImplemented
                TargetObject = $bulkRequest
            }
            ThrowError @errorParameter
        }

        $issueCount = @($bulkRequest.TargetToSourcesMapping.Values | ForEach-Object { $_.IssueIdsOrKeys } | Where-Object { $_ }).Count
        $target = '{0} issue(s) to {1}' -f $issueCount, ($bulkRequest.TargetToSourcesMapping.Keys -join '; ')
        if ($PSCmdlet.ShouldProcess($target, 'Submit Jira bulk issue move')) {
            $result = Invoke-JiraMethod `
                -URI '/rest/api/3/bulk/issues/move' `
                -Method POST `
                -Body (ConvertTo-Json -InputObject $payload -Depth 30) `
                -Credential $Credential

            Write-Output (ConvertTo-JiraSubmittedBulkOperation -InputObject $result)
        }
    }
}
