<# build.ps1
Usage: .\build.ps1 [-Configuration Release] [-Version 2025.12.06] [-Output artifacts]
#>
param(
    [string]$Configuration = 'Release',
    [string]$Version,
    [string]$Output = 'artifacts'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Путь к директории скрипта
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Нормализуем путь к выходной папке
if (-not [System.IO.Path]::IsPathRooted($Output)) {
    $Output = Join-Path $scriptDir $Output
}

# Путь к nuspec
$nuspecPath = Join-Path $scriptDir 'BaHooo.ReSharper.I18n.ru.nuspec'
if (-not (Test-Path $nuspecPath)) {
    throw "Файл nuspec не найден: $nuspecPath"
}

# Если версия не передана — берём из nuspec
if (-not $Version) {
    $nuspecText = Get-Content $nuspecPath -Raw
    $match = [Regex]::Match($nuspecText, '<version>(.*?)</version>', 'IgnoreCase')
    if ($match.Success) {
        $Version = $match.Groups[1].Value
    } else {
        throw "Не удалось извлечь версию из nuspec"
    }
}

Write-Host "Building BaHooo.ReSharper.I18n.ru (version $Version)"
Write-Host "Script directory: $scriptDir"
Write-Host "Nuspec path: $nuspecPath"
Write-Host "Output directory: $Output"

# Ensure artifacts folder
if (-not (Test-Path $Output)) {
    New-Item -ItemType Directory -Path $Output | Out-Null
}

# Резервная копия nuspec
$backupNuspec = "$nuspecPath.bak"
if (-not (Test-Path $backupNuspec)) {
    Copy-Item $nuspecPath $backupNuspec -Force
    Write-Host "Backup created: $backupNuspec"
}

# Читаем версию из nuspec
$nuspecText = Get-Content $nuspecPath -Raw
$match = [Regex]::Match($nuspecText, '<version>(.*?)</version>', 'IgnoreCase')

if ($match.Success) {
    $Version = $match.Groups[1].Value
    Write-Host "Using version from nuspec: $Version"
} else {
    # Если не удалось извлечь — используем дату
    $Version = (Get-Date -Format 'yyyy.MM.dd')
    Write-Host "Version not found in nuspec, using date: $Version"
}


# Копируем .resources из общей папки build/resources
$resourcesSource = Join-Path $scriptDir '..\..\build\resources'
$resourcesTarget = Join-Path $scriptDir 'DotFiles\Extensions\BaHooo.ReSharper.I18n.ru\i18n'

if (-not (Test-Path $resourcesTarget)) {
    New-Item -ItemType Directory -Path $resourcesTarget -Force | Out-Null
}

Write-Host "Copying resources from $resourcesSource to $resourcesTarget"
Copy-Item "$resourcesSource\*.resources" $resourcesTarget -Force

# Функция упаковки
function Invoke-NuGetPack {
    param($nugetExe)

    Write-Host "Running: $nugetExe pack `"$nuspecPath`" -OutputDirectory `"$Output`" -NoDefaultExcludes"
    & $nugetExe pack $nuspecPath -OutputDirectory $Output -NoDefaultExcludes
    if ($LASTEXITCODE -ne 0) {
        throw "nuget pack вернул код $LASTEXITCODE"
    }
}

# Ищем nuget.exe
$nugetCmd = Get-Command nuget -ErrorAction SilentlyContinue
if ($nugetCmd) {
    Invoke-NuGetPack $nugetCmd.Source
} else {
    Write-Host "nuget.exe не найден в PATH, пробуем dotnet pack..."
    $csproj = Get-ChildItem -Path $scriptDir -Filter *.csproj -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($csproj) {
        & dotnet pack $csproj.FullName -c $Configuration -o $Output /p:PackageVersion=$Version
        if ($LASTEXITCODE -ne 0) {
            throw "dotnet pack вернул код $LASTEXITCODE"
        }
    } else {
        throw "nuget.exe и .csproj не найдены, упаковка невозможна."
    }
}

# Проверяем результат
$created = Get-ChildItem -Path $Output -Filter '*.nupkg' -File -ErrorAction SilentlyContinue
if ($created -and ($created | Measure-Object).Count -gt 0) {
    Write-Host "Package(s) created:"
    $created | ForEach-Object { Write-Host $_ }

    # Очистка ненужных .resources после успешной упаковки
    Write-Host "Cleaning up temporary .resources files..."
    Remove-Item "$resourcesTarget\*.resources" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Не найдено созданных .nupkg в $Output"
    throw "Упаковка завершилась без создания .nupkg"
}
