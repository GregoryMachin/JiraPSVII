function Resolve-JiraConfiguredServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object]
        $Server
    )

    $metadata = @{
        Product            = $null
        DeploymentType     = $null
        AuthenticationType = $null
        CloudId            = $null
    }

    $serverValue = $Server
    if ($Server.PSObject.Properties['Uri']) {
        $serverValue = $Server.Uri

        foreach ($propertyName in @('Product', 'DeploymentType', 'AuthenticationType', 'CloudId')) {
            if ($Server.PSObject.Properties[$propertyName]) {
                $metadata[$propertyName] = $Server.$propertyName
            }
        }

        if ($Server.PSObject.Properties['Type'] -and -not [string]::IsNullOrWhiteSpace([string]$Server.Type)) {
            $serverType = [string]$Server.Type
            if ($serverType -ne 'Jira') {
                throw "Set-JiraConfigServer only accepts Jira server configuration entries. The supplied configuration Type is '$serverType'."
            }
        }
    }

    [Uri]$serverUri = $null
    if (-not [Uri]::TryCreate([string]$serverValue, [UriKind]::Absolute, [ref]$serverUri)) {
        throw "Server must be an absolute URI (e.g., https://jira.domain.com/)"
    }

    if (-not $serverUri.IsAbsoluteUri) {
        throw "Server must be an absolute URI (e.g., https://jira.domain.com/)"
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$metadata.Product) -and [string]$metadata.Product -ne 'Jira') {
        throw "Set-JiraConfigServer only accepts Jira server configuration entries. The supplied configuration Product is '$($metadata.Product)'."
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$metadata.DeploymentType)) {
        switch -Regex ([string]$metadata.DeploymentType) {
            '^(?i:Cloud)$' {
                $metadata.DeploymentType = 'Cloud'
                break
            }
            '^(?i:DataCenter|Data Center)$' {
                $metadata.DeploymentType = 'DataCenter'
                break
            }
            '^(?i:Server)$' {
                $metadata.DeploymentType = 'Server'
                break
            }
            default {
                throw "Unsupported Jira DeploymentType '$($metadata.DeploymentType)'. Use Cloud, DataCenter, or Server."
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$metadata.AuthenticationType) -and [string]$metadata.AuthenticationType -eq 'OAuth') {
        if (-not [string]::IsNullOrWhiteSpace([string]$metadata.DeploymentType) -and $metadata.DeploymentType -ne 'Cloud') {
            throw "Conflicting Jira configuration metadata: AuthenticationType OAuth requires DeploymentType Cloud."
        }

        if ([string]::IsNullOrWhiteSpace([string]$metadata.DeploymentType)) {
            $metadata.DeploymentType = 'Cloud'
        }
    }

    if ($metadata.DeploymentType -eq 'Cloud' -and $serverUri.Scheme -ne 'https') {
        throw "Jira Cloud configuration requires an HTTPS server URI."
    }

    [PSCustomObject]@{
        Uri      = $serverUri
        Metadata = $metadata
    }
}
