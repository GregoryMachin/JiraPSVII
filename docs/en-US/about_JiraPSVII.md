---
Module Name: JiraPSVII
online version: https://github.com/GregoryMachin/JiraPSVII/blob/master/docs/en-US/about_JiraPSVII.md
locale: en-US
hide: true
---
# JiraPSVII

## about_JiraPSVII

# SHORT DESCRIPTION

JiraPSVII is a PowerShell module to interact with Atlassian JIRA via a REST API, while maintaining a consistent PowerShell look and feel.

# LONG DESCRIPTION

Jira is an issuetracker from Atlassian.
JiraPSVII is a Powershell implementation to interact with it's API.

JiraPSVII can be used by any user.
The Jira server will check if the authenticated user has the necessary permissions to perform the action.
This allows JiraPSVII to be used by system administrators (eg: to create new Users), project administrators (eg: to create new Versions) and users (eg: to create or view an issue).

## GETTING STARTED

```powershell
# Tell the module what is the server's address
Set-JiraConfigServer -Server "https://jira.example.com"

# Authenticate (choose one method):

# Option 1: Jira Cloud (API Token)
$token = ConvertTo-SecureString $env:JIRA_API_TOKEN -AsPlainText -Force
New-JiraSession -ApiToken $token -EmailAddress "you@example.com"

# Option 2: Jira Data Center (Personal Access Token)
$pat = ConvertTo-SecureString $env:JIRA_PAT -AsPlainText -Force
New-JiraSession -PersonalAccessToken $pat

# Option 3: Username/Password
$cred = Get-Credential
New-JiraSession -Credential $cred

# Now use JiraPSVII commands without passing credentials each time
Get-JiraIssue -Issue "PR-123"
```

JiraPSVII uses the information provided by `Set-JiraConfigServer` to resolve what server to connect to.
(`Get-JiraConfigServer` can be used to inspect what server is currently being used).

JiraPSVII automatically detects whether you're connecting to Jira Cloud or Data Center and adapts its API calls accordingly. See [about_JiraPSVII_Authentication](about/authentication.html) for details.

## DISCOVERING YOUR ENVIRONMENT

Finding all projects you have access to:

```powershell
Get-JiraProject
```

Get all issues in a project:

```powershell
Get-JiraIssue -Query "project = CS"
```

See all available information of an issue:

```powershell
Get-JiraIssue "CS-15" | Format-List *
```

> The view of an issue is minimized so that a table-view is easier to read.
> There are a few options to get to see all the properties of an issue.
> Such as the example above.

# EXAMPLES

1. Creating issues from a CSV file

Given a CSV file which looks something like this:

```csv
project,summary,description,assignee
CS,Update Server Config, The config of server "srv1" must be updated, admin
CS,Delete temporary files,, admin
```

Issues can be created for each for the entries above with JiraPSVII like this:

```powershell
Import-CSV "./data.csv" | Foreach { New-JiraIssue -Project $_.project -Summary $_.summary -Description $_.description -Assignee $_.assignee }
```

2. Set the "fixVersions" of multiple issues at once

```powershell
# Get all versions from the project
$version = Get-JiraVersion -Project TV |
    # Filter by part of the name
    Where {$_.Name -like "1.3"}

# Get all issues we need
Get-JiraIssue -Query 'project = TV AND label = "ReadyForRelease' |
    # Update each issue
    Set-JiraIssue -FixVersion $version.Name
```

# NOTE

This project is a fork of JiraPS by the AtlassianPS volunteer organization, maintained by Gregory Machin.
We are always interested in hearing from new users!
Open an issue on GitHub and let us know what you think.

# SEE ALSO

[JiraPSVII on Github](https://github.com/GregoryMachin/JiraPSVII)

[Jira's REST API documentation](https://developer.atlassian.com/cloud/jira/platform/rest/)

# KEYWORDS

- Jira
- Atlassian
