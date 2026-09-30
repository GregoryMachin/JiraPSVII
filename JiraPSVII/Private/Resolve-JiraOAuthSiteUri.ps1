function Resolve-JiraOAuthSiteUri {
    [CmdletBinding()]
    [OutputType([System.Uri])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Uri]
        $SiteUrl
    )

    $isTrustedSite = $SiteUrl.IsAbsoluteUri -and $SiteUrl.Scheme -eq 'https'
    $isTrustedSite = $isTrustedSite -and $SiteUrl.IsDefaultPort
    $isTrustedSite = $isTrustedSite -and [String]::IsNullOrEmpty($SiteUrl.UserInfo)
    $isTrustedSite = $isTrustedSite -and $SiteUrl.Host.EndsWith('.atlassian.net', [StringComparison]::OrdinalIgnoreCase)
    $isTrustedSite = $isTrustedSite -and ($SiteUrl.AbsolutePath -eq '/' -or [String]::IsNullOrEmpty($SiteUrl.AbsolutePath))
    $isTrustedSite = $isTrustedSite -and [String]::IsNullOrEmpty($SiteUrl.Query)
    $isTrustedSite = $isTrustedSite -and [String]::IsNullOrEmpty($SiteUrl.Fragment)
    if (-not $isTrustedSite) {
        throw [System.ArgumentException]::new('OAuth site URLs must be HTTPS root URLs on a *.atlassian.net host without user information, a custom port, query, or fragment.', 'SiteUrl')
    }

    [Uri]("https://{0}/" -f $SiteUrl.IdnHost.ToLowerInvariant())
}
