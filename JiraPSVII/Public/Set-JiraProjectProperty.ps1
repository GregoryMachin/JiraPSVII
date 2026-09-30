function Set-JiraProjectProperty {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType('AtlassianPSVII.JiraPSVII.EntityProperty')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
        [Alias('Key')]
        [AtlassianPSVII.JiraPSVII.Project]
        $Project,

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
        $projectIdentifier = if ($Project.Key) { $Project.Key } else { $Project.Id }
        $route = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/project/{0}/properties/{1}' -IsCloud $isCloud
        $uri = $route -f [Uri]::EscapeDataString([String]$projectIdentifier), [Uri]::EscapeDataString($PropertyKey)
        if ($PSCmdlet.ShouldProcess("$projectIdentifier property $PropertyKey", 'Set Jira project property')) {
            $result = Invoke-JiraMethod -URI $uri -Method PUT -Body $body -RawBody -Credential $Credential
            Write-Output (ConvertTo-JiraEntityProperty -InputObject ([PSCustomObject]@{ key = $PropertyKey; value = $result }))
        }
    }
}
