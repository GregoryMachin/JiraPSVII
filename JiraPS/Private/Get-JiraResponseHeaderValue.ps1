function Get-JiraResponseHeaderValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $Headers,

        [Parameter(Mandatory)]
        [String[]]
        $Name
    )

    if (-not $Headers) { return $null }

    foreach ($candidateName in $Name) {
        foreach ($key in @($Headers.Keys)) {
            if ($key -eq $candidateName) {
                $value = $Headers[$key]
                if ($value -is [System.Collections.IEnumerable] -and $value -isnot [String]) {
                    $value = ($value | ForEach-Object { [String]$_ }) -join ', '
                }

                return ([String]$value -replace '[\r\n]+', ' ').Trim()
            }
        }
    }

    $null
}
