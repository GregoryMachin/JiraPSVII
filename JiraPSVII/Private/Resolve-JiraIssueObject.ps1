function Resolve-JiraIssueObject {
    [CmdletBinding()]
    [OutputType( [AtlassianPSVII.JiraPSVII.Issue] )]
    param(
        [Parameter( Mandatory, ValueFromPipeline )]
        [AtlassianPSVII.JiraPSVII.Issue]
        $InputObject,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        if ($InputObject.RestURL) {
            Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Using `$InputObject as object"
            return $InputObject
        }

        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] Resolve Issue '$($InputObject.Key)' to object"
        Get-JiraIssue -Key $InputObject.Key -Credential $Credential -ErrorAction Stop
    }
}
