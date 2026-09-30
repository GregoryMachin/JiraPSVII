function ConvertTo-JiraSession {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.Session])]
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
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Building AtlassianPSVII.JiraPSVII.Session"

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

        [AtlassianPSVII.JiraPSVII.Session]$hash
    }
}
