function New-JiraIssueLinkRequest {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions",
        "",
        Justification = "Builds and returns a local request DTO without side effects."
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Alias('Type')]
        [AtlassianPSVII.JiraPSVII.IssueLinkTypeTransformation()]
        [AtlassianPSVII.JiraPSVII.IssueLinkType]
        $LinkType,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Alias('InwardIssue')]
        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
        [AtlassianPSVII.JiraPSVII.Issue]
        $FromIssue,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [Alias('OutwardIssue')]
        [AtlassianPSVII.JiraPSVII.IssueTransformation()]
        [AtlassianPSVII.JiraPSVII.Issue]
        $ToIssue
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    process {
        $typeRef = [AtlassianPSVII.JiraPSVII.IssueLinkTypeRef]@{}
        if ($LinkType.Name) {
            $typeRef.Name = $LinkType.Name
        }
        if ($LinkType.Id) {
            $typeRef.Id = $LinkType.Id
        }

        if (-not $typeRef.Name -and -not $typeRef.Id) {
            ThrowError `
                -ExceptionType "System.ArgumentException" `
                -Message "The link type must include either a Name or an Id." `
                -ErrorId 'ParameterProperties.Incomplete' `
                -Category InvalidArgument `
                -TargetObject $LinkType `
                -Cmdlet $PSCmdlet
        }

        $inwardRef = [AtlassianPSVII.JiraPSVII.LinkedIssueRef]@{}
        if ($FromIssue.Key) {
            $inwardRef.Key = $FromIssue.Key
        }
        if ($FromIssue.Id) {
            $inwardRef.Id = $FromIssue.Id
        }
        if (-not $inwardRef.Key -and -not $inwardRef.Id) {
            ThrowError `
                -ExceptionType "System.ArgumentException" `
                -Message "The from issue must include either a Key or an Id." `
                -ErrorId 'ParameterProperties.Incomplete' `
                -Category InvalidArgument `
                -TargetObject $FromIssue `
                -Cmdlet $PSCmdlet
        }

        $outwardRef = [AtlassianPSVII.JiraPSVII.LinkedIssueRef]@{}
        if ($ToIssue.Key) {
            $outwardRef.Key = $ToIssue.Key
        }
        if ($ToIssue.Id) {
            $outwardRef.Id = $ToIssue.Id
        }
        if (-not $outwardRef.Key -and -not $outwardRef.Id) {
            ThrowError `
                -ExceptionType "System.ArgumentException" `
                -Message "The to issue must include either a Key or an Id." `
                -ErrorId 'ParameterProperties.Incomplete' `
                -Category InvalidArgument `
                -TargetObject $ToIssue `
                -Cmdlet $PSCmdlet
        }

        [AtlassianPSVII.JiraPSVII.IssueLinkCreateRequest]@{
            Type         = $typeRef
            InwardIssue  = $inwardRef
            OutwardIssue = $outwardRef
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
