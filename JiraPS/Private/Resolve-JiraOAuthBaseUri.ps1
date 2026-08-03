function Resolve-JiraOAuthBaseUri {
    [CmdletBinding()]
    [OutputType([System.Uri])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CloudId
    )

    [Guid]$parsedCloudId = [Guid]::Empty
    if (-not [Guid]::TryParseExact($CloudId, 'D', [ref]$parsedCloudId)) {
        throw [System.ArgumentException]::new("CloudId must be a UUID in 'D' format, for example '11223344-a1b2-3b33-c444-def123456789'.", 'CloudId')
    }

    [Uri]("https://api.atlassian.com/ex/jira/{0}" -f $parsedCloudId.ToString('D'))
}
