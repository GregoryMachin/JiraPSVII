function ConvertTo-JiraSession {
    [CmdletBinding()]
    [OutputType([AtlassianPS.JiraPS.Session])]
    param(
        [Parameter( Mandatory )]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $Session,

        [String]
        $Username,

        [String]
        $DeploymentType,

        [String]
        $AuthenticationType,

        [String]
        $CloudId
    )

    process {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Building AtlassianPS.JiraPS.Session"

        $hash = @{
            WebSession = $Session
        }

        if ($Username) {
            $hash.Username = $Username
        }
        if ($DeploymentType) {
            $hash.DeploymentType = $DeploymentType
        }
        if ($AuthenticationType) {
            $hash.AuthenticationType = $AuthenticationType
        }
        if ($CloudId) {
            $hash.CloudId = $CloudId
        }

        [AtlassianPS.JiraPS.Session]$hash
    }
}
