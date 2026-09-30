function Test-JiraCloudServer {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    if ($script:JiraServerMetadata -and -not [string]::IsNullOrWhiteSpace([string]$script:JiraServerMetadata.DeploymentType)) {
        return $script:JiraServerMetadata.DeploymentType -eq 'Cloud'
    }

    (Get-JiraServerInformation -Credential $Credential -ErrorAction Stop).DeploymentType -eq 'Cloud'
}
