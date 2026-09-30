---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/New-JiraUser/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/New-JiraUser/
---
# New-JiraUser

## SYNOPSIS

Creates a new user in JIRA

## SYNTAX

```powershell
New-JiraUser [-UserName] <string> [-EmailAddress] <string> [[-DisplayName] <string>]
 [[-Notify] <bool>] [-Product <string[]>] [[-Credential] <pscredential>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION

This function creates a new user in JIRA.

On Jira Cloud, the command uses REST API v3 and sends the email address plus the product access selected with `-Product`.
`-UserName`, `-DisplayName`, and `-Notify` are retained for Data Center compatibility and are not sent to Cloud.
An empty Cloud `-Product` list requests no product access, following least privilege.

On Jira Data Center, the new user is notified via e-mail by default.

The new user's password is also randomly generated.

## EXAMPLES

### EXAMPLE 1

```powershell
New-JiraUser -UserName "testUser" -EmailAddress "testUser@example.com"
```

This example creates a new JIRA user named testUser,
and sends a notification e-mail.
The user's DisplayName will be set to "testUser" since it is not specified.

### EXAMPLE 2

```powershell
New-JiraUser -UserName "testUser2" -EmailAddress "testUser2@example.com" -DisplayName "Test User 2"
```

This example illustrates setting a user's display name during user creation.

## PARAMETERS

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

Credentials to use to connect to JIRA.
If not specified, this function will use anonymous access.

```yaml
Type: PSCredential
DefaultValue: '[System.Management.Automation.PSCredential]::Empty'
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DisplayName

Display name of the user.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EmailAddress

E-mail address of the user.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Email
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Notify

Notify the user by e-mail

```yaml
Type: Boolean
DefaultValue: True
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Product

Jira product access to grant while creating a Cloud user.
Omit this parameter to create the account without requesting product access.

```yaml
Type: String[]
DefaultValue: '@()'
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
AcceptedValues:
- jira-core
- jira-servicedesk
- jira-product-discovery
- jira-software
HelpMessage: ''
```

### -UserName

Name of user.

```yaml
Type: String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
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
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AtlassianPSVII.JiraPSVII.User

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.
Creating users requires Jira site-administrator permissions.

## RELATED LINKS

[Get-JiraUser](../Get-JiraUser/)

[Remove-JiraUser](../Remove-JiraUser/)
