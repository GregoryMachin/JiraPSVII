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

# The fork's AtlassianPSVII.Standards is not on the PowerShell Gallery, and CI runners have no
# .local-modules folder: fetch the pinned version from its GitHub release (backlog PSVII-11),
# verify it against the SHA-256 below, and unpack it there. The requirements file is parsed
# (not Import-PowerShellDataFile, which returns only its first entry).
# When bumping the Standards pin in build.requirements.psd1, add the new release's SHA-256 (from
# its SHA256SUMS asset) here; an unlisted version falls back to Install-Module from the Gallery.
$standardsReleaseSha256 = @{
    '1.0.0' = 'b91646f8d6f52aae517e95496a36f3b69d1f45f52c1b6b17b90b6c536f78839c'
}
$requirementsAst = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'), [ref]$null, [ref]$null)
$standardsPin = $requirementsAst.EndBlock.Statements[0].PipelineElements[0].Expression.SafeGetValue() |
    Where-Object { $_.ModuleName -eq 'AtlassianPSVII.Standards' } |
    Select-Object -First 1
if ($standardsPin -and $standardsReleaseSha256.ContainsKey([String]$standardsPin.RequiredVersion)) {
    $expectedSha256 = $standardsReleaseSha256[[String]$standardsPin.RequiredVersion]
    $standardsTarget = Join-Path -Path $localModulesPath -ChildPath "AtlassianPSVII.Standards/$($standardsPin.RequiredVersion)"
    if (-not (Test-Path -LiteralPath (Join-Path -Path $standardsTarget -ChildPath 'AtlassianPSVII.Standards.psd1'))) {
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        }
        $releaseUri = 'https://github.com/GregoryMachin/AtlassianPSVII.Standards/releases/download/v{0}/AtlassianPSVII.Standards.zip' -f $standardsPin.RequiredVersion
        $downloadPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
        $null = New-Item -Path $downloadPath -ItemType Directory -Force
        try {
            $zipPath = Join-Path -Path $downloadPath -ChildPath 'AtlassianPSVII.Standards.zip'
            Invoke-WebRequest -Uri $releaseUri -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
            $actualHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
            if ($actualHash -ne $expectedSha256) {
                throw "AtlassianPSVII.Standards $($standardsPin.RequiredVersion) from '$releaseUri' has SHA-256 $actualHash, expected $expectedSha256."
            }
            Expand-Archive -LiteralPath $zipPath -DestinationPath $downloadPath -Force
            $null = New-Item -Path $standardsTarget -ItemType Directory -Force
            Copy-Item -Path (Join-Path -Path $downloadPath -ChildPath 'AtlassianPSVII.Standards/*') -Destination $standardsTarget -Recurse -Force
        }
        finally {
            Remove-Item -LiteralPath $downloadPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if ((Test-Path -LiteralPath $localModulesPath -PathType Container) -and ($env:PSModulePath -notlike "*$localModulesPath*")) {
    $env:PSModulePath = '{0}{1}{2}' -f $localModulesPath, [System.IO.Path]::PathSeparator, $env:PSModulePath
    # Later GitHub Actions steps run in new processes: hand the module path on to them.
    if ($env:GITHUB_ENV) {
        Add-Content -LiteralPath $env:GITHUB_ENV -Value "PSModulePath=$env:PSModulePath"
    }
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
