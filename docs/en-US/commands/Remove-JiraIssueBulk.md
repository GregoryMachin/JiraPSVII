---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/Remove-JiraIssueBulk/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Remove-JiraIssueBulk/
---
# Remove-JiraIssueBulk

## SYNOPSIS

Permanently deletes explicit Jira Cloud issues in a bulk operation.

## SYNTAX

```powershell
Remove-JiraIssueBulk [-Issue] <object[]> [-Credential <pscredential>] [-SkipNotification] [-ValidateOnly]
 [-WhatIf] [-Confirm] [<CommonParameters>]

Remove-JiraIssueBulk -Request <BulkIssueDeleteRequest> [-Credential <pscredential>] [-ValidateOnly]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Submits a Jira Cloud REST API v3 bulk delete request and returns its asynchronous task ID.
Deletion is permanent and the command uses high-impact confirmation.

`-Issue` requires an explicit list of issue keys, issue IDs, typed issue objects, or objects with a `Key` or `Id` property.
Wildcard selection is rejected.
Use `-ValidateOnly` to review the typed request before submission.

This command is Cloud-only; Jira Server and Data Center do not expose this route.

## EXAMPLES

### EXAMPLE 1

```powershell
Remove-JiraIssueBulk -Issue SCRUM-1, SCRUM-2 -WhatIf
```

Shows the permanent bulk deletion that would be requested without submitting it.

### EXAMPLE 2

```powershell
$request = Remove-JiraIssueBulk -Issue SCRUM-1 -SkipNotification -ValidateOnly
$request | ConvertTo-Json -Depth 10
```

Builds and validates a no-notification delete request without sending it to Jira.

## PARAMETERS

### -Confirm

Prompts for confirmation before submitting the permanent deletion.

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

A prebuilt typed `AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest`.

```yaml
Type: BulkIssueDeleteRequest
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

### AtlassianPSVII.JiraPSVII.SubmittedBulkOperation

When submitted, returns the Jira asynchronous bulk-operation task ID.

### AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest

When `-ValidateOnly` is used, returns the validated request object.

## RELATED LINKS

[Remove-JiraIssue](../Remove-JiraIssue/)
