# Add new key/value entries to EXISTING .ru-RU.resx files from a merged translations
# JSON: array of { File, Key, En, Ru }. Text-insert before </root> (existing bytes
# untouched), XML-escape the value, validate placeholders/CJK/empty, then round-trip.
#requires -Version 5
param(
    [string]$TransJson,
    [string]$ResxFolder,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
if (-not $TransJson)  { $TransJson  = Join-Path $PSScriptRoot 'new-translations-2026.json' }
if (-not $ResxFolder) { $ResxFolder = Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU' }

$cjk = -join ('[' , [char]0x3000 , '-' , [char]0x303F , [char]0x3040 , '-' , [char]0x30FF , [char]0x3400 , '-' , [char]0x4DBF , [char]0x4E00 , '-' , [char]0x9FFF , [char]0xF900 , '-' , [char]0xFAFF , [char]0xFF00 , '-' , [char]0xFFEF , ']')

function Get-Indices {
    param([string]$Text)
    [regex]::Matches($Text, '\{(\d+)[,\}]') | ForEach-Object { $_.Groups[1].Value } | Sort-Object
}
function ConvertTo-XmlText {
    param([string]$S)
    $S.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

$entries = Get-Content -LiteralPath $TransJson -Raw | ConvertFrom-Json

$byFile = @{}
foreach ($e in $entries) {
    if (-not $byFile.ContainsKey($e.File)) { $byFile[$e.File] = @() }
    $byFile[$e.File] += $e
}

$addedTotal = 0; $skipExisting = 0; $errors = 0
foreach ($file in ($byFile.Keys | Sort-Object)) {
    $path = Join-Path $ResxFolder $file
    if (-not (Test-Path -LiteralPath $path)) { Write-Host "NO FILE: $file" -ForegroundColor Red; $errors++; continue }
    $text = [System.IO.File]::ReadAllText($path)

    $existing = @{}
    foreach ($m in [regex]::Matches($text, '<data\s+name="([^"]+)"')) { $existing[$m.Groups[1].Value] = $true }

    $sb = New-Object System.Text.StringBuilder
    $cnt = 0
    foreach ($e in $byFile[$file]) {
        if ($existing.ContainsKey($e.Key)) { $skipExisting++; continue }
        $enIdx = @(Get-Indices $e.En)
        $ruIdx = @(Get-Indices ([string]$e.Ru))
        $bad = @($ruIdx | Where-Object { $enIdx -notcontains $_ })
        if ($bad.Count -gt 0) {
            Write-Host ("PLACEHOLDER: {0} [{1}] ru has {{{2}}} not in en" -f $file, $e.Key, ($bad -join ',')) -ForegroundColor Red
            $errors++; continue
        }
        if ($e.Ru -match $cjk) { Write-Host ("CJK: {0} [{1}]" -f $file, $e.Key) -ForegroundColor Red; $errors++; continue }
        if ([string]::IsNullOrWhiteSpace($e.Ru)) { Write-Host ("EMPTY: {0} [{1}]" -f $file, $e.Key) -ForegroundColor Red; $errors++; continue }
        $escKey = ConvertTo-XmlText $e.Key
        $escVal = ConvertTo-XmlText $e.Ru
        [void]$sb.AppendLine("<data name=`"$escKey`" xml:space=`"preserve`">")
        [void]$sb.AppendLine("  <value>$escVal</value>")
        [void]$sb.AppendLine("</data>")
        $existing[$e.Key] = $true
        $cnt++
    }

    if ($sb.Length -eq 0) { continue }
    if ($DryRun) { Write-Host ("[dry] {0}: +{1}" -f $file, $cnt); $addedTotal += $cnt; continue }

    $idx = $text.LastIndexOf('</root>')
    if ($idx -lt 0) { Write-Host "NO </root> in $file" -ForegroundColor Red; $errors++; continue }
    $new = $text.Substring(0, $idx) + $sb.ToString() + $text.Substring($idx)
    try { $x = New-Object System.Xml.XmlDocument; $x.LoadXml($new) }
    catch { Write-Host ("XML INVALID after insert in {0}: {1}" -f $file, $_.Exception.Message) -ForegroundColor Red; $errors++; continue }
    [System.IO.File]::WriteAllText($path, $new, (New-Object System.Text.UTF8Encoding($true)))
    $addedTotal += $cnt
    Write-Host ("OK {0}: +{1}" -f $file, $cnt) -ForegroundColor Green
}

Write-Host ""
Write-Host ("Added: {0} | skipped(existing): {1} | errors: {2}" -f $addedTotal, $skipExisting, $errors)
if ($errors -gt 0) { exit 2 }
