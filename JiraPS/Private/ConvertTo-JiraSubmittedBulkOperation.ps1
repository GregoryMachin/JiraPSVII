function ConvertTo-JiraSubmittedBulkOperation {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.SubmittedBulkOperation])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            if ($null -eq $item) { continue }

            [AtlassianPS.JiraPS.SubmittedBulkOperation]@{
                TaskId = [String]$item.taskId
            }
        }
    }
}
