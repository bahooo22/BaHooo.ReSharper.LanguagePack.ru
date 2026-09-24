# Полная проверка перевода всех resx-файлов пакета против neutral-ресурсов установки.
# Проверки: XML-валидность, пустые значения, CJK-символы, наборы ключей,
# плейсхолдеры {n}, записи ru==en без кириллицы (кандидаты на непереведённость).
# Отчёт: build/i18n-translation-report.txt
#requires -Version 5
param(
    # Каталог установки определялся раньше константой, и эта константа уже успела протухнуть:
    # в файле лежал путь G:\eXample\AppData\Local\JetBrains\Installations\ReSharperPlatformVs18_23258025,
    # который после обновления платформы перестал существовать, и проверка падала с
    # «не удается найти путь». Теперь тот же автопоиск, что в i18n-audit.ps1: обе сверки
    # обязаны смотреть в одну и ту же установку, иначе их числа несопоставимы.
    [string]$InstallDir,
    [string]$ResxFolder,
    [string]$ReportPath,
    # Дата в отчёте делает его разным на каждый прогон, поэтому любой пересъём пачкает git diff и
    # не доказывает воспроизводимость сверки. По умолчанию дата не пишется (провенанс виден из
    # git log по файлу отчёта), `-stamp` возвращает её, когда отчёт идёт человеку.
    [switch]$Stamp
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

function Find-LatestReSharperInstall {
    $roots = @(
        (Join-Path ${env:ProgramFiles(x86)} 'JetBrains\Installations'),
        "$env:LOCALAPPDATA\JetBrains\Installations"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    $candidates = foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -Directory -Filter 'ReSharperPlatform*' -ErrorAction SilentlyContinue
    }
    $latest = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        throw "Каталог установки ReSharper не найден в: $($roots -join ', '). Передайте -InstallDir явно."
    }
    return $latest.FullName
}

if (-not $InstallDir) { $InstallDir = Find-LatestReSharperInstall }
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
$statFiles = 0; $statEntries = 0; $statXml = 0; $statEmpty = 0; $statEmptyUpstream = 0; $statCjk = 0; $statKeys = 0; $statPh = 0; $statNoNeutral = 0; $statIdentical = 0; $statIdenticalSuspicious = 0

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
    # `.Count` через point-access у hashtable недоверителен: в DPA.Core.Resources.Strings есть
    # ключ с именем `Count`, и PowerShell отдаёт значение этого ключа вместо свойства.
    $statEntries += $values.Keys.Count

    # пустые значения
    # Порядок обхода ключей фиксируется сортировкой: без него enumeration у hashtable меняется
    # от прогона к прогону, и весь отчёт выглядел переписанным в git diff.
    # Пустое ru-значение само по себе ещё не дефект: если upstream хранит в neutral пустую
    # строку, переводчик зеркалит её осознанно. Без этой пометки метрика «пустых значений: 4»
    # читалась как 4 пропуска.
    $hasNeutral = $neutral.ContainsKey($neutralName)
    $enAll = if ($hasNeutral) { $neutral[$neutralName] } else { $null }
    foreach ($k in @($values.Keys | Sort-Object)) {
        if ([string]::IsNullOrWhiteSpace($values[$k])) {
            $statEmpty++
            $note = ' (neutral недоступен — сверить вручную)'
            if ($hasNeutral) {
                if (-not $enAll.ContainsKey($k))    { $note = '; в neutral такого ключа нет' }
                elseif ([string]::IsNullOrWhiteSpace($enAll[$k])) {
                    $note = '; en тоже пуст (upstream) — не пропуск'; $statEmptyUpstream++
                }
                else { $note = "; en НЕ пуст ('{0}') — реальный пропуск" -f $enAll[$k] }
            }
            $problems.Add("$($rf.Name): ПУСТОЕ ЗНАЧЕНИЕ [$k]$note")
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

    $missing = @($en.Keys   | Where-Object { -not $values.ContainsKey($_) } | Sort-Object)
    $extra   = @($values.Keys | Where-Object { -not $en.ContainsKey($_) }   | Sort-Object)
    if ($missing.Count -gt 0) { $statKeys++; $problems.Add("$($rf.Name): НЕТ КЛЮЧЕЙ (в resx меньше, чем в DLL): $($missing -join ', ')") }
    if ($extra.Count -gt 0)   { $statKeys++; $problems.Add("$($rf.Name): ЛИШНИЕ КЛЮЧИ (в resx больше, чем в DLL): $($extra -join ', ')") }

    foreach ($k in @($en.Keys | Sort-Object)) {
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
[void]$sb.AppendLine("Установка: $InstallDir")
if ($Stamp) { [void]$sb.AppendLine("Дата: $(Get-Date -Format 'yyyy-MM-dd HH:mm')") }
[void]$sb.AppendLine()
[void]$sb.AppendLine("resx-файлов:                $statFiles")
[void]$sb.AppendLine("записей всего:              $statEntries")
[void]$sb.AppendLine("neutral-ресурсов доступно:  $($neutral.Count)")
[void]$sb.AppendLine("без neutral (нет DLL):      $statNoNeutral")
[void]$sb.AppendLine()
[void]$sb.AppendLine("XML-ошибок:                 $statXml")
[void]$sb.AppendLine("пустых значений:            $statEmpty  (en тоже пуст: $statEmptyUpstream)")
[void]$sb.AppendLine("CJK-утечек:                 $statCjk")
[void]$sb.AppendLine("расхождений ключей:         $statKeys")
[void]$sb.AppendLine("расхождений плейсхолдеров:  $statPh")
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

# Отчёт нормализуем в LF: .gitattributes задаёт *.txt eol=lf, а StringBuilder даёт CRLF,
# из-за чего каждый прогон показывался в git diff как полностью переписанный файл.
[System.IO.File]::WriteAllText($ReportPath, ($sb.ToString() -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($true)))
Write-Host ''
Write-Host 'ИТОГИ:'
Write-Host ("  файлов: {0}, записей: {1}" -f $statFiles, $statEntries)
Write-Host ("  XML-ошибок: {0} | пустых: {1} | CJK: {2} | ключи: {3} | плейсхолдеры: {4}" -f $statXml, $statEmpty, $statCjk, $statKeys, $statPh) -ForegroundColor $(if ($statXml + $statEmpty + $statCjk + $statKeys + $statPh -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ("  ru==en без кириллицы: {0} (подробно в отчёте)" -f $statIdentical)
Write-Host ("  Отчёт: {0}" -f $ReportPath)
