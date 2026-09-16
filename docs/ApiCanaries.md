# API contract canaries

**Added:** Phase 9 Task 60.

## Purpose

Detect a Jira Cloud API contract change (a field disappearing, a route shape changing) before a user reports it, on a schedule tighter than the nightly full integration suite. This is deliberately separate from:

- `smoke_tests` (`.github/workflows/ci.yml`): runs on every first-party PR and push, gates merges and releases.
- `integration_tests.yml`: the full Cloud + Dockerized Data Center regression suite, nightly.

Canaries are a health signal, not a regression suite: narrow scope, frequent for reads, less frequent (but still bounded) for the one write lifecycle they exercise.

## The two tiers

| Tier | Pester tag | Schedule | What it does |
|---|---|---|---|
| Read canary | `CanaryRead` | Every 4 hours | A handful of pure-read checks already shared with `Smoke` (`Get-JiraIssue`, JQL search, `Get-JiraServerInformation`) against the fixed `JIRA_TEST_ISSUE`/`JIRA_TEST_PROJECT` fixtures. No resource is created. |
| Write-lifecycle canary | `CanaryWrite` | Once daily (11:40 UTC, offset from the 05:00 UTC nightly full suite) | One disposable issue: create, read it back, update its summary, delete it, confirm it is gone. See `Tests/Integration/ApiCanary.Integration.Tests.ps1`. |

Both tiers are Cloud-only: Jira Data Center is pinned, versioned software with no "the vendor changed something under us" risk the way a continuously deployed Cloud API has, and Data Center is already covered by `integration_tests.yml`'s nightly Dockerized `server_integration_tests` job.

Both tiers, and manual runs via `workflow_dispatch`, live in `.github/workflows/api_canary.yml`.

## Required setup: a dedicated canary account

Both jobs authenticate as `ATLASSIAN_CANARY_USER` (repository variable) / `ATLASSIAN_CANARY_PAT` (repository secret) -- **a separate, least-privilege Jira Cloud account and API token from the one `smoke_tests`/`integration_tests.yml` use (`ATLASSIAN_CLOUD_USER`/`ATLASSIAN_CLOUD_PAT`)**. This account only needs create/read/update/delete permission on the configured `JIRA_TEST_PROJECT`, nothing else.

Until that account and its variable/secret are provisioned, both canary jobs fail fast with an actionable "required environment variables are not set" error from `Invoke-Build -Task TestIntegration` rather than silently skipping or reporting a false green. Provisioning a real least-privilege Atlassian account and a GitHub Actions secret is a manual, live-credential step outside the scope of any automated change to this repository.

## Published results

Each job runs `Tools/Publish-ApiCanaryResult.ps1` after its Pester run (`if: always()`, so a failed or timed-out run still publishes what it has) and uploads the result as a workflow artifact alongside the raw NUnit XML:

- `Read-Canary-Results` / `api-canary-read-results.json`
- `Write-Canary-Results` / `api-canary-write-results.json`

Each JSON array entry is one operation's result: `SchemaVersion`, `Repository`, `Operation`, `DeploymentType`, `Status` (`Passed`/`Failed`/`Skipped`), `StartedAtUtc`, `CompletedAtUtc`, `DurationMilliseconds`, `Message`, `Metadata`. This intentionally matches the schema `AtlassianPS.Standards`' `ConvertTo-ApiCanaryResult` already produces (see that function's own doc in `AtlassianPS.Standards/docs/ApiQualityPrimitives.md`) -- **but `Publish-ApiCanaryResult.ps1` builds these objects by hand instead of calling that function**, because `ConvertTo-ApiCanaryResult` was added to `AtlassianPS.Standards`' source but has never been published (it is still listed under "Unreleased" in that repository's own `CHANGELOG.md`), and this repository's `Tools/build.requirements.psd1` still pins the last published release, `0.1.11`, which predates it. Once `AtlassianPS.Standards` ships a release containing it and this repository's pin is updated, `Publish-ApiCanaryResult.ps1` should be simplified to call `ConvertTo-AtlassianPSApiCanaryResult -AsJson` directly (see that script's own `.NOTES`).

## Adding a check to a tier

- Read canary: add the `CanaryRead` tag to an existing (or new) read-only `Describe` block under `Tests/Integration/`, alongside its existing tags. Keep it read-only and inexpensive -- this tier runs six times a day.
- Write-lifecycle canary: extend `Tests/Integration/ApiCanary.Integration.Tests.ps1` itself rather than adding a second `CanaryWrite`-tagged file, so there is exactly one disposable resource and one lifecycle to reason about and clean up.
