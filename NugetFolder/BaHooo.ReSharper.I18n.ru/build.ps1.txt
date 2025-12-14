<# build.ps1
Usage: .\build.ps1 [-Configuration Release] [-Version 2025.12.06] [-Output artifacts]
#>
param(
    [string]$Configuration = 'Release',
    [string]$Version,
    [string]$Output = 'artifacts',
    [switch]$Help,
    [alias("h")][switch]$HelpAlias
)

# Проверяем запрос помощи
if ($Help -or $HelpAlias) {
    Show-Help
    exit 0
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Путь к директории скрипта
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }

# Путь к корню проекта
$projectRoot = Join-Path $scriptDir '..\..'

# Нормализуем путь к выходной папке
if (-not [System.IO.Path]::IsPathRooted($Output)) {
    $Output = Join-Path $scriptDir $Output
}

# Путь к nuspec
$nuspecPath = Join-Path $scriptDir 'BaHooo.ReSharper.I18n.ru.nuspec'
if (-not (Test-Path $nuspecPath)) {
    throw "Файл nuspec не найден: $nuspecPath"
}

# Путь к папке с ресурсами
$resourcesSource = Join-Path $projectRoot 'build\resources'

# Основная логика
Write-Host "`n=== Сборка пакета ===" -ForegroundColor Cyan

# Если версия не передана — берём из nuspec
if (-not $Version) {
    $nuspecText = Get-Content $nuspecPath -Raw
    if ($nuspecText -match '<version>(.*?)</version>') {
        $Version = $Matches[1]
        Write-Host "Используется версия из nuspec: $Version" -ForegroundColor Cyan
    } else {
        $Version = (Get-Date -Format 'yyyy.MM.dd')
        Write-Host "Версия не найдена в nuspec, использую дату: $Version" -ForegroundColor Yellow
    }
} else {
    # Обновляем версию в nuspec если указана явно
    $nuspecContent = Get-Content $nuspecPath -Raw
    $oldVersion = ''
    
    if ($nuspecContent -match '<version>(.*?)</version>') {
        $oldVersion = $Matches[1]
    }
    
    $nuspecContent = $nuspecContent -replace '<version>.*?</version>', "<version>$Version</version>"
    $nuspecContent | Out-File $nuspecPath -Encoding UTF8 -Force
    
    if ($oldVersion) {
        Write-Host "Версия в nuspec обновлена: $oldVersion → $Version" -ForegroundColor Green
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
Copy-Item $nuspecPath $backupNuspec -Force -ErrorAction SilentlyContinue
Write-Host "Backup created: $backupNuspec"

# Копируем .resources из общей папки build/resources
$resourcesTarget = Join-Path $scriptDir 'DotFiles\Extensions\BaHooo.ReSharper.I18n.ru\i18n'

if (-not (Test-Path $resourcesTarget)) {
    New-Item -ItemType Directory -Path $resourcesTarget -Force | Out-Null
}

Write-Host "Copying resources from $resourcesSource to $resourcesTarget"

# Проверяем, есть ли файлы для копирования
if (Test-Path $resourcesSource) {
    $resourceFiles = Get-ChildItem -Path $resourcesSource -Filter '*.resources' -File
    if ($resourceFiles.Count -gt 0) {
        Copy-Item "$resourcesSource\*.resources" $resourcesTarget -Force
        Write-Host "Скопировано $($resourceFiles.Count) .resources файлов" -ForegroundColor Green
    } else {
        Write-Host "Внимание: Нет .resources файлов для копирования!" -ForegroundColor Yellow
    }
} else {
    Write-Host "Внимание: Папка с ресурсами не найдена: $resourcesSource" -ForegroundColor Yellow
}

# Функция упаковки
function Invoke-NuGetPack {
    param($nugetExe)

    Write-Host "`n=== Создание NuGet пакета ===" -ForegroundColor Cyan
    Write-Host "Running: $nugetExe pack `"$nuspecPath`" -OutputDirectory `"$Output`" -NoDefaultExcludes"
    
    & $nugetExe pack $nuspecPath -OutputDirectory $Output -NoDefaultExcludes
    if ($LASTEXITCODE -ne 0) {
        throw "nuget pack вернул код $LASTEXITCODE"
    }
}

# Ищем nuget.exe
$nugetCmd = Get-Command nuget -ErrorAction SilentlyContinue
if ($nugetCmd) {
    Write-Host "Используется nuget.exe из: $($nugetCmd.Source)" -ForegroundColor Gray
    Invoke-NuGetPack $nugetCmd.Source
} else {
    # Вместо поиска .csproj, просто сообщаем об ошибке
    Write-Host "ОШИБКА: nuget.exe не найден в PATH!" -ForegroundColor Red
    Write-Host "Пожалуйста, установите NuGet или добавьте его в переменную PATH." -ForegroundColor Yellow
    Write-Host "Можно скачать с: https://www.nuget.org/downloads" -ForegroundColor Yellow
    Write-Host "Или установить через: winget install Microsoft.NuGet" -ForegroundColor Yellow
    throw "nuget.exe не найден, упаковка невозможна."
}

# Проверяем результат
$created = Get-ChildItem -Path $Output -Filter '*.nupkg' -File -ErrorAction SilentlyContinue
if ($created -and ($created | Measure-Object).Count -gt 0) {
    Write-Host "`n=== Пакеты успешно созданы ===" -ForegroundColor Green
    $created | ForEach-Object { 
        Write-Host "  ✓ $($_.Name)" -ForegroundColor Green 
    }
    
    # Очистка ненужных .resources после успешной упаковки
    Write-Host "`nОчистка временных файлов..." -ForegroundColor Gray
    if (Test-Path $resourcesTarget) {
        Remove-Item "$resourcesTarget\*.resources" -Force -ErrorAction SilentlyContinue
        Write-Host "Временные .resources файлы удалены" -ForegroundColor Gray
    }
    
    Write-Host "`n=== Сборка успешно завершена! ===" -ForegroundColor Green
} else {
    Write-Host "Не найдено созданных .nupkg в $Output" -ForegroundColor Red
    throw "Упаковка завершилась без создания .nupkg"
}

function Show-Help {
    Write-Host @"
ИСПОЛЬЗОВАНИЕ:
    .\build.ps1 [ПАРАМЕТРЫ]

ПАРАМЕТРЫ:
    -Configuration <config>     Конфигурация сборки (по умолчанию: Release)
    -Version <версия>           Версия пакета (например: 2025.3.0.4)
    -Output <путь>              Папка для выходных файлов (по умолчанию: artifacts)
    -Help, -h                   Показать эту справку

ОПИСАНИЕ:
    Скрипт для сборки пакета BaHooo.ReSharper.I18n.ru.
    Использует .nuspec файл для создания NuGet пакета.
    Для работы требуется наличие nuget.exe в системе PATH.

ТРЕБОВАНИЯ:
    - NuGet CLI (nuget.exe) должен быть установлен и доступен в PATH
    - Можно скачать с: https://www.nuget.org/downloads
    - Или установить через: winget install Microsoft.NuGet

ПРИМЕРЫ:
    .\build.ps1                    # Сборка с текущей версией
    .\build.ps1 -Version "2025.3.0.5"  # Сборка с указанной версией
    .\build.ps1 -Output "C:\packages"  # Сборка в указанную папку
    .\build.ps1 -Help              # Показать справку

КОМАНДА ПАКЕТИРОВАНИЯ:
    nuget pack "BaHooo.ReSharper.I18n.ru.nuspec" -OutputDirectory "artifacts" -NoDefaultExcludes

ПУТИ:
    Скрипт использует следующие пути (относительно своего расположения):
    - .nuspec файл:              BaHooo.ReSharper.I18n.ru.nuspec
    - Ресурсы:                   ..\..\build\resources
    - Выходная папка:            artifacts (по умолчанию)
    - Временные ресурсы:         DotFiles\Extensions\BaHooo.ReSharper.I18n.ru\i18n
"@
}
