function Get-JiraServerInformation {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $Force
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceURi = "/rest/api/2/serverInfo"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($script:JiraServerInfo -and -not $Force) {
            Write-Output $script:JiraServerInfo
            return
        }

        $parameter = @{
            URI         = $resourceURi
            Method      = "GET"
            Credential  = $Credential
            CacheKey    = 'ServerInfo'
            CacheExpiry = [TimeSpan]::FromMinutes(5)
            BypassCache = $Force
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

        try {
            $result = Invoke-JiraMethod @parameter
            $script:JiraServerInfo = ConvertTo-JiraServerInfo -InputObject $result
            Write-Output $script:JiraServerInfo
        }
        catch {
            if ($script:JiraServerMetadata -and -not [string]::IsNullOrWhiteSpace([string]$script:JiraServerMetadata.DeploymentType)) {
                $script:JiraServerInfo = [AtlassianPSVII.JiraPSVII.ServerInfo]@{
                    BaseURL        = $script:JiraServerUrl
                    DeploymentType = $script:JiraServerMetadata.DeploymentType
                }
                Write-Output $script:JiraServerInfo
                return
            }

            $exceptionType = if ($_.Exception) { $_.Exception.GetType().FullName } else { 'Unknown' }
            $exception = [System.InvalidOperationException]"Unable to determine Jira deployment type from /rest/api/2/serverInfo. Configure explicit DeploymentType metadata with AtlassianPSVII.Configuration and pass that server entry to Set-JiraConfigServer, or fix the Jira URL, network connectivity, or authentication before retrying. Underlying error type: $exceptionType."
            $errorItem = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                'JiraPSVII.ServerInfo.AutoDetectionFailed',
                [System.Management.Automation.ErrorCategory]::ConnectionError,
                $script:JiraServerUrl
            )
            throw $errorItem
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

New-Alias -Name "Get-JiraServerInfo" -Value "Get-JiraServerInformation" -ErrorAction SilentlyContinue
