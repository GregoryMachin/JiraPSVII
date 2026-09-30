function Set-JiraIssueProperty {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType('AtlassianPSVII.JiraPSVII.EntityProperty')]
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

        [Parameter(Mandatory, Position = 2)]
        [AllowNull()]
        [Object]
        $Value,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        Test-JiraEntityPropertyKey -Key $PropertyKey
        $body = ConvertTo-JiraPropertyJson -Value $Value
        $isCloud = Test-JiraCloudServer -Credential $Credential
        $route = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/issue/{0}/properties/{1}' -IsCloud $isCloud
        $uri = $route -f [Uri]::EscapeDataString([String]$Issue.Key), [Uri]::EscapeDataString($PropertyKey)
        if ($PSCmdlet.ShouldProcess("$($Issue.Key) property $PropertyKey", 'Set Jira issue property')) {
            $result = Invoke-JiraMethod -URI $uri -Method PUT -Body $body -RawBody -Credential $Credential
            Write-Output (ConvertTo-JiraEntityProperty -InputObject ([PSCustomObject]@{ key = $PropertyKey; value = $result }))
        }
    }
}
