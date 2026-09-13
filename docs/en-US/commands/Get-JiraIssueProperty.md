---
external help file: JiraPS-help.xml
Module Name: JiraPS
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

Gets property keys or one property value from a Jira issue. JiraPS validates property keys and JSON values before sending requests.

## EXAMPLES

### Example 1

Runs Get-JiraIssueProperty with the requested identifiers.

## PARAMETERS

### -Credential

The Credential parameter.

```yaml
Type: System.Management.Automation.PSCredential
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
Type: AtlassianPS.JiraPS.Issue
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
Type: System.String
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

### AtlassianPS.JiraPS.Issue

Gets property keys or one property value from a Jira issue. JiraPS validates property keys and JSON values before sending requests.

## OUTPUTS

### AtlassianPS.JiraPS.EntityProperty

Gets property keys or one property value from a Jira issue. JiraPS validates property keys and JSON values before sending requests.

## NOTES

Property values may be visible to users or integrations with access to the entity. Do not store secrets in properties.

## RELATED LINKS

[JiraPS commands](../)
