---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Move-JiraIssueBulk/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Move-JiraIssueBulk/
---
# Move-JiraIssueBulk

## SYNOPSIS

Submits a Jira Cloud bulk issue move request.

## SYNTAX

```powershell
Move-JiraIssueBulk [-Issue] <object[]> -TargetProject <string> -TargetIssueType <string>
 [-TargetParent <string>] [-Credential <pscredential>] [-SkipNotification] [-ValidateOnly]
 [-WhatIf] [-Confirm] [<CommonParameters>]

Move-JiraIssueBulk -Request <BulkIssueMoveRequest> [-Credential <pscredential>] [-ValidateOnly]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Submits a Jira Cloud REST API v3 bulk move request and returns its asynchronous task ID.
`-Issue` requires an explicit list of issue keys, issue IDs, typed issue objects, or objects with a `Key` or `Id` property.
Wildcard selection is rejected.

Specify the destination project and issue type explicitly.
Use `-TargetParent` only when moving items to a subtask type; it is included in Jira's target mapping key.
The convenience parameter set requests Jira's inference defaults for classifications, required fields, statuses, and subtask type mappings.
Use a typed `BulkIssueMoveRequest` for advanced field, status, or classification mappings.

This command is Cloud-only; Jira Server and Data Center do not expose this route.

## EXAMPLES

### EXAMPLE 1

```powershell
Move-JiraIssueBulk -Issue SCRUM-1, SCRUM-2 -TargetProject SCRUM -TargetIssueType 10001 -WhatIf
```

Shows the bulk move request without submitting it.

### EXAMPLE 2

```powershell
Move-JiraIssueBulk -Issue SCRUM-2 -TargetProject SCRUM -TargetIssueType 10002 -TargetParent SCRUM-1 -SkipNotification
```

Moves an explicit issue to a subtask type under the specified parent without bulk notification.

### EXAMPLE 3

```powershell
$request = Move-JiraIssueBulk -Issue SCRUM-1 -TargetProject SCRUM -TargetIssueType 10001 -ValidateOnly
$request | ConvertTo-Json -Depth 30
```

Builds and validates the typed request without sending it to Jira.

## PARAMETERS

### -Confirm

Controls the Confirm parameter.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -Issue

Explicit issue keys, issue IDs, typed issue objects, or objects with a `Key` or `Id` property.
Wildcards are not supported.

```yaml
Type: Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- IssueId
- Key
ParameterSets:
- Name: ByIssue
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Request

A prebuilt typed `AtlassianPS.JiraPS.BulkIssueMoveRequest` for advanced target mappings.

```yaml
Type: BulkIssueMoveRequest
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByRequest
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SkipNotification

Sets Jira's `sendBulkNotification` field to `false`.

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

### -TargetIssueType

The destination Jira issue-type ID.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIssue
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TargetParent

The destination parent issue key or ID when the target is a subtask type.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIssue
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TargetProject

The destination Jira project key or ID.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIssue
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ValidateOnly

Builds and validates the typed request without submitting it.

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

### -WhatIf

Shows what would happen if the cmdlet runs.

```yaml
Type: SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### AtlassianPS.JiraPS.SubmittedBulkOperation

When submitted, returns the Jira asynchronous bulk-operation task ID.

### AtlassianPS.JiraPS.BulkIssueMoveRequest

When `-ValidateOnly` is used, returns the validated request object.

## RELATED LINKS

[Set-JiraIssueBulk](../Set-JiraIssueBulk/)
