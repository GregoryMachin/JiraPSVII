function Get-JiraProjectClassificationLevel {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.ProjectClassificationLevel])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNull()]
        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
        [AtlassianPSVII.JiraPSVII.Project[]]
        $Project,

        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        if (-not (Test-JiraCloudServer -Credential $Credential)) {
            $errorParameter = @{
                Cmdlet       = $PSCmdlet
                Exception    = [System.NotSupportedException]::new('Project classification levels are available only on Jira Cloud.')
                ErrorId      = 'OperationNotSupported.JiraCloudOnly'
                Category     = [System.Management.Automation.ErrorCategory]::NotImplemented
                TargetObject = $Project
            }
            ThrowError @errorParameter
        }
    }

    process {
        foreach ($projectItem in $Project) {
            $projectIdentifier = if ($projectItem.Key) { $projectItem.Key } else { $projectItem.Id }
            if (-not $projectIdentifier) {
                throw [System.ArgumentException]::new('Project key or ID is required to retrieve classification levels.', 'Project')
            }

            $projectPathSegment = [Uri]::EscapeDataString([String]$projectIdentifier)
            $uri = "/rest/api/3/project/$projectPathSegment/classification-config"
            $result = Invoke-JiraMethod -URI $uri -Method GET -Credential $Credential
            ConvertTo-JiraProjectClassificationLevel -InputObject $result
        }
    }
}
