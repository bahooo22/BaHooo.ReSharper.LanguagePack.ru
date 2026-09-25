#requires -Version 7
<#
.SYNOPSIS
    Полный смысловой скан перевода: каждая пара en(neutral из DLL) <-> ru(resx) попадает
    в именованную категорию-кандидат на дефект, с ПОЛНЫМИ значениями для живого просмотра.
.DESCRIPTION
    Отличия от i18n-verify-translations.ps1:
      - verify считает статистику и печатает только индексы плейсхолдеров;
      - этот сканер печатает сами тексты и разбивает по категориям-эвристикам:
        A  ru без кириллицы (ru==en либо англ. калька с правкой регистра/пунктуации)
        B1 ru ссылается на {N}, которого нет в en -> гарантированный падёж string.Format
        B2 наборы индексов различаются, но ru не выход за границы (потеря/дубль аргумента)
        C  ru «зашил» латинский литерал в кавычках, которого нет в en (в en на его месте {N})
        D в ru целая англоязычная цепочка из >=4 слов подряд (фрагмент непереведённого текста)
    Таблицы без neutral в этой установке в CAT-0 (не проверяемо) — их список в конце.
    Выход: build/semantic-scan-<date>.txt, категории отсортированы, значения в ||кавчках.
#>
[CmdletBinding()]
param(
    [string]$InstallDir,
    [string]$ResxFolder,
    [string]$OutPath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $InstallDir) {
    $roots = @((Join-Path ${env:ProgramFiles(x86)} 'JetBrains\Installations'),
               "$env:LOCALAPPDATA\JetBrains\Installations") |
             Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    $InstallDir = $(foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -Directory -Filter 'ReSharperPlatform*' -ErrorAction SilentlyContinue
    }) | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $ResxFolder) { $ResxFolder = Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU' }
if (-not $OutPath) { $OutPath = Join-Path $PSScriptRoot ("semantic-scan-{0:yyyy-MM-dd}.txt" -f (Get-Date)) }

$hasCyrillic = '[\u0400-\u04FF]'
$cjk = '[\u3000-\u303F\u3040-\u30FF\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\uFF00-\uFFEF]'

Write-Host "Установка: $InstallDir"
$needed = @{}
Get-ChildItem -LiteralPath $ResxFolder -Filter '*.ru-RU.resx' -File | ForEach-Object {
    $needed[($_.BaseName -replace '\.ru-RU$', '') + '.resources'] = $true
}
# 1. neutral-карты (однократно)
$neutral = @{}
Get-ChildItem -LiteralPath $InstallDir -Filter *.dll -File | ForEach-Object {
    try { $asm = [System.Reflection.Assembly]::LoadFile($_.FullName) } catch { return }
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
            } catch { } finally { $stream.Close() }
        }
    }
}
Write-Host ("neutral прочитано: {0} из {1}" -f $neutral.Count, $needed.Keys.Count)

function Get-PhSet([string]$Text) {
    @([regex]::Matches($Text, '\{(\d+)\}') | ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object -Unique)
}
function QuotedAscii([string]$Text) {
    # латинские литералы в одинарных/двойных кавычках или `backtick`, без {N} внутри
    $q = [char]39; $dq = [char]34; $bt = [char]96
    $body = '[A-Za-z][A-Za-z0-9 ./_+-]{1,30}'
    $pat  = "[$q$dq]($body)[$q$dq]|$bt($body)$bt"
    @([regex]::Matches($Text, $pat) |
       ForEach-Object { if ($_.Groups[1].Success) { $_.Groups[1].Value } else { $_.Groups[2].Value } })
}
# известные легальные английские цепочки в UI по-русски (термины и продукты)
$whitelist = @(
  'Visual Studio','Entity Framework','Model View Controller','Modern Business Services',
  'Universal Windows Platform','Windows Presentation Foundation','Language Integrated Query',
  'eXtensible Application Markup Language','Asp Net Core','Net Core','ReSharper Cpp',
  'Rider','JetBrains','NuGet','Node JS','Type Script','Java Script','Silver Light',
  'XUnit','Team Project','Task Group','Task List','Azure DevOps','Source Control'
)
function HasEnglishRun([string]$t) {
    # 4+ слова из латиницы подряд (каждое 2+ букв), не считая слов-кодов в кавычках
    $m = [regex]::Matches($t, '(?<![\w`"''])([A-Za-z][\w.-]*\s+){3,}[A-Za-z][\w.-]*(?![\w`"''])')
    foreach ($x in $m) {
        $run = $x.Value.Trim()
        $skip = $false
        foreach ($w in $whitelist) { if ($run -like "*$w*") { $skip = $true; break } }
        if (-not $skip) { return $run }
    }
    return $null
}

$catA = New-Object 'System.Collections.Generic.List[string]'
$catB1 = New-Object 'System.Collections.Generic.List[string]'
$catB2 = New-Object 'System.Collections.Generic.List[string]'
$catC = New-Object 'System.Collections.Generic.List[string]'
$catD = New-Object 'System.Collections.Generic.List[string]'
$cat0 = New-Object 'System.Collections.Generic.List[string]'
$statPairs = 0

foreach ($rf in @(Get-ChildItem -LiteralPath $ResxFolder -Filter '*.ru-RU.resx' -File | Sort-Object Name)) {
    $neutralName = ($rf.BaseName -replace '\.ru-RU$', '') + '.resources'
    $xml = New-Object System.Xml.XmlDocument
    $xml.Load($rf.FullName)
    $values = @{}
    foreach ($d in $xml.SelectNodes('//root/data')) {
        $v = $d.SelectSingleNode('value')
        $values[$d.name] = $(if ($v) { $v.InnerText } else { '' })
    }
    if (-not $neutral.ContainsKey($neutralName)) {
        $cat0.Add("$($rf.Name) — нейтрального ресурса нет в этой установке (записей: $($values.Keys.Count))")
        continue
    }
    $en = $neutral[$neutralName]
    $resTag = $rf.Name -replace '\.ru-RU\.resx$',''
    foreach ($k in @($values.Keys | Sort-Object)) {
        if (-not $en.ContainsKey($k)) { continue }
        $ruv = [string]$values[$k]; $env_ = [string]$en[$k]
        if ($ruv.Length -eq 0 -or $env_.Length -eq 0) { continue }
        $statPairs++
        $line = "$resTag | $k | EN: ||$env_|| | RU: ||$ruv||"
        $flagged = $false
        if ($ruv -notmatch $hasCyrillic) { $catA.Add($line); $flagged = $true }
        $enIdx = Get-PhSet $env_; $ruIdx = Get-PhSet $ruv
        $extra = @($ruIdx | Where-Object { $enIdx -notcontains $_ })
        if ($extra.Count -gt 0) { $catB1.Add($line + " || RU-индексы вне en: $($extra -join ',') (en: $($enIdx -join ','))"); $flagged = $true }
        elseif (@($enIdx | Where-Object { $ruIdx -notcontains $_ }).Count -gt 0) { $catB2.Add($line); $flagged = $true }
        # C: зашитый литерал в ru, которого нет в en (в en там, вероятно, {N})
        foreach ($q in (QuotedAscii $ruv | Sort-Object -Unique)) {
            if ($env_ -notlike "*$q*" -and $q -notmatch '[{}]') {
                $catC.Add($line + " || зашитый литерал RU: '$q'"); $flagged = $true; break
            }
        }
        if ($ruv -match $cjk) { $catB1.Add($line + ' || CJK') }
        if (-not $flagged) {
            $run = HasEnglishRun $ruv
            if ($run) { $catD.Add($line + " || англ. цепочка: «$run»") }
        }
    }
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("=== Полный смысловой скан перевода против $InstallDir ===")
[void]$sb.AppendLine("Пар en/ru просмотрено: $statPairs")
foreach ($sec in @(@('CAT-B1 — ПАДАЮЩИЙ string.Format / CJK (критично)', $catB1),
                   @('CAT-C — зашитый в ru литерал, отсутствующий в en (класс дефекта RefReadonly)', $catC),
                   @('CAT-B2 — ru теряет аргументы en (класс LicenseTo/EM_Model_Installed)', $catB2),
                   @('CAT-A — ru без кириллицы (ru==en или калька; класс SystemModulesConstants)', $catA),
                   @('CAT-D — английская цепочка 4+ слов внутри ru (возможен неперевод)', $catD),
                   @('CAT-0 — таблицы без neutral в этой установке', $cat0))) {
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("--- $($sec[0]) : $($sec[1].Count) ---")
    foreach ($l in $sec[1]) { [void]$sb.AppendLine($l) }
}
[System.IO.File]::WriteAllText($OutPath, $sb.ToString().Replace("`r`n","`n"), (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Отчёт: $OutPath"
Write-Host ("B1={0} C={1} B2={2} A={3} D={4} NO-NEUTRAL={5}" -f $catB1.Count,$catC.Count,$catB2.Count,$catA.Count,$catD.Count,$cat0.Count)
