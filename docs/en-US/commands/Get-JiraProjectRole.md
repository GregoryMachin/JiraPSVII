---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://github.com/GregoryMachin/JiraPSVII/blob/master/docs/en-US/commands/Get-JiraProjectRole.md
locale: en-US
---
# Get-JiraProjectRole

## SYNOPSIS

Returns project roles and their actors from Jira.

## SYNTAX

```powershell
Get-JiraProjectRole [-Project] <Project[]> [-RoleId <uint[]>] [-ExcludeInactiveUsers]
 [-Credential <pscredential>] [<CommonParameters>]
```

## DESCRIPTION

Returns role details for one or more Jira projects. Jira Cloud uses REST API v3 and Jira Data Center uses REST API v2. When `-RoleId` is omitted, the command discovers the project's role IDs and retrieves each role's details and actors.

The command treats role URLs returned by Jira as untrusted metadata. It extracts only a validated numeric role ID and rebuilds the request against the configured Jira deployment.

Viewing project roles requires the Administer Projects permission for an applicable project or the Administer Jira global permission.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraProjectRole -Project TEST
```

Returns all roles and actors for project `TEST`.

### EXAMPLE 2

```powershell
Get-JiraProjectRole -Project TEST -Id 10360 -ExcludeInactiveUsers
```

Returns role `10360` for project `TEST`, excluding inactive user actors.

### EXAMPLE 3

```powershell
Get-JiraProject TEST | Get-JiraProjectRole
```

Accepts a typed JiraPSVII project object from the pipeline.

## PARAMETERS

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

### -ExcludeInactiveUsers

Excludes inactive users from the returned role actors.

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

### -Project

One or more project keys, IDs, or typed JiraPSVII project objects.

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
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RoleId

One or more numeric project-role IDs. When omitted, all roles for each project are returned.

```yaml
Type: UInt32[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
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
-InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### AtlassianPSVII.JiraPSVII.Project

## OUTPUTS

### AtlassianPSVII.JiraPSVII.ProjectRole

## NOTES

## RELATED LINKS

[Get-JiraProject](../Get-JiraProject/)

[Add-JiraFilterPermission](../Add-JiraFilterPermission/)
