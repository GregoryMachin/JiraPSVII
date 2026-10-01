---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://github.com/GregoryMachin/JiraPSVII/blob/master/docs/en-US/commands/Get-JiraProjectProperty.md
locale: en-US
---

# Get-JiraProjectProperty

## SYNOPSIS

Gets property keys or one property value from a Jira project.

## SYNTAX

### __AllParameterSets

```
Get-JiraProjectProperty [-Project] <Project> [[-PropertyKey] <string>] [-Credential <pscredential>]
 [<CommonParameters>]
```

## ALIASES

This cmdlet has no aliases.

## DESCRIPTION

Gets property keys or one property value from a Jira project. JiraPSVII validates property keys and JSON values before sending requests.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraProjectProperty -Project TEST -PropertyKey 'integration.syncedAt'
```

Reads the `integration.syncedAt` property from project `TEST`.

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

### -Project

The Project parameter.

```yaml
Type: Project
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

### AtlassianPSVII.JiraPSVII.Project

Gets property keys or one property value from a Jira project. JiraPSVII validates property keys and JSON values before sending requests.

## OUTPUTS

### AtlassianPSVII.JiraPSVII.EntityProperty

Gets property keys or one property value from a Jira project. JiraPSVII validates property keys and JSON values before sending requests.

## NOTES

Property values may be visible to users or integrations with access to the entity. Do not store secrets in properties.

## RELATED LINKS

[JiraPSVII commands](../)
