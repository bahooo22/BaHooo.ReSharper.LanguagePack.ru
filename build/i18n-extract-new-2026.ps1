# Extract keys that exist in the 2026.2.2 neutral resources but are MISSING from the
# translated .ru-RU.resx (i.e. new strings to translate). Output grouped JSON.
#requires -Version 5
param(
    [string]$InstallDir = 'C:\Program Files (x86)\JetBrains\Installations\ReSharperPlatformVs18_e6a7a229',
    [string]$ResxFolder,
    [string]$OutJson
)

$ErrorActionPreference = 'Stop'
if (-not $ResxFolder) { $ResxFolder = Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU' }
if (-not $OutJson)    { $OutJson    = Join-Path $PSScriptRoot 'missing-2026.json' }

# 1. map: needed neutral resource name -> resx full path
$needed = @{}
Get-ChildItem -LiteralPath $ResxFolder -Filter '*.ru-RU.resx' -File | ForEach-Object {
    $needed[($_.BaseName -replace '\.ru-RU$', '') + '.resources'] = $_.FullName
}

# 2. load only needed neutral resources from DLLs; also remember source dll
$neutral = @{}   # resName -> hashtable key->en
$dllOf   = @{}   # resName -> dll file name
Get-ChildItem -LiteralPath $InstallDir -Filter *.dll -File | ForEach-Object {
    $dllName = $_.Name
    try {
        $asm = [System.Reflection.Assembly]::LoadFile($_.FullName)
        foreach ($rn in $asm.GetManifestResourceNames()) {
            if ($rn -like '*.resources' -and $rn -notlike '*.g.resources' -and $needed.ContainsKey($rn) -and -not $neutral.ContainsKey($rn)) {
                $stream = $asm.GetManifestResourceStream($rn)
                if (-not $stream) { continue }
                try {
                    $rd = New-Object System.Resources.ResourceReader($stream)
                    $dict = @{}
                    foreach ($e in $rd) { if ($e.Value -is [string]) { $dict[$e.Key] = $e.Value } }
                    $rd.Close()
                    if ($dict.Count -gt 0) { $neutral[$rn] = $dict; $dllOf[$rn] = $dllName }
                } finally { $stream.Close() }
            }
        }
    } catch { }
}
Write-Host (" neutral-ресурсов прочитано: {0} из {1} нужных" -f $neutral.Count, $needed.Count)

# 3. per resx: existing keys, diff
$result = @()
$totalMissing = 0
foreach ($rn in ($neutral.Keys | Sort-Object)) {
    $resxPath = $needed[$rn]
    $xml = New-Object System.Xml.XmlDocument
    $xml.Load($resxPath)
    $have = @{}
    foreach ($d in $xml.SelectNodes('//root/data')) { $have[$d.name] = $true }

    $en = $neutral[$rn]
    $missing = @($en.Keys | Where-Object { -not $have.ContainsKey($_) } | Sort-Object)
    if ($missing.Count -eq 0) { continue }
    $entries = @($missing | ForEach-Object {
        [pscustomobject]@{ Key = $_; En = $en[$_] }
    })
    $totalMissing += $missing.Count
    $result += [pscustomobject]@{
        Resource = $rn
        Dll      = $dllOf[$rn]
        ResxFile = (Split-Path -Leaf $resxPath)
        Count    = $missing.Count
        Entries  = $entries
    }
}

$json = ConvertTo-Json -InputObject $result -Depth 5
[System.IO.File]::WriteAllText($OutJson, $json, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "OK: $OutJson"
Write-Host (" таблиц с новыми ключами: {0}, всего новых строк: {1}" -f $result.Count, $totalMissing)
foreach ($r in ($result | Sort-Object Count -Descending)) {
    Write-Host ("  {0,-4} {1}" -f $r.Count, $r.ResxFile)
}
