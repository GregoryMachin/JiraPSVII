#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPS {
    Describe "Get-JiraProjectRole" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:jiraServer = 'https://jira.example.com'
            $script:projectKey = 'TEST'
            $script:roleId = 10360
            $script:roleMap = [PSCustomObject]@{
                Developers = "$jiraServer/rest/api/2/project/$projectKey/role/$roleId"
            }
            $script:roleResponse = [PSCustomObject]@{
                self        = "$jiraServer/rest/api/2/project/$projectKey/role/$roleId"
                name        = 'Developers'
                id          = $roleId
                description = 'Project developers'
                actors      = @([PSCustomObject]@{ displayName = 'jira-developers' })
            }

            Mock Test-JiraCloudServer -ModuleName JiraPS { $false }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and $URI -eq "/rest/api/2/project/$projectKey/role"
            } { $roleMap }
            Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                $Method -eq 'Get' -and $URI -eq "/rest/api/2/project/$projectKey/role/10360"
            } { $roleResponse }
            Mock Invoke-JiraMethod -ModuleName JiraPS {
                throw "Unidentified call to Invoke-JiraMethod: $Method $URI"
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command Get-JiraProjectRole
            }

            It "has the expected parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = 'Project'; type = 'AtlassianPS.JiraPS.Project[]' }
                @{ parameter = 'RoleId'; type = 'System.UInt32[]' }
                @{ parameter = 'ExcludeInactiveUsers'; type = 'System.Management.Automation.SwitchParameter' }
                @{ parameter = 'Credential'; type = 'System.Management.Automation.PSCredential' }
            ) {
                param($parameter, $type)
                $command | Should -HaveParameter $parameter
                $command.Parameters[$parameter].ParameterType.FullName | Should -Be $type
            }

            It "aliases RoleId as Id" {
                $command.Parameters.RoleId.Aliases | Should -Contain 'Id'
            }
        }

        Describe "Data Center deployment" {
            It "retrieves the project role map and returns typed role details" {
                $roles = Get-JiraProjectRole -Project $projectKey

                @($roles) | Should -HaveCount 1
                $roles.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.ProjectRole'
                $roles.Id | Should -Be $roleId
                $roles.Name | Should -Be 'Developers'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $URI -eq "/rest/api/2/project/$projectKey/role"
                }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $URI -eq "/rest/api/2/project/$projectKey/role/$roleId"
                }
            }

            It "supports direct role lookup without retrieving the role map" {
                Get-JiraProjectRole -Project $projectKey -Id $roleId | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 0 -ParameterFilter {
                    $URI -eq "/rest/api/2/project/$projectKey/role"
                }
            }
        }

        Describe "Cloud deployment" {
            BeforeEach {
                Mock Test-JiraCloudServer -ModuleName JiraPS { $true }
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and $URI -eq "/rest/api/3/project/$projectKey/role"
                } { $roleMap }
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and $URI -eq "/rest/api/3/project/$projectKey/role/10360"
                } { $roleResponse }
            }

            It "uses REST API v3 and rebuilds detail routes from numeric role IDs" {
                $roles = Get-JiraProjectRole -Project $projectKey

                $roles.GetType().FullName | Should -Be 'AtlassianPS.JiraPS.ProjectRole'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $URI -eq "/rest/api/3/project/$projectKey/role/$roleId"
                }
            }

            It "escapes project path segments and forwards the inactive-user filter" {
                $escapedProject = 'TEAM%20OPS'
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $Method -eq 'Get' -and $URI -eq "/rest/api/3/project/$escapedProject/role/$roleId"
                } { $roleResponse }

                Get-JiraProjectRole -Project 'TEAM OPS' -RoleId $roleId -ExcludeInactiveUsers

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPS -Exactly 1 -ParameterFilter {
                    $URI -eq "/rest/api/3/project/$escapedProject/role/$roleId" -and
                    $GetParameter.excludeInactiveUsers -eq $true
                }
            }

            It "propagates permission failures" {
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $URI -eq "/rest/api/3/project/$projectKey/role/$roleId"
                } { throw 'Forbidden' }

                { Get-JiraProjectRole -Project $projectKey -RoleId $roleId } | Should -Throw -ExpectedMessage '*Forbidden*'
            }

            It "rejects an invalid role URL returned by Jira" {
                Mock Invoke-JiraMethod -ModuleName JiraPS -ParameterFilter {
                    $URI -eq "/rest/api/3/project/$projectKey/role"
                } { [PSCustomObject]@{ Developers = 'https://evil.example/roles/not-a-number' } }

                { Get-JiraProjectRole -Project $projectKey } | Should -Throw -ExpectedMessage '*invalid project-role URL*'
            }
        }
    }
}
