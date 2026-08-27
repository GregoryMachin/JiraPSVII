---
external help file: JiraPS-help.xml
Module Name: JiraPS
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

### -Issue

Explicit issue keys, issue IDs, typed issue objects, or objects with a `Key` or `Id` property.
Wildcards are not supported.

### -Request

A prebuilt typed `AtlassianPS.JiraPS.BulkIssueDeleteRequest`.

### -SkipNotification

Sets Jira's `sendBulkNotification` field to `false`.

### -ValidateOnly

Builds and validates the typed request without submitting it.

### -Confirm

Prompts for confirmation before submitting the permanent deletion.

### -WhatIf

Shows what would happen if the cmdlet runs.

## OUTPUTS

### AtlassianPS.JiraPS.SubmittedBulkOperation

When submitted, returns the Jira asynchronous bulk-operation task ID.

### AtlassianPS.JiraPS.BulkIssueDeleteRequest

When `-ValidateOnly` is used, returns the validated request object.

## RELATED LINKS

[Remove-JiraIssue](../Remove-JiraIssue/)
