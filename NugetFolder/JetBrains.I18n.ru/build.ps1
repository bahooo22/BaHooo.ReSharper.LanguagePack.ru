<# build.ps1
Usage: .\build.ps1 [-Configuration Release] [-Version 2025.11.27] [-Output artifacts]
#>
param(
    [string]$Configuration = 'Release',
    [string]$Version,
    [string]$Output = 'artifacts'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Путь к директории скрипта (работает независимо от текущей рабочей директории)
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Нормализуем путь к выходной папке (относительно скрипта, если не абсолютный)
if (-not [System.IO.Path]::IsPathRooted($Output)) {
    $Output = Join-Path $scriptDir $Output
}

# Путь к nuspec-файлу (в каталоге скрипта)
$nuspecPath = Join-Path $scriptDir 'BaHooo.ReSharper.I18n.ru.nuspec'

if (-not (Test-Path $nuspecPath)) {
    throw "Файл nuspec не найден: $nuspecPath"
}

# Если версия не передана параметром, берём её из nuspec
if (-not $Version) {
    $nuspecText = Get-Content $nuspecPath -Raw
    $match = [Regex]::Match($nuspecText, '<version>(.*?)</version>', 'IgnoreCase')
    if ($match.Success) {
        $Version = $match.Groups[1].Value
    }
    else {
        throw "Не удалось извлечь версию из nuspec"
    }
}

Write-Host "Building JetBrains.I18n.ru language pack (version $Version)"
Write-Host "Script directory: $scriptDir"
Write-Host "Nuspec path: $nuspecPath"
Write-Host "Output directory: $Output"

# Ensure artifacts folder
if (-not (Test-Path $Output)) {
    New-Item -ItemType Directory -Path $Output | Out-Null
}

# Резервная копия nuspec (на случай)
$backupNuspec = "$nuspecPath.bak"
if (-not (Test-Path $backupNuspec)) {
    Copy-Item $nuspecPath $backupNuspec -Force
    Write-Host "Backup created: $backupNuspec"
}

# Update nuspec version (простая замена)
$nuspecText = Get-Content $nuspecPath -Raw
$nuspecText = [Regex]::Replace($nuspecText, '<version>.*?</version>', "<version>$Version</version>", 'IgnoreCase')
$nuspecText | Set-Content $nuspecPath -Encoding utf8
Write-Host "Updated version in nuspec to $Version"

# Функция для запуска nuget pack
function Invoke-NuGetPack {
    param($nugetExe)

    Write-Host "Running: $nugetExe pack `"$nuspecPath`" -OutputDirectory `"$Output`" -NoDefaultExcludes"
    & $nugetExe pack $nuspecPath -OutputDirectory $Output -NoDefaultExcludes
    if ($LASTEXITCODE -ne 0) {
        throw "nuget pack вернул код $LASTEXITCODE"
    }
}

# Попытка найти nuget в PATH
$nugetCmd = Get-Command nuget -ErrorAction SilentlyContinue

if ($nugetCmd) {
    Invoke-NuGetPack $nugetCmd.Source
}
else {
    Write-Host "nuget.exe не найден в PATH. Попытка скачать nuget.exe..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $tmp = Join-Path $env:TEMP 'nuget.exe'
        $nugetUrl = 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe'
        Invoke-WebRequest -Uri $nugetUrl -OutFile $tmp -UseBasicParsing -ErrorAction Stop
        Write-Host "nuget.exe скачан в $tmp"
        Invoke-NuGetPack $tmp
    }
    catch {
        Write-Host "Не удалось скачать или запустить nuget.exe: $($_.Exception.Message)"
        Write-Host "Пробуем альтернативный путь: если в каталоге есть .csproj, попробуем dotnet pack для проекта."
        # Поиск csproj в той же папке (или в подпапках)
        $csproj = Get-ChildItem -Path $scriptDir -Filter *.csproj -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($csproj) {
            Write-Host "Найден проект: $($csproj.FullName). Выполняем dotnet pack..."
            & dotnet pack $csproj.FullName -c $Configuration -o $Output /p:PackageVersion=$Version
            if ($LASTEXITCODE -ne 0) {
                throw "dotnet pack вернул код $LASTEXITCODE"
            }
        }
        else {
            throw "nuget.exe не доступен и .csproj не найден. Невозможно упаковать .nuspec без nuget.exe."
        }
    }
}

# Выведем результат
$created = Get-ChildItem -Path $Output -Filter '*.nupkg' -File -ErrorAction SilentlyContinue
if ($created -and ($created | Measure-Object).Count -gt 0) {
    Write-Host "Package(s) created:"
    $created | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Не найдено созданных .nupkg в $Output"
    throw "Упаковка завершилась без создания .nupkg"
}