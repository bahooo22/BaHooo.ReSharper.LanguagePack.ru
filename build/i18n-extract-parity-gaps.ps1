# Извлечение НЕдостающих ключей по build/parity-gaps.txt: нейтральные значения из DLL установки
# против того, что уже есть в наших .resx. Выход — JSON для перевода (батчев).
#
# Зачем отдельный скрипт: i18n-extract-missing.ps1 выгружал полные таблицы 7 ДЕФИЦИТНЫХ ресурсов
# (тех, которых у нас не было вовсе). Здесь задача обратная — таблицы уже покрыты, но обновление
# платформы добавило в них несколько ключей, и выгружать ради них всю таблицу (3855 строк в
# Daemon.CSharp) значит раздуть вход перевода в сотни раз.
#requires -Version 5
param(
    [string]$InstallDir,
    [string]$ResxFolder = (Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU'),
    [string]$GapsFile   = (Join-Path $PSScriptRoot 'parity-gaps.txt'),
    [string]$MatrixFile = (Join-Path $PSScriptRoot 'dll-coverage-matrix.tsv'),
    [string]$OutJson    = (Join-Path $PSScriptRoot 'parity-gap-strings.json')
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'i18n-install.psm1')
$InstallDir = Resolve-InstallDir $InstallDir

if (-not (Test-Path -LiteralPath $GapsFile))   { throw "нет файла дефицита ключей: $GapsFile" }
if (-not (Test-Path -LiteralPath $MatrixFile)) { throw "нет матрицы: $MatrixFile" }

# Таблица -> DLL берётся из матрицы (колонки: Dll, Resource, Strings, Covered, Owner, Actionable)
$dllOfResource = @{}
foreach ($line in Get-Content -LiteralPath $MatrixFile) {
    $c = $line -split "`t"
    if ($c.Count -ge 2) { $dllOfResource[$c[1]] = $c[0] }
}

$result = @()
foreach ($line in Get-Content -LiteralPath $GapsFile) {
    if (-not $line.Trim()) { continue }
    $c = $line -split "`t"
    $res = $c[0]
    $dll = $dllOfResource[$res]
    if (-not $dll) { Write-Host "пропущен (нет DLL в матрице): $res"; continue }
    $dllPath = Join-Path $InstallDir $dll
    if (-not (Test-Path -LiteralPath $dllPath)) { Write-Host "пропущен (DLL не найдена): $dll"; continue }

    $ruPath = Join-Path $ResxFolder ("{0}.ru-RU.resx" -f $res)
    if (-not (Test-Path -LiteralPath $ruPath)) { Write-Host "пропущен (нет нашего resx): $res"; continue }
    [xml]$ru = Get-Content -LiteralPath $ruPath -Raw -Encoding UTF8
    # Имена берутся через SelectNodes, а не через $ru.resource.data: адаптер PowerShell к XML
    # на resx отдаёт пусто (в нём xsd-схема внутри <root>), и наивное обращение молча давало
    # «недостающими» ВСЕ нейтральные ключи — 5399 вместо реальных 28.
    $haveKeys = @{}
    foreach ($d in $ru.SelectNodes('//data')) { $haveKeys[$d.GetAttribute('name')] = $true }

    $asm = [System.Reflection.Assembly]::LoadFile($dllPath)
    $streamName = "$res.resources"
    $stream = $asm.GetManifestResourceStream($streamName)
    if (-not $stream) { Write-Host "пропущен (нет потока $streamName в $dll)"; continue }
    $reader = New-Object System.Resources.ResourceReader($stream)
    $missing = @()
    foreach ($entry in $reader) {
        if ($entry.Value -isnot [string]) { continue }
        if (-not $haveKeys.ContainsKey($entry.Key)) {
            $missing += [pscustomobject]@{ Key = $entry.Key; En = $entry.Value }
        }
    }
    $reader.Close(); $stream.Close()

    Write-Host ("{0}: DLL={1} нейтральных={2} недостающих={3}" -f $res, $dll, ([int]$c[1].Split('=')[1]), $missing.Count)
    if ($missing.Count -gt 0) {
        $result += [pscustomobject]@{
            Resource = $res
            ResxFile = ("{0}.ru-RU.resx" -f $res)
            Dll      = $dll
            Missing  = $missing
        }
    }
}

$json = ConvertTo-Json $result -Depth 5
[System.IO.File]::WriteAllText($OutJson, $json, (New-Object System.Text.UTF8Encoding($false)))
$total = ($result | ForEach-Object { $_.Missing.Count } | Measure-Object -Sum).Sum
Write-Host ("итого таблиц с пробелами: {0}, ключей: {1}; JSON: {2}" -f $result.Count, $total, $OutJson)
