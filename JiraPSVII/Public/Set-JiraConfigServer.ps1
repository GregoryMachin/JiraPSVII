function Set-JiraConfigServer {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter( Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName )]
        [ValidateNotNullOrEmpty()]
        [Alias('Uri')]
        [Object]
        $Server
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

    }

    process {
        $configuredServer = Resolve-JiraConfiguredServer -Server $Server

        $script:JiraServerUrl = $configuredServer.Uri
        $script:JiraServerInfo = $null
        $script:JiraServerMetadata = $configuredServer.Metadata

        $serverConfigParent = Split-Path -Path $script:serverConfig -Parent
        if (-not [string]::IsNullOrWhiteSpace($serverConfigParent)) {
            $null = New-Item -Path $serverConfigParent -ItemType Directory -Force
        }
        Set-Content -Value $configuredServer.Uri -Path "$script:serverConfig"
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
