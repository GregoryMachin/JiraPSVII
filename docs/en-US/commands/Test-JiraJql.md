---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/Test-JiraJql/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Test-JiraJql/
---
# Test-JiraJql

## SYNOPSIS

Parses and validates JQL without executing a search.

## SYNTAX

```powershell
Test-JiraJql [-Query] <string[]> [-Validation <string>] [-Credential <pscredential>]
 [<CommonParameters>]
```

## DESCRIPTION

Sends one or more JQL queries to Jira Cloud's REST API v3 parser and returns a typed result for every query. Results include the input query, Jira's normalized query and parsed structure when available, an `IsValid` flag, and structured error messages.

This command validates only; it does not execute the query or return issues. It is supported only on Jira Cloud and fails explicitly on Jira Data Center.

JQL is sent in a JSON request body. Do not construct JQL by directly concatenating untrusted values; validate or safely escape values before composing a query.

## EXAMPLES

### EXAMPLE 1

```powershell
Test-JiraJql -Query 'project = TEST AND status = Open'
```

Strictly validates one query and returns its structured parse result.

### EXAMPLE 2

```powershell
@('project = TEST', 'project =') | Test-JiraJql -Validation Warn
```

Batches pipeline input into one parse request and returns one result for each input query.

## PARAMETERS

### -Credential

Credentials to use to connect to Jira. If omitted, the current JiraPSVII session or anonymous access is used.

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

One or more JQL queries to parse and validate.

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

### -Validation

Jira parser validation mode. The default is `Strict`; accepted values are `Strict`, `Warn`, and `None`.

```yaml
Type: String
DefaultValue: Strict
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
AcceptedValues:
- Strict
- Warn
- None
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

### AtlassianPSVII.JiraPSVII.JqlValidationResult

## NOTES

Jira Cloud only.

## RELATED LINKS

[Get-JiraJqlApproximateCount](../Get-JiraJqlApproximateCount/)
