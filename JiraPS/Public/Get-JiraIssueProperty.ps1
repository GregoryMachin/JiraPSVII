function Get-JiraIssueProperty {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType('AtlassianPS.JiraPS.EntityProperty')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.IssueTransformation()]
        [Alias('Key')]
        [AtlassianPS.JiraPS.Issue]
        $Issue,

        [Parameter(Position = 1)]
        [String]
        $PropertyKey,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        if ($PropertyKey) { Test-JiraEntityPropertyKey -Key $PropertyKey }
        $isCloud = Test-JiraCloudServer -Credential $Credential
        $issueKey = [Uri]::EscapeDataString([String]$Issue.Key)
        $route = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/issue/{0}/properties' -IsCloud $isCloud
        if ($PropertyKey) { $route += '/' + [Uri]::EscapeDataString($PropertyKey) }
        $result = Invoke-JiraMethod -URI ($route -f $issueKey) -Method GET -Credential $Credential
        if ($PropertyKey) { Write-Output (ConvertTo-JiraEntityProperty -InputObject $result) }
        elseif ($result.keys) { Write-Output (ConvertTo-JiraEntityProperty -InputObject @($result.keys)) }
    }
}
