#requires -Module PowerShellGet

[CmdletBinding()]
param(
    [Parameter(DontShow = $true)]
    [ValidateSet('Desktop', 'Core')]
    [String]$RuntimePSEdition = $PSVersionTable.PSEdition,

    [Parameter(DontShow = $true)]
    [Switch]$ForceDesktopBootstrapRemediation
)

$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).ProviderPath
$buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
$manifestPath = Join-Path -Path $projectRoot -ChildPath 'JiraPSVII/JiraPSVII.psd1'

# A sibling, git-ignored ".local-modules" directory (outside every repo, never committed)
# holds AtlassianPSVII.Standards builds that have not been published to the real PowerShell
# Gallery -- consumed directly per the project's own direction, without ever installing
# into (or colliding with) the machine's real, shared module path. Prepending it here is
# scoped to this process only; it is never written to $PROFILE or a persistent
# environment variable.
$localModulesPath = Join-Path -Path (Split-Path -Path $projectRoot -Parent) -ChildPath '.local-modules'
if ((Test-Path -LiteralPath $localModulesPath -PathType Container) -and ($env:PSModulePath -notlike "*$localModulesPath*")) {
    $env:PSModulePath = "$localModulesPath;$env:PSModulePath"
}

$buildRequirements = Import-PowerShellDataFile -Path $buildRequirementsPath
$standardsRequirement = $buildRequirements |
    Where-Object { $_.ModuleName -eq 'AtlassianPSVII.Standards' } |
    Select-Object -First 1

if (-not $standardsRequirement -or -not $standardsRequirement.RequiredVersion) {
    throw "Could not resolve AtlassianPSVII.Standards required version from '$buildRequirementsPath'."
}

$standardsVersion = [string] $standardsRequirement.RequiredVersion
$isWindowsPowerShell = $RuntimePSEdition -eq 'Desktop'
if ($isWindowsPowerShell) {
    $nuGetProvider = Get-PackageProvider -Name 'NuGet' -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    $requiresNuGetBootstrap = (
        $ForceDesktopBootstrapRemediation -or
        (-not $nuGetProvider -or $nuGetProvider.Version -lt [Version] '2.8.5.201')
    )

    if ($requiresNuGetBootstrap) {
        Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -Scope CurrentUser -Force -ErrorAction Stop
    }

}

$psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
if (-not $psGalleryRepository) {
    try {
        Register-PSRepository -Default -ErrorAction Stop
    }
    catch {
        throw "PSGallery repository is unavailable. Register PSGallery or configure repository access, then rerun '$($MyInvocation.MyCommand.Path)'."
    }

    $psGalleryRepository = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
}

if (-not $psGalleryRepository) {
    throw "PSGallery repository is unavailable. Register PSGallery or configure repository access, then rerun '$($MyInvocation.MyCommand.Path)'."
}

if ($isWindowsPowerShell -and ($ForceDesktopBootstrapRemediation -or $psGalleryRepository.InstallationPolicy -ne 'Trusted')) {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop
}

# Skip the network install when the exact pinned version is already available locally
# (for example a locally built, not-yet-published AtlassianPSVII.Standards release installed
# directly into a module path) -- matching the idempotency Install-AtlassianPSVIIDependencyRequirement
# already applies to every other dependency, rather than unconditionally forcing a Gallery
# fetch that would fail outright for a version PSGallery does not have yet.
$existingStandards = Get-Module -Name 'AtlassianPSVII.Standards' -ListAvailable |
    Where-Object { $_.Version.ToString() -eq $standardsVersion } |
    Select-Object -First 1

if (-not $existingStandards) {
    Install-Module -Name 'AtlassianPSVII.Standards' `
        -RequiredVersion $standardsVersion `
        -Scope CurrentUser `
        -Repository 'PSGallery' `
        -AllowClobber `
        -Force `
        -ErrorAction Stop
}

Import-Module -Name 'AtlassianPSVII.Standards' -RequiredVersion $standardsVersion -Force -ErrorAction Stop

$null = Install-AtlassianPSVIIDependencyRequirement `
    -BuildRequirementsPath $buildRequirementsPath `
    -ManifestPath $manifestPath `
    -ErrorAction Stop
