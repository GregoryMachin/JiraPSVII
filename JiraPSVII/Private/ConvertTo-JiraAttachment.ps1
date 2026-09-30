function ConvertTo-JiraAttachment {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Attachment])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            if ($i -is [AtlassianPSVII.JiraPSVII.Attachment]) {
                $i
                continue
            }

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.Attachment"

            $author = if ($i.Author) {
                ConvertTo-JiraUser -InputObject $i.Author
            }
            else {
                $null
            }

            $props = @{
                'ID'        = $i.id
                'Self'      = [uri]$i.self
                'FileName'  = $i.FileName
                'Author'    = $author
                'Created'   = ConvertTo-JiraDateTimeOffsetValue $i.created
                'Size'      = ConvertTo-JiraNullableInt64 $i.size
                'MimeType'  = $i.mimeType
                'Content'   = [uri]$i.content
                'Thumbnail' = [uri]$i.thumbnail
            }

            if ($i.properties) {
                $attachmentProperties = @{}
                foreach ($property in $i.properties.PSObject.Properties) {
                    $attachmentProperties[$property.Name] = $property.Value
                }
                $props.Properties = $attachmentProperties
            }

            [AtlassianPSVII.JiraPSVII.Attachment]$props
        }
    }
}
