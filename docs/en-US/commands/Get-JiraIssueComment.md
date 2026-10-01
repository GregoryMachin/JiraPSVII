---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://github.com/GregoryMachin/JiraPSVII/blob/master/docs/en-US/commands/Get-JiraIssueComment.md
locale: en-US
---
# Get-JiraIssueComment

## SYNOPSIS

Returns comments on an issue in JIRA.

## SYNTAX

```powershell
Get-JiraIssueComment [-Issue] <Issue> [[-Credential] <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

This function obtains comments from existing issues in JIRA.
Jira Cloud uses REST API v3 and converts Atlassian Document Format bodies to plain strings.
The `RenderedBody` property contains server-rendered HTML when Jira supplies it and must be treated as untrusted content.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraIssueComment -Key TEST-001
```

This example returns all comments posted to issue TEST-001.

### EXAMPLE 2

```powershell
Get-JiraIssue TEST-002 | Get-JiraIssueComment
```

This example illustrates use of the pipeline to return all comments on issue TEST-002.

## PARAMETERS

### -Credential

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
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

### -Issue

JIRA issue to check for comments.

Can be a `AtlassianPSVII.JiraPSVII.Issue` object, issue key, or internal issue ID.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPSVII.JiraPSVII.Issue / String

## OUTPUTS

### AtlassianPSVII.JiraPSVII.Comment

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

## RELATED LINKS

[Add-JiraIssueComment](../Add-JiraIssueComment/)

[Get-JiraIssue](../Get-JiraIssue/)
