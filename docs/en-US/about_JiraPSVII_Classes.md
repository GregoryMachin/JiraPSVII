---
locale: en-US
layout: documentation
online version: https://atlassianps.org/docs/JiraPS/about/classes.html
Module Name: JiraPSVII
permalink: /docs/JiraPS/about/classes.html
---
# JiraPSVII

## about_JiraPSVII_Classes

# SHORT DESCRIPTION

This topic explains how to use the `AtlassianPSVII.JiraPSVII.*` classes introduced and expanded in JiraPSVII v3.

# LONG DESCRIPTION

JiraPSVII v3 promotes core domain objects to real .NET classes under the `AtlassianPSVII.JiraPSVII` namespace.
Those classes are used for converter output, parameter binding, and transformer-based input coercion across public cmdlets.
For a migration-focused view of what changed from v2, see [about_JiraPSVII_MigrationV3](migration-v3.html).

## The six identifier-driven classes

These six classes are the common "stub by identifier" entry points in scripts.

| Class | Canonical identifier slot |
| ----- | ------------------------- |
| `AtlassianPSVII.JiraPSVII.Issue` | `Key` |
| `AtlassianPSVII.JiraPSVII.Version` | `ID` (fallback `Name`) |
| `AtlassianPSVII.JiraPSVII.Filter` | `ID` |
| `AtlassianPSVII.JiraPSVII.Project` | `Key` (or `ID`) |
| `AtlassianPSVII.JiraPSVII.User` | `AccountId` on Cloud, otherwise `Name` |
| `AtlassianPSVII.JiraPSVII.Group` | `Name` |

## Three ways to construct a stub

### 1) String constructor

Use `::new('<identifier>')` for concise "single value" creation.

```powershell
$issue = [AtlassianPSVII.JiraPSVII.Issue]::new('TEST-1')
Add-JiraIssueComment -Issue $issue -Comment 'Ready for review.'
```

### 2) Hashtable cast

Use a cast when you want to set multiple properties up front.

```powershell
$version = [AtlassianPSVII.JiraPSVII.Version]@{
    ID       = 10200
    Released = $true
}
Set-JiraVersion -Version $version
```

### 3) Pipeline from a resolved object

Use converter-returned objects directly when chaining cmdlets.

```powershell
Get-JiraIssue -Query 'project = TEST AND status = "In Review"' |
    Add-JiraIssueComment -Comment 'Review sign-off complete.'
```

## How transformers route input

Most strongly-typed cmdlet parameters in v3 use `*TransformationAttribute` classes.
The routing rules are consistent across families:

- String input creates an identifier stub for the target class.
- Numeric input is treated as an ID where the class supports numeric identity (`Version`, `Filter`, `Project`).
- Existing `AtlassianPSVII.JiraPSVII.*` instances pass through unchanged.
- Legacy `PSCustomObject` values with the relevant `PSTypeName` are converted into the corresponding class for backward compatibility.

This lets v2-style scripts keep passing plain strings while v3 scripts can pass richer objects without extra glue code.

## Working with resolved objects

Resolved objects returned by cmdlets are real class instances, so they work naturally with type checks and tab completion.
`ToString()` returns the canonical identifier for user-friendly output in pipelines, logs, and interpolation.
Identifier-based equality and comparisons deduplicate correctly (`-eq`, `Sort-Object -Unique`, hashtable keys) in JiraPSVII v3.

When you need properties that are not modeled on a given class, query the relevant endpoint/cmdlet that surfaces that data and inspect the returned payload shape before building assumptions into script logic.
In practice, prefer explicit property access for stable fields and avoid relying on display formatting as data.

## JQL result classes

Jira Cloud JQL operations return dedicated result classes rather than loose objects.

| Class | Purpose |
| ----- | ------- |
| `AtlassianPSVII.JiraPSVII.JqlValidationResult` | Preserves the input and normalized query, validity, structured error messages, and parsed structure returned by `Test-JiraJql`. |
| `AtlassianPSVII.JiraPSVII.JqlApproximateCountResult` | Preserves the query, nullable 64-bit count, validation errors, and explicit approximate and permission-scoped flags returned by `Get-JiraJqlApproximateCount`. |

## OAuth resource class

`Get-JiraOAuthResource` returns `AtlassianPSVII.JiraPSVII.OAuthResource` objects.
The class exposes the validated `CloudId`, site `Name`, canonical `Url`, granted `Scopes`, and optional inert `AvatarUrl` metadata.
Its `CloudId` property can bind by property name to `New-JiraSession -CloudId`.

# SEE ALSO

- [about_JiraPSVII_MigrationV3](migration-v3.html)
- [Get-JiraIssue](../commands/Get-JiraIssue/)
- [Set-JiraIssue](../commands/Set-JiraIssue/)
