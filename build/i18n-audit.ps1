# Аудит покрытия локализации: встроенные neutral-ресурсы ReSharper DLL против файлов пакета.
# Выход: сводка в консоль + полный отчёт в build/i18n-coverage-report.txt
#requires -Version 5
[CmdletBinding()]
param(
    # По умолчанию — последняя по времени установки платформа ReSharper на этой машине;
    # каталог содержит хэш установки, поэтому захардкодить его нельзя.
    [string]$InstallDir,
    [string]$ResxFolder,
    [string]$I18nDir,
    [string]$ReportPath,
    # Строка «Дата:» делает отчёт разным на КАЖДЫЙ прогон, то есть любой пересъём шумами пачкает
    # git diff и невозможно доказать воспроизводимость сверки. По умолчанию дата в отчёт не
    # пишется (провенанс и так виден из git log по файлу отчёта), `-stamp` возвращает её, когда
    # отчёт идёт человеку, а не машине.
    [switch]$Stamp
)

$ErrorActionPreference = 'Stop'

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

if (-not $InstallDir) {
    $InstallDir = Find-LatestReSharperInstall
    Write-Host "Каталог установки определён автоматически: $InstallDir"
}
if (-not $ResxFolder) { $ResxFolder = Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU' }
if (-not $I18nDir)    { $I18nDir = Join-Path $InstallDir 'Extensions\BaHooo.ReSharper.I18n.ru\i18n' }
if (-not $ReportPath) { $ReportPath = Join-Path $PSScriptRoot 'i18n-coverage-report.txt' }

function Get-NeutralResources {
    # Neutral (безкультурные) .resources из всех top-level DLL установки.
    param([string]$Dir)

    $satelliteRegex = '\.[a-z]{2,3}(-[A-Za-z]{2,8})?\.resources$'
    $rows = New-Object 'System.Collections.Generic.List[object]'
    $failed = New-Object 'System.Collections.Generic.List[string]'

    $dlls = Get-ChildItem -LiteralPath $Dir -Filter *.dll -File
    $i = 0
    foreach ($dll in $dlls) {
        $i++
        try {
            $asm = [System.Reflection.Assembly]::LoadFile($dll.FullName)
            $names = $asm.GetManifestResourceNames()
            foreach ($n in $names) {
                if ($n -like '*.resources' -and $n -notlike '*.g.resources' -and $n -notmatch $satelliteRegex) {
                    $rows.Add([pscustomobject]@{ Resource = $n; Dll = $dll.Name })
                }
            }
        }
        catch {
            $failed.Add("$($dll.Name): $($_.Exception.GetType().Name)")
        }
        if ($i % 100 -eq 0) { Write-Host "  ...просканировано $i / $($dlls.Count)" }
    }

    [pscustomobject]@{ Rows = $rows; Failed = $failed; Total = $dlls.Count }
}

function Get-PackResourceNames {
    # Имена ресурсов (X.resources), соответствующие resx-файлам пакета.
    param([string]$Dir)
    Get-ChildItem -LiteralPath $Dir -Filter '*.ru-RU.resx' -File |
        ForEach-Object { ($_.BaseName -replace '\.ru-RU$', '') + '.resources' }
}

Write-Host '1/4 Сканирование DLL установки ReSharper...'
$scan = Get-NeutralResources -Dir $InstallDir
$neutral = $scan.Rows | Group-Object Resource | Sort-Object Name

Write-Host '2/4 Чтение списка пакета (resx)...'
$pack = Get-PackResourceNames -Dir $ResxFolder

Write-Host '3/4 Чтение задеплоенного i18n-каталога...'
$deployed = if (Test-Path -LiteralPath $I18nDir) {
    Get-ChildItem -LiteralPath $I18nDir -Filter *.resources -File | Select-Object -ExpandProperty Name
} else { @() }

Write-Host '4/4 Сравнение...'
$packSet    = New-Object 'System.Collections.Generic.HashSet[string]' (,([string[]]$pack))
$neutralSet = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($g in $neutral) { [void]$neutralSet.Add($g.Name) }

$missing = @($neutral | Where-Object { -not $packSet.Contains($_.Name) })
$stale   = @($pack | Where-Object { -not $neutralSet.Contains($_) })

# Нормализация имён задеплоенных файлов: снимаем суффикс культуры .ru-RU
$deployedNorm = @($deployed | ForEach-Object { $_ -replace '\.ru-RU\.resources$', '.resources' })
$deployedExtra    = @($deployedNorm | Where-Object { -not $packSet.Contains($_) })
$packNotDeployed  = @($pack | Where-Object { $deployedNorm -notcontains $_ })

# Размер и число строковых записей для отсутствующих ресурсов: без числа строк
# список неотличим — 180-байтовый пустой контейнер формы и таблица на 2900 строк
# выглядят одинаково. Поток уже открыт, поэтому доплата за подсчёт почти нулевая.
$sizeByName = @{}
$strCountByName = @{}
$missingNames = @($missing | Select-Object -ExpandProperty Name -Unique)
if ($missingNames.Count -gt 0) {
    $dllMap = @{}
    foreach ($r in $scan.Rows) { if (-not $dllMap.ContainsKey($r.Resource)) { $dllMap[$r.Resource] = $r.Dll } }
    foreach ($dll in ($missingNames | ForEach-Object { $dllMap[$_] } | Sort-Object -Unique)) {
        try {
            $asm = [System.Reflection.Assembly]::LoadFile((Join-Path $InstallDir $dll))
            foreach ($n in $missingNames) {
                if ($dllMap[$n] -eq $dll -and -not $sizeByName.ContainsKey($n)) {
                    $s = $asm.GetManifestResourceStream($n)
                    if ($s) {
                        $sizeByName[$n] = $s.Length
                        try {
                            $reader = New-Object System.Resources.ResourceReader($s)
                            $enumerator = $reader.GetEnumerator()
                            $strings = 0
                            while ($enumerator.MoveNext()) { if ($enumerator.Value -is [string]) { $strings++ } }
                            # Close() освобождает и сам читатель, и его перечислитель:
                            # у ResourceEnumerator в .NET Framework нет метода Dispose().
                            $reader.Close()
                            $strCountByName[$n] = $strings
                        } catch {
                            $strCountByName[$n] = -1
                        }
                        $s.Close()
                    }
                }
            }
        } catch { }
    }
}

# --- Отчёт ---
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("=== Аудит покрытия локализации: $InstallDir ===")
if ($Stamp) { [void]$sb.AppendLine("Дата: $(Get-Date -Format 'yyyy-MM-dd HH:mm')") }
[void]$sb.AppendLine()
[void]$sb.AppendLine("DLL просканировано:        $($scan.Total)")
[void]$sb.AppendLine("  не удалось загрузить:    $($scan.Failed.Count)")
[void]$sb.AppendLine("Neutral .resources всего:  $($neutralSet.Count)")
[void]$sb.AppendLine("Файлов в пакете (resx):    $($pack.Count)")
[void]$sb.AppendLine("Задеплоено в i18n:         $($deployed.Count)")
[void]$sb.AppendLine()
[void]$sb.AppendLine("ПОКРЫТО ПАКЕТОМ:  $($neutralSet.Count - $missing.Count) из $($neutralSet.Count)")
[void]$sb.AppendLine("ОТСУТСТВУЕТ В ПАКЕТЕ: $($missing.Count)")
[void]$sb.AppendLine("В ПАКЕТЕ, НО НЕ НАЙДЕНО В DLL (устаревшие?): $($stale.Count)")
[void]$sb.AppendLine("Задеплоено лишнего (нет в resx): $($deployedExtra.Count)")
[void]$sb.AppendLine("Есть в resx, но не задеплоено: $($packNotDeployed.Count)")
[void]$sb.AppendLine()

if ($missing.Count -gt 0) {
    [void]$sb.AppendLine('--- ОТСУТСТВУЮЩИЕ В ПАКЕТЕ (ресурс | DLL | размер байт | строковых записей) ---')
    [void]$sb.AppendLine('    (-1 = ресурс не читается как набор имя/значение; 0 = пустой контейнер формы/картинок)')
    foreach ($m in $missing | Sort-Object { $_.Name -notlike '*.Strings*' }, Name) {
        $sz = $sizeByName[$m.Name]; $szText = if ($sz) { '{0}' -f $sz } else { '?' }
        $st = $strCountByName[$m.Name]; $stText = if ($null -eq $st) { '?' } else { '{0}' -f $st }
        $kind = if ($m.Name -like '*.Strings.*' -or $m.Name -like '*.Strings') { '[Strings]' } else { '[other]  ' }
        $dllsText = (@($m.Group | Select-Object -ExpandProperty Dll -Unique) -join ', ')
        [void]$sb.AppendLine("$kind $($m.Name) | $dllsText | $szText | $stText")
    }
    [void]$sb.AppendLine()

    # Сводка по своим (JetBrains) ресурсам: сторонние NuGet/DevExpress/Actipro/yWorks
    # механизмом сателлитов не перекрываются, их доля в списке — только шум.
    $own = @($missing | Where-Object { (@($_.Group | Select-Object -ExpandProperty Dll -Unique)) -like 'JetBrains*' })
    $ownWithData = @($own | Where-Object { $_.Name -notlike '*.Sharepoint.ResourceFiles.*' })
    $empty = @($ownWithData | Where-Object { $strCountByName[$_.Name] -eq 0 })
    $withStrings = @($ownWithData | Where-Object { $strCountByName[$_.Name] -gt 0 })
    $sumStrings = 0
    foreach ($w in $withStrings) { $sumStrings += $strCountByName[$w.Name] }
    [void]$sb.AppendLine('--- ОЦЕНКА ДЕФИЦИТА ПО РЕСУРСАМ JETBRAINS ---')
    [void]$sb.AppendLine("Непокрытых JetBrains-ресурсов:              $($own.Count)")
    [void]$sb.AppendLine("  из них файлы данных SharePoint:            $(@($own).Count - @($ownWithData).Count) (синхронизированы с ASPX-разметкой, не переводятся)")
    [void]$sb.AppendLine("  пустых контейнеров (0 строковых записей):  $($empty.Count)")
    [void]$sb.AppendLine("  таблиц со строками:                        $($withStrings.Count), всего строк: $sumStrings")
    [void]$sb.AppendLine()

    # Сводных чисел мало: чтобы разделить дефицит на «видно в VS», «расширение не
    # установлено» и «дубли одного ресурса в нескольких DLL», нужен сам список
    # таблиц с размером и числом строк, отсортированный по убыванию строк.
    [void]$sb.AppendLine('--- ТАБЛИЦЫ СО СТРОКАМИ (строков | ресурс | DLL | байт) ---')
    foreach ($w in ($withStrings | Sort-Object { -$strCountByName[$_.Name] }, Name)) {
        $szText = if ($sizeByName[$w.Name]) { '{0}' -f $sizeByName[$w.Name] } else { '?' }
        $dllsText = (@($w.Group | Select-Object -ExpandProperty Dll -Unique) -join ', ')
        [void]$sb.AppendLine(('{0,6} | {1} | {2} | {3}' -f $strCountByName[$w.Name], $w.Name, $dllsText, $szText))
    }
    [void]$sb.AppendLine()
}

if ($stale.Count -gt 0) {
    [void]$sb.AppendLine('--- В ПАКЕТЕ, НО НЕ НАЙДЕНО В DLL ---')
    foreach ($s in $stale | Sort-Object) { [void]$sb.AppendLine("  $s") }
    [void]$sb.AppendLine()
}

if ($deployedExtra.Count -gt 0) {
    [void]$sb.AppendLine('--- ЗАДЕПЛОИРОВАНО, НО НЕТ В RESX ПАКЕТА ---')
    foreach ($s in $deployedExtra | Sort-Object) { [void]$sb.AppendLine("  $s") }
    [void]$sb.AppendLine()
}

if ($packNotDeployed.Count -gt 0) {
    [void]$sb.AppendLine('--- В RESX ЕСТЬ, НО НЕ ЗАДЕПЛОИРОВАНО В I18N ---')
    foreach ($s in $packNotDeployed | Sort-Object) { [void]$sb.AppendLine("  $s") }
    [void]$sb.AppendLine()
}

if ($scan.Failed.Count -gt 0) {
    [void]$sb.AppendLine('--- DLL НЕ УДАЛОСЬ ЗАГРУЗИТЬ (обычно нативные) ---')
    foreach ($f in $scan.Failed | Sort-Object) { [void]$sb.AppendLine("  $f") }
}

[System.IO.File]::WriteAllText($ReportPath, ($sb.ToString() -replace "`r`n", "`n"), [System.Text.Encoding]::UTF8)
Write-Host ''
Write-Host 'ИТОГИ:'
Write-Host "  Ресурсов в установке:   $($neutralSet.Count)"
Write-Host "  Покрыто пакетом:         $($neutralSet.Count - $missing.Count)"
Write-Host "  Отсутствует в пакете:    $($missing.Count)  (из них строковых [Strings]: $(@($missing | Where-Object { $_.Name -like '*.Strings*' }).Count))"
Write-Host "  Устаревших в пакете:     $($stale.Count)"
Write-Host "  Полный отчёт:            $ReportPath"
