#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '5.7'; MaximumVersion = '5.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe 'Get-JiraAuditRecord' -Tag Unit {
        BeforeAll {
            $script:from = [DateTimeOffset]'2024-01-01T00:00:00+00:00'
            $script:to = [DateTimeOffset]'2024-01-02T00:00:00+00:00'
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                param($URI, $Method, $GetParameter)
                if ($URI -ne '/rest/api/2/auditing/record' -or $Method -ne 'GET') { throw 'Unexpected audit request.' }
                if ($GetParameter.offset -eq 0) {
                    return [pscustomobject]@{
                        total = 3
                        records = @(
                            [pscustomobject]@{ id = 1; created = 1704067200000; category = 'USER_MANAGEMENT'; summary = 'Actor redacted'; authorAccountId = $null; authorDisplayName = $null },
                            [pscustomobject]@{ id = 2; created = '2024-01-01T00:01:00.000+0000'; category = 'USER_MANAGEMENT'; summary = 'Role changed'; authorAccountId = 'account-1'; authorDisplayName = 'Admin' }
                        )
                    }
                }
                if ($GetParameter.offset -eq 2) {
                    return [pscustomobject]@{ total = 3; records = @([pscustomobject]@{ id = 3; created = 1704067320000; category = 'PROJECT'; summary = 'Project changed' }) }
                }
                throw "Unexpected offset $($GetParameter.offset)."
            }
        }

        It 'uses bounded date filters and follows audit offset pagination' {
            $records = @(Get-JiraAuditRecord -From $from -To $to -PageSize 2)

            $records | Should -HaveCount 3
            $records[0] | Should -BeOfType 'AtlassianPS.JiraPS.AuditRecord'
            $records[0].Created | Should -Be ([DateTimeOffset]'2024-01-01T00:00:00+00:00')
            $records[0].AuthorAccountId | Should -BeNullOrEmpty
            $records[1].AuthorDisplayName | Should -Be 'Admin'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter {
                $URI -eq '/rest/api/2/auditing/record' -and $GetParameter.offset -eq 0 -and $GetParameter.limit -eq 2 -and $GetParameter.from -eq 1704067200000 -and $GetParameter.to -eq 1704153600000
            }
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $GetParameter.offset -eq 2 -and $GetParameter.limit -eq 2 }
        }

        It 'respects PowerShell First without requesting another page' {
            @(Get-JiraAuditRecord -From $from -To $to -PageSize 2 -First 1) | Should -HaveCount 1
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly -Times 1 -ParameterFilter { $GetParameter.offset -eq 0 -and $GetParameter.limit -eq 1 }
        }

        It 'rejects inverted date filters before a request' {
            { Get-JiraAuditRecord -From $to -To $from -ErrorAction Stop } | Should -Throw '*From must be earlier*'
        }

        It 'propagates administrative permission failures' {
            Mock Invoke-JiraMethod -ModuleName JiraPS { throw 'Forbidden: Jira administrators only.' }
            { Get-JiraAuditRecord -From $from -To $to -ErrorAction Stop } | Should -Throw '*administrators only*'
        }
    }
}
