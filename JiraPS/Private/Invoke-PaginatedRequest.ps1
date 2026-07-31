function Invoke-PaginatedRequest {
    [CmdletBinding(SupportsPaging)]
    param(
        [Parameter( Mandatory )]
        [Uri]
        $URI,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = "GET",

        [String]
        $Body,

        [Switch]
        $RawBody,

        [Hashtable]
        $Headers = @{},

        [Hashtable]
        $GetParameter = @{},

        [Switch]
        $Paging,

        [String]
        $InFile,

        [String]
        $OutFile,

        [Switch]
        $StoreSession,

        [ValidateSet(
            "JiraComment",
            "JiraIssue",
            "JiraUser",
            "JiraVersion",
            "JiraWorklogItem"
        )]
        [String]
        $OutputType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter( Mandatory )]
        [PSCustomObject]
        $Response,

        [String[]]
        $ItemPropertyName = $script:PagingContainers,

        [String]
        $TokenPropertyName = 'nextPageToken',

        [String]
        $TokenParameterName = 'nextPageToken',

        [String]
        $CompletionPropertyName = 'isLast',

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    process {
        $null = $PSBoundParameters.Remove("Paging")
        $null = $PSBoundParameters.Remove("Skip")
        $null = $PSBoundParameters.Remove("Response")
        $null = $PSBoundParameters.Remove("ItemPropertyName")
        $null = $PSBoundParameters.Remove("TokenPropertyName")
        $null = $PSBoundParameters.Remove("TokenParameterName")
        $null = $PSBoundParameters.Remove("CompletionPropertyName")

        if (-not $PSBoundParameters["GetParameter"]) {
            $PSBoundParameters["GetParameter"] = $GetParameter
        }

        $first = $PSCmdlet.PagingParameters.First
        $skipRemaining = [int]$PSCmdlet.PagingParameters.Skip
        $total = 0
        $outputCount = 0
        $offset = 0
        if ($PSCmdlet.PagingParameters.Skip) {
            $offset = $PSCmdlet.PagingParameters.Skip
        }

        $seenTokens = @{}
        $usingTokenPagination = $false

        do {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Invoking pagination [currentTotal: $total]"
            $result = Expand-Result -InputObject $Response -Container $ItemPropertyName
            $rawResultCount = @($result).Count
            $responsePropertyNames = $Response.PSObject.Properties.Name
            if ($responsePropertyNames -contains $TokenPropertyName) {
                $usingTokenPagination = $true
            }
            $isTokenPagedResponse = $usingTokenPagination

            $total += $rawResultCount
            $pageSize = $script:DefaultPageSize
            if (-not [string]::IsNullOrEmpty($Response.maxResults)) {
                $pageSize = $Response.maxResults
            }

            if ($isTokenPagedResponse -and $skipRemaining -gt 0) {
                if ($rawResultCount -le $skipRemaining) {
                    $skipRemaining -= $rawResultCount
                    $result = @()
                }
                else {
                    $result = $result | Select-Object -Skip $skipRemaining
                    $skipRemaining = 0
                }
            }

            if (($outputCount + @($result).Count) -gt $first) {
                $remaining = [Math]::Max(0, $first - $outputCount)
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Only output the first $remaining item(s) of page"
                $result = $result | Select-Object -First $remaining
            }

            Convert-Result -InputObject $result -OutputType $OutputType
            $outputCount += @($result).Count

            if ($responsePropertyNames -contains $CompletionPropertyName -and $Response.$CompletionPropertyName -eq $true) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as completion property is true"
                break
            }

            if ($outputCount -ge $first) {
                Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as $outputCount reached $first"
                break
            }

            if ($responsePropertyNames -contains $TokenPropertyName -and $Response.$TokenPropertyName) {
                $nextToken = [string]$Response.$TokenPropertyName
                if ($seenTokens.ContainsKey($nextToken)) {
                    Write-Warning "[$($MyInvocation.MyCommand.Name)] Repeated pagination token received; stopping pagination with $total results collected"
                    break
                }

                [Uri]$nextTokenUri = $null
                if ([Uri]::TryCreate($nextToken, [UriKind]::Absolute, [ref]$nextTokenUri)) {
                    [Uri]$currentUri = $URI
                    if ($nextTokenUri.Scheme -ne $currentUri.Scheme -or $nextTokenUri.Host -ne $currentUri.Host) {
                        throw "Refusing to follow Jira pagination token or link to an untrusted host."
                    }
                }

                $seenTokens[$nextToken] = $true
                $PSBoundParameters["GetParameter"][$TokenParameterName] = $nextToken
            }
            else {
                if ($isTokenPagedResponse) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] No pagination token found; stopping pagination"
                    break
                }

                if ($rawResultCount -lt $pageSize) {
                    Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Stopping paging, as page had less entries than $pageSize"
                    break
                }

                $PSBoundParameters["GetParameter"]["startAt"] = $total + $offset
                $expectedTotal = $PSBoundParameters["GetParameter"]["startAt"] + $pageSize
                if ($expectedTotal -gt $PSCmdlet.PagingParameters.First) {
                    $reduceBy = $expectedTotal - $PSCmdlet.PagingParameters.First
                    $PSBoundParameters["GetParameter"]["maxResults"] = $pageSize - $reduceBy
                }
            }

            $Response = Invoke-JiraMethod @PSBoundParameters

            if ($null -eq $Response) {
                Write-Warning "[$($MyInvocation.MyCommand.Name)] Received null response during pagination (possible auth failure or server error); stopping pagination with $total results collected"
                break
            }

            if (-not $isTokenPagedResponse) {
                $result = Expand-Result -InputObject $Response -Container $ItemPropertyName
                if (@($result).Count -eq 0) {
                    break
                }
            }

        } while ($null -ne $Response)

        if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
            [double]$Accuracy = 1.0
            $PSCmdlet.PagingParameters.NewTotalCount($total, $Accuracy)
        }
    }
}
