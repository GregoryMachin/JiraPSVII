---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraBulkOperationProgress/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraBulkOperationProgress/
---
# Get-JiraBulkOperationProgress

## SYNOPSIS

Gets Jira Cloud bulk-operation queue progress by task ID.

## SYNTAX

```powershell
Get-JiraBulkOperationProgress [-TaskId] <string> [-Credential <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

Gets a typed status record for an exact Jira Cloud bulk-operation task ID.
The result includes percent complete, timing fields, submitted user details permitted by Jira, processed issue IDs, inaccessible issue count, and a structured map of accessible failed issue IDs to their reported reasons.

The command is Cloud-only and does not enumerate tasks or bypass Jira's permission and task-access checks.
Jira keeps a bulk-operation status available for up to 14 days from submission; a missing, expired, or inaccessible task is reported by Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraBulkOperationProgress -TaskId 10641
```

Gets the status of a submitted bulk operation.

### EXAMPLE 2

```powershell
Set-JiraIssueBulk -Issue SCRUM-1 -Summary 'Updated' | Get-JiraBulkOperationProgress
```

Pipes a submitted bulk-operation task to status retrieval.

## PARAMETERS

### -TaskId

The exact Jira bulk-operation task ID returned by a submission command.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
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

### -Credential

Credentials to use to connect to Jira.
If omitted, the current JiraPSVII session is used.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -ProgressAction, -Verbose, -WarningAction, and -WarningVariable.

## OUTPUTS

### AtlassianPSVII.JiraPSVII.BulkOperationProgress

The permission-scoped status and result details for one bulk operation.

## INPUTS

### System.String

## NOTES

Jira Cloud only.
Failure reason text can contain operational details; handle and log it carefully.

## RELATED LINKS

[Wait-JiraBulkOperation](../Wait-JiraBulkOperation/)
