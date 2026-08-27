function Set-JiraOAuthAuthorizationHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Hashtable]
        $Headers,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )

    if (-not $script:JiraOAuthClientCredentials) {
        return
    }

    if ($Headers.ContainsKey('Authorization')) {
        return
    }

    $accessToken = Get-JiraOAuthClientCredentialsAccessToken
    if ([String]::IsNullOrWhiteSpace($accessToken)) {
        return
    }

    $authorization = "Bearer $accessToken"
    $Headers['Authorization'] = $authorization
    if ($WebSession) {
        $WebSession.Headers['Authorization'] = $authorization
    }
}
