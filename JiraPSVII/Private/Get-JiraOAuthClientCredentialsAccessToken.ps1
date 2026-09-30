function Get-JiraOAuthClientCredentialsAccessToken {
    [CmdletBinding()]
    param()

    if (-not $script:JiraOAuthClientCredentials) {
        return
    }

    $now = [DateTimeOffset]::UtcNow
    if (-not $script:JiraOAuthClientCredentials.AccessToken -or $now -ge $script:JiraOAuthClientCredentials.RefreshAt) {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Renewing Jira OAuth client-credentials access token"
        $token = Request-JiraOAuthClientCredentialsToken `
            -ClientId $script:JiraOAuthClientCredentials.ClientId `
            -ClientSecret $script:JiraOAuthClientCredentials.ClientSecret `
            -RefreshSkew $script:JiraOAuthClientCredentials.RefreshSkew

        $script:JiraOAuthClientCredentials.AccessToken = $token.AccessToken
        $script:JiraOAuthClientCredentials.ExpiresAt = $token.ExpiresAt
        $script:JiraOAuthClientCredentials.RefreshAt = $token.RefreshAt
        $script:JiraOAuthClientCredentials.TokenType = $token.TokenType
        $script:JiraOAuthClientCredentials.Scopes = $token.Scopes
    }

    [System.Net.NetworkCredential]::new('', $script:JiraOAuthClientCredentials.AccessToken).Password
}
