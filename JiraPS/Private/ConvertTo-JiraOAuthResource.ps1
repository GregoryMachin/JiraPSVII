function ConvertTo-JiraOAuthResource {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.OAuthResource])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject
    )

    process {
        foreach ($resource in $InputObject) {
            $cloudId = [String]$resource.id
            $null = Resolve-JiraOAuthBaseUri -CloudId $cloudId
            $siteUrl = Resolve-JiraOAuthSiteUri -SiteUrl ([Uri]$resource.url)

            $avatarUrl = $null
            if (-not [String]::IsNullOrWhiteSpace([String]$resource.avatarUrl)) {
                [Uri]$parsedAvatarUrl = $null
                if ([Uri]::TryCreate([String]$resource.avatarUrl, [UriKind]::Absolute, [ref]$parsedAvatarUrl)) {
                    $avatarUrl = $parsedAvatarUrl
                }
            }

            [AtlassianPS.JiraPS.OAuthResource]@{
                CloudId   = ([Guid]$cloudId).ToString('D')
                Name      = [String]$resource.name
                Url       = $siteUrl
                Scopes    = [String[]]@($resource.scopes | Where-Object { $_ })
                AvatarUrl = $avatarUrl
            }
        }
    }
}
