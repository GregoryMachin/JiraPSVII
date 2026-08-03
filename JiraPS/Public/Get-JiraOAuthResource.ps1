function Get-JiraOAuthResource {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.OAuthResource])]
    param(
        [Parameter()]
        [SecureString]
        $OAuthAccessToken,

        [Parameter()]
        [String]
        $CloudId,

        [Parameter()]
        [String]
        $SiteName,

        [Parameter()]
        [Uri]
        $SiteUrl,

        [Parameter()]
        [ValidateScript({ $_ -gt [TimeSpan]::Zero })]
        [TimeSpan]
        $CacheExpiry = [TimeSpan]::FromMinutes(15),

        [Parameter()]
        [Switch]
        $BypassCache
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        $selectorParameters = @{}
        foreach ($selectorName in 'CloudId', 'SiteName', 'SiteUrl') {
            if ($PSBoundParameters.ContainsKey($selectorName)) {
                $selectorParameters[$selectorName] = $PSBoundParameters[$selectorName]
            }
        }
        if ($selectorParameters.Count -gt 1) {
            throw [System.ArgumentException]::new('Specify only one OAuth resource selector: CloudId, SiteName, or SiteUrl.')
        }

        $resourceUri = 'https://api.atlassian.com/oauth/token/accessible-resources'
    }

    process {
        $hasExplicitToken = $PSBoundParameters.ContainsKey('OAuthAccessToken')
        $requestHeaders = @{}
        if ($hasExplicitToken) {
            $script:JiraOAuthResourceCache = $null
            $tokenPlain = [System.Net.NetworkCredential]::new('', $OAuthAccessToken).Password
            if ([String]::IsNullOrWhiteSpace($tokenPlain)) {
                throw [System.ArgumentException]::new('OAuthAccessToken must not be empty.', 'OAuthAccessToken')
            }
            $requestHeaders['Authorization'] = "Bearer $tokenPlain"
        }
        else {
            $session = Get-JiraSession
            if (-not $session -or $session.AuthenticationType -ne 'OAuth') {
                throw [System.InvalidOperationException]::new('Provide OAuthAccessToken or create an OAuth session with New-JiraSession first.')
            }
        }

        $useCache = -not $hasExplicitToken -and -not $BypassCache
        if ($useCache -and $script:JiraOAuthResourceCache -and (Get-Date) -lt $script:JiraOAuthResourceCache.Expiry) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Using cached OAuth resource metadata"
            Resolve-JiraOAuthResource -Resource $script:JiraOAuthResourceCache.Data @selectorParameters
            return
        }

        try {
            $response = Invoke-JiraMethod -Uri $resourceUri -Method Get -Headers $requestHeaders
            $resources = @($response | ConvertTo-JiraOAuthResource)
            if (-not $hasExplicitToken) {
                $script:JiraOAuthResourceCache = @{
                    Data   = [AtlassianPS.JiraPS.OAuthResource[]]$resources
                    Expiry = (Get-Date).Add($CacheExpiry)
                }
            }
            Resolve-JiraOAuthResource -Resource $resources @selectorParameters
        }
        catch {
            $script:JiraOAuthResourceCache = $null
            throw
        }
        finally {
            $tokenPlain = $null
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
