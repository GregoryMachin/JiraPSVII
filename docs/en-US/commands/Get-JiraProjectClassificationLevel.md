---
external help file: JiraPS-help.xml
Module Name: JiraPS
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraProjectClassificationLevel/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraProjectClassificationLevel/
---

# Get-JiraProjectClassificationLevel

## SYNOPSIS

Gets the available and default data-classification levels for a Jira Cloud project.

## SYNTAX

```
Get-JiraProjectClassificationLevel [-Project] <Project[]> [-Credential <pscredential>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has no aliases.

## DESCRIPTION

Gets the classification configuration exposed by Jira Cloud for a project and emits one typed object for each available classification level.
Each result identifies whether it is the project default or organization default and includes Jira's rank, status, color, and guidance where supplied.

This uses Jira Cloud's experimental `/rest/api/3/project/{projectIdOrKey}/classification-config` endpoint.
It is unavailable on Jira Server and Data Center and fails before making a request against those deployments.
Jira requires the applicable project browse and administration permissions or global Jira administration permission.

## EXAMPLES

### Example 1

```powershell
Get-JiraProjectClassificationLevel -Project SECURITY
```

Gets the classification levels available to the authenticated caller for the SECURITY project.

## PARAMETERS

### -Credential

Credentials to use for Jira Cloud.
The caller must have the permissions Jira requires to view the project's classification configuration.

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

### -Project

A Jira project key, ID, or JiraPS project object.

```yaml
Type: Project[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
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
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPS.JiraPS.Project[]

A JiraPS project key, ID, or project object.

## OUTPUTS

### AtlassianPS.JiraPS.ProjectClassificationLevel

One available project classification level with default-state metadata.

## NOTES

Jira Cloud only.
This endpoint is experimental and its availability, response fields, and required permissions may change.
Classification labels and guidance may be sensitive governance information; handle the returned data accordingly.

## RELATED LINKS

[Get-JiraProject](../Get-JiraProject/)
