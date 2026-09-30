#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Set-JiraIssueBulk" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            $script:jiraServer = 'https://jira.example.com'
            $script:bulkFields = [PSCustomObject]@{
                fields = @(
                    [PSCustomObject]@{
                        id     = 'summary'
                        name   = 'Summary'
                        type   = 'text'
                        schema = [PSCustomObject]@{ type = 'string'; system = 'summary' }
                    }
                    [PSCustomObject]@{
                        id     = 'description'
                        name   = 'Description'
                        type   = 'textarea'
                        schema = [PSCustomObject]@{ type = 'doc'; system = 'description' }
                    }
                    [PSCustomObject]@{
                        id     = 'customfield_10001'
                        name   = 'Customer Ref'
                        type   = 'text'
                        schema = [PSCustomObject]@{ type = 'string' }
                    }
                    [PSCustomObject]@{
                        id     = 'customfield_20002'
                        name   = 'Number Field'
                        type   = 'number'
                        schema = [PSCustomObject]@{ type = 'number' }
                    }
                )
            }

            Mock Get-JiraConfigServer -ModuleName JiraPSVII { $jiraServer }
            Mock Test-JiraCloudServer -ModuleName JiraPSVII { $true }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $Method -eq 'GET' -and $URI -eq '/rest/api/3/bulk/issues/fields'
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'GetParameter'
                $bulkFields
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII -ParameterFilter {
                $Method -eq 'POST' -and $URI -eq '/rest/api/3/bulk/issues/fields'
            } {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri', 'Body'
                [PSCustomObject]@{ taskId = '10641' }
            }
            Mock Invoke-JiraMethod -ModuleName JiraPSVII {
                Write-MockDebugInfo 'Invoke-JiraMethod' 'Method', 'Uri'
                throw "Unidentified call to Invoke-JiraMethod"
            }
        }

        Describe "Signature" {
            BeforeAll {
                $script:command = Get-Command -Name Set-JiraIssueBulk
            }

            Context "Parameter Types" {
                It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                    @{ parameter = 'Issue'; type = 'Object[]' }
                    @{ parameter = 'Summary'; type = 'String' }
                    @{ parameter = 'Description'; type = 'String' }
                    @{ parameter = 'Fields'; type = 'PSObject' }
                    @{ parameter = 'EditedFieldsInput'; type = 'AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput' }
                    @{ parameter = 'SelectedAction'; type = 'String[]' }
                    @{ parameter = 'Request'; type = 'AtlassianPSVII.JiraPSVII.BulkIssueEditRequest' }
                    @{ parameter = 'Credential'; type = 'PSCredential' }
                    @{ parameter = 'SkipNotification'; type = 'Switch' }
                    @{ parameter = 'ValidateOnly'; type = 'Switch' }
                    @{ parameter = 'AllowCrossProject'; type = 'Switch' }
                ) {
                    param($parameter, $type)
                    $command | Should -HaveParameter $parameter -Type $type
                }
            }

            Context "Parameter Sets" {
                It "defines parameter set '<setName>'" -TestCases @(
                    @{ setName = 'ByIssue' }
                    @{ setName = 'ByRequest' }
                ) {
                    param($setName)
                    $command.ParameterSets.Name | Should -Contain $setName
                }

                It "uses 'ByIssue' as the default parameter set" {
                    $command.DefaultParameterSet | Should -Be 'ByIssue'
                }

                It "has aliases for the issue list" {
                    $command.Parameters['Issue'].Aliases | Should -Contain 'IssueId'
                    $command.Parameters['Issue'].Aliases | Should -Contain 'Key'
                }
            }
        }

        Describe "Behavior" {
            It "submits a bulk edit request and returns the async task id" {
                $result = Set-JiraIssueBulk -Issue 'TEST-1', 'TEST-2' -Summary 'Bulk summary'

                $result | Should -BeOfType 'AtlassianPSVII.JiraPSVII.SubmittedBulkOperation'
                $result.TaskId | Should -Be '10641'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and
                    $URI -eq '/rest/api/3/bulk/issues/fields' -and
                    ($Body | ConvertFrom-Json).selectedIssueIdsOrKeys -contains 'TEST-1' -and
                    ($Body | ConvertFrom-Json).editedFieldsInput.singleLineTextFields[0].fieldId -eq 'summary' -and
                    ($Body | ConvertFrom-Json).editedFieldsInput.singleLineTextFields[0].text -eq 'Bulk summary' -and
                    ($Body | ConvertFrom-Json).sendBulkNotification -eq $true
                }
            }

            It "combines summary, description, and resolved custom string fields" {
                Set-JiraIssueBulk -Issue 'TEST-1' -Summary 'Bulk summary' -Description 'Bulk **description**' -Fields @{ 'Customer Ref' = 'ABC-123' }

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                    if ($Method -ne 'POST' -or $URI -ne '/rest/api/3/bulk/issues/fields') { return $false }
                    $payload = $Body | ConvertFrom-Json
                    $payload.selectedActions | Should -Contain 'summary'
                    $payload.selectedActions | Should -Contain 'description'
                    $payload.selectedActions | Should -Contain 'customfield_10001'
                    $payload.editedFieldsInput.singleLineTextFields.fieldId | Should -Contain 'summary'
                    $payload.editedFieldsInput.singleLineTextFields.fieldId | Should -Contain 'customfield_10001'
                    $payload.editedFieldsInput.richTextFields[0].fieldId | Should -Be 'description'
                    $payload.editedFieldsInput.richTextFields[0].richText.type | Should -Be 'doc'
                    $true
                }
            }

            It "accepts a typed request payload" {
                $fields = [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput]@{
                    SingleLineTextFields = @(@{ fieldId = 'summary'; text = 'Typed summary' })
                }
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueEditRequest]@{
                    SelectedIssueIdsOrKeys = @('TEST-1')
                    SelectedActions        = @('summary')
                    EditedFieldsInput      = $fields
                    SendBulkNotification   = $false
                }

                $result = Set-JiraIssueBulk -Request $request

                $result.TaskId | Should -Be '10641'
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and
                    ($Body | ConvertFrom-Json).sendBulkNotification -eq $false
                }
            }

            It "returns a typed request and does not submit when -ValidateOnly is used" {
                $result = Set-JiraIssueBulk -Issue 'TEST-1' -Summary 'Dry run' -ValidateOnly

                $result | Should -BeOfType 'AtlassianPSVII.JiraPSVII.BulkIssueEditRequest'
                $result.SelectedIssueIdsOrKeys | Should -Be @('TEST-1')
                $result.SelectedActions | Should -Be @('summary')
                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 -ParameterFilter {
                    $Method -eq 'POST'
                }
            }

            It "supports -WhatIf without submitting" {
                Set-JiraIssueBulk -Issue 'TEST-1' -Summary 'Bulk summary' -WhatIf

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 -ParameterFilter {
                    $Method -eq 'POST'
                }
            }

            It "sets sendBulkNotification false when -SkipNotification is used" {
                Set-JiraIssueBulk -Issue 'TEST-1' -Summary 'Bulk summary' -SkipNotification

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'POST' -and
                    ($Body | ConvertFrom-Json).sendBulkNotification -eq $false
                }
            }
        }

        Describe "Input Validation" {
            It "rejects Jira Server or Data Center before submitting" {
                Mock Test-JiraCloudServer -ModuleName JiraPSVII { $false }

                { Set-JiraIssueBulk -Issue 'TEST-1' -Summary 'Bulk summary' -ErrorAction Stop } |
                    Should -Throw '*not supported against Jira Server or Data Center*'

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 0 -ParameterFilter {
                    $Method -eq 'POST'
                }
            }

            It "rejects cross-project issue keys unless -AllowCrossProject is explicit" {
                { Set-JiraIssueBulk -Issue 'TEST-1', 'OPS-2' -Summary 'Bulk summary' -ErrorAction Stop } |
                    Should -Throw '*Pass -AllowCrossProject*'
            }

            It "allows explicit cross-project issue keys" {
                { Set-JiraIssueBulk -Issue 'TEST-1', 'OPS-2' -Summary 'Bulk summary' -AllowCrossProject } |
                    Should -Not -Throw

                Should -Invoke Invoke-JiraMethod -ModuleName JiraPSVII -Exactly -Times 1 -ParameterFilter {
                    $Method -eq 'POST'
                }
            }

            It "rejects wildcard issue selection" {
                { Set-JiraIssueBulk -Issue 'TEST-*' -Summary 'Bulk summary' -ErrorAction Stop } |
                    Should -Throw '*Wildcard issue selection is not supported*'
            }

            It "rejects unsupported loose field types instead of guessing a Jira field collection" {
                { Set-JiraIssueBulk -Issue 'TEST-1' -Fields @{ 'Number Field' = 10 } -ErrorAction Stop } |
                    Should -Throw '*cannot infer the Jira bulk edit field collection*'
            }

            It "rejects typed request payloads with unsafe values" {
                $fields = [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput]@{
                    RichTextFields = @(@{ fieldId = 'description'; richText = { Get-Secret } })
                }
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueEditRequest]@{
                    SelectedIssueIdsOrKeys = @('TEST-1')
                    SelectedActions        = @('description')
                    EditedFieldsInput      = $fields
                }

                { Set-JiraIssueBulk -Request $request -ErrorAction Stop } |
                    Should -Throw '*must not contain credentials, secure strings, or script blocks*'
            }
        }
    }
}
