---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraAuditRecord/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraAuditRecord/
---

# Get-JiraAuditRecord

## SYNOPSIS

Gets sensitive, administrative Jira audit records over a bounded time range.

## SYNTAX

```
Get-JiraAuditRecord [[-From] <DateTimeOffset>] [[-To] <DateTimeOffset>] [[-PageSize] <uint>]
 [[-Offset] <uint>] [[-Credential] <pscredential>] [-IncludeTotalCount] [-Skip <ulong>]
 [-First <ulong>] [<CommonParameters>]
```

## ALIASES

This cmdlet has no aliases.

## DESCRIPTION

Gets audit records visible to the authenticated Jira administrator.
By default the query is limited to the preceding 24 hours to avoid unintentionally retrieving an unbounded audit history.
Use `-From` and `-To` to select a UTC time range, `-PageSize` to control each Jira request, and the common `-First` and `-Skip` parameters to bound output.

Audit records can contain account identifiers, IP addresses, project names, configuration changes, and other operationally sensitive information.
JiraPS keeps the result only in the pipeline and does not log request or response contents.
The command supports the `/rest/api/2/auditing/record` route on Jira Cloud and Data Center, but Jira still enforces its deployment-specific administrator permission.

## EXAMPLES

### Example 1

```powershell
Get-JiraAuditRecord -From (Get-Date).ToUniversalTime().AddHours(-4) -To (Get-Date).ToUniversalTime() -First 100
```

Gets up to 100 audit records from the prior four hours.

## PARAMETERS

### -Credential

Credentials for a Jira administrator.
Jira rejects this request when the authenticated principal lacks access to audit records.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -First

Limits the number of audit records emitted by the command.

```yaml
Type: UInt64
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

### -From

The inclusive UTC start of the audit time range.
The default is 24 hours before invocation.

```yaml
Type: DateTimeOffset
DefaultValue: ([DateTimeOffset]::UtcNow.AddDays(-1))
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IncludeTotalCount

Includes the PowerShell paging total-count metadata when supported by the host.

```yaml
Type: SwitchParameter
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

### -Offset

The zero-based Jira audit-record offset from which to start reading.

```yaml
Type: UInt32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PageSize

The number of audit records requested per Jira call.

```yaml
Type: UInt32
DefaultValue: 100
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Skips this many audit records before emitting output.

```yaml
Type: UInt64
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

### -To

The inclusive UTC end of the audit time range.
The default is the invocation time.

```yaml
Type: DateTimeOffset
DefaultValue: '[DateTimeOffset]::UtcNow'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
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

## OUTPUTS

### AtlassianPS.JiraPS.AuditRecord

One administrative audit record, including the event metadata Jira makes visible to the caller.

## NOTES

Audit data is sensitive.
Use an explicitly scoped administrative credential, request the smallest useful time range, and avoid persisting or broadly sharing results.

## RELATED LINKS

[Get-JiraConfigServer](../Get-JiraConfigServer/)
