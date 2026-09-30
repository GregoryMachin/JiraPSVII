function ConvertTo-JiraEntityProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object[]]
        $InputObject
    )

    process {
        foreach ($item in $InputObject) {
            if ($null -eq $item) { continue }
            $key = if ($item -is [String]) { $item } else { [String]$item.key }
            if ([String]::IsNullOrWhiteSpace($key)) { continue }

            $result = [PSCustomObject]@{
                Key   = $key
                Value = if ($item -is [String]) { $null } else { ConvertTo-JiraSafePropertyValue -Value $item.value -Path 'value' -AllowNull }
            }
            $result.PSObject.TypeNames.Insert(0, 'AtlassianPSVII.JiraPSVII.EntityProperty')
            Write-Output $result
        }
    }
}

function ConvertTo-JiraPropertyJson {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [Object]
        $Value
    )

    if ($null -eq $Value) {
        throw [System.ArgumentException]::new('Property values must be a non-null JSON primitive, object, or array.', 'Value')
    }

    $safeValue = ConvertTo-JiraSafePropertyValue -Value $Value -Path 'Value'
    $json = ConvertTo-Json -InputObject $safeValue -Depth 20 -Compress
    if ([Text.Encoding]::UTF8.GetByteCount($json) -gt 32768) {
        throw [System.ArgumentOutOfRangeException]::new('Value', 'Property values must not exceed 32,768 UTF-8 bytes when serialized as JSON.')
    }
    $json
}

function ConvertTo-JiraSafePropertyValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [Object]
        $Value,

        [Parameter(Mandatory)]
        [String]
        $Path,

        [Switch]
        $AllowNull
    )

    if ($null -eq $Value) {
        if ($AllowNull) { return $null }
        throw [System.ArgumentException]::new("Property value '$Path' must not be null.", 'Value')
    }
    if ($Value -is [ScriptBlock] -or $Value -is [System.Management.Automation.PSCredential] -or $Value -is [Security.SecureString]) {
        throw [System.ArgumentException]::new("Property value '$Path' must not contain credentials, secure strings, or script blocks.", 'Value')
    }
    if ($Value -is [String] -or $Value -is [ValueType]) { return $Value }

    if ($Value -is [Collections.IDictionary]) {
        $safe = [ordered]@{}
        foreach ($entry in $Value.GetEnumerator()) {
            $key = [String]$entry.Key
            Test-JiraEntityPropertyDataKey -Key $key -Path $Path
            $safe[$key] = ConvertTo-JiraSafePropertyValue -Value $entry.Value -Path "$Path.$key" -AllowNull
        }
        return $safe
    }
    if ($Value -is [Collections.IEnumerable]) {
        $safe = [Collections.Generic.List[Object]]::new()
        $index = 0
        foreach ($entry in $Value) {
            $safe.Add((ConvertTo-JiraSafePropertyValue -Value $entry -Path "$Path[$index]" -AllowNull))
            $index++
        }
        return @($safe)
    }

    $safe = [ordered]@{}
    foreach ($property in $Value.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' })) {
        Test-JiraEntityPropertyDataKey -Key $property.Name -Path $Path
        $safe[$property.Name] = ConvertTo-JiraSafePropertyValue -Value $property.Value -Path "$Path.$($property.Name)" -AllowNull
    }
    if ($safe.Count -eq 0) {
        throw [System.ArgumentException]::new("Property value '$Path' must be JSON-serializable data.", 'Value')
    }
    $safe
}

function Test-JiraEntityPropertyKey {
    [CmdletBinding()]
    param([Parameter(Mandatory)][String]$Key)

    if ($Key -notmatch '^[A-Za-z0-9][A-Za-z0-9._:-]{0,254}$') {
        throw [System.ArgumentException]::new('Property keys must be 1-255 characters and contain only letters, digits, dots, underscores, colons, or hyphens.', 'PropertyKey')
    }
    Test-JiraEntityPropertyDataKey -Key $Key -Path 'PropertyKey'
}

function Test-JiraEntityPropertyDataKey {
    [CmdletBinding()]
    param([Parameter(Mandatory)][String]$Key, [Parameter(Mandatory)][String]$Path)

    if ($Key -in @('__proto__', 'prototype', 'constructor')) {
        throw [System.ArgumentException]::new("Property data key '$Path.$Key' is not allowed.", 'Value')
    }
    if ($Key -match '(?i)(password|secret|token|credential|authorization|private.?key|api.?key)') {
        throw [System.ArgumentException]::new("Property data key '$Path.$Key' appears to contain a secret and is not allowed.", 'Value')
    }
}
