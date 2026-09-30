function Get-JiraBulkOperationProgress {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.BulkOperationProgress])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')]
        [String]
        $TaskId,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        if (-not (Test-JiraCloudServer -Credential $Credential)) {
            $errorParameter = @{
                Cmdlet       = $PSCmdlet
                Exception    = [System.NotSupportedException]::new('Get-JiraBulkOperationProgress uses Jira Cloud bulk-operation status polling and is not supported against Jira Server or Data Center.')
                ErrorId      = 'OperationNotSupported.JiraCloudOnly'
                Category     = [System.Management.Automation.ErrorCategory]::NotImplemented
                TargetObject = $TaskId
            }
            ThrowError @errorParameter
        }

        $result = Invoke-JiraMethod -URI "/rest/api/3/bulk/queue/$TaskId" -Method GET -Credential $Credential
        Write-Output (ConvertTo-JiraBulkOperationProgress -InputObject $result)
    }
}
