---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/Set-JiraIssueBulk/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Set-JiraIssueBulk/
---
# Set-JiraIssueBulk

## SYNOPSIS

Submits a Jira Cloud bulk issue edit request.

## SYNTAX

### ByIssue (Default)

```powershell
Set-JiraIssueBulk [-Issue] <object[]> [-Summary <string>] [-Description <string>] [-Fields <psobject>]
 [-EditedFieldsInput <JiraBulkEditFieldsInput>] [-SelectedAction <string[]>] [-Credential <pscredential>]
 [-SkipNotification] [-ValidateOnly] [-AllowCrossProject] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ByRequest

```powershell
Set-JiraIssueBulk -Request <BulkIssueEditRequest> [-Credential <pscredential>] [-SkipNotification]
 [-ValidateOnly] [-AllowCrossProject] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

Submits a Jira Cloud REST API v3 bulk issue edit request and returns the asynchronous bulk-operation task id.
This command is Cloud-only. Jira Server and Data Center do not expose this Jira Cloud bulk operation route.

`-Issue` must be an explicit list of issue keys, issue IDs, typed `AtlassianPSVII.JiraPSVII.Issue` objects, or objects with a `Key` or `Id` property.
Wildcard issue selection is rejected.
When issue keys from multiple projects are supplied, pass `-AllowCrossProject` to make the cross-project edit explicit.

For simple edits, use `-Summary`, `-Description`, and string-compatible `-Fields` entries.
For advanced Jira bulk edit field collections, build an `AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput` or full `AtlassianPSVII.JiraPSVII.BulkIssueEditRequest` and pass it to the command.

Use `-ValidateOnly` to build and validate the typed request without submitting it to Jira.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraIssueBulk -Issue SCRUM-1, SCRUM-2 -Summary 'Updated in bulk' -SkipNotification
```

Submits a Jira Cloud bulk edit that changes the summary on two issues without sending Jira bulk notifications.

### EXAMPLE 2

```powershell
$request = Set-JiraIssueBulk -Issue SCRUM-1, SCRUM-2 -Description 'Reviewed by automation' -ValidateOnly
$request | ConvertTo-Json -Depth 30
```

Builds and validates the typed bulk edit request without submitting it.

### EXAMPLE 3

```powershell
$fields = [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput]@{
    SingleLineTextFields = @(
        @{
            fieldId = 'summary'
            text    = 'Typed bulk summary'
        }
    )
}

Set-JiraIssueBulk -Issue SCRUM-1 -EditedFieldsInput $fields -SelectedAction summary
```

Submits a bulk edit from a typed field input object.

## PARAMETERS

### -AllowCrossProject

Allows a bulk edit request where explicit issue keys show more than one project key.

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

### -Confirm

Prompts you for confirmation before running the cmdlet.

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

Credentials to use to connect to Jira.
If not specified, this function uses the current JiraPSVII session or anonymous access.

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

### -Description

New description for all selected issues.
The text is converted to Atlassian Document Format before submission.

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

### -EditedFieldsInput

Typed Jira bulk edit field input.
Pass `-SelectedAction` with the field IDs/actions represented in the typed input.

```yaml
Type: JiraBulkEditFieldsInput
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

### -Fields

Hashtable or object mapping field names or IDs to values.
This convenience path supports string-compatible fields and rich-text fields that Jira reports through the bulk editable fields endpoint.
Use `-EditedFieldsInput` or `-Request` for advanced field collection shapes.

```yaml
Type: PSObject
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

### -Issue

Explicit issue keys, issue IDs, typed issue objects, or objects with `Key` or `Id`.
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

A prebuilt typed bulk edit request.

```yaml
Type: BulkIssueEditRequest
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

### -SelectedAction

Bulk edit selected action values for a typed `-EditedFieldsInput`.
Simple `-Summary`, `-Description`, and supported `-Fields` entries add their own selected actions automatically.

```yaml
Type: String[]
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

### -SkipNotification

Sets Jira's `sendBulkNotification` request field to `false`.

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

### -Summary

New summary for all selected issues.

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

### -ValidateOnly

Builds and validates the typed request without submitting it to Jira.

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
The cmdlet is not run.

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

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable.
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## OUTPUTS

### AtlassianPSVII.JiraPSVII.SubmittedBulkOperation

When the request is submitted, the command returns the Jira asynchronous bulk-operation task id.

### AtlassianPSVII.JiraPSVII.BulkIssueEditRequest

When `-ValidateOnly` is used, the command returns the validated request object instead of submitting it.

## RELATED LINKS

[Set-JiraIssue](../Set-JiraIssue/)
