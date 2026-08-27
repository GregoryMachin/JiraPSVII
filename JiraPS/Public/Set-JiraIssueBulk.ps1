function Set-JiraIssueBulk {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByIssue')]
    [OutputType([AtlassianPS.JiraPS.SubmittedBulkOperation], [AtlassianPS.JiraPS.BulkIssueEditRequest])]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'ByIssue')]
        [ValidateNotNullOrEmpty()]
        [Alias('IssueId', 'Key')]
        [Object[]]
        $Issue,

        [Parameter(ParameterSetName = 'ByIssue')]
        [String]
        $Summary,

        [Parameter(ParameterSetName = 'ByIssue')]
        [String]
        $Description,

        [Parameter(ParameterSetName = 'ByIssue')]
        [PSObject]
        $Fields,

        [Parameter(ParameterSetName = 'ByIssue')]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.JiraBulkEditFieldsInput]
        $EditedFieldsInput,

        [Parameter(ParameterSetName = 'ByIssue')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $SelectedAction,

        [Parameter(Mandatory, ParameterSetName = 'ByRequest')]
        [ValidateNotNull()]
        [AtlassianPS.JiraPS.BulkIssueEditRequest]
        $Request,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Switch]
        $SkipNotification,

        [Switch]
        $ValidateOnly,

        [Switch]
        $AllowCrossProject
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        if ($PsCmdlet.ParameterSetName -eq 'ByRequest') {
            $bulkRequest = $Request
        }
        else {
            $issueIdsOrKeys = Resolve-JiraBulkIssueIdOrKey -Issue $Issue -CallerName $MyInvocation.MyCommand.Name
            Test-JiraBulkCrossProjectSelection -IssueIdsOrKeys $issueIdsOrKeys -AllowCrossProject:$AllowCrossProject -Cmdlet $PSCmdlet

            $combinedFields = [AtlassianPS.JiraPS.JiraBulkEditFieldsInput]::new()
            $combinedActions = [System.Collections.Generic.List[String]]::new()

            if ($EditedFieldsInput) {
                Merge-JiraBulkEditFieldsInput -Target $combinedFields -Source $EditedFieldsInput
                if ($SelectedAction) {
                    foreach ($action in $SelectedAction) { Add-JiraBulkSelectedAction -List $combinedActions -Action $action }
                }
            }

            if ($Summary) {
                Add-JiraBulkSelectedAction -List $combinedActions -Action 'summary'
                $combinedFields.SingleLineTextFields += @(
                    @{
                        fieldId = 'summary'
                        text    = $Summary
                    }
                )
            }

            if ($Description) {
                Add-JiraBulkSelectedAction -List $combinedActions -Action 'description'
                $combinedFields.RichTextFields += @(
                    @{
                        fieldId  = 'description'
                        richText = Resolve-JiraTextFieldPayload -Text $Description -IsCloud $true
                    }
                )
            }

            if ($Fields) {
                $editableFields = Get-JiraBulkEditableField -IssueIdsOrKeys $issueIdsOrKeys -Credential $Credential
                foreach ($assignment in ConvertTo-JiraFieldAssignment `
                        -Fields (ConvertTo-JiraBulkFieldHashtable -Fields $Fields) `
                        -ScopedMeta $editableFields `
                        -IsCloud $true `
                        -ScopedContext 'bulk editable fields' `
                        -CallerName $MyInvocation.MyCommand.Name `
                        -FallbackFieldFetcher { @($editableFields) }) {
                    Add-JiraBulkSelectedAction -List $combinedActions -Action $assignment.Id
                    Add-JiraBulkFieldAssignment -FieldsInput $combinedFields -Assignment $assignment -Cmdlet $PSCmdlet
                }
            }

            if ($combinedFields.GetFieldUpdateCount() -eq 0) {
                $errorParameter = @{
                    Cmdlet       = $PSCmdlet
                    Exception    = [System.ArgumentException]::new('The parameters provided do not change any issues. Specify -Summary, -Description, -Fields, -EditedFieldsInput, or pass a typed -Request.')
                    ErrorId      = 'ParameterValue.NoBulkFieldUpdates'
                    Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
                    TargetObject = $Issue
                }
                ThrowError @errorParameter
            }

            $bulkRequest = [AtlassianPS.JiraPS.BulkIssueEditRequest]@{
                SelectedIssueIdsOrKeys = $issueIdsOrKeys
                SelectedActions        = [String[]]@($combinedActions)
                EditedFieldsInput      = $combinedFields
                SendBulkNotification   = -not $SkipNotification
            }
        }

        Test-JiraBulkCrossProjectSelection -IssueIdsOrKeys $bulkRequest.SelectedIssueIdsOrKeys -AllowCrossProject:$AllowCrossProject -Cmdlet $PSCmdlet
        $payload = $bulkRequest.ToJiraPayload()

        if ($ValidateOnly) {
            Write-Output $bulkRequest
            return
        }

        if (-not (Test-JiraCloudServer -Credential $Credential)) {
            $errorParameter = @{
                Cmdlet       = $PSCmdlet
                Exception    = [System.NotSupportedException]::new('Set-JiraIssueBulk uses Jira Cloud issue bulk operations and is not supported against Jira Server or Data Center.')
                ErrorId      = 'OperationNotSupported.JiraCloudOnly'
                Category     = [System.Management.Automation.ErrorCategory]::NotImplemented
                TargetObject = $bulkRequest
            }
            ThrowError @errorParameter
        }

        $target = '{0} issue(s)' -f @($bulkRequest.SelectedIssueIdsOrKeys).Count
        if ($PSCmdlet.ShouldProcess($target, 'Submit Jira bulk issue edit')) {
            $result = Invoke-JiraMethod `
                -URI '/rest/api/3/bulk/issues/fields' `
                -Method POST `
                -Body (ConvertTo-Json -InputObject $payload -Depth 30) `
                -Credential $Credential

            Write-Output (ConvertTo-JiraSubmittedBulkOperation -InputObject $result)
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}

function Resolve-JiraBulkIssueIdOrKey {
    [CmdletBinding()]
    [OutputType([String[]])]
    param(
        [Parameter(Mandatory)]
        [Object[]]
        $Issue,

        [String]
        $CallerName = $MyInvocation.MyCommand.Name
    )

    $ids = foreach ($item in $Issue) {
        if ($null -eq $item) { continue }

        $value = if ($item -is [System.Management.Automation.PSObject]) { $item.BaseObject } else { $item }
        if ($value -is [AtlassianPS.JiraPS.Issue]) {
            if (-not [String]::IsNullOrWhiteSpace($value.Key)) { [String]$value.Key; continue }
            if (-not [String]::IsNullOrWhiteSpace($value.Id)) { [String]$value.Id; continue }
        }
        elseif ($value -is [String]) {
            [String]$value
            continue
        }

        $pso = [System.Management.Automation.PSObject]::AsPSObject($item)
        $keyProperty = $pso.Properties['Key']
        $idProperty = $pso.Properties['Id']
        if ($keyProperty -and -not [String]::IsNullOrWhiteSpace([String]$keyProperty.Value)) {
            [String]$keyProperty.Value
            continue
        }
        if ($idProperty -and -not [String]::IsNullOrWhiteSpace([String]$idProperty.Value)) {
            [String]$idProperty.Value
            continue
        }

        $errorParameter = @{
            Exception    = [System.ArgumentException]::new('Each issue must be a non-empty string, an AtlassianPS.JiraPS.Issue, or an object with a Key or Id property.')
            ErrorId      = 'ParameterValue.InvalidBulkIssue'
            Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
            TargetObject = $item
        }
        Write-Debug "[$CallerName] Invalid bulk issue input type: $($item.GetType().FullName)"
        $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord $errorParameter.Exception, $errorParameter.ErrorId, $errorParameter.Category, $errorParameter.TargetObject))
    }

    $ids = [String[]]@($ids)
    foreach ($id in $ids) {
        if ([String]::IsNullOrWhiteSpace($id)) {
            throw [System.ArgumentException]::new('Issue IDs or keys must not be null, empty, or whitespace.', 'Issue')
        }
        if ($id.IndexOfAny([char[]]'*?[]') -ge 0) {
            throw [System.ArgumentException]::new("Wildcard issue selection is not supported for Jira bulk edits ('$id'). Pass explicit issue IDs or keys.", 'Issue')
        }
    }

    if ($ids.Count -eq 0) {
        throw [System.ArgumentException]::new('At least one issue ID or key is required.', 'Issue')
    }
    if ($ids.Count -gt [AtlassianPS.JiraPS.BulkOperationLimits]::MaxIssueCount) {
        throw [System.ArgumentOutOfRangeException]::new('Issue', $ids.Count, 'Bulk edit operations support at most 1,000 issues per request.')
    }

    $ids
}

function Test-JiraBulkCrossProjectSelection {
    [CmdletBinding()]
    param(
        [String[]]
        $IssueIdsOrKeys,

        [Switch]
        $AllowCrossProject,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet
    )

    if ($AllowCrossProject) { return }

    $projectKeys = @(
        foreach ($issueIdOrKey in @($IssueIdsOrKeys)) {
            if ($issueIdOrKey -match '^(?<Project>[A-Z][A-Z0-9_]+)-\d+$') {
                $Matches.Project
            }
        }
    ) | Sort-Object -Unique

    if ($projectKeys.Count -gt 1) {
        $errorParameter = @{
            Cmdlet       = $Cmdlet
            Exception    = [System.ArgumentException]::new("Bulk edit targets include multiple project keys ($($projectKeys -join ', ')). Pass -AllowCrossProject to submit an explicit cross-project bulk edit.")
            ErrorId      = 'ParameterValue.CrossProjectBulkEditRequiresOptIn'
            Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
            TargetObject = $IssueIdsOrKeys
        }
        ThrowError @errorParameter
    }
}

function ConvertTo-JiraBulkFieldHashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [PSObject]
        $Fields
    )

    if ($Fields -is [hashtable] -or $Fields -is [System.Collections.IDictionary]) {
        return , $Fields
    }

    ConvertTo-Hashtable -InputObject $Fields
}

function Get-JiraBulkEditableField {
    [CmdletBinding()]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [String[]]
        $IssueIdsOrKeys,

        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $result = Invoke-JiraMethod `
        -URI '/rest/api/3/bulk/issues/fields' `
        -Method GET `
        -GetParameter @{ issueIdsOrKeys = ($IssueIdsOrKeys -join ',') } `
        -Credential $Credential

    @($result.fields)
}

function Add-JiraBulkSelectedAction {
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Collections.Generic.List[String]]
        $List,

        [Parameter(Mandatory)]
        [String]
        $Action
    )

    if (-not $List.Contains($Action)) {
        $null = $List.Add($Action)
    }
}

function Merge-JiraBulkEditFieldsInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AtlassianPS.JiraPS.JiraBulkEditFieldsInput]
        $Target,

        [Parameter(Mandatory)]
        [AtlassianPS.JiraPS.JiraBulkEditFieldsInput]
        $Source
    )

    foreach ($property in [AtlassianPS.JiraPS.JiraBulkEditFieldsInput].GetProperties()) {
        $sourceValue = $property.GetValue($Source, $null)
        if ($null -ne $sourceValue) {
            $property.SetValue($Target, $sourceValue, $null)
        }
    }
}

function Add-JiraBulkFieldAssignment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AtlassianPS.JiraPS.JiraBulkEditFieldsInput]
        $FieldsInput,

        [Parameter(Mandatory)]
        [PSObject]
        $Assignment,

        [System.Management.Automation.PSCmdlet]
        $Cmdlet
    )

    $field = $Assignment.Field
    $fieldType = [String]$field.type
    $schemaType = [String]$field.Schema.type
    $value = $Assignment.Value

    if (Test-JiraRichTextField -Field $field) {
        if ($value -is [String]) {
            $value = Resolve-JiraTextFieldPayload -Text $value -IsCloud $true
        }
        $FieldsInput.RichTextFields += @(
            @{
                fieldId  = $Assignment.Id
                richText = $value
            }
        )
        return
    }

    if ($Assignment.Id -eq 'summary' -or $fieldType -in @('text', 'singleLineText', 'string') -or $schemaType -eq 'string') {
        $FieldsInput.SingleLineTextFields += @(
            @{
                fieldId = $Assignment.Id
                text    = [String]$value
            }
        )
        return
    }

    $errorParameter = @{
        Cmdlet       = $Cmdlet
        Exception    = [System.NotSupportedException]::new("Field '$($Assignment.InputName)' resolved to '$($Assignment.Id)', but Set-JiraIssueBulk cannot infer the Jira bulk edit field collection for type '$fieldType'. Build a typed AtlassianPS.JiraPS.JiraBulkEditFieldsInput and pass it with -EditedFieldsInput and -SelectedAction.")
        ErrorId      = 'ParameterValue.UnsupportedBulkEditField'
        Category     = [System.Management.Automation.ErrorCategory]::InvalidArgument
        TargetObject = $Assignment
    }
    ThrowError @errorParameter
}
