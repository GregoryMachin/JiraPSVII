
> **Fork notice:** JiraPSVII is a fork of [JiraPS](https://github.com/AtlassianPS/JiraPS) by the [AtlassianPS](https://github.com/AtlassianPS) team (MIT License), renamed and maintained by Gregory Machin. "VII" is only part of the name: it supports Windows PowerShell 5.1 and PowerShell 7.4+, and can be loaded side by side with the upstream module.
---
layout: module
permalink: /module/JiraPSVII/
---
# [JiraPSVII](https://atlassianps.org/module/JiraPS)

[![GitHub release](https://img.shields.io/github/release/GregoryMachin/JiraPSVII.svg?style=for-the-badge)](https://github.com/GregoryMachin/JiraPSVII/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/GregoryMachin/JiraPSVII/ci.yml?style=for-the-badge)](https://github.com/GregoryMachin/JiraPSVII/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)

JiraPSVII is a Windows PowerShell module to interact with Atlassian [JIRA] via a REST API, while maintaining a consistent PowerShell look and feel.

Join the conversation on [![SlackLogo][] AtlassianPSVII.Slack.com](https://atlassianps.org/slack)

[SlackLogo]: https://atlassianps.org/assets/img/Slack_Mark_Web_28x28.png
<!--more-->

---

## Instructions

### Installation

JiraPSVII is not published to the PowerShell Gallery; use it straight from its repository:

```powershell
git clone https://github.com/GregoryMachin/JiraPSVII.git
Import-Module ./JiraPSVII/JiraPSVII/JiraPSVII.psd1
```

For the built release copy (merged module and compiled help) run `./Tools/setup.ps1` and
`Invoke-Build -Task Build` in the clone, then import `./Release/JiraPSVII/JiraPSVII.psd1`.

### Usage

```powershell
# To use each session:
Import-Module JiraPSVII
Set-JiraConfigServer 'https://YourCloud.atlassian.net'
New-JiraSession -Credential $cred
```

You can find the full documentation on our [homepage](https://atlassianps.org/docs/JiraPS) and in the console.

```powershell
# Review the help at any time!
Get-Help about_JiraPSVII
Get-Command -Module JiraPSVII
Get-Help Get-JiraIssue -Full # or any other command
```

For more information on how to use JiraPSVII, check out the [Documentation](https://atlassianps.org/docs/JiraPS/).

### Contribute

Want to contribute to AtlassianPSVII? Great!
We appreciate [everyone](https://atlassianps.org/#people) who invests their time to make our modules the best they can be.

Check out our guidelines on [Contributing] to our modules and documentation.

#### DevContainer

This repository offers a ["devcontainer"](https://containers.dev/) setup.

> **What are Development Containers?**
> A development container (or dev container for short) allows you to use
> a container as a full-featured development environment.
> It can be used to run an application, to separate tools, libraries,
> or runtimes needed for working with a codebase,
> and to aid in continuous integration and testing.

You can use the devcontainer to spin up a fine tuned development environment with
everything you need for working on this project.

The easiest way for using DevContainers is with [VS Code](https://code.visualstudio.com/),
its extension `ms-vscode-remote.remote-containers`,
and [docker](https://docs.docker.com/engine/install/).
When opening the repository in VS Code, it will recommend the installation of the extension.
And once installed, you will be prompted to "Reopen in Container".

## Tested on

| Configuration | Status |
| ------------- | ------ |
| Windows PowerShell v5.1 | [CI workflow](https://github.com/GregoryMachin/JiraPSVII/actions/workflows/ci.yml) |
| PowerShell 7 on Windows | [CI workflow](https://github.com/GregoryMachin/JiraPSVII/actions/workflows/ci.yml) |
| PowerShell 7 on Ubuntu | [CI workflow](https://github.com/GregoryMachin/JiraPSVII/actions/workflows/ci.yml) |
| PowerShell 7 on macOS | [CI workflow](https://github.com/GregoryMachin/JiraPSVII/actions/workflows/ci.yml) |

## Acknowledgements

* Thanks to [replicaJunction] for getting this module on its feet
* Thanks to everyone ([Our Contributors](https://atlassianps.org/#people)) that helped with this module

## Useful links

* [Source Code]
* [Latest Release]
* [Submit an Issue]
* [Contributing]
* How you can help us: [List of Issues](https://github.com/GregoryMachin/JiraPSVII/issues?q=is%3Aissue+is%3Aopen+label%3Aup-for-grabs)

## Disclaimer

Hopefully this is obvious, but:

> This is an open source project (under the [MIT license]), and all contributors are volunteers. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

<!-- reference-style links -->
  [JIRA]: https://www.atlassian.com/software/jira
  [PowerShell Gallery]: https://www.powershellgallery.com/
  [Source Code]: https://github.com/GregoryMachin/JiraPSVII
  [Latest Release]: https://github.com/GregoryMachin/JiraPSVII/releases/latest
  [Submit an Issue]: https://github.com/GregoryMachin/JiraPSVII/issues/new
  [replicaJunction]: https://github.com/replicaJunction
  [MIT license]: https://github.com/GregoryMachin/JiraPSVII/blob/master/LICENSE
  [Contributing]: https://atlassianps.org/docs/Contributing/
