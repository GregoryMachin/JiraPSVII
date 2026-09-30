#requires -modules @{ ModuleName = 'Pester'; ModuleVersion = '6.2'; MaximumVersion = '6.999' }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe 'Get-JiraProjectClassificationLevel' -Tag Unit {
        BeforeAll {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $URI -eq '/rest/api/3/project/TEAM%20OPS/classification-config' -and $Method -eq 'GET'
            } {
                [pscustomobject]@{
                    containerOverride               = 'ANY'
                    defaultClassificationLevel      = [pscustomobject]@{ id = 'classification/restricted' }
                    organizationClassificationLevel = [pscustomobject]@{ id = 'classification/confidential' }
                    classificationLevels            = @(
                        [pscustomobject]@{ id = 'classification/restricted'; status = 'published'; name = 'Restricted'; rank = 1; description = 'Redacted fixture'; guideline = 'Need to know'; color = 'RED' },
                        [pscustomobject]@{ id = 'classification/confidential'; status = 'published'; name = 'Confidential'; rank = 2; color = 'BLUE' }
                    )
                }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII { throw 'Unexpected classification request.' }
        }

        It 'maps configuration levels and escapes the project route segment' {
            $levels = @(Get-JiraProjectClassificationLevel -Project 'TEAM OPS')

            $levels | Should -HaveCount 2
            $levels[0] | Should -BeOfType 'AtlassianPSVII.JiraPSVII.ProjectClassificationLevel'
            $levels[0].IsDefault | Should -BeTrue
            $levels[0].IsOrganizationDefault | Should -BeFalse
            $levels[1].IsOrganizationDefault | Should -BeTrue
            $levels[0].ContainerOverride | Should -Be 'ANY'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter { $URI -eq '/rest/api/3/project/TEAM%20OPS/classification-config' }
        }

        It 'rejects Data Center without sending the Cloud-only request' {
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            { Get-JiraProjectClassificationLevel -Project 'TEST' -ErrorAction Stop } | Should -Throw '*only on Jira Cloud*'
            Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0
        }

        It 'propagates project-administration permission failures' {
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $URI -eq '/rest/api/3/project/TEAM%20OPS/classification-config' } { throw 'Forbidden' }

            { Get-JiraProjectClassificationLevel -Project 'TEAM OPS' -ErrorAction Stop } | Should -Throw '*Forbidden*'
        }
    }
}
