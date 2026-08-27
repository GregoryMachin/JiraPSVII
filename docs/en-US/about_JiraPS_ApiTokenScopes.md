---
locale: en-US
layout: documentation
title: API Token Scopes
online version: https://atlassianps.org/docs/JiraPS/about/api-token-scopes.html
Module Name: JiraPS
permalink: /docs/JiraPS/about/api-token-scopes.html
---
# API Token Scopes

## about_JiraPS_ApiTokenScopes

# SHORT DESCRIPTION

Explains scoped Jira Cloud API tokens for JiraPS, including scope selection,
rotation, and permission troubleshooting.

# LONG DESCRIPTION

Jira Cloud API tokens can be created with scopes. Scoped tokens are preferred
over unscoped legacy tokens because they limit what a copied or leaked token can
do. JiraPS cannot introspect an API token to prove which scopes were selected;
Jira Cloud enforces scopes when each REST API request is made.

Use `New-JiraSession -ApiToken -EmailAddress` for legacy/unscoped API tokens.
Use `New-JiraSession -ApiToken -EmailAddress -CloudId` for scoped API tokens so
JiraPS routes requests through `https://api.atlassian.com/ex/jira/{cloudId}`.

Use the narrowest token that covers the automation. Scopes are not a replacement
for Jira permissions: the Atlassian account or service account still needs
product access, project permissions, issue security access, and any global or
project administration permissions required by the operation.

## Scope Families

The following classic Jira scopes cover the current JiraPS command families.
When Atlassian documents narrower granular scopes for an endpoint, prefer the
granular set only after confirming the exact REST operation in the API contract
inventory.

| Command family | Minimum classic scope | Jira permission still required |
| --- | --- | --- |
| Session validation and user profile reads | `read:jira-user` | Authenticated Jira access |
| Project, issue, field, component, version, filter, JQL, comment, worklog, attachment, remote-link, and watcher reads | `read:jira-work` | Browse Projects plus issue security where applicable |
| Issue creation or edits, comments, worklogs, attachments, watchers, transitions, issue links, remote links, and deletes | `write:jira-work` | Operation-specific create/edit/delete/transition permissions |
| Project components, versions, roles, and project-level settings | `manage:jira-project` | Administer Projects or project admin role |
| Global Jira administration, users, groups, priorities, statuses, and issue-link types | `manage:jira-configuration` | Jira administrator permissions |
| Jira Service Management customer/request operations, where used by a tenant workflow | `read:servicedesk-request`, `write:servicedesk-request`, or `manage:servicedesk-customer` | JSM product access and request/customer permissions |

## Creating Tokens

For user-run scripts, create the token from the Atlassian account security page.
For backend automation, prefer a service account. Give the token a name that
describes the automation, choose an explicit expiry date, and record where the
token is stored. Do not store token values in source control, transcripts, issue
comments, or build logs.

```powershell
$token = Read-Host -AsSecureString "Jira Cloud API token"
New-JiraSession -ApiToken $token -EmailAddress "automation@example.com"
```

```powershell
$token = Read-Host -AsSecureString "Scoped Jira Cloud API token"
New-JiraSession -ApiToken $token `
    -EmailAddress "automation@example.com" `
    -CloudId '11223344-a1b2-3b33-c444-def123456789'
```

## Rotation

Treat API tokens as secrets. Rotate them before expiry, revoke unused tokens,
and keep automation able to load the replacement from a secure store. Atlassian
API token values cannot be recovered after creation; if the value is lost,
create a replacement token and revoke the old one.

## Troubleshooting

An authentication failure usually means the token is expired, revoked, copied
incorrectly, or paired with the wrong email address. An authorization failure
usually means the token lacks the required scope, the account lacks Jira product
access, or Jira permissions prevent access to the project, issue, field, or
administrative resource.

JiraPS adds guidance to HTTP 401 and 403 errors, but it does not print tokens,
authorization headers, or token bodies.

## OAuth Comparison

API tokens remain useful for user-owned scripts and migration scenarios. For
non-interactive service-account automation, prefer OAuth client credentials
where possible because the integration can use short-lived access tokens and an
app-specific grant model.
