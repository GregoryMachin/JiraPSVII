---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Wait-JiraBulkOperation/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Wait-JiraBulkOperation/
---
# Wait-JiraBulkOperation

## SYNOPSIS

Waits for a Jira Cloud bulk-operation task to reach a terminal status.

## SYNTAX

```powershell
Wait-JiraBulkOperation [-TaskId] <string> [-Credential <pscredential>]
 [-PollIntervalSeconds <int>] [-TimeoutSec <int>] [-MaxPollCount <int>] [-ProgressId <int>]
 [<CommonParameters>]
```

## DESCRIPTION

Polls the Jira Cloud bulk-operation queue for one exact task ID and writes progress while the task is running.
Polling is bounded by both `-TimeoutSec` and `-MaxPollCount`.
When Jira provides a Retry-After value, the next poll waits at least that long.

The command returns the terminal `BulkOperationProgress` result, including structured partial-failure details when Jira completed only some accessible issues.
It does not cancel a task on timeout or interruption and never resubmits the original bulk operation.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraIssueBulk -Issue SCRUM-1 -Summary 'Updated' | Wait-JiraBulkOperation
```

Submits a bulk edit and waits for its completion.

### EXAMPLE 2

```powershell
Wait-JiraBulkOperation -TaskId 10641 -PollIntervalSeconds 10 -TimeoutSec 1800
```

Waits at ten-second intervals, for up to 30 minutes, subject to Jira Retry-After guidance.

## PARAMETERS

### -TaskId

The exact Jira bulk-operation task ID to poll.

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

### -PollIntervalSeconds

The minimum number of seconds between polls.

```yaml
Type: Int32
DefaultValue: 5
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

### -TimeoutSec

The maximum total wait time in seconds.

```yaml
Type: Int32
DefaultValue: 900
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

### -MaxPollCount

The maximum number of status requests before the command stops waiting.

```yaml
Type: Int32
DefaultValue: 180
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

### -ProgressId

The PowerShell progress record ID used while waiting.

```yaml
Type: Int32
DefaultValue: 1
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

### AtlassianPS.JiraPS.BulkOperationProgress

The terminal, permission-scoped bulk-operation status.

## INPUTS

### System.String

## NOTES

Jira Cloud only.
Jira retains task status for up to 14 days.
Stopping the command leaves the remote bulk operation unchanged.

## RELATED LINKS

[Get-JiraBulkOperationProgress](../Get-JiraBulkOperationProgress/)
