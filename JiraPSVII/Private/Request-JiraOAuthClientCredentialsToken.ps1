function Request-JiraOAuthClientCredentialsToken {
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingConvertToSecureStringWithPlainText",
        "",
        Justification = "OAuth token endpoint returns a plaintext access token; JiraPSVII stores it as SecureString in memory only."
    )]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ClientId,

        [Parameter(Mandatory)]
        [SecureString]
        $ClientSecret,

        [Parameter()]
        [ValidateScript({ $_ -gt [TimeSpan]::Zero })]
        [TimeSpan]
        $RefreshSkew = [TimeSpan]::FromMinutes(5)
    )

    $clientSecretPlain = $null
    $accessTokenPlain = $null
    try {
        $clientSecretPlain = [System.Net.NetworkCredential]::new('', $ClientSecret).Password
        if ([String]::IsNullOrWhiteSpace($clientSecretPlain)) {
            throw [System.ArgumentException]::new('OAuthClientSecret must not be empty.', 'OAuthClientSecret')
        }

        $body = @{
            grant_type    = 'client_credentials'
            client_id     = $ClientId
            client_secret = $clientSecretPlain
            audience      = 'api.atlassian.com'
        } | ConvertTo-Json -Compress

        Set-TlsLevel -Tls12
        $response = Invoke-WebRequest `
            -Uri 'https://auth.atlassian.com/oauth/token' `
            -Method Post `
            -Headers @{ Accept = 'application/json' } `
            -ContentType 'application/json' `
            -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
            -UseBasicParsing `
            -ErrorAction Stop

        $payload = ConvertFrom-Json -InputObject ([String]$response.Content)
        $accessTokenPlain = [String]$payload.access_token
        if ([String]::IsNullOrWhiteSpace($accessTokenPlain)) {
            throw [System.InvalidOperationException]::new('OAuth token response did not contain an access token.')
        }

        $expiresIn = [Int]$payload.expires_in
        if ($expiresIn -le 0) {
            throw [System.InvalidOperationException]::new('OAuth token response did not contain a valid expiry.')
        }

        [PSCustomObject]@{
            AccessToken = ConvertTo-SecureString -String $accessTokenPlain -AsPlainText -Force
            ExpiresAt   = [DateTimeOffset]::UtcNow.AddSeconds($expiresIn)
            RefreshAt   = [DateTimeOffset]::UtcNow.AddSeconds($expiresIn).Subtract($RefreshSkew)
            TokenType   = [String]$payload.token_type
            Scopes      = [String[]]@(([String]$payload.scope -split '\s+') | Where-Object { $_ })
        }
    }
    catch {
        $statusCode = $null
        $errorText = $null
        if ($_.Exception.Response) {
            try {
                $statusCode = [Int]$_.Exception.Response.StatusCode
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = [System.IO.StreamReader]::new($stream)
                $errorPayload = $reader.ReadToEnd()
                if ($errorPayload) {
                    $errorJson = $errorPayload | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($errorJson.error -or $errorJson.error_description) {
                        $errorText = @($errorJson.error, $errorJson.error_description | Where-Object { $_ }) -join ': '
                    }
                }
            }
            catch {
                Write-Verbose "OAuth client-credentials error response body could not be parsed: $($_.Exception.Message)"
            }
        }
        if ([String]::IsNullOrWhiteSpace($errorText)) {
            $errorText = $_.Exception.Message
        }
        $errorText = $errorText -replace [Regex]::Escape([String]$clientSecretPlain), '<redacted>'
        $message = if ($statusCode) {
            "OAuth client-credentials token exchange failed with HTTP $statusCode. $errorText"
        }
        else {
            "OAuth client-credentials token exchange failed. $errorText"
        }
        throw [System.InvalidOperationException]::new($message, $_.Exception)
    }
    finally {
        Set-TlsLevel -Revert
        $clientSecretPlain = $null
        $accessTokenPlain = $null
        $body = $null
    }
}
