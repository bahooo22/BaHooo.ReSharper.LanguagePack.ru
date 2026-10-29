#requires -Version 7
<#
.SYNOPSIS
    Деплой скомпилированных .resources из build\resources в оба живых каталога перевода.
.DESCRIPTION
    Живых каталога два, и они обновляются разными механизмами:
      1) оффлайн-папка `%LOCALAPPDATA%\JetBrains\i18n-ru` — её читают standalone-продукты
         через JET_BACKEND_LOCALIZATION_FOLDERS (см. i18n-offline-deploy.ps1);
      2) `Extensions\BaHooo.ReSharper.I18n.ru\i18n` внутри каталога установки ReSharper —
         канал Visual Studio.
    Скрипт идемпотентен: копирует только файлы, чей SHA-256 отличается от эталона, и печатает
    сверку по каждой цели (всего/отсутствует/лишних/расхождений). Отдельно проверяет About-строку
    в обеих version-bearing таблицах: версия пакета, донат-канал и адреса из `.github\wallets.md`
    (сверяются побайтово с носителем, а не с захардкоженными строками).

    Если файл держит запущенная Visual Studio, держатель обычно открывает его на чтение БЕЗ
    FileShare.Write: Copy-Item и запись через FileStream отказывают одним и тем же IOException,
    а чтение с FileShare.ReadWrite проходит. Скрипт различает этот случай и печатает имена
    процессов вместо общего «не удалось», потому что лечение здесь одно — закрыть VS и повторить.
.OUTPUTS
    Код возврата 0, если обе цели содержат полный набор без расхождений; иначе 1.
#>
[CmdletBinding()]
param(
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    # По умолчанию версия берётся из nuspec, чтобы скрипт не устаревал при следующем bump'е.
    [string]$Version,
    [string]$OfflineDir = (Join-Path $env:LOCALAPPDATA 'JetBrains\i18n-ru'),
    [string]$InstallDir
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'i18n-install.psm1') -Force

$resourcesDir = Join-Path $Root 'build\resources'
if (-not (Test-Path -LiteralPath $resourcesDir)) { throw "нет папки ресурсов: $resourcesDir" }

$sha = [System.Security.Cryptography.SHA256]::Create()
function Get-HashOf([string]$path) {
    (($sha.ComputeHash([System.IO.File]::ReadAllBytes($path))) | ForEach-Object { $_.ToString('x2') }) -join ''
}

if (-not $Version) {
    $nuspec = Join-Path $Root 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
    if (-not (Test-Path -LiteralPath $nuspec)) { throw "нет nuspec для определения версии: $nuspec" }
    $raw = Get-Content -LiteralPath $nuspec -Raw -Encoding UTF8
    $Version = [regex]::Match($raw, '<version>(.*?)</version>').Groups[1].Value
    if (-not $Version) { throw "в nuspec не найден <version>" }
}
Write-Host "версия пакета: $Version"

# Реквизиты — из их единственного носителя.
$walletsPath = Join-Path $Root '.github\wallets.md'
$wallets = @()
if (Test-Path -LiteralPath $walletsPath) {
    $wtext = Get-Content -LiteralPath $walletsPath -Raw -Encoding UTF8
    $bt = [char]96
    foreach ($m in [regex]::Matches($wtext, '\|[^|]+\| ' + $bt + '([^' + $bt + ']+)' + $bt)) {
        $wallets += $m.Groups[1].Value
    }
    # Файл двуязычный: одна и та же таблица адресов встречается в RU- и EN-блоке.
    $wallets = @($wallets | Select-Object -Unique)
}
Write-Host ("адресов из .github\wallets.md: {0}" -f $wallets.Count)

$src = @{}
foreach ($f in Get-ChildItem -LiteralPath $resourcesDir -Filter '*.resources' -File) { $src[$f.Name] = Get-HashOf $f.FullName }
Write-Host ("эталон build\resources: {0} файлов" -f $src.Count)

$install = Resolve-InstallDir $InstallDir
$targets = [ordered]@{
    'оффлайн'   = $OfflineDir
    'VS-канал' = (Join-Path $install 'Extensions\BaHooo.ReSharper.I18n.ru\i18n')
}

$aboutTables = @(
    'JetBrains.UI.Resources.Strings.ru-RU.resources',
    'JetBrains.UI.Avalonia.Resources.Strings.ru-RU.resources'
)

function Report-BlockedFile([string]$path) {
    $holders = @(Get-Process | Where-Object { $_.ProcessName -match 'devenv|ReSharper|ServiceHub' })
    if ($holders.Count -gt 0) {
        $names = ($holders | ForEach-Object { "{0} (Id {1})" -f $_.ProcessName, $_.Id }) -join ', '
        Write-Host "  файл держит процесс: $names"
        Write-Host '  лечение: закрыть Visual Studio и повторить этот же скрипт'
    } else {
        Write-Host '  процесс-держатель не определён (devenv/ReSharper/ServiceHub не запущены)'
    }
}

# Провалы считаются отдельно от списка проблемных целей: одна цель может дать несколько
# провалов (расхождение ресурсов + About без адресов), а в итоге важно, какие именно цели не готовы.
$fail = 0
$badTargets = @()
function Add-BadTarget([string]$label) { if ($script:badTargets -notcontains $label) { $script:badTargets += $label } }

foreach ($label in $targets.Keys) {
    $t = $targets[$label]
    Write-Host ''
    Write-Host "цель [$label]: $t"
    if (-not (Test-Path -LiteralPath $t)) {
        Write-Host '  НЕТ ПУТИ — пропущено'
        $fail++
        Add-BadTarget $label
        continue
    }

    $copied = 0; $skipped = 0; $blocked = @()
    foreach ($name in $src.Keys) {
        $dst = Join-Path $t $name
        if ((Test-Path -LiteralPath $dst) -and ((Get-HashOf $dst) -eq $src[$name])) { $skipped++; continue }
        try {
            Copy-Item -LiteralPath (Join-Path $resourcesDir $name) -Destination $dst -Force -ErrorAction Stop
            $copied++
        } catch [System.IO.IOException] {
            $blocked += $name
        }
    }
    foreach ($name in $blocked) {
        Write-Host "  ОТКАЗ ЗАПИСИ: $name"
        Report-BlockedFile (Join-Path $t $name)
    }

    $live = @{}
    foreach ($f in Get-ChildItem -LiteralPath $t -Filter '*.resources' -File) { $live[$f.Name] = Get-HashOf $f.FullName }
    $miss  = @($src.Keys  | Where-Object { -not $live.ContainsKey($_) })
    $extra = @($live.Keys | Where-Object { -not $src.ContainsKey($_) })
    $diff  = @($live.Keys | Where-Object { $src.ContainsKey($_) -and $live[$_] -ne $src[$_] })
    Write-Host ("  скопировано={0} уже совпадало={1} заблокировано={2} | всего={3} отсутствует={4} лишних={5} расхождений={6}" -f `
        $copied, $skipped, $blocked.Count, $live.Count, $miss.Count, $extra.Count, $diff.Count)
    if ($miss.Count -gt 0) { $miss | ForEach-Object { Write-Host "    отсутствует: $_" } }
    if ($extra.Count -gt 0) { $extra | ForEach-Object { Write-Host "    лишнее: $_" } }
    if ($diff.Count -gt 0) { $diff | ForEach-Object { Write-Host "    расхождение: $_" } }
    if (($miss.Count + $extra.Count + $diff.Count + $blocked.Count) -ne 0) { $fail++; Add-BadTarget $label }

    foreach ($table in $aboutTables) {
        $p = Join-Path $t $table
        if (-not (Test-Path -LiteralPath $p)) { Write-Host "  нет About-таблицы: $table"; $fail++; Add-BadTarget $label; continue }
        $txt = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($p))
        $okVer = $txt.Contains("v. $Version")
        $okDonate = $txt.Contains('donationalerts.com/r/bahooo')
        $okWallets = $true
        foreach ($w in $wallets) { if (-not $txt.Contains($w)) { $okWallets = $false } }
        Write-Host ("  {0}: версия {1} | донат {2} | адреса wallets.md {3}" -f $table, $okVer, $okDonate, $okWallets)
        if (-not ($okVer -and $okDonate -and $okWallets)) { $fail++; Add-BadTarget $label }
    }
}

Write-Host ''
if ($fail -eq 0) {
    Write-Host 'ИТОГ: обе цели полны, расхождений нет'
    exit 0
} else {
    Write-Host ("ИТОГ: провалов = {0}; цели, которые не готовы: {1}" -f $fail, ($badTargets -join ', '))
    exit 1
}
