function Get-JiraIssueAttachmentFile {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    [OutputType([Bool])]
    param (
        [Parameter( Mandatory, ValueFromPipeline )]
        [AtlassianPS.JiraPS.Attachment[]]
        [ValidateScript(
            {
                foreach ($item in @($_)) {
                    if (($null -eq $item) -or [string]::IsNullOrWhiteSpace($item.FileName) -or ($null -eq $item.Content)) {
                        $errorItem = [System.Management.Automation.ErrorRecord]::new(
                            ([System.ArgumentException]"Invalid 'Attachment' value"),
                            'ParameterValue.InvalidJiraAttachment',
                            [System.Management.Automation.ErrorCategory]::InvalidArgument,
                            $item
                        )
                        $errorItem.ErrorDetails = "Attachment values must be [AtlassianPS.JiraPS.Attachment] objects with FileName and Content populated."
                        $PSCmdlet.ThrowTerminatingError($errorItem)
                    }
                }

                return $true
            }
        )]
        $Attachment,

        [ValidateScript(
            {
                if (-not (Test-Path -LiteralPath $_ -PathType Container)) {
                    $errorItem = [System.Management.Automation.ErrorRecord]::new(
                        ([System.ArgumentException]"Path not found"),
                        'ParameterValue.FileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $_
                    )
                    $errorItem.ErrorDetails = "Invalid path '$_'."
                    $PSCmdlet.ThrowTerminatingError($errorItem)
                }
                else {
                    return $true
                }
            }
        )]
        [String]
        $Path,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        [Uri]$jiraServerUri = Get-JiraConfigServer -ErrorAction Stop
    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        foreach ($_Attachment in $Attachment) {
            $attachmentFileName = [string]$_Attachment.Filename
            if (
                [string]::IsNullOrWhiteSpace($attachmentFileName) -or
                $attachmentFileName -in @('.', '..') -or
                $attachmentFileName.IndexOfAny([char[]]@('/', '\')) -ge 0 -or
                [System.IO.Path]::IsPathRooted($attachmentFileName)
            ) {
                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.ArgumentException]"Unsafe attachment filename"),
                    'AttachmentFileName.InvalidPath',
                    [System.Management.Automation.ErrorCategory]::InvalidData,
                    $_Attachment
                )
                $errorItem.ErrorDetails = "Attachment filename [$attachmentFileName] must be a single file name without path components."
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }

            [Uri]$attachmentContentUri = $_Attachment.Content
            if (
                $attachmentContentUri.Scheme -notin @('http', 'https') -or
                $attachmentContentUri.Scheme -ne $jiraServerUri.Scheme -or
                $attachmentContentUri.Host -ne $jiraServerUri.Host -or
                $attachmentContentUri.Port -ne $jiraServerUri.Port
            ) {
                $errorItem = [System.Management.Automation.ErrorRecord]::new(
                    ([System.Security.SecurityException]"Untrusted attachment content URI"),
                    'AttachmentContentUri.UntrustedHost',
                    [System.Management.Automation.ErrorCategory]::SecurityError,
                    $attachmentContentUri
                )
                $errorItem.ErrorDetails = "Attachment content URI must use the configured Jira server origin."
                $PSCmdlet.ThrowTerminatingError($errorItem)
            }

            if ($Path) {
                $filename = Join-Path $Path $attachmentFileName
            }
            else {
                $filename = $attachmentFileName
            }

            $iwParameters = @{
                Uri        = $attachmentContentUri
                Method     = 'Get'
                OutFile    = $filename
                Credential = $Credential
            }

            $null = Invoke-JiraMethod @iwParameters
            Test-Path -LiteralPath $filename
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
