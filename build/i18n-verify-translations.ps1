# Полная проверка перевода всех resx-файлов пакета против neutral-ресурсов установки.
# Проверки: XML-валидность, пустые значения, CJK-символы, наборы ключей,
# плейсхолдеры {n}, записи ru==en без кириллицы (кандидаты на непереведённость).
# Отчёт: build/i18n-translation-report.txt
#requires -Version 5
param(
    [string]$InstallDir = 'G:\eXample\AppData\Local\JetBrains\Installations\ReSharperPlatformVs18_23258025',
    [string]$ResxFolder,
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

if (-not $ResxFolder) { $ResxFolder = Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU' }
if (-not $ReportPath) { $ReportPath = Join-Path $PSScriptRoot 'i18n-translation-report.txt' }

$cjkRegex = '[\u3000-\u303F\u3040-\u30FF\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\uFF00-\uFFEF]'
$hasCyrillic = '[\u0400-\u04FF]'

# --- 1. Нейтральные ресурсы из DLL (только те, для которых есть resx в пакете) ---
Write-Host '1/3 Сканирование neutral-ресурсов DLL установки...'
$neutral = @{}   # resource -> hashtable key->en
$failedDlls = New-Object 'System.Collections.Generic.List[string]'
$problems0 = New-Object 'System.Collections.Generic.List[string]'
$needed = @{}
Get-ChildItem -LiteralPath $ResxFolder -Filter '*.ru-RU.resx' -File | ForEach-Object {
    $needed[($_.BaseName -replace '\.ru-RU$', '') + '.resources'] = $true
}
Get-ChildItem -LiteralPath $InstallDir -Filter *.dll -File | ForEach-Object {
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
                    if ($dict.Count -gt 0) { $neutral[$rn] = $dict }
                } catch {
                    $problems0.Add("НЕ УДАЛОСЬ ПРОЧИТАТЬ neutral $rn из $($_.Name): $($_.Exception.Message)")
                } finally { $stream.Close() }
            }
        }
    }
    catch { $failedDlls.Add($_.Name) }
}
Write-Host (" neutral-ресурсов прочитано: {0} из {1} нужных" -f $neutral.Count, $needed.Count)

function Get-Placeholders {
    param([string]$Text)
    [regex]::Matches($Text, '\{\d+\}') | ForEach-Object { $_.Value } | Sort-Object
}

# --- 2. Проверка каждого resx ---
Write-Host '2/3 Проверка resx-файлов пакета...'
$problems = New-Object 'System.Collections.Generic.List[string]'
$suspicious = New-Object 'System.Collections.Generic.List[string]'
$statFiles = 0; $statEntries = 0; $statXml = 0; $statEmpty = 0; $statCjk = 0; $statKeys = 0; $statPh = 0; $statNoNeutral = 0; $statIdentical = 0; $statIdenticalSuspicious = 0

$resxFiles = @(Get-ChildItem -LiteralPath $ResxFolder -Filter '*.ru-RU.resx' -File)
foreach ($rf in $resxFiles) {
    $statFiles++
    $neutralName = ($rf.BaseName -replace '\.ru-RU$', '') + '.resources'

    # XML-валидность + чтение
    $values = $null
    try {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load($rf.FullName)
        $values = @{}
        foreach ($d in $xml.SelectNodes('//root/data')) {
            $v = $d.SelectSingleNode('value')
            $values[$d.name] = $(if ($v) { $v.InnerText } else { '' })
        }
    }
    catch {
        $statXml++
        $problems.Add("$($rf.Name): XML НЕ ПАРСИТСЯ: $($_.Exception.Message)")
        continue
    }
    try { $statEntries += [int]$values.Count }
    catch {
        Write-Host ("ДИАГНОСТИКА: файл={0} тип values={1} values.Count={2}" -f $rf.Name, $values.GetType().FullName, $values.Count) -ForegroundColor Magenta
        $statEntries += @($values.Keys).Count
    }

    # пустые значения
    foreach ($k in @($values.Keys)) {
        if ([string]::IsNullOrWhiteSpace($values[$k])) {
            $statEmpty++
            $problems.Add("$($rf.Name): ПУСТОЕ ЗНАЧЕНИЕ [$k]")
        }
        if ($values[$k] -match $cjkRegex) {
            $statCjk++
            $problems.Add("$($rf.Name): CJK-СИМВОЛЫ в [$k]: $($values[$k])")
        }
    }

    # сравнение с neutral
    if (-not $neutral.ContainsKey($neutralName)) {
        $statNoNeutral++
        $suspicious.Add("$($rf.Name): neutral-ресурс не найден в этой установке (проверка ключей/плейсхолдеров пропущена)")
        continue
    }
    $en = $neutral[$neutralName]

    $missing = @($en.Keys | Where-Object { -not $values.ContainsKey($_) })
    $extra   = @($values.Keys | Where-Object { -not $en.ContainsKey($_) })
    if ($missing.Count -gt 0) { $statKeys++; $problems.Add("$($rf.Name): НЕТ КЛЮЧЕЙ (в resx меньше, чем в DLL): $($missing -join ', ')") }
    if ($extra.Count -gt 0)   { $statKeys++; $problems.Add("$($rf.Name): ЛИШНИЕ КЛЮЧИ (в resx больше, чем в DLL): $($extra -join ', ')") }

    foreach ($k in @($en.Keys)) {
        if (-not $values.ContainsKey($k)) { continue }
        $enPh = @(Get-Placeholders $en[$k]) -join ','
        $ruPh = @(Get-Placeholders $values[$k]) -join ','
        if ($enPh -ne $ruPh) {
            $statPh++
            $problems.Add("$($rf.Name): ПЛЕЙСХОЛДЕРЫ [$k]: en[$enPh] != ru[$ruPh]")
        }
        if ($values[$k] -ceq $en[$k] -and $values[$k] -notmatch $hasCyrillic -and $values[$k] -match '[A-Za-z]{2,}') {
            $statIdentical++
            $suspicious.Add("$($rf.Name): ru==en [$k] = $($values[$k])")
            if ($values[$k] -match '[a-z]{3,}') { $statIdenticalSuspicious++ }
        }
    }
}

# --- 3. Отчёт ---
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('=== Проверка перевода всех resx-файлов пакета ===')
[void]$sb.AppendLine("Дата: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
[void]$sb.AppendLine()
[void]$sb.AppendLine("resx-файлов:                $statFiles")
[void]$sb.AppendLine("записей всего:              $statEntries")
[void]$sb.AppendLine("neutral-ресурсов доступно:  $($neutral.Count)")
[void]$sb.AppendLine("без neutral (нет DLL):      $statNoNeutral")
[void]$sb.AppendLine()
[void]$sb.AppendLine("XML-ошибок:                 $statXml")
[void]$sb.AppendLine("пустых значений:            $statEmpty")
[void]$sb.AppendLine("CJK-утечек:                 $statCjk")
[void]$sb.AppendLine("расхождений ключей:         $statKeys")
[void]$sb.AppendLine("ошибок плейсхолдеров:       $statPh")
[void]$sb.AppendLine("ru==en (без кириллицы):     $statIdentical  (с малыми англ. словами: $statIdenticalSuspicious)")
[void]$sb.AppendLine()

if ($problems.Count -gt 0) {
    [void]$sb.AppendLine('--- ПРОБЛЕМЫ (нужны исправления) ---')
    foreach ($p in $problems) { [void]$sb.AppendLine("  $p") }
    [void]$sb.AppendLine()
}
if ($problems0.Count -gt 0) {
    [void]$sb.AppendLine('--- НЕ ПРОЧИТАННЫЕ NEUTRAL-РЕСУРСЫ (пропущены) ---')
    foreach ($p in $problems0) { [void]$sb.AppendLine("  $p") }
    [void]$sb.AppendLine()
}
if ($suspicious.Count -gt 0) {
    [void]$sb.AppendLine('--- НА КЛАДКУ ВНИМАНИЯ ---')
    foreach ($s in $suspicious) { [void]$sb.AppendLine("  $s") }
}
if ($failedDlls.Count -gt 0) {
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('--- DLL НЕ ЗАГРУЗИЛИСЬ (нативные, не влияют) ---')
    foreach ($f in $failedDlls) { [void]$sb.AppendLine("  $f") }
}

[System.IO.File]::WriteAllText($ReportPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
Write-Host ''
Write-Host 'ИТОГИ:'
Write-Host ("  файлов: {0}, записей: {1}" -f $statFiles, $statEntries)
Write-Host ("  XML-ошибок: {0} | пустых: {1} | CJK: {2} | ключи: {3} | плейсхолдеры: {4}" -f $statXml, $statEmpty, $statCjk, $statKeys, $statPh) -ForegroundColor $(if ($statXml + $statEmpty + $statCjk + $statKeys + $statPh -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ("  ru==en без кириллицы: {0} (подробно в отчёте)" -f $statIdentical)
Write-Host ("  Отчёт: {0}" -f $ReportPath)
