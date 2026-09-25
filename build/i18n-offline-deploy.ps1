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

$productExes = [ordered]@{
    'dotCover261'  = @('dotCover.UI.64.exe','dotCover.UI.64a.exe')
    'dotMemory261' = @('dotMemory.UI.64.exe','dotMemory.UI.64a.exe')
    'dotPeek261'   = @('dotPeek64.exe','dotPeek64a.exe')
    'dotTrace261'  = @('dotTrace64.exe','dotTrace64a.exe','dotTrace.UI.64.exe','DotTraceLauncher.exe')
}
$launchers = Join-Path $TargetDir 'launchers'
New-Item -ItemType Directory -Path $launchers -Force | Out-Null

foreach ($prod in $productExes.Keys) {
    $dir = Join-Path $InstallRoot $prod
    if (-not (Test-Path -LiteralPath $dir)) { Write-Host "пропущен (нет папки): $prod"; continue }
    $exe = $productExes[$prod] | Where-Object { Test-Path -LiteralPath (Join-Path $dir $_) } | Select-Object -First 1
    if (-not $exe) { Write-Host "пропущен (нет известного UI-exe): $prod"; continue }
    $bat = Join-Path $launchers ("ru-{0}.bat" -f $prod)
    @(
        '@echo off'
        'rem dotPeek/dotTrace/... на русском: культура + папка сателлитов (base64 пути)'
        ('set "JET_BACKEND_CULTURE={0}"' -f $Culture)
        ('set "JET_BACKEND_LOCALIZATION_FOLDERS={0}"' -f $b64)
        ('start "" "{0}" %*' -f (Join-Path $dir $exe))
    ) | Set-Content -LiteralPath $bat -Encoding ASCII
    Write-Host "запускатель: $bat  ->  $dir\$exe"
}
Write-Host "`nВСЁ. Запускайте продукты через .bat из $launchers"
