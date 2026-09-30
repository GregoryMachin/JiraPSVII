function Set-JiraOAuthAuthorizationHeader {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        '',
        Justification = 'Private helper used internally by Invoke-JiraMethod to populate an in-memory request header; no interactive ShouldProcess flow is expected.'
    )]
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
