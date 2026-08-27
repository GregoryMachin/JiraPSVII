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

### -Issue

Explicit issue keys, issue IDs, typed issue objects, or objects with a `Key` or `Id` property.
Wildcards are not supported.

### -TargetProject

The destination Jira project key or ID.

### -TargetIssueType

The destination Jira issue-type ID.

### -TargetParent

The destination parent issue key or ID when the target is a subtask type.

### -Request

A prebuilt typed `AtlassianPS.JiraPS.BulkIssueMoveRequest` for advanced target mappings.

### -SkipNotification

Sets Jira's `sendBulkNotification` field to `false`.

### -ValidateOnly

Builds and validates the typed request without submitting it.

### -WhatIf

Shows what would happen if the cmdlet runs.

## OUTPUTS

### AtlassianPS.JiraPS.SubmittedBulkOperation

When submitted, returns the Jira asynchronous bulk-operation task ID.

### AtlassianPS.JiraPS.BulkIssueMoveRequest

When `-ValidateOnly` is used, returns the validated request object.

## RELATED LINKS

[Set-JiraIssueBulk](../Set-JiraIssueBulk/)
