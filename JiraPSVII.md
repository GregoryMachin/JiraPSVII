# JiraPSVII current state

Reviewed: 2026-07-27

## Purpose

`JiraPSVII` is the core AtlassianPSVII PowerShell client for Jira issue, project, user, group, filter, version, worklog, attachment, watcher, transition, and link automation.
It targets both Jira Cloud and Jira Data Center while keeping a stable PowerShell-oriented command and object model.

## How it works

- The manifest is version `3.0.0`, supports Windows PowerShell 5.1 and PowerShell Core, and has no runtime module dependencies.
- Sixty-eight public source files expose the user command surface and 66 private files provide routing, conversion, caching, paging, retry, logging, and validation.
- C# types and argument transformations under `JiraPSVII/Types` produce strongly typed `AtlassianPSVII.JiraPSVII.*` objects.
- All HTTP work flows through `Invoke-JiraMethod` and the private request wrapper stack.
- Deployment detection distinguishes Cloud from Server/Data Center.
- Cloud issue writes, comments, worklogs, transitions, create metadata, and enhanced JQL search selectively route to REST API v3 and use Atlassian Document Format where required.
- Data Center generally retains REST API v2 paths, username identity, and plain-text/wiki field behavior.
- Authentication supports Cloud email plus API token and Data Center bearer personal access tokens; per-command credentials remain available.
- Metadata responses are cached and retries handle throttling/transient service failures.

Snapshot: branch `master`, last local commit `ec414bb` dated 2026-05-31.

## Testing and delivery

- 152 `*.Tests.ps1` files are present: 123 named unit-test files and 22 integration-test files, plus build/help/example/manifest/tooling suites.
- Tests cover public/private functions, typed models and transformations, ADF conversion, paging, caching, retry behavior, request construction, response headers, and documentation.
- CI lints on Ubuntu, builds one artifact, tests Windows PowerShell 5.1 and PowerShell 7 on Windows/Linux/macOS, and runs Cloud smoke tests when secrets are available.
- Scheduled/manual integration runs cover Cloud and Dockerized Jira Data Center, including bounded parallel Pester execution.
- Pester 5.7.1 and PSScriptAnalyzer 1.25.0 are pinned.
- The required local gate is `Invoke-Build -Task Build, Test`, with lint and targeted suites used during development.

## Current strengths

- Version 3.0.0 is a substantive Cloud/Data Center compatibility release.
- The transport is centralized and mockable.
- Cloud `accountId`, Data Center username, Cloud ADF, and Data Center text differences are modeled explicitly.
- Token-based Jira Cloud JQL search support already exists at `/rest/api/3/search/jql`.
- Strong types and binding-time transformations improve reliability.
- Tests and CI are extensive and include live product tracks.
- Authentication, retry, cache invalidation, secret redaction, and response-header logging have dedicated behavior.

## Gaps and risks

1. Many Cloud operations still originate from `/rest/api/2` paths.
   Jira v2 remains documented, but v3 is the latest and is required for modern rich-text payloads; an operation-level Cloud v3 audit is needed.
2. `Get-JiraProject` still uses the non-paginated `/rest/api/2/project` route.
   Atlassian directs Cloud clients to the paginated `/project/search` operation.
3. OAuth 2.0 authorization-code (3LO), scoped token discovery, refresh, and `api.atlassian.com/ex/jira/{cloudId}` routing are not implemented.
4. Cloud/Data Center detection calls server information and falls back to a Server-shaped result on failure.
   Authentication/network failures can therefore select the wrong payload contract.
5. API deprecation telemetry should be first-class: capture `Deprecation`, `Sunset`, `Link`, request ID, rate-limit, and retry headers without exposing secrets.
6. The Data Center Docker track is valuable today but affected Jira Data Center reaches end of life in 2029.
7. `FunctionsToExport = '*'` should be replaced with an explicit packaged surface.
8. Several TODOs and loose return areas remain, including issue watcher and edit metadata typing.
9. JiraPSVII depends on rapid Cloud contract detection, but current scheduled tests should be mapped explicitly to every public API operation.

## Recommended update plan

### Now

1. Create a generated API inventory mapping every public command to method, Cloud route/version, Data Center route, identity fields, body format, pagination model, and live-test coverage.
2. Move Cloud project listing to `/rest/api/3/project/search` with pagination while preserving Data Center behavior.
3. Finish Cloud v3 routing for operations whose v2/v3 representation differs, with fixture and live tests.
4. Make deployment selection explicit in configured sessions and treat detection failure as an actionable error unless the caller opts into a deployment type.
5. Add structured, redacted deprecation/rate-limit telemetry and a scheduled job that fails on approaching sunset dates.

### Next

6. Implement an extensible OAuth 2.0 (3LO) session provider with refresh-token handling, scopes, Cloud ID discovery, and `api.atlassian.com` routing.
7. Support scoped API tokens without weakening existing ad-hoc email/token workflows.
8. Generate explicit exports and compare packaged commands/types against a compatibility baseline.
9. Complete typed outputs for remaining raw metadata and remove documented TODO debt in focused releases.
10. Publish a Cloud-first support policy and a Data Center maintenance/migration timeline toward 2029.
11. Add consumer compatibility tests for JiraAgilePSVII against JiraPSVII 3.x before tightening its required version.

## Primary platform references

- Jira Cloud REST API v3: <https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/>
- Jira Cloud v2/v3 distinction and authentication guidance: <https://developer.atlassian.com/cloud/jira/platform/rest/v2/intro/>
- Jira Cloud authentication: <https://developer.atlassian.com/cloud/jira/platform/basic-auth-for-rest-apis/>
- Jira Cloud changelog: <https://developer.atlassian.com/cloud/jira/platform/changelog/>
- Atlassian REST API deprecation headers: <https://developer.atlassian.com/platform/marketplace/atlassian-rest-api-policy/>
- Jira Data Center REST API: <https://developer.atlassian.com/server/jira/platform/rest/v11000/intro/>
- Data Center end of life: <https://www.atlassian.com/licensing/data-center-end-of-life>

## Review boundary

This was a static review of source, types, tests, docs, build scripts, and workflows.
No authenticated integration tests or full build were executed.

