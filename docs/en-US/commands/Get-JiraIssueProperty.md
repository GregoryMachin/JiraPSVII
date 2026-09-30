---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraIssueProperty/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraIssueProperty/
---

# Get-JiraIssueProperty

## SYNOPSIS

Gets property keys or one property value from a Jira issue.

## SYNTAX

### __AllParameterSets

```
Get-JiraIssueProperty [-Issue] <Issue> [[-PropertyKey] <string>] [-Credential <pscredential>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has no aliases.

## DESCRIPTION

Gets property keys or one property value from a Jira issue. JiraPSVII validates property keys and JSON values before sending requests.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueProperty -Issue TEST-01 -PropertyKey 'integration.syncedAt'
```

Reads the `integration.syncedAt` property from issue `TEST-01`.

## PARAMETERS

### -Credential

The Credential parameter.

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

The Issue parameter.

```yaml
Type: Issue
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Key
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

### -PropertyKey

The PropertyKey parameter.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
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
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPSVII.JiraPSVII.Issue

Gets property keys or one property value from a Jira issue. JiraPSVII validates property keys and JSON values before sending requests.

## OUTPUTS

### AtlassianPSVII.JiraPSVII.EntityProperty

Gets property keys or one property value from a Jira issue. JiraPSVII validates property keys and JSON values before sending requests.

## NOTES

Property values may be visible to users or integrations with access to the entity. Do not store secrets in properties.

## RELATED LINKS

[JiraPSVII commands](../)
