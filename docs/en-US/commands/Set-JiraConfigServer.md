---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://github.com/GregoryMachin/JiraPSVII/blob/master/docs/en-US/commands/Set-JiraConfigServer.md
locale: en-US
---
# Set-JiraConfigServer

## SYNOPSIS

Defines the configured URL for the JIRA server

## SYNTAX

```powershell
Set-JiraConfigServer [-Server] <Object> [<CommonParameters>]
```

## DESCRIPTION

This function defines the configured URL for the JIRA server that JiraPSVII should manipulate.
The `-Server` parameter still accepts the legacy URI or string value.
It also accepts an AtlassianPSVII.Configuration server entry from the pipeline or by property name.
When the server entry includes `Product`, `DeploymentType`, `AuthenticationType`, or `CloudId`, JiraPSVII keeps that metadata in the current module session and uses it before probing `/serverInfo`.

## EXAMPLES

### EXAMPLE 1

```powershell
Set-JiraConfigServer 'https://jira.example.com:8080'
```

This example defines the server URL of the JIRA server configured for the JiraPSVII module.

### EXAMPLE 2

```powershell
Get-AtlassianServerConfiguration -Name "Jira Cloud" | Set-JiraConfigServer
```

This example configures JiraPSVII from an AtlassianPSVII.Configuration server entry.
If the entry contains `DeploymentType = "Cloud"` and OAuth metadata, JiraPSVII uses that explicit metadata instead of falling back to deployment auto-detection.

## PARAMETERS

### -Server

The base URL of the Jira instance, or a configuration object with a `Uri` property.
Configuration objects can also include `Product`, `DeploymentType`, `AuthenticationType`, and `CloudId` metadata.
Only Jira entries are accepted.
Cloud and OAuth entries must use HTTPS.

```yaml
Type: Object
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Uri
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

### String

### System.Object

## OUTPUTS

### System.String

## NOTES

Support for multiple configuration files is limited at this point in time,
but enhancements are planned for the next major release.
This can be tracked in [JiraPSVII#194](https://github.com/AtlassianPS/JiraPS/issues/194)

## RELATED LINKS

[about_JiraPSVII_Authentication](../../about/authentication.html)

[Get-JiraConfigServer](../Get-JiraConfigServer/)
