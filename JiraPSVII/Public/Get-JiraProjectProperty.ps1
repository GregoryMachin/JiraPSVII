function Get-JiraProjectProperty {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    [OutputType('AtlassianPSVII.JiraPSVII.EntityProperty')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
        [Alias('Key')]
        [AtlassianPSVII.JiraPSVII.Project]
        $Project,

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
        $projectIdentifier = if ($Project.Key) { $Project.Key } else { $Project.Id }
        $route = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/project/{0}/properties' -IsCloud $isCloud
        if ($PropertyKey) { $route += '/' + [Uri]::EscapeDataString($PropertyKey) }
        $result = Invoke-JiraMethod -URI ($route -f [Uri]::EscapeDataString([String]$projectIdentifier)) -Method GET -Credential $Credential
        if ($PropertyKey) { Write-Output (ConvertTo-JiraEntityProperty -InputObject $result) }
        elseif ($result.keys) { Write-Output (ConvertTo-JiraEntityProperty -InputObject @($result.keys)) }
    }
}
