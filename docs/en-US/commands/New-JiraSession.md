---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraSession/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraSession/
---
# New-JiraSession

## SYNOPSIS

Creates a persistent JIRA authenticated session which can be used by other JiraPSVII functions

## SYNTAX

### Credential (Default)

```powershell
New-JiraSession [-Credential <pscredential>] [-Headers <hashtable>] [<CommonParameters>]
```

### PersonalAccessToken

```powershell
New-JiraSession -PersonalAccessToken <securestring> [-Headers <hashtable>] [<CommonParameters>]
```

### ApiToken

```powershell
New-JiraSession -ApiToken <securestring> -EmailAddress <string> [-CloudId <string>] [-Headers <hashtable>]
 [<CommonParameters>]
```

### OAuthAccessToken

```powershell
New-JiraSession -OAuthAccessToken <securestring> -CloudId <string> [-Headers <hashtable>]
 [<CommonParameters>]
```

### OAuthClientCredentials

```powershell
New-JiraSession -OAuthClientId <string> -OAuthClientSecret <securestring>
 [-OAuthCloudId <string>] [-OAuthSiteName <string>] [-OAuthSiteUrl <uri>]
 [-OAuthTokenRefreshSkew <timespan>] [-Headers <hashtable>] [<CommonParameters>]
```

## DESCRIPTION

This function creates a persistent, authenticated session in to JIRA which can be used by all other JiraPSVII functions instead of explicitly passing parameters.

This removes the need to use the `-Credential` parameter constantly for each function call.

JiraPSVII supports multiple authentication methods:

- **Credential**: Traditional username/password authentication (Jira Data Center)
- **PersonalAccessToken**: Personal Access Token (PAT) authentication (Jira Data Center 8.14+)
- **ApiToken**: API Token authentication with email address (Jira Cloud)
- **OAuthAccessToken**: Caller-supplied OAuth bearer access token with an explicit Jira Cloud ID
- **OAuthClientCredentials**: Non-interactive OAuth client-credentials authentication for Jira Cloud service accounts and backend automation

You can find more information in [about_JiraPSVII_Authentication](../../about/authentication.html)

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraIssue TEST-01
```

Creates a Jira session for jiraUsername using basic authentication.
The following `Get-JiraIssue` is run using the saved session for jiraUsername.

### EXAMPLE 2

```powershell
$pat = Read-Host -AsSecureString "Enter your PAT"
New-JiraSession -PersonalAccessToken $pat
Get-JiraIssue TEST-01
```

Creates a Jira session using a Personal Access Token (PAT) with Bearer authentication.
This is the recommended method for Jira Data Center 8.14 and later.

### EXAMPLE 3

```powershell
$apiToken = Read-Host -AsSecureString "Enter your API token"
New-JiraSession -ApiToken $apiToken -EmailAddress "user@example.com"
Get-JiraIssue TEST-01
```

Creates a Jira session using an API token with your Atlassian account email.
Use a scoped API token where possible, and make sure the token includes the
scopes needed by the Jira commands you call.

### EXAMPLE 4

```powershell
$apiToken = Read-Host -AsSecureString "Enter your scoped API token"
New-JiraSession `
    -ApiToken $apiToken `
    -EmailAddress "user@example.com" `
    -CloudId '11223344-a1b2-3b33-c444-def123456789'
Get-JiraIssue TEST-01
```

Creates a Jira session using a scoped API token and explicit Jira Cloud ID.
Scoped API tokens are routed through `api.atlassian.com/ex/jira/{cloudId}`.

### EXAMPLE 5

```powershell
$headers = @{ "X-Custom-Header" = "value" }
New-JiraSession -PersonalAccessToken $pat -Headers $headers
```

Creates a Jira session with a PAT and additional custom headers.

### EXAMPLE 6

```powershell
$pat = ConvertTo-SecureString $env:JIRA_PAT -AsPlainText -Force
New-JiraSession -PAT $pat
```

Uses the `-PAT` alias for brevity.
The `-BearerToken` alias is also supported for backward compatibility.

### EXAMPLE 7

```powershell
$accessToken = Read-Host -AsSecureString "Enter the OAuth access token"
New-JiraSession -OAuthAccessToken $accessToken `
    -CloudId '11223344-a1b2-3b33-c444-def123456789'
Get-JiraIssue TEST-01
```

Creates a Jira Cloud OAuth session from a token obtained by an external broker.
JiraPSVII validates the Cloud ID and routes subsequent requests through `api.atlassian.com`.

### EXAMPLE 8

```powershell
$clientSecret = ConvertTo-SecureString $env:JIRA_OAUTH_CLIENT_SECRET -AsPlainText -Force
New-JiraSession `
    -OAuthClientId $env:JIRA_OAUTH_CLIENT_ID `
    -OAuthClientSecret $clientSecret `
    -OAuthSiteUrl 'https://example.atlassian.net'
Get-JiraProject
```

Creates a Jira Cloud OAuth session using the non-interactive client-credentials grant.
JiraPSVII exchanges the client ID and client secret for a short-lived bearer token, selects the Jira Cloud site, and renews the token in memory before expiry.

## PARAMETERS

### -CloudId

The UUID Cloud ID of the Jira site authorized for the OAuth access token or
scoped API token. JiraPSVII uses it to construct
`https://api.atlassian.com/ex/jira/{cloudId}` and rejects other Atlassian Cloud
request hosts or Cloud IDs.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ApiToken
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: OAuthAccessToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ApiToken

An API token for Jira Cloud authentication.
Must be used together with `-EmailAddress`.

Create an API token at: https://id.atlassian.com/manage-profile/security/api-tokens

Scoped API tokens are recommended. JiraPSVII cannot inspect the token to verify
its scopes before use; Jira Cloud enforces the selected scopes and account
permissions per request. See `about_JiraPSVII_ApiTokenScopes` for command-family
scope guidance.

```yaml
Type: SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ApiToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

Credentials to use to connect to JIRA using basic authentication.

```yaml
Type: PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Credential
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EmailAddress

The email address associated with your Atlassian account.
Required when using `-ApiToken` for Jira Cloud authentication.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ApiToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Headers

Additional headers to include in requests.

```yaml
Type: Hashtable
DefaultValue: '@{}'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PersonalAccessToken

A Personal Access Token (PAT) for Bearer token authentication.
Use this for Jira Data Center 8.14 and later.

Create a PAT in Jira: Profile > Personal Access Tokens > Create token

Aliases: `BearerToken`, `PAT`

```yaml
Type: SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases:
- BearerToken
- PAT
ParameterSets:
- Name: PersonalAccessToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OAuthAccessToken

A caller-supplied Jira Cloud OAuth bearer access token.
The value must be a `SecureString`; JiraPSVII does not perform interactive authorization or refresh in this parameter set.

```yaml
Type: SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: OAuthAccessToken
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OAuthClientId

The OAuth client ID for a Jira Cloud app or service account credential that supports the client-credentials grant.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: OAuthClientCredentials
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OAuthClientSecret

The OAuth client secret for the client-credentials grant.
The value must be supplied as a `SecureString`; JiraPSVII keeps it in memory only for token renewal and does not persist it to configuration.

```yaml
Type: SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: OAuthClientCredentials
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OAuthCloudId

Selects the Jira Cloud site by UUID Cloud ID when the OAuth credential can access more than one site.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: OAuthClientCredentials
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OAuthSiteName

Selects the Jira Cloud site by exact accessible-resource display name.
Use `-OAuthCloudId` or `-OAuthSiteUrl` instead when names are ambiguous.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: OAuthClientCredentials
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OAuthSiteUrl

Selects the Jira Cloud site by root `https://*.atlassian.net` URL.

```yaml
Type: Uri
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: OAuthClientCredentials
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OAuthTokenRefreshSkew

How long before token expiry JiraPSVII should renew an OAuth client-credentials access token.
The default is five minutes.

```yaml
Type: TimeSpan
DefaultValue: 00:05:00
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: OAuthClientCredentials
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### PSCredential

### System.Security.SecureString

## OUTPUTS

### AtlassianPSVII.JiraPSVII.Session

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[about_JiraPSVII_Authentication](../../about/authentication.html)

[Get-JiraSession](../Get-JiraSession/)

[Get-JiraOAuthResource](../Get-JiraOAuthResource/)
