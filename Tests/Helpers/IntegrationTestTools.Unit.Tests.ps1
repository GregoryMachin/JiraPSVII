#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeAll {
    . "$PSScriptRoot/IntegrationTestTools.ps1"
}

Describe 'Read-DotEnvFile' -Tag Unit {
    BeforeEach {
        [Environment]::SetEnvironmentVariable('JIRAPSVII_ENV_EXISTING', $null)
        [Environment]::SetEnvironmentVariable('JIRAPSVII_ENV_ALLOWED', $null)
        [Environment]::SetEnvironmentVariable('JIRAPSVII_ENV_EXCLUDED', $null)
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable('JIRAPSVII_ENV_EXISTING', $null)
        [Environment]::SetEnvironmentVariable('JIRAPSVII_ENV_ALLOWED', $null)
        [Environment]::SetEnvironmentVariable('JIRAPSVII_ENV_EXCLUDED', $null)
    }

    It 'overwrites an existing process environment variable by default' {
        $envFile = Join-Path -Path $TestDrive -ChildPath 'existing.env'
        Set-Content -LiteralPath $envFile -Value 'JIRAPSVII_ENV_EXISTING=from-file'

        [Environment]::SetEnvironmentVariable('JIRAPSVII_ENV_EXISTING', 'from-process')

        Read-DotEnvFile -Path $envFile

        $env:JIRAPSVII_ENV_EXISTING | Should -Be 'from-file'
    }

    It 'loads missing variables that are not excluded' {
        $envFile = Join-Path -Path $TestDrive -ChildPath 'allowed.env'
        Set-Content -LiteralPath $envFile -Value 'JIRAPSVII_ENV_ALLOWED=from-file'

        Read-DotEnvFile -Path $envFile

        $env:JIRAPSVII_ENV_ALLOWED | Should -Be 'from-file'
    }

    It 'does not load excluded variables' {
        $envFile = Join-Path -Path $TestDrive -ChildPath 'excluded.env'
        Set-Content -LiteralPath $envFile -Value @(
            'JIRAPSVII_ENV_ALLOWED=from-file'
            'JIRAPSVII_ENV_EXCLUDED=from-file'
        )

        Read-DotEnvFile -Path $envFile -ExcludeName 'JIRAPSVII_ENV_EXCLUDED'

        $env:JIRAPSVII_ENV_ALLOWED | Should -Be 'from-file'
        $env:JIRAPSVII_ENV_EXCLUDED | Should -BeNullOrEmpty
    }
}

Describe 'Get-DotEnvExcludedName' -Tag Unit {
    BeforeEach {
        [Environment]::SetEnvironmentVariable('CI_JIRA_TYPE', $null)
    }

    AfterEach {
        [Environment]::SetEnvironmentVariable('CI_JIRA_TYPE', $null)
    }

    It 'does not exclude fixtures for Cloud runs' {
        Get-DotEnvExcludedName | Should -BeNullOrEmpty
    }

    It 'excludes Cloud fixture names for Server runs' {
        [Environment]::SetEnvironmentVariable('CI_JIRA_TYPE', 'Server')

        Get-DotEnvExcludedName | Should -Be @(
            'JIRA_TEST_PROJECT'
            'JIRA_TEST_ISSUE'
            'JIRA_TEST_GROUP'
            'JIRA_TEST_FILTER'
            'JIRA_TEST_VERSION'
        )
    }
}
