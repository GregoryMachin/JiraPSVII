#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    Initialize-TestEnvironment
    $script:moduleToTest = Resolve-ModuleSource

    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope JiraPSVII {
    Describe "AtlassianPSVII.JiraPSVII strong-typed POCO classes" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            function Get-JiraTestObject {
                param(
                    [Parameter(Mandatory)]
                    [string]$TypeName,

                    [hashtable]$Property = @{}
                )

                $type = $TypeName -as [Type]
                $object = [Activator]::CreateInstance($type)
                foreach ($name in $Property.Keys) {
                    $object.$name = $Property[$name]
                }
                $object
            }

            function Get-JiraTestObjectFromString {
                param(
                    [Parameter(Mandatory)]
                    [string]$TypeName,

                    [AllowNull()]
                    [string]$Value
                )

                [Activator]::CreateInstance(($TypeName -as [Type]), [object[]]@($Value))
            }
        }

        Context "Type loading" {
            It "loads <typeName> into the current AppDomain" -TestCases @(
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Attachment' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkEditMultiSelectFieldOption' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueEditRequest' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueMoveRequest' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueOperation' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueMoveTarget' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkOperationLimits' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkOperationProgress' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkOperationStatus' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Component' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.CreateMetaField' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.EditMetaField' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Field' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.FilterPermission' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.IssueLink' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.IssueLinkType' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.IssueType' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.JqlApproximateCountResult' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.JqlValidationResult' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.OAuthResource' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Link' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Priority' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ProjectRole' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Resolution' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Session' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Status' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.StatusCategory' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.SubmittedBulkOperation' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Transition' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Worklogitem' }
            ) {
                param($typeName)

                ($typeName -as [Type]) | Should -Not -BeNullOrEmpty -Because "$typeName must be available after module import"
            }
        }

        Context "Hashtable construction" {
            It "constructs an Issue from a hashtable literal" {
                $issue = [AtlassianPSVII.JiraPSVII.Issue]@{ Key = 'TEST-1'; Summary = 'hashtable init' }

                $issue.Key | Should -Be 'TEST-1'
                $issue.Summary | Should -Be 'hashtable init'
            }

            It "constructs a User from a hashtable literal" {
                $user = [AtlassianPSVII.JiraPSVII.User]@{ Name = 'jdoe'; DisplayName = 'John Doe'; Active = $true }

                $user.Name | Should -Be 'jdoe'
                $user.DisplayName | Should -Be 'John Doe'
                $user.Active | Should -BeTrue
            }
        }

        Context "ToString() overrides" {
            It "<typeName> formats <scenario>" -TestCases @(
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = @{ Key = 'TEST-1'; Summary = 'my summary' }; scenario = 'key and summary'; expected = '[TEST-1] my summary' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; property = @{ Name = 'jdoe'; DisplayName = 'John' }; scenario = 'name first'; expected = 'jdoe' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; property = @{ DisplayName = 'John' }; scenario = 'display name fallback'; expected = 'John' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; property = @{ AccountId = 'abc-123' }; scenario = 'account ID fallback'; expected = 'abc-123' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; property = @{}; scenario = 'empty'; expected = '' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project'; property = @{ Name = 'My Project' }; scenario = 'name'; expected = 'My Project' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = @{ Name = '1.0.0' }; scenario = 'name'; expected = '1.0.0' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter'; property = @{ Name = 'My Filter' }; scenario = 'name'; expected = 'My Filter' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment'; property = @{ Body = 'hello' }; scenario = 'body'; expected = 'hello' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment'; property = @{}; scenario = 'empty'; expected = '' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo'; property = @{ DeploymentType = 'Cloud'; Version = '1001.0.0' }; scenario = 'deployment and version'; expected = '[Cloud] 1001.0.0' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo'; property = @{ Version = '1001.0.0' }; scenario = 'version fallback'; expected = '1001.0.0' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo'; property = @{ DeploymentType = 'Cloud' }; scenario = 'deployment fallback'; expected = 'Cloud' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo'; property = @{}; scenario = 'empty'; expected = '' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Session'; property = @{ JSessionID = 'abc' }; scenario = 'session ID'; expected = 'JiraSession[JSessionID=abc]' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Session'; property = @{}; scenario = 'empty'; expected = 'JiraSession' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.SubmittedBulkOperation'; property = @{ TaskId = '10641' }; scenario = 'task id'; expected = '10641' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkOperationProgress'; property = @{ TaskId = '10641'; Status = [AtlassianPSVII.JiraPSVII.BulkOperationStatus]::RUNNING }; scenario = 'task id and status'; expected = '10641 [RUNNING]' }
            ) {
                param($typeName, $property, $expected)

                (Get-JiraTestObject -TypeName $typeName -Property $property).ToString() | Should -Be $expected
            }
        }

        Context "Strong cross-reference slot typing" {
            # These assertions lock in the slot type for every cross-reference
            # so a future loosening (e.g. Project.Lead going back to System.Object)
            # is caught immediately. Strong slots are what give us IntelliSense
            # and parse-time errors when the wrong thing is assigned.

            It "<typeName>.<property> is <expectedType>" -TestCases @(
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project'; property = 'Lead'; expectedType = [AtlassianPSVII.JiraPSVII.User] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment'; property = 'Author'; expectedType = [AtlassianPSVII.JiraPSVII.User] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment'; property = 'UpdateAuthor'; expectedType = [AtlassianPSVII.JiraPSVII.User] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Project'; expectedType = [AtlassianPSVII.JiraPSVII.Project] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter'; property = 'Owner'; expectedType = [AtlassianPSVII.JiraPSVII.User] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Assignee'; expectedType = [object] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Creator'; expectedType = [AtlassianPSVII.JiraPSVII.User] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Reporter'; expectedType = [AtlassianPSVII.JiraPSVII.User] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Comment'; expectedType = [AtlassianPSVII.JiraPSVII.Comment[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Status'; expectedType = [AtlassianPSVII.JiraPSVII.Status] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'IssueLinks'; expectedType = [AtlassianPSVII.JiraPSVII.IssueLink[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Attachment'; expectedType = [AtlassianPSVII.JiraPSVII.Attachment[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Transition'; expectedType = [AtlassianPSVII.JiraPSVII.Transition[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project'; property = 'IssueTypes'; expectedType = [AtlassianPSVII.JiraPSVII.IssueType[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project'; property = 'Components'; expectedType = [AtlassianPSVII.JiraPSVII.Component[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter'; property = 'FilterPermissions'; expectedType = [AtlassianPSVII.JiraPSVII.FilterPermission[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'RestUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'HttpUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; property = 'RestUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter'; property = 'SearchUrl'; expectedType = [uri] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Description'; expectedType = [string] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment'; property = 'Body'; expectedType = [string] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; property = 'Groups'; expectedType = [string[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo'; property = 'ScmInfo'; expectedType = [string] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo'; property = 'BuildNumber'; expectedType = [System.Nullable[long]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueEditRequest'; property = 'EditedFieldsInput'; expectedType = [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueEditRequest'; property = 'SelectedActions'; expectedType = [string[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueMoveRequest'; property = 'TargetToSourcesMapping'; expectedType = [System.Collections.IDictionary] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueMoveTarget'; property = 'IssueIdsOrKeys'; expectedType = [string[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkOperationProgress'; property = 'SubmittedBy'; expectedType = [AtlassianPSVII.JiraPSVII.User] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkOperationProgress'; property = 'ProcessedAccessibleIssues'; expectedType = [long[]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter'; property = 'Favourite'; expectedType = [bool] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = 'Archived'; expectedType = [bool] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = 'Released'; expectedType = [bool] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = 'Overdue'; expectedType = [bool] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = 'Project'; expectedType = [System.Nullable[long]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = 'StartDate'; expectedType = [System.Nullable[datetime]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = 'ReleaseDate'; expectedType = [System.Nullable[datetime]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Created'; expectedType = [System.Nullable[System.DateTimeOffset]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment'; property = 'Updated'; expectedType = [System.Nullable[System.DateTimeOffset]] }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo'; property = 'ServerTime'; expectedType = [System.Nullable[System.DateTimeOffset]] }
            ) {
                param($typeName, $property, $expectedType)

                ($typeName -as [Type]).GetProperty($property).PropertyType | Should -Be $expectedType
            }
        }

        Context "Convenience constructors" {
            # The six identifier-driven classes ship a string-arg ctor for the
            # common stub-from-an-identifier flow that scripts and pipelines
            # exercise constantly. Each one mirrors the routing logic of its
            # matching ArgumentTransformationAttribute so passing a string
            # through `[Class]::new('value')` and through `-Parameter 'value'`
            # produce identical stubs.

            It "<typeName>('<inputValue>') stores input in <expectedProperty>" -TestCases @(
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; inputValue = 'TEST-1'; expectedProperty = 'Key'; expectedValue = 'TEST-1'; emptyProperty = 'ID' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; inputValue = 'jdoe'; expectedProperty = 'Name'; expectedValue = 'jdoe'; emptyProperty = 'AccountId' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project'; inputValue = 'TEST'; expectedProperty = 'Key'; expectedValue = 'TEST'; emptyProperty = 'ID' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Group'; inputValue = 'jira-users'; expectedProperty = 'Name'; expectedValue = 'jira-users'; emptyProperty = 'Size' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter'; inputValue = '12345'; expectedProperty = 'ID'; expectedValue = '12345'; emptyProperty = 'Name' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; inputValue = '10001'; expectedProperty = 'ID'; expectedValue = '10001'; emptyProperty = 'Name' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; inputValue = 'My Version'; expectedProperty = 'Name'; expectedValue = 'My Version'; emptyProperty = 'ID' }
            ) {
                param($typeName, $inputValue, $expectedProperty, $expectedValue, $emptyProperty)

                $value = Get-JiraTestObjectFromString -TypeName $typeName -Value $inputValue

                $value | Should -BeOfType ($typeName -as [Type])
                $value.$expectedProperty | Should -Be $expectedValue
                $value.$emptyProperty | Should -BeNullOrEmpty
            }

            It "<typeName> string-arg ctor rejects '<label>' input" -TestCases @(
                # Symmetric with the matching ArgumentTransformationAttribute
                # error: building a stub via the ctor must not silently
                # accept nonsense that the parameter binder would reject.
                foreach ($typeName in 'AtlassianPSVII.JiraPSVII.Issue', 'AtlassianPSVII.JiraPSVII.User', 'AtlassianPSVII.JiraPSVII.Project', 'AtlassianPSVII.JiraPSVII.Group', 'AtlassianPSVII.JiraPSVII.Filter', 'AtlassianPSVII.JiraPSVII.Version') {
                    foreach ($case in @(
                            @{ label = 'null'; value = $null }
                            @{ label = 'empty'; value = '' }
                            @{ label = 'space'; value = ' ' }
                            @{ label = 'tab'; value = "`t" }
                        )) {
                        @{ typeName = $typeName; label = $case.label; value = $case.value }
                    }
                }
            ) {
                param($typeName, $value)

                { Get-JiraTestObjectFromString -TypeName $typeName -Value $value } | Should -Throw
            }

            It "the parameterless ctor is preserved on <typeName>" -TestCases @(
                # Regression guard: declaring a parameterized ctor in C#
                # removes the implicit parameterless ctor, which the
                # [Class]@{ ... } hashtable-cast pattern depends on. Each
                # class must keep `public Foo() {}` explicitly.
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Group' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Comment' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Session' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.ServerInfo' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueEditRequest' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueMoveRequest' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkIssueMoveTarget' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.SubmittedBulkOperation' }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.BulkOperationProgress' }
            ) {
                param($typeName)

                $type = $typeName -as [Type]
                $type | Should -Not -BeNullOrEmpty -Because "$typeName must be loaded"
                $type.GetConstructor([Type]::EmptyTypes) |
                    Should -Not -BeNullOrEmpty -Because "$typeName must keep an explicit parameterless ctor"
            }

            It "the hashtable-cast pattern still works for <typeName>.<property>" -TestCases @(
                # The 30+ existing [Class]@{ ... } call sites in the test
                # suite would fail loudly if we lost the parameterless ctor
                # or its property setters; this assertion locks the contract
                # in one place so it cannot regress quietly.
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Issue'; property = 'Key'; value = 'TEST-1'; create = { [AtlassianPSVII.JiraPSVII.Issue]@{ Key = 'TEST-1' } } }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.User'; property = 'Name'; value = 'jdoe'; create = { [AtlassianPSVII.JiraPSVII.User]@{ Name = 'jdoe' } } }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Project'; property = 'Key'; value = 'TEST'; create = { [AtlassianPSVII.JiraPSVII.Project]@{ Key = 'TEST' } } }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Group'; property = 'Name'; value = 'jira-users'; create = { [AtlassianPSVII.JiraPSVII.Group]@{ Name = 'jira-users' } } }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Filter'; property = 'ID'; value = '1'; create = { [AtlassianPSVII.JiraPSVII.Filter]@{ ID = '1' } } }
                @{ typeName = 'AtlassianPSVII.JiraPSVII.Version'; property = 'Name'; value = '1.0'; create = { [AtlassianPSVII.JiraPSVII.Version]@{ Name = '1.0' } } }
            ) {
                param($property, $value, $create)

                (& $create).$property | Should -Be $value
            }

            It "the string-arg ctor produces a stub that round-trips through the matching transformer parameter" {
                # End-to-end check: build a stub via ::new() and bind it to
                # an actual cmdlet parameter so the transformer either
                # passes it through (singleton case) or fans it out (array
                # case). This catches a transformer regression that would
                # accept the string but reject the typed stub.
                $cmd = Get-Command Add-JiraIssueComment
                $param = $cmd.Parameters['Issue']
                $param.ParameterType.FullName | Should -Be 'AtlassianPSVII.JiraPSVII.Issue'

                $stub = [AtlassianPSVII.JiraPSVII.Issue]::new('TEST-1')
                # The transformer accepts an existing Issue and returns it
                # unchanged. We do not invoke the cmdlet (no live Jira),
                # but we drive the transformer directly to prove the round-trip.
                $transformerType = [AtlassianPSVII.JiraPSVII.IssueTransformationAttribute]
                $transformer = $transformerType::new()
                $result = $transformer.Transform($null, $stub)
                $result | Should -Be $stub
            }
        }

        Context "Identifier-based equality and comparison" {
            BeforeAll {
                function Assert-IdentifierBehavior {
                    param(
                        [Parameter(Mandatory)]
                        [object]$Primary,

                        [Parameter(Mandatory)]
                        [object]$Equivalent,

                        [Parameter(Mandatory)]
                        [object]$Different
                    )

                    ($Primary -eq $Equivalent) | Should -BeTrue
                    ($Primary -eq $Different) | Should -BeFalse
                    (@($Primary) -contains $Equivalent) | Should -BeTrue

                    (@($Different, $Primary) | Sort-Object)[0] | Should -Be $Primary
                    (@($Primary, $Equivalent, $Different) | Sort-Object -Unique).Count | Should -Be 2

                    $groups = @($Primary, $Equivalent, $Different) | Group-Object -AsHashTable
                    $groups.Count | Should -Be 2
                    $groups[$Primary].Count | Should -Be 2

                    $lookup = @{}
                    $lookup[$Primary] = 'first'
                    $lookup[$Equivalent] = 'second'
                    $lookup[$Different] = 'third'

                    $lookup.Count | Should -Be 2
                    $lookup[$Primary] | Should -Be 'second'
                }
            }

            It "<scenario>" -TestCases @(
                @{
                    scenario   = 'Issue compares by Key'
                    primary    = { [AtlassianPSVII.JiraPSVII.Issue]@{ Key = 'TEST-1'; Summary = 'first' } }
                    equivalent = { [AtlassianPSVII.JiraPSVII.Issue]@{ Key = 'test-1'; Summary = 'second' } }
                    different  = { [AtlassianPSVII.JiraPSVII.Issue]@{ Key = 'TEST-2'; Summary = 'third' } }
                }
                @{
                    scenario   = 'Project compares by Key'
                    primary    = { [AtlassianPSVII.JiraPSVII.Project]@{ Key = 'ALPHA'; Name = 'Alpha' } }
                    equivalent = { [AtlassianPSVII.JiraPSVII.Project]@{ Key = 'alpha'; Name = 'Alpha (clone)' } }
                    different  = { [AtlassianPSVII.JiraPSVII.Project]@{ Key = 'BETA'; Name = 'Beta' } }
                }
                @{
                    scenario   = 'Group compares by Name'
                    primary    = { [AtlassianPSVII.JiraPSVII.Group]@{ Name = 'jira-admins' } }
                    equivalent = { [AtlassianPSVII.JiraPSVII.Group]@{ Name = 'JIRA-ADMINS' } }
                    different  = { [AtlassianPSVII.JiraPSVII.Group]@{ Name = 'jira-users' } }
                }
                @{
                    scenario   = 'Filter compares by ID'
                    primary    = { [AtlassianPSVII.JiraPSVII.Filter]@{ ID = '10001'; Name = '10001' } }
                    equivalent = { [AtlassianPSVII.JiraPSVII.Filter]@{ ID = '10001'; Name = 'same-id-different-name' } }
                    different  = { [AtlassianPSVII.JiraPSVII.Filter]@{ ID = '20001'; Name = '20001' } }
                }
                @{
                    scenario   = 'Version compares by ID first, then Name'
                    primary    = { [AtlassianPSVII.JiraPSVII.Version]@{ ID = '10001'; Name = '1.0.0' } }
                    equivalent = { [AtlassianPSVII.JiraPSVII.Version]@{ ID = '10001'; Name = '1.0.0-alt' } }
                    different  = { [AtlassianPSVII.JiraPSVII.Version]@{ ID = '20001'; Name = '2.0.0' } }
                }
                @{
                    scenario   = 'User compares by AccountId first, then Name'
                    primary    = { [AtlassianPSVII.JiraPSVII.User]@{ AccountId = 'abc-123'; Name = 'legacy-user-a' } }
                    equivalent = { [AtlassianPSVII.JiraPSVII.User]@{ AccountId = 'ABC-123'; Name = 'legacy-user-b' } }
                    different  = { [AtlassianPSVII.JiraPSVII.User]@{ AccountId = 'def-456'; Name = 'legacy-user-a' } }
                }
                @{
                    scenario   = 'User falls back to Name when AccountId is absent'
                    primary    = { [AtlassianPSVII.JiraPSVII.User]@{ Name = 'asmith' } }
                    equivalent = { [AtlassianPSVII.JiraPSVII.User]@{ Name = 'ASMITH'; DisplayName = 'Alice Smith' } }
                    different  = { [AtlassianPSVII.JiraPSVII.User]@{ Name = 'jdoe' } }
                }
            ) {
                param($primary, $equivalent, $different)

                Assert-IdentifierBehavior -Primary (& $primary) -Equivalent (& $equivalent) -Different (& $different)
            }

            It "<type> identifier-less objects do not deduplicate under Sort-Object -Unique" -TestCases @(
                @{ type = 'Issue'; create = { [AtlassianPSVII.JiraPSVII.Issue]::new() } }
                @{ type = 'Project'; create = { [AtlassianPSVII.JiraPSVII.Project]::new() } }
                @{ type = 'Group'; create = { [AtlassianPSVII.JiraPSVII.Group]::new() } }
                @{ type = 'Filter'; create = { [AtlassianPSVII.JiraPSVII.Filter]::new() } }
                @{ type = 'Version'; create = { [AtlassianPSVII.JiraPSVII.Version]::new() } }
                @{ type = 'User'; create = { [AtlassianPSVII.JiraPSVII.User]::new() } }
            ) {
                param($type, $create)

                $first = & $create
                $second = & $create

                ($first -eq $second) | Should -BeFalse -Because "$type equality is identity-based only when an identifier exists"
                ($first.CompareTo($second)) | Should -Not -Be 0 -Because "$type comparison must not collapse distinct identifier-less objects"
                (@($first, $second) | Sort-Object -Unique).Count | Should -Be 2 -Because "$type identifier-less instances must stay distinct"
            }

            It "<type> identifier-less objects still equal themselves" -TestCases @(
                @{ type = 'Issue'; create = { [AtlassianPSVII.JiraPSVII.Issue]::new() } }
                @{ type = 'Project'; create = { [AtlassianPSVII.JiraPSVII.Project]::new() } }
                @{ type = 'Group'; create = { [AtlassianPSVII.JiraPSVII.Group]::new() } }
                @{ type = 'Filter'; create = { [AtlassianPSVII.JiraPSVII.Filter]::new() } }
                @{ type = 'Version'; create = { [AtlassianPSVII.JiraPSVII.Version]::new() } }
                @{ type = 'User'; create = { [AtlassianPSVII.JiraPSVII.User]::new() } }
            ) {
                param($type, $create)

                $value = & $create

                ($value.Equals($value)) | Should -BeTrue -Because "$type must satisfy reflexive equality even before an identifier is populated"
                ($value.CompareTo($value)) | Should -Be 0 -Because "$type compare-to-self must remain stable"
            }
        }

        Context "Transformer fallthrough across competing parameter sets" {
            BeforeAll {
                function Invoke-IssuePreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Issue')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Issue')]
                        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
                        [AtlassianPSVII.JiraPSVII.Issue]$Issue,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
                        [AtlassianPSVII.JiraPSVII.Project]$Project
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-UserPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'User')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'User')]
                        [AtlassianPSVII.JiraPSVII.UserTransformation()]
                        [AtlassianPSVII.JiraPSVII.User]$User,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Group')]
                        [AtlassianPSVII.JiraPSVII.GroupTransformation()]
                        [AtlassianPSVII.JiraPSVII.Group]$Group
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-GroupPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Group')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Group')]
                        [AtlassianPSVII.JiraPSVII.GroupTransformation()]
                        [AtlassianPSVII.JiraPSVII.Group]$Group,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'User')]
                        [AtlassianPSVII.JiraPSVII.UserTransformation()]
                        [AtlassianPSVII.JiraPSVII.User]$User
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-VersionPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Version')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Version')]
                        [AtlassianPSVII.JiraPSVII.VersionTransformation()]
                        [AtlassianPSVII.JiraPSVII.Version]$Version,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
                        [AtlassianPSVII.JiraPSVII.Project]$Project
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-FilterPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Filter')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Filter')]
                        [AtlassianPSVII.JiraPSVII.FilterTransformation()]
                        [AtlassianPSVII.JiraPSVII.Filter]$Filter,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
                        [AtlassianPSVII.JiraPSVII.Project]$Project
                    )
                    process { $PSCmdlet.ParameterSetName }
                }

                function Invoke-ProjectPreferredBinding {
                    [CmdletBinding(DefaultParameterSetName = 'Project')]
                    param(
                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Project')]
                        [AtlassianPSVII.JiraPSVII.ProjectTransformation()]
                        [AtlassianPSVII.JiraPSVII.Project]$Project,

                        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Version')]
                        [AtlassianPSVII.JiraPSVII.VersionTransformation()]
                        [AtlassianPSVII.JiraPSVII.Version]$Version
                    )
                    process { $PSCmdlet.ParameterSetName }
                }
            }

            It "<transformer> falls through to <expectedParameterSet> when competing input is piped" -TestCases @(
                @{
                    transformer          = 'IssueTransformation'
                    createInput          = { [AtlassianPSVII.JiraPSVII.Project]::new('TEST') }
                    invokeBinding        = { param($value) $value | Invoke-IssuePreferredBinding }
                    expectedParameterSet = 'Project'
                }
                @{
                    transformer          = 'UserTransformation'
                    createInput          = { [AtlassianPSVII.JiraPSVII.Group]::new('jira-users') }
                    invokeBinding        = { param($value) $value | Invoke-UserPreferredBinding }
                    expectedParameterSet = 'Group'
                }
                @{
                    transformer          = 'GroupTransformation'
                    createInput          = { [AtlassianPSVII.JiraPSVII.User]::new('jdoe') }
                    invokeBinding        = { param($value) $value | Invoke-GroupPreferredBinding }
                    expectedParameterSet = 'User'
                }
                @{
                    transformer          = 'VersionTransformation'
                    createInput          = { [AtlassianPSVII.JiraPSVII.Project]::new('TEST') }
                    invokeBinding        = { param($value) $value | Invoke-VersionPreferredBinding }
                    expectedParameterSet = 'Project'
                }
                @{
                    transformer          = 'FilterTransformation'
                    createInput          = { [AtlassianPSVII.JiraPSVII.Project]::new('TEST') }
                    invokeBinding        = { param($value) $value | Invoke-FilterPreferredBinding }
                    expectedParameterSet = 'Project'
                }
                @{
                    transformer          = 'ProjectTransformation'
                    createInput          = { [AtlassianPSVII.JiraPSVII.Version]::new('10001') }
                    invokeBinding        = { param($value) $value | Invoke-ProjectPreferredBinding }
                    expectedParameterSet = 'Version'
                }
            ) {
                param($createInput, $invokeBinding, $expectedParameterSet)

                & $invokeBinding (& $createInput) | Should -Be $expectedParameterSet
            }

            It "<transformerType> reports type-specific errors on unrelated values" -TestCases @(
                @{ transformerType = [AtlassianPSVII.JiraPSVII.VersionTransformationAttribute]; expectedMessage = '*AtlassianPSVII.JiraPSVII.Version*' }
                @{ transformerType = [AtlassianPSVII.JiraPSVII.FilterTransformationAttribute]; expectedMessage = '*AtlassianPSVII.JiraPSVII.Filter*' }
                @{ transformerType = [AtlassianPSVII.JiraPSVII.ProjectTransformationAttribute]; expectedMessage = '*AtlassianPSVII.JiraPSVII.Project*' }
            ) {
                param($transformerType, $expectedMessage)

                $transformer = $transformerType::new()
                { $transformer.Transform($null, [datetime]::UtcNow) } | Should -Throw $expectedMessage
            }
        }

        Context "Bulk operation request DTOs" {
            It "serializes a bulk delete request with Jira wire names" {
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest]@{
                    SelectedIssueIdsOrKeys = @('TEST-1', '10002')
                    SendBulkNotification   = $false
                }

                $payload = $request.ToJiraPayload()
                $json = $payload | ConvertTo-Json -Depth 10
                $roundTrip = $json | ConvertFrom-Json

                $request.Operation | Should -Be ([AtlassianPSVII.JiraPSVII.BulkIssueOperation]::Delete)
                $roundTrip.selectedIssueIdsOrKeys | Should -Be @('TEST-1', '10002')
                $roundTrip.sendBulkNotification | Should -BeFalse
                ($json -cmatch 'SelectedIssueIdsOrKeys|SendBulkNotification') | Should -BeFalse
            }

            It "serializes a bulk edit request with explicit field collections and selected actions" {
                $fields = [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput]::FromDictionary(@{
                        singleLineTextFields = @(
                            @{
                                fieldId = 'summary'
                                text    = 'Updated summary'
                            }
                        )
                        priority             = @{
                            priorityId = '2'
                        }
                    })
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueEditRequest]@{
                    SelectedIssueIdsOrKeys = @('TEST-1')
                    SelectedActions        = @('summary', 'priority')
                    EditedFieldsInput      = $fields
                    SendBulkNotification   = $true
                }

                $payload = $request.ToJiraPayload()
                $roundTrip = $payload | ConvertTo-Json -Depth 10 | ConvertFrom-Json

                $request.Operation | Should -Be ([AtlassianPSVII.JiraPSVII.BulkIssueOperation]::Edit)
                $fields.GetFieldUpdateCount() | Should -Be 2
                $roundTrip.editedFieldsInput.singleLineTextFields[0].fieldId | Should -Be 'summary'
                $roundTrip.editedFieldsInput.priority.priorityId | Should -Be '2'
                $roundTrip.selectedActions | Should -Be @('summary', 'priority')
                $roundTrip.selectedIssueIdsOrKeys | Should -Be @('TEST-1')
                $roundTrip.sendBulkNotification | Should -BeTrue
            }

            It "rejects unknown bulk edit field collections" {
                {
                    [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput]::FromDictionary(@{
                            unknownFields = @(@{ fieldId = 'customfield_10000'; value = 'x' })
                        })
                } | Should -Throw '*Unknown bulk edit field collection*'
            }

            It "enforces the 200-field bulk edit limit" {
                $updates = foreach ($index in 1..201) {
                    @{
                        fieldId = "customfield_$index"
                        text    = "value-$index"
                    }
                }
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueEditRequest]@{
                    SelectedIssueIdsOrKeys = @('TEST-1')
                    SelectedActions        = @('customfield_1')
                    EditedFieldsInput      = [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput]@{
                        SingleLineTextFields = @($updates)
                    }
                }

                { $request.ToJiraPayload() } | Should -Throw '*200 fields*'
            }

            It "enforces the 1,000-issue limit for delete requests" {
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueDeleteRequest]@{
                    SelectedIssueIdsOrKeys = @(1..1001 | ForEach-Object { "TEST-$_" })
                }

                { $request.ToJiraPayload() } | Should -Throw '*1,000 issues*'
            }

            It "serializes a bulk move request with target-to-sources mapping" {
                $target = [AtlassianPSVII.JiraPSVII.BulkIssueMoveTarget]@{
                    IssueIdsOrKeys          = @('TEST-1', 'TEST-2')
                    InferFieldDefaults      = $false
                    InferStatusDefaults     = $true
                    InferSubtaskTypeDefault = $true
                    TargetStatus            = @(
                        @{
                            statuses = @{
                                '10001' = @('10002')
                            }
                        }
                    )
                }
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueMoveRequest]@{
                    SendBulkNotification   = $true
                    TargetToSourcesMapping = @{
                        'DEST,10001' = $target
                    }
                }

                $payload = $request.ToJiraPayload()
                $roundTrip = $payload | ConvertTo-Json -Depth 20 | ConvertFrom-Json

                $request.Operation | Should -Be ([AtlassianPSVII.JiraPSVII.BulkIssueOperation]::Move)
                $roundTrip.sendBulkNotification | Should -BeTrue
                $roundTrip.targetToSourcesMapping.'DEST,10001'.issueIdsOrKeys | Should -Be @('TEST-1', 'TEST-2')
                $roundTrip.targetToSourcesMapping.'DEST,10001'.inferFieldDefaults | Should -BeFalse
                $roundTrip.targetToSourcesMapping.'DEST,10001'.inferStatusDefaults | Should -BeTrue
            }

            It "rejects unsafe values before serialization" {
                $fields = [AtlassianPSVII.JiraPSVII.JiraBulkEditFieldsInput]@{
                    RichTextFields = @(
                        @{
                            fieldId  = 'description'
                            richText = { Get-Secret }
                        }
                    )
                }
                $request = [AtlassianPSVII.JiraPSVII.BulkIssueEditRequest]@{
                    SelectedIssueIdsOrKeys = @('TEST-1')
                    SelectedActions        = @('description')
                    EditedFieldsInput      = $fields
                }

                { $request.ToJiraPayload() } | Should -Throw '*must not contain credentials, secure strings, or script blocks*'
            }

            It "models submitted and progress status responses without request credentials" {
                $submitted = [AtlassianPSVII.JiraPSVII.SubmittedBulkOperation]@{ TaskId = '10641' }
                $progress = [AtlassianPSVII.JiraPSVII.BulkOperationProgress]@{
                    TaskId                          = '10641'
                    Status                          = [AtlassianPSVII.JiraPSVII.BulkOperationStatus]::COMPLETE
                    ProgressPercent                 = 100
                    SubmittedBy                     = [AtlassianPSVII.JiraPSVII.User]@{ AccountId = 'abc-123' }
                    ProcessedAccessibleIssues       = @([long]10001, [long]10002)
                    InvalidOrInaccessibleIssueCount = 0
                    TotalIssueCount                 = 2
                }

                $submitted.TaskId | Should -Be '10641'
                $progress.Status | Should -Be ([AtlassianPSVII.JiraPSVII.BulkOperationStatus]::COMPLETE)
                $progress.SubmittedBy.AccountId | Should -Be 'abc-123'
                $progress.ProcessedAccessibleIssues | Should -Be @([long]10001, [long]10002)
                ($progress.PSObject.Properties.Name | Where-Object { $_ -match 'Credential|Token|Secret|Password' }) |
                    Should -BeNullOrEmpty
            }
        }

        Context "ConvertTo-Hashtable" {
            It "round-trips a PSCustomObject into a Hashtable" {
                $hash = [PSCustomObject]@{ A = 1; B = 'two' } | ConvertTo-Hashtable

                $hash | Should -BeOfType [hashtable]
                $hash.A | Should -Be 1
                $hash.B | Should -Be 'two'
            }

            It "lets a [Class](ConvertTo-Hashtable) cast succeed where [Class]\$psobject would fail on PS5.1" {
                # The motivating bug for ConvertTo-Hashtable: casting a
                # PSCustomObject to a custom .NET class throws
                # PSInvalidCastException on Windows PowerShell 5.1, but casting
                # from a Hashtable is fine. This test would fail on PS5.1
                # without the round-trip.
                $payload = [PSCustomObject]@{ Name = 'jdoe'; DisplayName = 'John Doe'; Active = $true }
                { [AtlassianPSVII.JiraPSVII.User](ConvertTo-Hashtable -InputObject $payload) } | Should -Not -Throw
            }
        }
    }
}
