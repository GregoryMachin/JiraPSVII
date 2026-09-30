function ConvertTo-JiraSubmittedBulkOperation {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.SubmittedBulkOperation])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            if ($null -eq $item) { continue }

            [AtlassianPSVII.JiraPSVII.SubmittedBulkOperation]@{
                TaskId = [String]$item.taskId
            }
        }
    }
}
