---
external help file: JiraPSVII-help.xml
Module Name: JiraPSVII
online version: https://atlassianps.org/docs/JiraPS/commands/Get-JiraProject/
locale: en-US
layout: documentation
permalink: /docs/JiraPS/commands/Get-JiraProject/
---
# Get-JiraProject

## SYNOPSIS

Returns a project from Jira

## SYNTAX

### _All (Default)

```powershell
Get-JiraProject [-PageSize <uint>] [-Credential <pscredential>] [-IncludeTotalCount] [-Skip <ulong>]
 [-First <ulong>] [<CommonParameters>]
```

### _Search

```powershell
Get-JiraProject [-Project] <string[]> [-Credential <pscredential>] [-IncludeTotalCount] [-Skip <ulong>]
 [-First <ulong>] [<CommonParameters>]
```

## DESCRIPTION

This function returns information regarding a specified project from Jira.

If the Project parameter is not supplied, it will return information about all projects the given user is authorized to view.
On Jira Cloud, the cmdlet uses the paginated `/rest/api/3/project/search` endpoint and walks every page by default.
Use `-First`, `-Skip`, and `-IncludeTotalCount` to limit, offset, or count the returned projects.

The `-Project` parameter will accept either a project ID or a project key.
Direct project lookup and Jira Data Center collection behavior continue to use the existing v2 project routes.

## EXAMPLES

### EXAMPLE 1

```powershell
Get-JiraProject -Project TEST -Credential $cred
```

Returns information about the project TEST

### EXAMPLE 2

```powershell
Get-JiraProject 2 -Credential $cred
```

Returns information about the project with ID 2

### EXAMPLE 3

```powershell
Get-JiraProject
```

Returns information about all projects the user is authorized to view

### EXAMPLE 4

```powershell
Get-JiraProject -First 25 -Skip 50
```

Returns the next 25 projects after skipping the first 50 visible projects.

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
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -First

Indicates how many items to return.

```yaml
Type: UInt64
DefaultValue: 18446744073709551615
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

### -IncludeTotalCount

Causes an extra output of the total count at the beginning.

Note this is actually a uInt64, but with a custom string representation.

```yaml
Type: SwitchParameter
DefaultValue: ''
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

### -PageSize

Maximum number of results to fetch per call.

This setting can be tuned to get better performance according to the load on the server.

> Warning: too high of a PageSize can cause a timeout on the request.

```yaml
Type: UInt32
DefaultValue: 25
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _All
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

The Project ID or project key of a project to search.

```yaml
Type: String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: _Search
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Skip

Controls how many things will be skipped before starting output.

Defaults to 0.

```yaml
Type: UInt64
DefaultValue: 0
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### AtlassianPSVII.JiraPSVII.Project

## NOTES

This function requires either the `-Credential` parameter to be passed or a persistent JIRA session.
See `New-JiraSession` for more details.
If neither are supplied, this function will run with anonymous access to JIRA.

Remaining operations for `project` have not yet been implemented in the module.

## RELATED LINKS
