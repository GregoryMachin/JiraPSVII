#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"
    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Get-JiraUser" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"
            # $VerbosePreference = 'Continue'  # Uncomment for mock debugging

            #region Definitions
            $script:jiraServer = 'http://jiraserver.example.com'
            $script:testUsername = 'powershell-test'
            $script:testEmail = "$testUsername@example.com"
            $script:testGroup1 = 'testGroup1'
            $script:testGroup2 = 'testGroup2'

            $script:restResult = @"
[
    {
        "self": "$jiraServer/rest/api/2/user?username=$testUsername",
        "key": "$testUsername",
        "name": "$testUsername",
        "emailAddress": "$testEmail",
        "displayName": "Powershell Test User",
        "active": true
    }
]
"@

            # Removed from JSON: avatarUrls, timeZone
            $script:restResult2 = @"
{
    "self": "$jiraServer/rest/api/2/user?username=$testUsername",
    "key": "$testUsername",
    "name": "$testUsername",
    "emailAddress": "$testEmail",
    "displayName": "Powershell Test User",
    "active": true,
    "groups": {
        "size": 2,
        "items": [
            {
                "name": "$testGroup1",
                "self": "$jiraServer/rest/api/2/group?groupname=$testGroup1"
            },
            {
                "name": "$testGroup2",
                "self": "$jiraServer/rest/api/2/group?groupname=$testGroup2"
            }
        ]
    },
    "expand": "groups"
}
"@
            #endregion Definitions

            #region Mocks
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

            Mock Get-JiraConfigServer -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Get-JiraConfigServer'
                Write-Output $jiraServer
            }

            Mock ConvertTo-JiraUser -ModuleName JiraPSVII {
                Write-MockDebugInfo 'ConvertTo-JiraUser'
                $user = [AtlassianPSVII.JiraPSVII.User]@{
                    Name         = $InputObject.name
                    AccountId    = $InputObject.accountId
                    DisplayName  = $InputObject.displayName
                    EmailAddress = $InputObject.emailAddress
                    Active       = $InputObject.active
                    RestUrl      = $InputObject.self
                }
                $user | Add-Member -NotePropertyName self -NotePropertyValue $InputObject.self -Force
                $user | Add-Member -NotePropertyName groups -NotePropertyValue $InputObject.groups -Force
                $user
            }

            # Return information of the current user
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq '/rest/api/2/myself' } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            # Searching for a user.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq '/rest/api/2/user/search' -and $GetParameter.username -eq $testUsername } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq '/rest/api/2/user/search' -and $GetParameter.username -eq '%' } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult
            }

            # Viewing a specific user. The main difference here is that this includes groups, and the first does not.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter { $Method -eq 'Get' -and $URI -eq '/rest/api/2/user' -and $GetParameter.username -eq $testUsername -and $GetParameter.expand -eq 'groups' } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                ConvertFrom-Json -InputObject $restResult2
            }

            # Generic catch-all. This will throw an exception if we forgot to mock something.
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
            #endregion Mocks
        }

        Describe "Signature" {
            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'InputObject'; type = 'AtlassianPSVII.JiraPSVII.User[]' }
                    @{ parameter = 'UserName'; type = 'String[]' }
                    @{ parameter = 'AccountId'; type = 'String[]' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                ) {
                    param($parameter, $type)
                    (Get-Command -Name Get-JiraUser) | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Mandatory Parameters" {}

            Context "Default Values" {}
        }

        Describe "Behavior" {
            It "Gets information about the logged in Jira user" {
                $getResult = Get-JiraUser

                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter { $URI -eq '/rest/api/2/myself' }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter { $URI -eq '/rest/api/2/user' -and $GetParameter.username -eq $testUsername -and $GetParameter.expand -eq 'groups' }
            }

            It "Gets information about a provided Jira user" {
                $getResult = Get-JiraUser -UserName $testUsername

                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter { $URI -eq '/rest/api/2/user/search' -and $GetParameter.username -eq $testUsername }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter { $URI -eq '/rest/api/2/user' -and $GetParameter.username -eq $testUsername -and $GetParameter.expand -eq 'groups' }
            }

            It "Gets information about a provided Jira exact user" {
                $getResult = Get-JiraUser -UserName $testUsername -Exact

                $getResult | Should -Not -BeNullOrEmpty

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter { $Method -eq 'Get' -and $URI -eq '/rest/api/2/user' -and $GetParameter.username -eq $testUsername -and $GetParameter.expand -eq 'groups' }
            }

            It "Returns all available properties about the returned user object" {
                $getResult = Get-JiraUser -UserName $testUsername

                $restObj = ConvertFrom-Json -InputObject $restResult

                $getResult.self | Should -Be $restObj.self
                $getResult.Name | Should -Be $restObj.name
                $getResult.DisplayName | Should -Be $restObj.displayName
                $getResult.Active | Should -Be $restObj.active

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter { $URI -eq '/rest/api/2/user' -and $GetParameter.username -eq $testUsername -and $GetParameter.expand -eq 'groups' }
            }

            It "Gets information for a provided Jira user if a AtlassianPSVII.JiraPSVII.User object is provided to the InputObject parameter" {
                $getResult = Get-JiraUser -UserName $testUsername
                $result2 = Get-JiraUser -InputObject $getResult

                $result2 | Should -Not -BeNullOrEmpty
                $result2.Name | Should -Be $testUsername

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 2 -ParameterFilter { $URI -eq '/rest/api/2/user' -and $GetParameter.username -eq $testUsername -and $GetParameter.expand -eq 'groups' }
            }

            It "Allow it search for multiple users" {
                Get-JiraUser -UserName "%"

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/2/user/search' -and $GetParameter.username -eq '%'
                }
            }

            It "Allows to change the max number of users to be returned" {
                Get-JiraUser -UserName "%" -MaxResults 100

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/2/user/search' -and
                    $GetParameter.username -eq '%' -and
                    $GetParameter.maxResults -eq 100
                }
            }

            It "Can skip a certain amount of results" {
                Get-JiraUser -UserName "%" -Skip 10

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/2/user/search' -and
                    $GetParameter.username -eq '%' -and
                    $GetParameter.startAt -eq 10
                }
            }

            It "Provides information about the user's group membership in Jira" {
                $getResult = Get-JiraUser -UserName $testUsername

                $getResult.groups.size | Should -Be 2
                $getResult.groups.items[0].Name | Should -Be $testGroup1
            }

            Context "Output checking" {
                It "Uses ConvertTo-JiraUser to beautify output" {
                    Get-JiraUser -UserName $testUsername | Out-Null
                    Should -Invoke ConvertTo-JiraUser -ModuleName JiraPSVII -Exactly 1
                }
            }
        }

        Describe "Input Validation" {
            Context "Type Validation - Positive Cases" {}

            Context "Type Validation - Negative Cases" {}
        }

        Describe "Cloud Deployment" {
            BeforeAll {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }

                $script:testAccountId = '5b10ac8d82e05b22cc7d4ef5'
                $script:testNamespacedAccountId = '557058:1500a9f1-0000-42b3-0000-ab8900008d00'

                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and $URI -eq '/rest/api/3/user/search' -and $GetParameter.query -eq $testUsername
                } {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    $obj = ConvertFrom-Json -InputObject $restResult
                    $obj | Add-Member -NotePropertyName 'accountId' -NotePropertyValue $testAccountId -Force
                    $obj
                }

                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -eq '/rest/api/3/user' -and
                    $GetParameter.accountId -in @($testAccountId, $testNamespacedAccountId) -and
                    $GetParameter.expand -eq 'groups'
                } {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    ConvertFrom-Json -InputObject $restResult2
                }

                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and $URI -eq '/rest/api/3/myself'
                } {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    $obj = ConvertFrom-Json -InputObject $restResult
                    $obj | Add-Member -NotePropertyName 'accountId' -NotePropertyValue $testAccountId -Force
                    $obj
                }

                Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                    Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                    throw "Unidentified call to Invoke-JiraMethod"
                }
            }

            It "uses query parameter instead of username for search on Cloud" {
                Get-JiraUser -UserName $testUsername

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/3/user/search' -and
                    $GetParameter.query -eq $testUsername -and
                    -not $GetParameter.ContainsKey('includeInactive')
                }
            }

            It "uses accountId for exact lookup on Cloud" {
                Get-JiraUser -AccountId $testAccountId -Exact

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/3/user' -and $GetParameter.accountId -eq $testAccountId
                }
            }

            It "re-fetches by accountId when using -Self on Cloud" {
                Get-JiraUser

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/3/myself'
                }
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/3/user' -and $GetParameter.accountId -eq $testAccountId
                }
            }

            It "supports the namespaced Cloud accountId format" {
                Get-JiraUser -AccountId $testNamespacedAccountId -Exact

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 1 -ParameterFilter {
                    $URI -eq '/rest/api/3/user' -and $GetParameter.accountId -eq $testNamespacedAccountId
                }
            }

            It "rejects an exact Cloud lookup by username to avoid ambiguous identity resolution" {
                { Get-JiraUser -UserName $testUsername -Exact -ErrorAction Stop } |
                    Should -Throw -ErrorId 'CloudUserAccountId.Required,Get-JiraUser'

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly 0 -ParameterFilter {
                    $URI -eq '/rest/api/3/user'
                }
            }

            It "propagates Cloud user-search permission failures" {
                Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                    $Method -eq 'Get' -and
                    $URI -eq '/rest/api/3/user/search' -and
                    $GetParameter.query -eq 'forbidden-user'
                } {
                    throw [System.UnauthorizedAccessException]::new('Browse users and groups permission is required.')
                }

                { Get-JiraUser -UserName 'forbidden-user' -ErrorAction Stop } |
                    Should -Throw -ExceptionType ([System.UnauthorizedAccessException])
            }
        }
    }
}
