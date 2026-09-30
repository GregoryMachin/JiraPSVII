function Remove-JiraProjectProperty {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
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

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        Test-JiraEntityPropertyKey -Key $PropertyKey
        $isCloud = Test-JiraCloudServer -Credential $Credential
        $projectIdentifier = if ($Project.Key) { $Project.Key } else { $Project.Id }
        $route = ConvertTo-JiraRestApiV3Url -Url '/rest/api/2/project/{0}/properties/{1}' -IsCloud $isCloud
        $uri = $route -f [Uri]::EscapeDataString([String]$projectIdentifier), [Uri]::EscapeDataString($PropertyKey)
        if ($PSCmdlet.ShouldProcess("$projectIdentifier property $PropertyKey", 'Remove Jira project property')) {
            Invoke-JiraMethod -URI $uri -Method DELETE -Credential $Credential
        }
    }
}
