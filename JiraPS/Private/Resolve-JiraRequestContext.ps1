function Resolve-JiraRequestContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Uri]
        $Uri,

        [Hashtable]
        $GetParameter = @{},

        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $DefaultPageSize,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet
    )

    $providedUriValue = $Uri.OriginalString
    $oauthBaseUri = $null
    if ($script:JiraServerMetadata -and [string]$script:JiraServerMetadata.AuthenticationType -eq 'OAuth') {
        $oauthBaseUri = Resolve-JiraOAuthBaseUri -CloudId ([string]$script:JiraServerMetadata.CloudId)
    }

    if (-not $Uri.IsAbsoluteUri) {
        if (-not $providedUriValue.StartsWith('/')) {
            $errorParameter = @{
                Cmdlet       = $Cmdlet
                Exception    = [System.ArgumentException]::new("Invalid URI path '$providedUriValue'. Relative URIs must start with '/'.")
                ErrorId      = 'ParameterValue.UriPathMustStartWithSlash'
                Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = $providedUriValue
            }
            ThrowError @errorParameter
        }

        if ($oauthBaseUri) {
            [Uri]$Uri = "{0}{1}" -f $oauthBaseUri.AbsoluteUri.TrimEnd('/'), $providedUriValue
        }
        else {
            $server = Get-JiraConfigServer -ErrorAction SilentlyContinue
            if ([String]::IsNullOrWhiteSpace($server)) {
                $errorParameter = @{
                    Cmdlet       = $Cmdlet
                    Exception    = [System.ArgumentException]::new("Cannot resolve relative URI '$providedUriValue' because no Jira server is configured. Use Set-JiraConfigServer first.")
                    ErrorId      = 'ParameterValue.JiraServerNotConfigured'
                    Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    TargetObject = $providedUriValue
                }
                ThrowError @errorParameter
            }

            [Uri]$Uri = "{0}{1}" -f $server.TrimEnd('/'), $providedUriValue
        }
    }

    if (-not $Uri.IsAbsoluteUri) {
        $errorParameter = @{
            Cmdlet       = $Cmdlet
            Exception    = [System.ArgumentException]::new("Invoke-JiraMethod: -Uri must be an absolute URI. Got '$providedUriValue'.")
            ErrorId      = 'ParameterValue.UriMustBeAbsolute'
            Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
            TargetObject = $providedUriValue
        }
        ThrowError @errorParameter
    }

    if ($oauthBaseUri) {
        $isAtlassianApiHost = $Uri.Scheme -eq 'https'
        $isAtlassianApiHost = $isAtlassianApiHost -and $Uri.Host -ceq 'api.atlassian.com'
        $isAtlassianApiHost = $isAtlassianApiHost -and $Uri.IsDefaultPort
        $isAtlassianApiHost = $isAtlassianApiHost -and [string]::IsNullOrEmpty($Uri.UserInfo)
        $oauthApiPath = $oauthBaseUri.AbsolutePath.TrimEnd('/')
        $isCloudApiPath = $Uri.AbsolutePath -eq $oauthApiPath
        $isCloudApiPath = $isCloudApiPath -or $Uri.AbsolutePath.StartsWith("$oauthApiPath/", [StringComparison]::Ordinal)
        $isResourceDiscoveryPath = $Uri.AbsolutePath -eq '/oauth/token/accessible-resources'

        if (-not $isAtlassianApiHost -or (-not $isCloudApiPath -and -not $isResourceDiscoveryPath)) {
            $errorParameter = @{
                Cmdlet       = $Cmdlet
                Exception    = [System.ArgumentException]::new('OAuth requests are restricted to the configured Jira Cloud ID under https://api.atlassian.com.')
                ErrorId      = 'ParameterValue.UntrustedOAuthUri'
                Category     = [System.Management.Automation.ErrorCategory]::SecurityError
                TargetObject = $Uri.GetLeftPart([UriPartial]::Path)
            }
            ThrowError @errorParameter
        }
    }

    $uriQuery = ConvertTo-ParameterHash -Uri $Uri
    $internalGetParameter = Join-Hashtable $uriQuery, $GetParameter

    $prohibitedTokenParameters = @(
        'access_token'
        'accesstoken'
        'api_token'
        'apitoken'
        'authorization'
        'bearertoken'
        'oauthaccesstoken'
        'personalaccesstoken'
    )
    $normalizedProhibitedNames = @($prohibitedTokenParameters | ForEach-Object { $_.Replace('_', '') })
    foreach ($parameterName in @($internalGetParameter.Keys)) {
        $normalizedParameterName = ([string]$parameterName).Replace('-', '').Replace('_', '').ToLowerInvariant()
        if ($normalizedParameterName -in $normalizedProhibitedNames) {
            $errorParameter = @{
                Cmdlet       = $Cmdlet
                Exception    = [System.ArgumentException]::new("Authentication tokens are not permitted in URI query parameters ('$parameterName'). Use an Authorization header.")
                ErrorId      = 'ParameterValue.TokenInQuery'
                Category     = [System.Management.Automation.ErrorCategory]::SecurityError
                TargetObject = $parameterName
            }
            ThrowError @errorParameter
        }
    }

    [Uri]$resolvedUri = $Uri.GetLeftPart("Path")

    if (-not $internalGetParameter.ContainsKey("maxResults")) {
        $internalGetParameter["maxResults"] = $DefaultPageSize
    }

    if ($Cmdlet -and $Cmdlet.PagingParameters) {
        if ($Cmdlet.PagingParameters.Skip) {
            $internalGetParameter["startAt"] = $Cmdlet.PagingParameters.Skip
        }

        if ($Cmdlet.PagingParameters.First -lt $internalGetParameter["maxResults"]) {
            $internalGetParameter["maxResults"] = $Cmdlet.PagingParameters.First
        }
    }

    [Uri]$paginatedUri = "{0}{1}" -f $resolvedUri, (ConvertTo-GetParameter $internalGetParameter)

    [PSCustomObject]@{
        Uri          = $resolvedUri
        PaginatedUri = $paginatedUri
        GetParameter = $internalGetParameter
    }
}
