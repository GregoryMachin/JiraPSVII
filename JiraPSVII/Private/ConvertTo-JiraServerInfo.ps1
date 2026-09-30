function ConvertTo-JiraServerInfo {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.ServerInfo])]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        foreach ($i in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to AtlassianPSVII.JiraPSVII.ServerInfo"

            $hash = @{
                BaseURL                         = [uri]$i.baseUrl
                Version                         = $i.version
                DeploymentType                  = if ($i.deploymentType) { $i.deploymentType } else { 'Server' }
                BuildNumber                     = $i.buildNumber
                BuildDate                       = ConvertTo-JiraDateTimeOffsetValue $i.buildDate
                ServerTime                      = ConvertTo-JiraDateTimeOffsetValue $i.serverTime
                ScmInfo                         = $i.scmInfo
                ServerTitle                     = $i.serverTitle
                DisplayUrl                      = [uri]$i.displayUrl
                DisplayUrlConfluence            = [uri]$i.displayUrlConfluence
                DisplayUrlServicedeskHelpCenter = [uri]$i.displayUrlServicedeskHelpCenter
                BuildPartnerName                = $i.buildPartnerName
                ServerTimeZone                  = $i.serverTimeZone
                DefaultLocale                   = $i.defaultLocale
            }

            if ($i.versionNumbers) {
                $hash.VersionNumbers = [int[]]@($i.versionNumbers)
            }

            [AtlassianPSVII.JiraPSVII.ServerInfo]$hash
        }
    }
}
