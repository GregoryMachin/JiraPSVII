function Get-JiraProject {
    # .ExternalHelp ..\JiraPSVII-help.xml
    [CmdletBinding( SupportsPaging, DefaultParameterSetName = '_All' )]
    param(
        [Parameter( Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = '_Search' )]
        [String[]]
        $Project,

        [Parameter( ParameterSetName = '_All' )]
        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]
        $PageSize = $script:DefaultPageSize,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $collectionResourceUri = "/rest/api/2/project"
        $lookupResourceUri = "/rest/api/2/project/{0}"
        $projectExpand = "description,lead,issueTypes,url,projectKeys"
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PSCmdlet.ParameterSetName) {
            '_All' {
                $isCloud = Test-JiraCloudServer -Credential $Credential
                if ($isCloud) {
                    $collectionResourceUri = "/rest/api/3/project/search"
                }

                $parameter = @{
                    URI          = $collectionResourceUri
                    Method       = "GET"
                    GetParameter = @{
                        expand     = $projectExpand
                        maxResults = $PageSize
                    }
                    Paging       = $isCloud
                    Credential   = $Credential
                }

                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $parameter[$_] = $PSCmdlet.PagingParameters.$_
                }
                Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                $result = Invoke-JiraMethod @parameter

                Write-Output (ConvertTo-JiraProject -InputObject $result)
            }
            '_Search' {
                foreach ($_project in $Project) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] Processing [$_project]"
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing `$_project [$_project]"

                    $parameter = @{
                        URI          = $lookupResourceUri -f $_project
                        Method       = "GET"
                        GetParameter = @{
                            expand = $projectExpand
                        }
                        Credential   = $Credential
                    }
                    Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"
                    $result = Invoke-JiraMethod @parameter

                    Write-Output (ConvertTo-JiraProject -InputObject $result)
                }
            }
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
