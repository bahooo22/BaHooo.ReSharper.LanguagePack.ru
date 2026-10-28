#requires -Version 7
<#
.SYNOPSIS
    Деплой нашего перевода на standalone-приложения JetBrains (dotPeek/dotTrace/dotMemory/dotCover).
.DESCRIPTION
    Официальный механизм (вынесено декомпиляцией JetBrains.Platform.Shell.dll,
    пространство JetBrains.Application.I18n):
      - культура для standalone берётся ТОЛЬКО из JET_BACKEND_CULTURE
        (StandaloneCultureContextComponent не подключает CultureOptionsReader);
      - сателлиты ищутся как "<Set>.<culture>.resources" ПЛОСКО (GetChildFiles) в папках из
        JET_BACKEND_LOCALIZATION_FOLDERS — путь в base64(UTF8), несколько через ';';
      - Extensions\*\i18n работает только там, где есть ApplicationPackagesFiles (VS/ReSharper).
    Скрипт:
      1) зеркалит build\resources (*.resources) в локальную папку i18n-ru;
      2) для каждого найденного продукта пишет .bat-запускатель с двумя env-переменными.
#>
[CmdletBinding()]
param(
    [string]$InstallRoot = 'C:\Program Files (x86)\JetBrains\Installations',
    [string]$ResourcesDir = (Join-Path $PSScriptRoot 'resources'),
    [string]$TargetDir = (Join-Path $env:LOCALAPPDATA 'JetBrains\i18n-ru'),
    [string]$Culture = 'ru-RU'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath $ResourcesDir)) { throw "нет папки ресурсов: $ResourcesDir" }
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

$src = @(Get-ChildItem -LiteralPath $ResourcesDir -Filter '*.resources' -File)
if ($src.Count -eq 0) { throw 'в $ResourcesDir нет .resources' }
$dst = @(Get-ChildItem -LiteralPath $TargetDir -Filter '*.resources' -File)
Copy-Item -LiteralPath ($src.FullName) -Destination $TargetDir -Force
$dstNow = @(Get-ChildItem -LiteralPath $TargetDir -Filter '*.resources' -File)
Write-Host ("ресурсов: было {0} в источнике, в цели теперь {1}" -f $src.Count, $dstNow.Count)

$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($TargetDir))

# Номера волн в именах папок не захардкожены: продукты ищутся по фактическому содержимому
# $InstallRoot (dotPeek262, dotTrace263, …), иначе запускатели молча ломаются при каждом
# обновлении платформы — так и случилось с серией 261 после перехода на 2026.2.3.
$exeCandidates = [ordered]@{
    'dotCover'  = @('dotCover.UI.64.exe','dotCover.UI.64a.exe')
    'dotMemory' = @('dotMemory.UI.64.exe','dotMemory.UI.64a.exe')
    'dotPeek'   = @('dotPeek64.exe','dotPeek64a.exe')
    'dotTrace'  = @('dotTrace64.exe','dotTrace64a.exe','dotTrace.UI.64.exe','DotTraceLauncher.exe')
}
$launchers = Join-Path $TargetDir 'launchers'
New-Item -ItemType Directory -Path $launchers -Force | Out-Null

$installed = @(Get-ChildItem -LiteralPath $InstallRoot -Directory |
               Where-Object { $_.Name -match '^(dotCover|dotMemory|dotPeek|dotTrace)\d+$' } |
               Sort-Object Name)
if ($installed.Count -eq 0) { Write-Host "в $InstallRoot не найдено ни одного standalone-продукта" }

foreach ($d in $installed) {
    $base = $d.Name -replace '\d+$', ''
    $candidates = $exeCandidates[$base]
    if (-not $candidates) { Write-Host "пропущен (неизвестный продукт): $($d.Name)"; continue }
    $exe = $candidates | Where-Object { Test-Path -LiteralPath (Join-Path $d.FullName $_) } | Select-Object -First 1
    if (-not $exe) { Write-Host "пропущен (нет известного UI-exe): $($d.Name)"; continue }
    $bat = Join-Path $launchers ("ru-{0}.bat" -f $d.Name)
    @(
        '@echo off'
        'rem dotPeek/dotTrace/... на русском: культура + папка сателлитов (base64 пути)'
        ('set "JET_BACKEND_CULTURE={0}"' -f $Culture)
        ('set "JET_BACKEND_LOCALIZATION_FOLDERS={0}"' -f $b64)
        ('start "" "{0}" %*' -f (Join-Path $d.FullName $exe))
    ) | Set-Content -LiteralPath $bat -Encoding ASCII
    Write-Host "запускатель: $bat  ->  $($d.FullName)\$exe"
}

# Чистка запускателей от прежних волн: путь из .bat больше не существует на диске.
foreach ($old in @(Get-ChildItem -LiteralPath $launchers -Filter 'ru-*.bat' -File)) {
    $target = (Get-Content -LiteralPath $old.FullName |
               Where-Object { $_ -match '^\s*start\s+""\s+"(.+)"\s*%\*' } |
               ForEach-Object { $Matches[1] } | Select-Object -First 1)
    if ($target -and -not (Test-Path -LiteralPath $target)) {
        Remove-Item -LiteralPath $old.FullName -Force
        Write-Host "снят устаревший запускатель (путь не существует): $($old.Name) -> $target"
    }
}
Write-Host "`nВСЁ. Запускайте продукты через .bat из $launchers"
