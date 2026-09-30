#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

<#
.SYNOPSIS
    Guards against an undocumented Data Center test-image pin change (Phase 9 Task 61).

.DESCRIPTION
    ../Project/DataCenterMaintenance.md records which Data Center version this
    repository's integration-test image represents. That document cannot be read at
    CI runtime -- Project/ is a tracker repository local to this workspace, not one
    of the AtlassianPSVII GitHub organization's published repositories, so a real CI run
    of this repository has no sibling checkout of it -- so the expected image is
    duplicated here as a literal string instead. If you change docker-compose.yml's
    pinned image, update both this test and DataCenterMaintenance.md's version table
    in the same change.
#>

Describe "Data Center support policy" -Tag Unit {
    BeforeAll {
        # Resolve-ProjectRoot (not a plain "$PSScriptRoot/.." relative path) is required
        # here: this file also runs from a copied Release/Tests/ location during
        # Invoke-Build -Task Test, where docker-compose.yml (never packaged into
        # Release/) is not one level up from the running script's own location.
        . "$PSScriptRoot/Helpers/TestTools.ps1"
        $script:projectRoot = Resolve-ProjectRoot
        $script:composeContent = Get-Content -Raw -LiteralPath (Join-Path $script:projectRoot 'docker-compose.yml')
    }

    It "still pins the Data Center test image recorded in Project/DataCenterMaintenance.md" {
        $script:composeContent | Should -Match ([Regex]::Escape('image: moveworkforward/atlas-run-standalone:${JIRA_IMAGE_TAG:-jira-11}'))
    }
}
