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
        [Parameter(ParameterSetName = 'ApiToken')]
        [ValidateNotNullOrEmpty()]
        [String]
        $CloudId,

        [Parameter(Mandatory, ParameterSetName = 'OAuthClientCredentials')]
        [ValidateNotNullOrEmpty()]
        [String]
        $OAuthClientId,

        [Parameter(Mandatory, ParameterSetName = 'OAuthClientCredentials')]
        [SecureString]
        $OAuthClientSecret,

        [Parameter(ParameterSetName = 'OAuthClientCredentials')]
        [ValidateNotNullOrEmpty()]
        [String]
        $OAuthCloudId,

        [Parameter(ParameterSetName = 'OAuthClientCredentials')]
        [ValidateNotNullOrEmpty()]
        [String]
        $OAuthSiteName,

        [Parameter(ParameterSetName = 'OAuthClientCredentials')]
        [Uri]
        $OAuthSiteUrl,

        [Parameter(ParameterSetName = 'OAuthClientCredentials')]
        [ValidateScript({ $_ -gt [TimeSpan]::Zero })]
        [TimeSpan]
        $OAuthTokenRefreshSkew = [TimeSpan]::FromMinutes(5),

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
        $previousOAuthClientCredentials = $script:JiraOAuthClientCredentials
        $restoreServerMetadata = $false
        $restoreOAuthClientCredentials = $false
        $sessionResult = $null

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
                if ($PSBoundParameters.ContainsKey('CloudId')) {
                    $null = Resolve-JiraOAuthBaseUri -CloudId $CloudId
                    $script:JiraServerMetadata = @{
                        DeploymentType     = 'Cloud'
                        AuthenticationType = 'ApiToken'
                        CloudId            = ([Guid]$CloudId).ToString('D')
                    }
                    $restoreServerMetadata = $true
                    $resourceUri = '/rest/api/3/myself'
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using scoped API token authentication (Cloud gateway)"
                }
                else {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using legacy API token authentication (Cloud site route)"
                }
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
            'OAuthClientCredentials' {
                $selectorParameters = @{}
                if ($PSBoundParameters.ContainsKey('OAuthCloudId')) { $selectorParameters.CloudId = $OAuthCloudId }
                if ($PSBoundParameters.ContainsKey('OAuthSiteName')) { $selectorParameters.SiteName = $OAuthSiteName }
                if ($PSBoundParameters.ContainsKey('OAuthSiteUrl')) { $selectorParameters.SiteUrl = $OAuthSiteUrl }
                if ($selectorParameters.Count -gt 1) {
                    throw [System.ArgumentException]::new('Specify only one OAuth resource selector: OAuthCloudId, OAuthSiteName, or OAuthSiteUrl.')
                }

                $token = Request-JiraOAuthClientCredentialsToken -ClientId $OAuthClientId -ClientSecret $OAuthClientSecret -RefreshSkew $OAuthTokenRefreshSkew
                $resources = @(Get-JiraOAuthResource -OAuthAccessToken $token.AccessToken)
                if ($selectorParameters.ContainsKey('CloudId')) {
                    $null = Resolve-JiraOAuthBaseUri -CloudId $selectorParameters.CloudId
                    $normalizedCloudId = ([Guid]$selectorParameters.CloudId).ToString('D')
                    $resources = @($resources | Where-Object { $_.CloudId -ceq $normalizedCloudId })
                }
                elseif ($selectorParameters.ContainsKey('SiteUrl')) {
                    $normalizedSiteUrl = Resolve-JiraOAuthSiteUri -SiteUrl $selectorParameters.SiteUrl
                    $resources = @($resources | Where-Object { $_.Url.AbsoluteUri -ceq $normalizedSiteUrl.AbsoluteUri })
                }
                elseif ($selectorParameters.ContainsKey('SiteName')) {
                    $resources = @($resources | Where-Object { $_.Name -ceq $selectorParameters.SiteName })
                }

                $jiraResources = @($resources | Where-Object {
                        @($_.Scopes | Where-Object { $_ -match '(^|:)jira($|-)' -or $_ -like '*:jira-*' }).Count -gt 0
                    })
                if ($selectorParameters.Count -eq 0) {
                    if ($jiraResources.Count -eq 0) {
                        throw [System.InvalidOperationException]::new('The OAuth client-credentials grant has no accessible Jira resources. Confirm the app is installed for Jira and has Jira scopes.')
                    }
                    if ($jiraResources.Count -gt 1) {
                        throw [System.InvalidOperationException]::new('More than one accessible Jira OAuth resource matched. Select the site with -OAuthCloudId, -OAuthSiteName, or -OAuthSiteUrl.')
                    }
                    $selectedResource = $jiraResources[0]
                }
                else {
                    if ($jiraResources.Count -eq 0) {
                        throw [System.InvalidOperationException]::new('The selected OAuth resource does not include Jira scopes.')
                    }
                    if ($jiraResources.Count -gt 1) {
                        throw [System.InvalidOperationException]::new('The OAuth resource selector identified more than one Jira resource. Select the site with -OAuthCloudId, -OAuthSiteName, or -OAuthSiteUrl.')
                    }
                    $selectedResource = $jiraResources[0]
                }

                $null = Resolve-JiraOAuthBaseUri -CloudId $selectedResource.CloudId
                $script:JiraServerMetadata = @{
                    DeploymentType     = 'Cloud'
                    AuthenticationType = 'OAuth'
                    CloudId            = ([Guid]$selectedResource.CloudId).ToString('D')
                }
                $script:JiraOAuthClientCredentials = @{
                    ClientId     = $OAuthClientId
                    ClientSecret = $OAuthClientSecret
                    AccessToken  = $token.AccessToken
                    ExpiresAt    = $token.ExpiresAt
                    RefreshAt    = $token.RefreshAt
                    RefreshSkew  = $OAuthTokenRefreshSkew
                    TokenType    = $token.TokenType
                    Scopes       = $token.Scopes
                    CloudId      = ([Guid]$selectedResource.CloudId).ToString('D')
                }
                $restoreServerMetadata = $true
                $restoreOAuthClientCredentials = $true

                $webSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
                Set-JiraOAuthAuthorizationHeader -Headers $requestHeaders -WebSession $webSession
                $sessionResult = ConvertTo-JiraSession -Session $webSession -DeploymentType Cloud -AuthenticationType OAuth -CloudId $script:JiraServerMetadata.CloudId
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using OAuth client-credentials authentication (Cloud)"
            }
        }

        if (-not $sessionResult) {
            $parameter = @{
                URI          = $resourceURi
                Method       = "GET"
                Headers      = $requestHeaders
                StoreSession = $true
            }
            if ($Credential) { $parameter.Add('Credential', $Credential) }
            try {
                $sessionResult = Invoke-JiraMethod @parameter
                $script:JiraOAuthResourceCache = $null
                $script:JiraOAuthClientCredentials = $null
                $restoreServerMetadata = $false
            }
            finally {
                $tokenPlain = $null
                $authString = $null
                $base64Auth = $null
                if ($restoreServerMetadata) {
                    $script:JiraServerMetadata = $previousServerMetadata
                }
                if ($restoreOAuthClientCredentials) {
                    $script:JiraOAuthClientCredentials = $previousOAuthClientCredentials
                }
            }
        }
        else {
            $script:JiraOAuthResourceCache = $null
            $restoreServerMetadata = $false
            $restoreOAuthClientCredentials = $false
        }

        $commandModule = $MyInvocation.MyCommand.Module
        if (-not $commandModule) {
            $commandModule = Get-Module -Name JiraPS | Select-Object -First 1
        }

        if (-not $commandModule) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Session result could not be stored because no JiraPS module instance was available"
        }
        elseif ($commandModule.PrivateData) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Adding session result to existing module PrivateData"
            $commandModule.PrivateData.Session = $sessionResult
        }
        else {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Creating module PrivateData"
            $commandModule.PrivateData = @{
                'Session' = $sessionResult
            }
        }

        Write-Output $sessionResult
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
