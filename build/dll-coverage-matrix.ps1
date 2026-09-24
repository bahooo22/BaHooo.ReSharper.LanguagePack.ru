#requires -Version 5
<#
  Матрица покрытия локализации по всем DLL установки.

  Зачем: «библиотек 624, а переведённых ресурсов меньше» — само по себе не дефицит.
  Переводимая единица — не DLL, а нейтральная таблица строк, которую механизм
  i18n-сателлитов вообще способен перекрыть. Скрипт раскладывает каждую такую
  таблицу по статусам и пишет два раздельных списка действий (part-A / part-B),
  чтобы два диалога не полезли в один и тот же ресурс.

  Выход:
    build/dll-coverage-matrix.tsv  — полная матрица (Dll, Resource, Strings, Covered, Owner, Actionable)
    build/deficit-part-A.txt        — переводимые недостающие таблицы, 1-я половина (мои)
    build/deficit-part-B.txt        — переводимые недостающие таблицы, 2-я половина (напарницы)
    build/parity-gaps.txt           — покрытые ресурсы, где в ru нет части ключей (регистронезависимо)
    сводка в консоль
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [string]$ResxFolder = (Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU'),
    [string]$OutDir = $PSScriptRoot
)
$ErrorActionPreference = 'Stop'
# ResXResourceReader живёт в System.Windows.Forms — в PS Core его надо явно загрузить.
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
    if (-not $latest) { throw 'ReSharper install not found; pass -InstallDir.' }
    return $latest.FullName
}
if (-not $InstallDir) { $InstallDir = Find-LatestReSharperInstall }

# --- Набор покрытых ресурсов (из имён .resx), регистронезависимо ---
$covered = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$resxByKey = @{}
foreach ($rx in (Get-ChildItem -LiteralPath $ResxFolder -Filter '*.ru-RU.resx' -File)) {
    $key = $rx.Name -replace '\.ru-RU\.resx$', ''
    [void]$covered.Add($key)
    $resxByKey[$key] = $rx.FullName
}

function Count-StringKeys($asm, $rn) {
    $s = $asm.GetManifestResourceStream($rn)
    if (-not $s) { return $null }
    $mm = New-Object System.IO.MemoryStream; $s.CopyTo($mm); $s.Close(); $mm.Position = 0
    $h = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $n = 0
    try {
        $rr = New-Object System.Resources.ResourceReader($mm); $e = $rr.GetEnumerator()
        while ($e.MoveNext()) { if ($e.Value -is [string]) { $h[[string]$e.Key] = [string]$e.Value; $n++ } }
        $rr.Close()
    } catch { $mm.Dispose(); return $null }
    $mm.Dispose()
    # N считаем отдельно: $h.Count в PowerShell резолвится как КЛЮЧ "count", а не свойство.
    return [pscustomobject]@{ Map = $h; N = $n }
}

$satellite = '\.[a-z]{2,3}(-[A-Za-z]{2,8})?\.resources$'
$dlls = Get-ChildItem -LiteralPath $InstallDir -Filter *.dll -File
$matrix = New-Object 'System.Collections.Generic.List[object]'
$loadFail = 0
$parity = New-Object 'System.Collections.Generic.List[object]'
$i = 0
foreach ($dll in $dlls) {
    $i++
    try { $asm = [System.Reflection.Assembly]::LoadFile($dll.FullName) }
    catch { $loadFail++; continue }
    $names = @()
    try { $names = $asm.GetManifestResourceNames() } catch { continue }
    foreach ($rn in $names) {
        if ($rn -notlike '*.resources' -or $rn -like '*.g.resources' -or $rn -match $satellite) { continue }
        $key = $rn -replace '\.resources$', ''
        $vals = Count-StringKeys $asm $rn
        if ($null -eq $vals) { continue }
        $strings = $vals.N
        $isCovered = $covered.Contains($key)
        $owner = if ($key -like 'JetBrains*' -or $dll.Name -like 'JetBrains*') { 'JetBrains' } else { 'third-party' }
        # Класс таблицы: данные/легальные тексты/паттерны перевода не требуют и механизмом
        # сателлитов не перекрываются по смыслу. В «переводимые» goes только ui.
        $kind = 'ui'
        if ($owner -ne 'JetBrains') { $kind = 'third-party' }
        # данные/легальные тексты/паттерны/шаблоны кода — механизмом не перекрываются по смыслу.
        elseif ($key -match '\.Sharepoint\.ResourceFiles\.' -or $key -match 'FileLayout|PatternResources|WikiResources|License|agreement|CodeStyle|Razor.*\.Texts$') { $kind = 'data/legal' }
        # Голый "Resources" в VSIX-пакете — собственная метадата пакета, не JetBrains-сателлит.
        elseif ($key -eq 'Resources' -and $dll.Name -like '*.Package.dll') { $kind = 'package-meta' }
        $actionable = ($owner -eq 'JetBrains' -and $strings -gt 0 -and -not $isCovered -and $kind -eq 'ui')
        $matrix.Add([pscustomobject]@{ Dll = $dll.Name; Resource = $key; Strings = $strings; Covered = $isCovered; Owner = $owner; Kind = $kind; Actionable = $actionable })

        # Регистронезависимая сверка ключей для покрытых ресурсов.
        if ($isCovered -and $strings -gt 0 -and $resxByKey.ContainsKey($key)) {
            $rxPath = $resxByKey[$key]
            try {
                $ru = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
                $xr = New-Object System.Resources.ResXResourceReader $rxPath
                foreach ($en2 in $xr) { if ($en2.Value -is [string]) { [void]$ru.Add([string]$en2.Key) } }
                $xr.Close()
                $miss = 0
                foreach ($k in $vals.Map.Keys) { if (-not $ru.Contains($k)) { $miss++ } }
                if ($miss -gt 0) { $parity.Add([pscustomobject]@{ Resource = $key; Neutral = $strings; MissingInRu = $miss }) }
            } catch { }
        }
    }
    if ($i % 150 -eq 0) { Write-Host "  ...$i / $($dlls.Count)" }
}

$TAB = [string][char]9
$matrix | Sort-Object -Property @{Expression='Strings'; Descending=$true}, @{Expression='Resource'; Descending=$false} |
    ForEach-Object { (($_.Dll, $_.Resource, $_.Strings, [int]$_.Covered, $_.Owner, $_.Kind, [int]$_.Actionable) -join $TAB) } |
    Set-Content -LiteralPath (Join-Path $OutDir 'dll-coverage-matrix.tsv') -Encoding UTF8

$act = @($matrix | Where-Object { $_.Actionable } | Sort-Object Resource)
$half = [int][Math]::Ceiling($act.Count / 2)
if ($act.Count -eq 0) { $actA = @(); $actB = @() }
else {
    $actA = @($act[0..([Math]::Max(0,$half-1))])
    $actB = if ($act.Count -gt $half) { @($act[$half..($act.Count-1)]) } else { @() }
}
($actA | ForEach-Object { ($_.Resource, ('strings='+$_.Strings), ('dll='+$_.Dll)) -join $TAB }) |
    Set-Content -LiteralPath (Join-Path $OutDir 'deficit-part-A.txt') -Encoding UTF8
($actB | ForEach-Object { ($_.Resource, ('strings='+$_.Strings), ('dll='+$_.Dll)) -join $TAB }) |
    Set-Content -LiteralPath (Join-Path $OutDir 'deficit-part-B.txt') -Encoding UTF8
($parity | Sort-Object -Property @{Expression='MissingInRu'; Descending=$true} | ForEach-Object { ($_.Resource, ('neutral='+$_.Neutral), ('missing-in-ru='+$_.MissingInRu)) -join $TAB }) |
    Set-Content -LiteralPath (Join-Path $OutDir 'parity-gaps.txt') -Encoding UTF8

$totalRes = $matrix.Count
$resWithStrings = @($matrix | Where-Object { $_.Strings -gt 0 })
$coveredRes = @($matrix | Where-Object { $_.Covered })
$missingRes = @($matrix | Where-Object { -not $_.Covered })
$missingJetbrainsStrings = @($matrix | Where-Object { $_.Actionable })
$missingThirdParty = @($missingRes | Where-Object { $_.Owner -eq 'third-party' })
$missingEmptyContainers = @($missingRes | Where-Object { $_.Owner -eq 'JetBrains' -and $_.Strings -eq 0 })
$missingDataLegal = @($missingRes | Where-Object { $_.Kind -eq 'data/legal' })
$missingPkgMeta = @($missingRes | Where-Object { $_.Kind -eq 'package-meta' })
$sumActionStrings = 0; foreach ($a in $missingJetbrainsStrings) { $sumActionStrings += $a.Strings }
$sumDataLegalStrings = 0; foreach ($a in $missingDataLegal) { $sumDataLegalStrings += $a.Strings }

Write-Host ''
Write-Host '================ МАТРИЦА ПОКРЫТИЯ ================'
Write-Host "InstallDir:                $InstallDir"
Write-Host "DLL просканировано:         $($dlls.Count)  (нельзя загрузить: $loadFail)"
Write-Host "Нейтральных .resources:     $totalRes"
Write-Host "  со строками (>0):         $($resWithStrings.Count)"
Write-Host "Покрыто пакетом:            $($coveredRes.Count)"
Write-Host "Не покрыто:                 $($missingRes.Count)"
Write-Host "  сторонние (не перекрываются i18n): $($missingThirdParty.Count)"
Write-Host "  JetBrains-пустышки (0 строк):       $($missingEmptyContainers.Count)"
Write-Host "  JetBrains данные/легальные/паттерны:$($missingDataLegal.Count)  (строк всего: $sumDataLegalStrings)"
Write-Host "  метадата VSIX-пакета:               $($missingPkgMeta.Count)"
Write-Host "  ==> ПЕРЕВОДИМЫХ UI-таблиц со строками:$($missingJetbrainsStrings.Count)  (строк всего: $sumActionStrings)"
Write-Host "Паритет покрытых: ресурсов с отсутствующими в ru ключами: $($parity.Count)"
Write-Host ''
Write-Host "Разделено: part-A (я) = $($actA.Count), part-B (напарница) = $($actB.Count)"
Write-Host "Файлы: build/dll-coverage-matrix.tsv, build/deficit-part-A.txt, build/deficit-part-B.txt, build/parity-gaps.txt"
