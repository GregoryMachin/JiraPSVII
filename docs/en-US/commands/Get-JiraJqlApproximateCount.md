---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraJqlApproximateCount/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraJqlApproximateCount/
---
# Get-JiraJqlApproximateCount

## SYNOPSIS

Returns an approximate, permission-scoped count for valid JQL.

## SYNTAX

```powershell
Get-JiraJqlApproximateCount [-Query] <string[]> [-Credential <pscredential>]
 [<CommonParameters>]
```

## DESCRIPTION

Strictly validates each JQL query, then requests Jira Cloud's approximate issue count. Invalid queries return structured validation errors and do not reach the count endpoint.

Counts can lag recent updates and include only issues visible to the authenticated user. Treat them as permission-scoped aggregate information. This command is supported only on Jira Cloud and fails explicitly on Jira Data Center.

JQL is sent in a JSON request body. Do not construct JQL by directly concatenating untrusted values; validate or safely escape values before composing a query.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraJqlApproximateCount -Query 'project = TEST AND resolution = Unresolved'
```

Validates the query and returns its approximate visible issue count.

### EXAMPLE 2

```powershell
@('project = TEST', 'project =') | Get-JiraJqlApproximateCount
```

Returns a count result for the valid query and a result containing validation errors for the invalid query.

## PARAMETERS

### -Credential

Credentials to use to connect to Jira. If omitted, the current JiraPS session or anonymous access is used.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
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

### -Query

One or more JQL queries to validate and count.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Jql
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
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

### System.String

## OUTPUTS

### AtlassianPS.JiraPS.JqlApproximateCountResult

## NOTES

Jira Cloud only. Counts are approximate and permission-scoped.

## RELATED LINKS

[Test-JiraJql](../Test-JiraJql/)
