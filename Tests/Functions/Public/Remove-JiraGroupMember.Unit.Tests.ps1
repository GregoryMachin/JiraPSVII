#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Remove-JiraGroupMember" -Tag 'Unit' {

        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testGroupName = 'testGroup'
            $script:testUsername1 = 'testUsername1'
            $script:testUsername2 = 'testUsername2'
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                $jiraServer
            }

            Mock Get-JiraGroup -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraGroup' 'GroupName'
                [PSCustomObject]@{
                    PSTypeName = "JiraPSVII.Group"
                    Name       = $testGroupName
                    Size       = 2
                }
            }

            Mock Resolve-JiraUser -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Resolve-JiraUser' 'InputObject'
                if ($InputObject) {
                    $obj = [PSCustomObject]@{
                        PSTypeName = "AtlassianPSVII.JiraPSVII.User"
                        Name       = "$InputObject"
                    }
                }
                else {
                    $obj = [PSCustomObject]@{
                        PSTypeName = "AtlassianPSVII.JiraPSVII.User"
                        Name       = ""
                    }
                }
                $obj | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                    Write-Output "$($this.Name)"
                }
                $obj
            }

            Mock Get-JiraGroupMember -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraGroupMember' 'Group'
                [PSCustomObject]@{
                    PSTypeName = "AtlassianPSVII.JiraPSVII.User"
                    Name       = $testUsername1
                }
            }

            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
            }
            #endregion Mocks
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Remove-JiraGroupMember
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Group'; type = 'AtlassianPSVII.JiraPSVII.Group[]' }
                    @{ parameter = 'User'; type = 'AtlassianPSVII.JiraPSVII.User[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'PassThru'; type = 'Switch' }
                    @{ parameter = 'Force'; type = 'Switch' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            Context "Member Removal" {
                It "Tests to see if a provided user is currently a member of the provided JIRA group before attempting to remove them" {
                    { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName "JiraPSVII" -Exactly -Times 1
                }

                It "Removes a user from a JIRA group if the user is a member" {
                    { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName "JiraPSVII" -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -eq '/rest/api/2/group/user' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['username'] -eq $testUsername1
                    } -Exactly -Times 1
                }

                It "Removes multiple users from a JIRA group if they are passed to the -User parameter" {
                    # Override our previous mock so we have two group members
                    Mock Get-JiraGroupMember -ModuleName JiraPSVII {
                        Write-MockDebugInfo 'Get-JiraGroupMember' 'Group'
                        @(
                            [PSCustomObject] @{
                                'Name' = $testUsername1
                            },
                            [PSCustomObject] @{
                                'Name' = $testUsername2
                            }
                        )
                    }

                    # Should use the REST method twice, since at present, you can only delete one group member per API call
                    { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1, $testUsername2 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName "JiraPSVII" -ParameterFilter {
                        $Method -eq 'Delete' -and
                        $URI -eq '/rest/api/2/group/user' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['username']
                    } -Exactly -Times 2
                }
            }
        }

        Describe "Input Validation" {
            Context "Positive cases" {
                It "Accepts a group name as a String to the -Group parameter" {
                    { Remove-JiraGroupMember -Group $testGroupName -User $testUsername1 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName "JiraPSVII" -ParameterFilter {
                        $Method -eq "Delete" -and
                        $URI -eq '/rest/api/2/group/user' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['username'] -eq $testUsername1
                    } -Exactly -Times 1
                }

                It "Accepts a JiraPSVII.Group object to the -Group parameter" {
                    {
                        $group = Get-JiraGroup -GroupName $testGroupName
                        Remove-JiraGroupMember -Group $group -User $testUsername1 -Force
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName "JiraPSVII" -ParameterFilter {
                        $Method -eq "Delete" -and
                        $URI -eq '/rest/api/2/group/user' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['username'] -eq $testUsername1
                    } -Exactly -Times 1
                }

                It "Accepts pipeline input from Get-JiraGroup" {
                    { Get-JiraGroup -GroupName $testGroupName | Remove-JiraGroupMember -User $testUsername1 -Force } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName "JiraPSVII" -ParameterFilter {
                        $Method -eq "Delete" -and
                        $URI -eq '/rest/api/2/group/user' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['username'] -eq $testUsername1
                    } -Exactly -Times 1
                }

                It "Accepts a AtlassianPSVII.JiraPSVII.User as input for -User parameter" {
                    {
                        $user = Resolve-JiraUser -InputObject $testUsername1
                        Remove-JiraGroupMember -Group $testGroupName -User $user -Force
                    } | Should -Not -Throw

                    Should -Invoke -CommandName Invoke-JiraMethod -ModuleName "JiraPSVII" -ParameterFilter {
                        $Method -eq "Delete" -and
                        $URI -eq '/rest/api/2/group/user' -and
                        $GetParameter['groupname'] -eq $testGroupName -and
                        $GetParameter['username'] -eq $testUsername1
                    } -Exactly -Times 1
                }
            }

            Context "Negative cases" {
                # TODO: Add negative input validation tests
            }
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }

                Mock Resolve-JiraUser -ModuleName JiraPSVII {
                    Write-MockDebugInfo 'Resolve-JiraUser'
                    $object = [PSCustomObject] @{
                        'Name'      = 'testUser'
                        'AccountId' = 'abc123def456'
                    }
                    $object.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.User')
                    $object
                }
            }

            It "uses accountId when removing a user on Cloud" {
                { Remove-JiraGroupMember -Group $testGroupName -User 'testUser' -Force } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $Method -eq 'Delete' -and
                    $URI -eq '/rest/api/3/group/user' -and
                    $GetParameter['groupname'] -eq $testGroupName -and
                    $GetParameter['accountId'] -eq 'abc123def456'
                }
            }

            It "uses groupId when a Cloud group object provides one" {
                $group = [AtlassianPSVII.JiraPSVII.Group]@{
                    Id = 'cloud-group-id'
                }

                { Remove-JiraGroupMember -Group $group -User 'testUser' -Force } | Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $Method -eq 'Delete' -and
                    $URI -eq '/rest/api/3/group/user' -and
                    $GetParameter['groupId'] -eq 'cloud-group-id' -and
                    -not $GetParameter.ContainsKey('groupname') -and
                    $GetParameter['accountId'] -eq 'abc123def456'
                }
            }

            It "rejects a Cloud membership mutation when accountId is unavailable" {
                Mock Resolve-JiraUser -ModuleName JiraPSVII {
                    [AtlassianPSVII.JiraPSVII.User]@{ Name = 'ambiguous-user' }
                }

                { Remove-JiraGroupMember -Group $testGroupName -User 'ambiguous-user' -Force -ErrorAction Stop } |
                    Should -Throw -ErrorId 'CloudUserAccountId.Required,Remove-JiraGroupMember'
            }
        }
    }
}
