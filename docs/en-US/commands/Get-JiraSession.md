---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://github.com/GregoryMachin/JiraPSVII/blob/master/docs/en-US/commands/Get-JiraSession.md
locale: en-US
---
# Get-JiraSession

## SYNOPSIS

Obtains a reference to the currently saved JIRA session

## SYNTAX

```powershell
Get-JiraSession [<CommonParameters>]
```

## DESCRIPTION

This function obtains a reference to the currently saved JIRA session.

This can provide a JIRA session ID, as well as the username used to connect to JIRA.

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraSession -Credential (Get-Credential jiraUsername)
Get-JiraSession
```

Creates a Jira session for jiraUsername, then obtains a reference to it.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AtlassianPSVII.JiraPSVII.Session

## NOTES

## RELATED LINKS

[about_JiraPSVII_Authentication](../../about/authentication.html)

[New-JiraSession](../New-JiraSession/)
