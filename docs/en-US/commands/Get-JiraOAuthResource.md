---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraOAuthResource/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraOAuthResource/
---
# Get-JiraOAuthResource

## SYNOPSIS

Returns Jira Cloud sites accessible to an OAuth access token.

## SYNTAX

```powershell
Get-JiraOAuthResource [-OAuthAccessToken <securestring>] [-CloudId <string>]
 [-SiteName <string>] [-SiteUrl <uri>] [-CacheExpiry <timespan>] [-BypassCache]
 [<CommonParameters>]
```

## DESCRIPTION

Calls Atlassian's OAuth `accessible-resources` endpoint and returns typed metadata for Jira Cloud sites represented by the caller-supplied token or current OAuth session.
Each result includes a validated UUID Cloud ID, canonical HTTPS `*.atlassian.net` site URL, display name, scopes, and optional avatar URL.

With no selector, the command returns every accessible resource without choosing by response order.
Use `-CloudId`, `-SiteUrl`, or `-SiteName` to select one site.
Display names are not identifiers, so duplicate exact names cause an error that requires Cloud ID or URL selection.

Explicit-token calls always contact Atlassian and invalidate the current-session metadata cache.
Calls using the current OAuth session use validated cached metadata for 15 minutes by default.
The cache contains no token or authorization header and can be refreshed with `-BypassCache` or cleared with `Clear-JiraCache -Type OAuthResources`.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraOAuthResource -OAuthAccessToken $accessToken
```

Returns all Jira Cloud sites represented by the token.

### EXAMPLE 2

```powershell
$site = Get-JiraOAuthResource -OAuthAccessToken $accessToken `
    -SiteUrl 'https://example.atlassian.net'
$site | New-JiraSession -OAuthAccessToken $accessToken
```

Selects a site by its validated URL and passes its Cloud ID to `New-JiraSession` by property name.

### EXAMPLE 3

```powershell
Get-JiraOAuthResource -CloudId '11223344-a1b2-3b33-c444-def123456789' -BypassCache
```

Refreshes accessible-resource metadata through the current OAuth session and selects an exact Cloud ID.

## PARAMETERS

### -BypassCache

Ignores cached OAuth resource metadata and requests current grants through the active OAuth session.
Explicit-token calls already bypass the cache.

```yaml
Type: SwitchParameter
DefaultValue: False
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

### -CacheExpiry

How long validated non-secret resource metadata can be reused by the current OAuth session.

```yaml
Type: TimeSpan
DefaultValue: 00:15:00
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

### -CloudId

Selects one resource by exact UUID Cloud ID.

```yaml
Type: String
DefaultValue: ''
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

### -OAuthAccessToken

A caller-supplied OAuth access token stored as a `SecureString`.
Omit it to use the current JiraPSVII OAuth session.

```yaml
Type: SecureString
DefaultValue: ''
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

### -SiteName

Selects one resource by exact display name.
Duplicate names are rejected because display names are not stable identifiers.

```yaml
Type: String
DefaultValue: ''
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

### -SiteUrl

Selects one resource by an HTTPS root URL on a `*.atlassian.net` host.

```yaml
Type: Uri
DefaultValue: ''
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### AtlassianPSVII.JiraPSVII.OAuthResource

## NOTES

Jira Cloud OAuth only.
The command discovers grants but does not perform authorization, token exchange, or refresh.

## RELATED LINKS

[New-JiraSession](../New-JiraSession/)

[Clear-JiraCache](../Clear-JiraCache/)
