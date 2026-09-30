function ConvertTo-JiraProjectClassificationLevel {
    [CmdletBinding()]
    [OutputType([AtlassianPSVII.JiraPSVII.ProjectClassificationLevel])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject
    )

    process {
        foreach ($configuration in $InputObject) {
            if ($null -eq $configuration) { continue }

            $defaultId = if ($configuration.defaultClassificationLevel) { [String]$configuration.defaultClassificationLevel.id } else { $null }
            $organizationDefaultId = if ($configuration.organizationClassificationLevel) { [String]$configuration.organizationClassificationLevel.id } else { $null }
            foreach ($level in @($configuration.classificationLevels)) {
                if ($null -eq $level) { continue }

                [AtlassianPSVII.JiraPSVII.ProjectClassificationLevel]@{
                    Id                    = [String]$level.id
                    Status                = [String]$level.status
                    Name                  = [String]$level.name
                    Rank                  = if ($null -ne $level.rank) { [Convert]::ToInt32($level.rank) } else { $null }
                    Description           = [String]$level.description
                    Guideline             = [String]$level.guideline
                    Color                 = [String]$level.color
                    IsDefault             = if ($defaultId) { [String]$level.id -eq $defaultId } else { $null }
                    IsOrganizationDefault = if ($organizationDefaultId) { [String]$level.id -eq $organizationDefaultId } else { $null }
                    ContainerOverride     = [String]$configuration.containerOverride
                }
            }
        }
    }
}
