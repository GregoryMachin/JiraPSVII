function Get-JiraJqlApproximateCount {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.JqlApproximateCountResult])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Jql')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Query,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        if (-not (Test-JiraCloudServer -Credential $Credential)) {
            throw [System.PlatformNotSupportedException]::new('Approximate JQL counts are supported only on Jira Cloud.')
        }

        $resourceUri = '/rest/api/3/search/approximate-count'
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"

        foreach ($_query in $Query) {
            $validationResult = Test-JiraJql -Query $_query -Validation Strict -Credential $Credential
            if (-not $validationResult.IsValid) {
                Write-Output ([AtlassianPS.JiraPS.JqlApproximateCountResult]@{
                        Query   = $_query
                        IsValid = $false
                        Errors  = $validationResult.Errors
                    })
                continue
            }

            $parameter = @{
                URI        = $resourceUri
                Method     = 'Post'
                Body       = ConvertTo-Json -InputObject @{ jql = $_query }
                Credential = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with a redacted request body"
            $response = Invoke-JiraMethod @parameter

            Write-Output ([AtlassianPS.JiraPS.JqlApproximateCountResult]@{
                    Query            = $_query
                    Count            = [Int64]$response.count
                    IsValid          = $true
                    IsApproximate    = $true
                    PermissionScoped = $true
                    Errors           = [String[]]@()
                })
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
