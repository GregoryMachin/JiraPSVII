function New-JiraSession {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [Parameter(ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,

        [Parameter(Mandatory, ParameterSetName = 'PersonalAccessToken')]
        [Alias('BearerToken', 'PAT')]
        [SecureString]
        $PersonalAccessToken,

        [Parameter(Mandatory, ParameterSetName = 'ApiToken')]
        [SecureString]
        $ApiToken,

        [Parameter(Mandatory, ParameterSetName = 'ApiToken')]
        [string]
        $EmailAddress,

        [Parameter(Mandatory, ParameterSetName = 'OAuthAccessToken')]
        [SecureString]
        $OAuthAccessToken,

        [Parameter(Mandatory, ParameterSetName = 'OAuthAccessToken', ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CloudId,

        [Hashtable]
        $Headers = @{ }
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceUri = "/rest/api/2/myself"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        $requestHeaders = Join-Hashtable -Hashtable @{}, $Headers
        $previousServerMetadata = $script:JiraServerMetadata
        $restoreServerMetadata = $false

        switch ($PSCmdlet.ParameterSetName) {
            'PersonalAccessToken' {
                $tokenPlain = [System.Net.NetworkCredential]::new('', $PersonalAccessToken).Password
                $requestHeaders['Authorization'] = "Bearer $tokenPlain"
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using Personal Access Token (PAT) authentication"
            }
            'ApiToken' {
                $tokenPlain = [System.Net.NetworkCredential]::new('', $ApiToken).Password
                $authString = "${EmailAddress}:${tokenPlain}"
                $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($authString))
                $requestHeaders['Authorization'] = "Basic $base64Auth"
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using API token authentication (Cloud)"
            }
            'OAuthAccessToken' {
                $null = Resolve-JiraOAuthBaseUri -CloudId $CloudId
                $tokenPlain = [System.Net.NetworkCredential]::new('', $OAuthAccessToken).Password
                if ([String]::IsNullOrWhiteSpace($tokenPlain)) {
                    throw [System.ArgumentException]::new('OAuthAccessToken must not be empty.', 'OAuthAccessToken')
                }

                $requestHeaders['Authorization'] = "Bearer $tokenPlain"
                $script:JiraServerMetadata = @{
                    DeploymentType     = 'Cloud'
                    AuthenticationType = 'OAuth'
                    CloudId            = ([Guid]$CloudId).ToString('D')
                }
                $restoreServerMetadata = $true
                $resourceUri = '/rest/api/3/myself'
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using caller-supplied OAuth access-token authentication (Cloud)"
            }
        }

        $parameter = @{
            URI          = $resourceURi
            Method       = "GET"
            Headers      = $requestHeaders
            StoreSession = $true
        }
        if ($Credential) { $parameter.Add('Credential', $Credential) }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with redacted authentication headers"
        try {
            $result = Invoke-JiraMethod @parameter
            $restoreServerMetadata = $false
        }
        finally {
            $tokenPlain = $null
            $authString = $null
            $base64Auth = $null
            if ($restoreServerMetadata) {
                $script:JiraServerMetadata = $previousServerMetadata
            }
        }

        if ($MyInvocation.MyCommand.Module.PrivateData) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding session result to existing module PrivateData"
            $MyInvocation.MyCommand.Module.PrivateData.Session = $result
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Creating module PrivateData"
            $MyInvocation.MyCommand.Module.PrivateData = @{
                'Session' = $result
            }
        }

        Write-Output $result
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
