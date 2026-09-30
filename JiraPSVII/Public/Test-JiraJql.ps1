function Test-JiraJql {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.JqlValidationResult])]
    param(
        [Parameter(Position = 0, Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Jql')]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Query,

        [Parameter()]
        [ValidateSet('Strict', 'Warn', 'None')]
        [String]
        $Validation = 'Strict',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        if (-not (Test-JiraCloudServer -Credential $Credential)) {
            throw [System.PlatformNotSupportedException]::new('JQL parsing through Test-JiraJql is supported only on Jira Cloud.')
        }

        $resourceUri = '/rest/api/3/jql/parse'
        $queries = [System.Collections.Generic.List[string]]::new()
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Bound parameter names: $($PSBoundParameters.Keys -join ', ')"
        foreach ($_query in $Query) {
            $queries.Add($_query)
        }
    }

    end {
        if ($queries.Count -gt 0) {
            $parameter = @{
                URI          = $resourceUri
                Method       = 'Post'
                GetParameter = @{ validation = $Validation.ToLowerInvariant() }
                Body         = ConvertTo-Json -InputObject @{ queries = $queries.ToArray() } -Depth 10
                Credential   = $Credential
            }
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with a redacted request body"
            $response = Invoke-JiraMethod @parameter
            $parsedQueries = @($response.queries)

            for ($index = 0; $index -lt $queries.Count; $index++) {
                $parsed = if ($index -lt $parsedQueries.Count) { $parsedQueries[$index] } else { $null }
                $errors = if ($parsed) { @($parsed.errors | Where-Object { $_ }) } else { @('Jira did not return a validation result for this query.') }

                [AtlassianPSVII.JiraPSVII.JqlValidationResult]@{
                    Query           = $queries[$index]
                    NormalizedQuery = if ($parsed) { $parsed.query } else { $null }
                    IsValid         = ($errors.Count -eq 0)
                    Errors          = [String[]]$errors
                    Structure       = if ($parsed) { $parsed.structure } else { $null }
                }
            }
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
