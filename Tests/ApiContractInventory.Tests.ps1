#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:moduleRoot = Resolve-ProjectRoot
}

Describe "API contract inventory" -Tag Unit {
    BeforeDiscovery {
        $script:inventoryPath = Join-Path $moduleRoot "docs/api-contract-inventory.md"
        $script:inventoryContent = if (Test-Path -LiteralPath $inventoryPath) {
            Get-Content -LiteralPath $inventoryPath -Raw
        }
        else {
            ""
        }

        $entryPattern = '(?m)^(?<Row>\| \[`(?<Name>[^`]+)`\]\((?<Source>[^)]+)\) \|.*)$'
        $script:inventoryEntries = @(
            [regex]::Matches($inventoryContent, $entryPattern) | ForEach-Object {
                [pscustomobject]@{
                    Name   = $_.Groups["Name"].Value
                    Source = $_.Groups["Source"].Value
                    Row    = $_.Groups["Row"].Value
                }
            }
        )

        $script:exportedFunctionNames = @(
            (Get-Module "JiraPS").ExportedFunctions.Keys | Sort-Object
        )

        $referencePattern = '\[[^\]]+\]\((?<Path>\.\./(?:JiraPS|Tests)/[^)]+)\)'
        $script:referencedFiles = @(
            [regex]::Matches($inventoryContent, $referencePattern) |
                ForEach-Object { $_.Groups["Path"].Value } |
                Sort-Object -Unique
        )
    }

    It "exists" {
        $inventoryPath | Should -Exist
    }

    It "contains exactly one row for every exported JiraPS function" {
        $inventoryEntries.Count | Should -Be $exportedFunctionNames.Count
        @($inventoryEntries.Name | Sort-Object -Unique).Count | Should -Be $inventoryEntries.Count
        @($inventoryEntries.Name | Sort-Object) | Should -Be $exportedFunctionNames
    }

    Context "Exported function <_>" -ForEach $inventoryEntries {
        BeforeAll {
            $script:inventoryEntry = $_
        }

        It "references its public source file" {
            $inventoryEntry.Source | Should -Be "../JiraPS/Public/$($inventoryEntry.Name).ps1"
        }

        It "references its unit test file" {
            $expectedUnitTest = "../Tests/Functions/Public/$($inventoryEntry.Name).Unit.Tests.ps1"
            $inventoryEntry.Row | Should -Match ([regex]::Escape("]($expectedUnitTest)"))
        }

        It "defines all contract columns" {
            @($inventoryEntry.Row -split '\|').Count | Should -Be 15
            $inventoryEntry.Row | Should -Not -Match '\|\s*\|'
        }
    }

    Context "Referenced source or test <_>" -ForEach $referencedFiles {
        It "exists relative to the inventory" {
            $relativePath = $_ -replace '/', [System.IO.Path]::DirectorySeparatorChar
            $resolvedPath = [System.IO.Path]::GetFullPath(
                (Join-Path (Split-Path $inventoryPath -Parent) $relativePath)
            )

            $resolvedPath | Should -Exist
        }
    }
}
