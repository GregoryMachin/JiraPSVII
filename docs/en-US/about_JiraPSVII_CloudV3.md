---
locale: en-US
layout: documentation
title: Cloud v3 Migration
online version: https://atlassianps.org/docs/JiraPS/about/cloud-v3.html
Module Name: JiraPSVII
permalink: /docs/JiraPS/about/cloud-v3.html
---
# JiraPSVII

## about_JiraPSVII_CloudV3

# SHORT DESCRIPTION

Summarizes the Jira Cloud REST API v3 migration completed in JiraPSVII `v3.1.0`:
what moved to current Cloud contracts, what stayed on Jira Data Center v2,
and the new capabilities the v3 platform makes available.

# LONG DESCRIPTION

Atlassian is retiring several Jira Software Cloud random-access issue-list
endpoints after 2026-11-01 and has moved most platform operations onto REST
API v3. JiraPSVII `v3.1.0` completes the corresponding migration project: every
in-scope Cloud operation now uses a current v3 contract, Jira Data Center
keeps its existing v2 behavior unchanged, and several new capabilities that
only exist on the v3 platform are now exposed.

This is an additive release. No public command name, parameter, alias, or
output shape was removed or renamed to deliver it. If you are looking for the
JiraPSVII v3.0.0 breaking-change list instead, see
[`about_JiraPSVII_MigrationV3`](migration-v3.html).

For the exact route, pagination, identity, permission, and test-coverage
mapping behind every command mentioned here, see
`docs/api-contract-inventory.md` in the JiraPSVII repository — this topic is a
narrative summary of that inventory, not a replacement for it.

## WHAT MOVED TO CLOUD V3

- Issue reads: direct issue lookup, JQL and saved-filter search, edit
  metadata, comments, worklogs, issue links, issue-link types, and remote
  links.
- User and group operations: Cloud identity now uses `accountId`
  exclusively; Data Center keeps username/name identity.
- Project resources: project collection search, components, versions,
  filters, and project roles.
- Attachment download validation (same-origin and filename checks apply on
  both deployments).

Jira Data Center retains its existing REST API v2 routes, offset pagination,
and username/name identity for every one of these operations; nothing here
changes Data Center behavior.

## NEW AUTHENTICATION OPTIONS

In addition to the `v3.0.0` Cloud API-token and Data Center
personal-access-token support, `New-JiraSession` now offers:

- **Caller-supplied OAuth bearer tokens** — pass a `SecureString` access
  token with an explicit Cloud ID; requests route only through
  `https://api.atlassian.com/ex/jira/{cloudId}`.
- **OAuth resource discovery** — `Get-JiraOAuthResource` lists the Jira
  sites and Cloud IDs a token or the current OAuth session can reach, and
  requires explicit selection when a display name is ambiguous.
- **Non-interactive OAuth client credentials** — `New-JiraSession
  -OAuthClientId -OAuthClientSecret` for service accounts and CI/CD, with no
  browser sign-in or interactive consent.

See [`about_JiraPSVII_Authentication`](authentication.html) for setup details
and [`about_JiraPSVII_ApiTokenScopes`](api-token-scopes.html) for scoped
API-token guidance.

## NEW BULK OPERATIONS (CLOUD-ONLY)

- `Set-JiraIssueBulk`, `Move-JiraIssueBulk`, and `Remove-JiraIssueBulk` submit
  typed, `ShouldProcess`-protected bulk edit, move, and delete requests for up
  to 1,000 issues per request.
- `Get-JiraBulkOperationProgress` and `Wait-JiraBulkOperation` poll the
  resulting task with bounded retries, progress reporting, and
  Retry-After-aware delays. Jira retains bulk-task status for up to 14 days;
  these commands do not support cancellation and never resubmit a destructive
  operation automatically.

These commands require the Jira Cloud global bulk-change permission and are
not available on Data Center.

## NEW GOVERNANCE AND METADATA COMMANDS

- `Get-JiraIssueProperty`/`Set-JiraIssueProperty`/`Remove-JiraIssueProperty`
  and `Get-JiraProjectProperty`/`Set-JiraProjectProperty`/
  `Remove-JiraProjectProperty` manage JSON-safe entity properties on Cloud v3
  and Data Center v2.
- `Get-JiraAuditRecord` reads Jira's audit log (bounded date range, offset
  paging) on both deployments where audit logging is available.
- `Get-JiraProjectClassificationLevel` reads Cloud's experimental data
  classification configuration. It is explicitly marked experimental and
  Cloud-only; treat its contract as subject to change.
- `Test-JiraJql` and `Get-JiraJqlApproximateCount` validate JQL and estimate
  match counts (Cloud-only) without running the full search.

## KNOWN GAPS AND CLOUD-ONLY BEHAVIOR

- Bulk operations, JQL validation/approximate-count, OAuth resource
  discovery, audit records beyond Data Center's v2 endpoint, and project
  classification levels have no Data Center equivalent and fail with an
  actionable error there instead of silently falling back.
- `Set-JiraUser` still cannot update a Cloud user's profile: Jira Cloud REST
  API v3 has no profile-update operation, so JiraPSVII reports that explicitly
  rather than attempting a legacy v2 mutation.
- Token scope introspection remains unavailable; JiraPSVII cannot confirm a
  scope is sufficient before Jira Cloud authorizes the request. See
  `about_JiraPSVII_ApiTokenScopes` for the command-family scope mapping used to
  reduce guesswork.

## SEE ALSO

- [about_JiraPSVII_MigrationV3](migration-v3.html)
- [about_JiraPSVII_Authentication](authentication.html)
- [about_JiraPSVII_ApiTokenScopes](api-token-scopes.html)
- `docs/api-contract-inventory.md` in the JiraPSVII repository
