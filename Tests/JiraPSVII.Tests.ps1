#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "General project validation" -Tag Unit {
    BeforeAll {
        Remove-Module JiraPSVII -ErrorAction SilentlyContinue

        $script:manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue

        $configFile = ("{0}/AtlassianPSVII/JiraPSVII/server_config" -f [Environment]::GetFolderPath('ApplicationData'))
        $configParent = Split-Path -Path $configFile -Parent
        if (-not (Test-Path -LiteralPath $configParent -PathType Container)) {
            $null = New-Item -Path $configParent -ItemType Directory -Force
        }
        $script:configFileAvailable = Test-Path -LiteralPath $configParent -PathType Container
        $script:oldConfig = if (Test-Path -LiteralPath $configFile -PathType Leaf) {
            Get-Content $configFile
        }
        else {
            $null
        }
    }
    AfterEach {
        if ($null -ne $script:oldConfig) {
            Set-Content -Value $script:oldConfig -Path $configFile -Force
        }
        elseif (Test-Path -LiteralPath $configFile -PathType Leaf) {
            Remove-Item -LiteralPath $configFile -Force
        }

        Remove-Module JiraPSVII -ErrorAction SilentlyContinue
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module 'JiraPSVII' can import cleanly" {
        { Import-Module $moduleToTest } | Should -Not -Throw
    }

    It "module 'JiraPSVII' exports functions" {
        Import-Module $moduleToTest

        (Get-Command -Module JiraPSVII | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module uses the correct root module" {
        $manifest.RootModule | Should -Be 'JiraPSVII.psm1'
    }

    It "module uses the correct guid" {
        $manifest.Guid | Should -Be 'e21096dd-f759-43e9-80c7-8a386ce59625'
    }

    It "module uses a valid version" {
        $manifest.Version | Should -Not -BeNullOrEmpty
        [Version]($manifest.Version) | Should -BeOfType [Version]
    }

    It "module uses the previous server config when loaded" -Skip:(-not $script:configFileAvailable) {
        Set-Content -Value "https://example.com" -Path $configFile -Force

        Import-Module $moduleToTest -Force

        Get-JiraConfigServer | Should -Be "https://example.com"
    }

    It "module manifest uses a semantic version" {
        $manifest.Version | Should -Match '^\d+\.\d+\.\d+(?:-.+)?$'
    }

    # It "module is imported with default prefix" {
    #     $prefix = Get-Metadata -Path $moduleToTest -PropertyName DefaultCommandPrefix

    #     Import-Module $moduleToTest -Force -ErrorAction Stop
    #     (Get-Command -Module JiraPSVII).Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }

    # It "module is imported with custom prefix" {
    #     $prefix = "Wiki"

    #     Import-Module $moduleToTest -Prefix $prefix -Force -ErrorAction Stop
    #     (Get-Command -Module JiraPSVII).Name | ForEach-Object {
    #         $_ | Should -Match "\-$prefix"
    #     }
    # }
}
