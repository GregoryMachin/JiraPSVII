function Resolve-JiraOAuthResource {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.OAuthResource])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AtlassianPSVII.JiraPSVII.OAuthResource[]]
        $Resource,

        [String]
        $CloudId,

        [String]
        $SiteName,

        [Uri]
        $SiteUrl
    )

    $selectorCount = @($PSBoundParameters.Keys | Where-Object { $_ -in 'CloudId', 'SiteName', 'SiteUrl' }).Count
    if ($selectorCount -gt 1) {
        throw [System.ArgumentException]::new('Specify only one OAuth resource selector: CloudId, SiteName, or SiteUrl.')
    }

    if ($PSBoundParameters.ContainsKey('CloudId')) {
        $null = Resolve-JiraOAuthBaseUri -CloudId $CloudId
        $normalizedCloudId = ([Guid]$CloudId).ToString('D')
        $matches = @($Resource | Where-Object { $_.CloudId -ceq $normalizedCloudId })
    }
    elseif ($PSBoundParameters.ContainsKey('SiteUrl')) {
        $normalizedSiteUrl = Resolve-JiraOAuthSiteUri -SiteUrl $SiteUrl
        $matches = @($Resource | Where-Object { $_.Url.AbsoluteUri -ceq $normalizedSiteUrl.AbsoluteUri })
    }
    elseif ($PSBoundParameters.ContainsKey('SiteName')) {
        $matches = @($Resource | Where-Object { $_.Name -ceq $SiteName })
    }
    else {
        return $Resource
    }

    if ($matches.Count -eq 0) {
        throw [System.Management.Automation.ItemNotFoundException]::new('No accessible Jira OAuth resource matched the requested selector.')
    }
    if ($matches.Count -gt 1) {
        throw [System.InvalidOperationException]::new('More than one accessible Jira OAuth resource matched. Select the site by CloudId or SiteUrl instead of display name.')
    }

    $matches[0]
}
