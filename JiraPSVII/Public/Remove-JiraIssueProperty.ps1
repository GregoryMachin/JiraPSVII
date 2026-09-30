function Remove-JiraIssueProperty {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPSVII.JiraPSVII.Issue]
        $Issue,

        [Parameter(Mandatory, Position = 1)]
        [String]
        $PropertyKey,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        Test-JiraEntityPropertyKey -Key $PropertyKey
        $isCloud = Test-JiraCloudServer -Credential $Credential
        $route = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/issue/{0}/properties/{1}' -IsCloud $isCloud
        $uri = $route -f [Uri]::EscapeDataString([String]$Issue.Key), [Uri]::EscapeDataString($PropertyKey)
        if ($PSCmdlet.ShouldProcess("$($Issue.Key) property $PropertyKey", 'Remove Jira issue property')) {
            Invoke-JiraMethod -URI $uri -Method DELETE -Credential $Credential
        }
    }
}
