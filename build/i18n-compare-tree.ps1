#requires -Version 7
<#
  Сравнение всех JetBrains*.dll дерева C:\Program Files (x86)\JetBrains\ (рекурсивно)
  с нашими resx-таблицами. Скан — дочерними pwsh-батчами (Assembly.LoadFile может
  уронить процесс на mixed-mode DLL; родитель восстанавливается с следующей записи).
  Выход: build/compare-jetbrains-tree-<date>.txt, промежуточный JSONL — build/scan-tree-raw.jsonl
#>
[CmdletBinding()]
param(
    [string]$Root = (Join-Path ${env:ProgramFiles(x86)} 'JetBrains'),
    [string]$ResxFolder = (Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU'),
    [int]$Batch = 80,
    [switch]$ReuseRaw
)
$ErrorActionPreference = 'Stop'
$outPath = Join-Path $PSScriptRoot ("compare-jetbrains-tree-{0:yyyy-MM-dd}.txt" -f (Get-Date))
$raw = Join-Path $PSScriptRoot 'scan-tree-raw.jsonl'
$cultureDir = '^(af|ar|az|be|bg|bn|bs|ca|cs|cy|da|de|el|es|et|eu|fa|fi|fil|fr|gl|he|hi|hr|hu|hy|id|is|it|ka|kk|km|kn|ko|lt|lv|mi|mk|ml|ms|mt|nb|nl|nn|pa|pl|pt|ro|ru|sk|sl|sq|sr|sv|sw|ta|te|th|tr|uk|ur|uz|vi|xh|zh|zh-Hans|zh-Hant)$'

# --- список DLL ---
$listFile = Join-Path $env:TEMP 'i18n-tree-dlls.txt'
if (-not $ReuseRaw) {
    $dlls = Get-ChildItem -LiteralPath $Root -Filter 'JetBrains*.dll' -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\Packages\\' -and $_.FullName -notmatch '\\vAny_[^\\]+\\' -and
                       -not ($_.Directory.Name -match $cultureDir) }
    $dlls.FullName | Set-Content -LiteralPath $listFile -Encoding UTF8
    "DLL к обходу: $($dlls.Count)"
    Remove-Item $raw -ErrorAction SilentlyContinue
    [IO.File]::WriteAllText($raw, '')

    # --- батчи с восстановлением ---
    $all = Get-Content -LiteralPath $listFile
    $i = 0
    $crashed = 0
    while ($i -lt $all.Count) {
        $batchSlice = $all[$i..([Math]::Min($i + $Batch - 1, $all.Count - 1))]
        $bf = Join-Path $env:TEMP 'i18n-tree-batch.txt'
        $batchSlice | Set-Content -LiteralPath $bf -Encoding UTF8
        $before = (Get-Content -LiteralPath $raw | Measure-Object -Line).Lines
        $proc = Start-Process pwsh -ArgumentList @('-NoProfile','-File',"$PSScriptRoot\i18n-scan-child.ps1",'-ListFile',$bf,'-OutFile',$raw) -PassThru -WindowStyle Hidden
        $proc.WaitForExit()
        $after = (Get-Content -LiteralPath $raw | Measure-Object -Line).Lines
        $done = $after - $before
        if ($proc.ExitCode -ne 0 -or $done -lt $batchSlice.Count) {
            # батч упал: записываем битую DLL и продолжаем со следующей
            $badIdx = $i + $done
            if ($badIdx -lt $all.Count) {
                ([pscustomobject]@{ dll = $all[$badIdx]; error = 'PROCESS_CRASH' } | ConvertTo-Json -Compress) |
                    Add-Content -LiteralPath $raw
                $crashed++
                "CRASH на: $($all[$badIdx])"
            }
            $i = $i + $done + 1
        } else {
            $i += $Batch
        }
        if ($i % 800 -lt $Batch) { "прогресс: $i/$($all.Count), крашей: $crashed" }
    }
    "обход завершён, крашей: $crashed"
}

# --- агрегация ---
$neutral = @{}
Get-Content -LiteralPath $raw | Where-Object { $_ } | ForEach-Object {
    $o = $_ | ConvertFrom-Json
    if ($o.PSObject.Properties['sets'] -and $o.sets) {
        foreach ($p in $o.sets.PSObject.Properties) {
            if (-not $neutral.ContainsKey($p.Name)) {
                $neutral[$p.Name] = [pscustomobject]@{ Dll = $o.dll.Substring($Root.Length); Keys = @($p.Value) }
            }
        }
    }
}
"нейтральных наборов со строками: $($neutral.Count)"

# --- наши resx ---
$ours = @{}
foreach ($rx in Get-ChildItem -LiteralPath $ResxFolder -Filter '*.ru-RU.resx' -File) {
    $name = $rx.Name -replace '\.ru-RU\.resx$', ''
    $keys = @{}
    [xml]$x = Get-Content -LiteralPath $rx.FullName -Raw -Encoding UTF8
    foreach ($d in $x.SelectNodes('/root/data')) { $keys[$d.name.ToLowerInvariant()] = $true }
    $ours[$name] = $keys
}

# --- сверка ---
$uncovered = New-Object System.Collections.Generic.List[object]
$parity = New-Object System.Collections.Generic.List[object]
$matched = 0
foreach ($set in $neutral.Keys | Sort-Object) {
    $info = $neutral[$set]
    $base = $set -replace '\.resources$', ''
    $ourKey = $null
    foreach ($k in $ours.Keys) { if ($k -ieq $base) { $ourKey = $k; break } }
    if ($null -eq $ourKey) {
        if ($base -like 'JetBrains.*') { $uncovered.Add([pscustomobject]@{ Set = $set; Strings = $info.Keys.Count; Dll = $info.Dll }) }
    } else {
        $matched++
        $ourSet = $ours[$ourKey]
        $missing = @($info.Keys | Where-Object { -not $ourSet.ContainsKey($_.ToLowerInvariant()) })
        if ($missing.Count -gt 0) {
            $parity.Add([pscustomobject]@{ Set = $set; Missing = $missing.Count; Total = $info.Keys.Count; Keys = ($missing | Sort-Object | Select-Object -First 15) })
        }
    }
}
$ourExtra = @($ours.Keys | Where-Object { $n = $_ + '.resources'; -not ($neutral.ContainsKey($n)) } | Sort-Object)

"покрыто: $matched; наших без neutral: $($ourExtra.Count); непокрытых JetBrains: $($uncovered.Count); паритет-разрывов: $($parity.Count)"

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Сравнение дерева $Root (JetBrains*.dll, рекурсивно) с $($ours.Count) resx-таблицами; съём $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$lines.Add("нейтральных наборов со строками: $($neutral.Count); покрыто: $matched")
$lines.Add('')
$lines.Add('--- НЕ ПОКРЫТЫ (JetBrains-наборы со строками, нет нашей resx) ---')
foreach ($u in ($uncovered | Sort-Object -Property Strings -Descending)) {
    $lines.Add(("{0,6}  {1}  [{2}]" -f $u.Strings, $u.Set, $u.Dll))
}
$lines.Add('')
$lines.Add('--- РАЗРЫВ ПАРИТЕТА (neutral-ключи, отсутствующие в нашем ru) ---')
foreach ($p in ($parity | Sort-Object -Property Missing -Descending)) {
    $lines.Add(("{0,5}/{1,-5} {2}" -f $p.Missing, $p.Total, $p.Set))
    $lines.Add('        примеры: ' + ($p.Keys -join ', '))
}
$lines.Add('')
$lines.Add('--- НАШИ ТАБЛИЦЫ БЕЗ neutral В ЭТОМ ДЕРЕВЕ ---')
foreach ($o in $ourExtra) { $lines.Add("  $o") }
Set-Content -LiteralPath $outPath -Value $lines -Encoding UTF8
"отчёт: $outPath"
