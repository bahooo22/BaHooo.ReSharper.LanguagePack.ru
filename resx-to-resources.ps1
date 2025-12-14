param(
    [string]$ResxFolder = '.\raw-resx-done_ru-RU',
    [string]$ResourcesOutput = '.\build\resources',   # общая папка для .resources
    [string]$Version,
    [string]$LogFile = 'build.log',
    [string]$ErrorLogFile = 'build.errors.log',
    
    # Основные ключи
    [switch]$NoBuild,
    [alias("nb")][switch]$NoBuildAlias,  # Алиас для краткости
    
    [switch]$NoResgen,
    [alias("nr")][switch]$NoResgenAlias, # Пропустить генерацию .resources
    
    [switch]$BuildOnly,
    [alias("bo")][switch]$BuildOnlyAlias, # Только сборка (пропустить resgen)
    
    [switch]$SyncVersions,
    [alias("sv")][switch]$SyncVersionsAlias, # Синхронизировать версии
    
    # НОВЫЙ ПАРАМЕТР: Отключить автоинкремент версии
    [switch]$SkipVersionUpdate,
    [alias("svu")][switch]$SkipVersionUpdateAlias,
    
    # НОВЫЙ ПАРАМЕТР: Принудительная конвертация всех файлов
    [switch]$ForceAll,
    [alias("fa")][switch]$ForceAllAlias,
    
    [switch]$Help,
    [alias("h")][switch]$HelpAlias
)

$resgen = 'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe'
$HashesFile = ".\build\resx-hashes.json"  # Файл для хранения хэшей

function Show-Help {
    Write-Host @"
ИСПОЛЬЗОВАНИЕ:
    .\resx-to-resources.ps1 [ПАРАМЕТРЫ]

ПАРАМЕТРЫ:
    -ResxFolder <путь>          Папка с исходными .resx файлами (по умолчанию: .\raw-resx-done_ru-RU)
    -ResourcesOutput <путь>     Папка для сгенерированных .resources файлов (по умолчанию: .\build\resources)
    -Version <версия>           Версия сборки (по умолчанию: автоматическое определение)
    -LogFile <файл>             Файл лога (по умолчанию: build.log)
    -ErrorLogFile <файл>        Файл лога ошибок (по умолчанию: build.errors.log)
    
    -NoResgen, -nr              Пропустить генерацию .resources файлов
    -BuildOnly, -bo             Только сборка (пропустить генерацию .resources)
    -NoBuild, -nb               Только генерация .resources (пропустить сборку)
    -SyncVersions, -sv          Синхронизировать версии перед выполнением
    -SkipVersionUpdate, -svu    Отключить автоматическое обновление версии (для CI/CD)
    -ForceAll, -fa              Принудительная конвертация ВСЕХ .resx файлов (для CI/CD)
    
    -Help, -h                   Показать эту справку

ФУНКЦИОНАЛ ПРОВЕРКИ ИЗМЕНЕНИЙ:
    Скрипт автоматически отслеживает изменения в .resx файлах:
    - Сохраняет хэши SHA256 всех .resx файлов в .\build\resx-hashes.json
    - При запуске проверяет, были ли изменения с последней конвертации
    - Если изменений нет, предлагает пропустить этап конвертации
    - Конвертирует ТОЛЬКО изменившиеся или новые файлы
    - Удаленные файлы отмечаются, но не влияют на конвертацию

АВТОМАТИЧЕСКОЕ ОБНОВЛЕНИЕ ВЕРСИИ:
    При обнаружении изменений в .resx файлах скрипт автоматически:
    1. Инкрементирует версию (формат: 2025.3.0.4 → 2025.3.0.5)
    2. Обновляет версию в .nuspec файлах:
        - NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec
        - MarketplaceFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec
    3. Обновляет версию в .resx файлах:
        - raw-resx-done_ru-RU\JetBrains.UI.Avalonia.Resources.Strings.ru-RU.resx
        - raw-resx-done_ru-RU\JetBrains.UI.Resources.Strings.ru-RU.resx

СИНХРОНИЗАЦИЯ ВЕРСИЙ:
    Используйте параметр -SyncVersions для принудительной синхронизации всех версий
    перед выполнением конвертации или сборки.

ИСПОЛЬЗОВАНИЕ В CI/CD:
    Для GitHub Actions используйте параметры:
    .\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild
    Это гарантирует:
    - Конвертацию ВСЕХ .resx файлов (даже если хэш-файл сброшен)
    - Автоинкремент версии отключен
    - Только конвертация, сборка отдельно

ПРИМЕРЫ:
    ЛОКАЛЬНО (с автоинкрементом версии):
    .\resx-to-resources.ps1                          # Полный процесс: проверка → конвертация → сборка
    
    CI/CD (без автоинкремента):
    .\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild  # Только конвертация всех файлов
    
    Только сборка:
    .\resx-to-resources.ps1 -BuildOnly               # Только сборка (пропустить resgen)
    
    Только конвертация:
    .\resx-to-resources.ps1 -NoBuild                 # Только генерация .resources
    
    Краткие формы:
    .\resx-to-resources.ps1 -fa -svu -nb             # Для CI/CD
    .\resx-to-resources.ps1 -bo                      # Только сборка
    .\resx-to-resources.ps1 -nr                      # Пропустить resgen
    .\resx-to-resources.ps1 -sv                      # Синхронизация версий

РЕЖИМЫ РАБОТЫ:
    1. Без параметров:           проверка → resgen → сборка (полный процесс с автоинкрементом)
    2. -NoBuild (-nb):           проверка → resgen → остановка
    3. -BuildOnly (-bo):         проверка → сборка (пропуск resgen)
    4. -ForceAll -SkipVersionUpdate: CI/CD режим (все файлы, без инкремента версии)
"@
}

# Проверяем запрос помощи
if ($Help -or $HelpAlias) {
    Show-Help
    exit 0
}

# Импортируем модуль управления версиями
$modulePath = Join-Path $PSScriptRoot 'VersionManager.psm1'
if (Test-Path $modulePath) {
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-Host "Модуль VersionManager успешно загружен" -ForegroundColor Gray
    }
    catch {
        Write-Host "Ошибка при загрузке модуля VersionManager: $_" -ForegroundColor Red
        # Создаем минимальную реализацию функций на месте
        Initialize-FallbackVersionFunctions
    }
} else {
    Write-Host "Модуль VersionManager не найден: $modulePath" -ForegroundColor Red
    # Создаем минимальную реализацию функций на месте
    Initialize-FallbackVersionFunctions
}

# Функция для инициализации запасных функций версионирования
function Initialize-FallbackVersionFunctions {
    Write-Host "Инициализация запасных функций версионирования..." -ForegroundColor Yellow
    
    # Минимальная реализация Update-AllVersions
    function Update-AllVersions {
        param(
            [string]$ProjectRoot,
            [string]$NewVersion
        )
        
        Write-Host "Запасная функция Update-AllVersions: обновление версии пропущено" -ForegroundColor Yellow
        Write-Host "Используйте параметр -SyncVersions для полной синхронизации версий" -ForegroundColor Yellow
        
        return @{
            Version = "0.0.0.0"
            NuspecUpdated = 0
            ResxUpdated = 0
        }
    }
    
    # Минимальная реализация Sync-Versions
    function Sync-Versions {
        param(
            [string]$ProjectRoot,
            [switch]$Force
        )
        
        Write-Host "Запасная функция Sync-Versions: синхронизация версий пропущена" -ForegroundColor Yellow
        Write-Host "Пожалуйста, проверьте наличие файла VersionManager.psm1" -ForegroundColor Yellow
        
        return $false
    }
    
    # Минимальная реализация Get-CurrentVersion
    function Get-CurrentVersion {
        param([string]$ProjectRoot)
        
        return "0.0.0.0"
    }
}

# Определяем режимы работы
$skipBuild = $NoBuild -or $NoBuildAlias
$skipResgen = $NoResgen -or $NoResgenAlias
$buildOnly = $BuildOnly -or $BuildOnlyAlias
$syncVersions = $SyncVersions -or $SyncVersionsAlias
$skipVersionUpdate = $SkipVersionUpdate -or $SkipVersionUpdateAlias
$forceAll = $ForceAll -or $ForceAllAlias

# Проверка конфликтующих параметров
if ($skipBuild -and $buildOnly) {
    Write-Host "Ошибка: Параметры -NoBuild и -BuildOnly не могут быть использованы вместе!" -ForegroundColor Red
    Write-Host "Используйте один из них." -ForegroundColor Red
    exit 1
}

if ($skipResgen -and (-not $skipBuild) -and (-not $buildOnly)) {
    Write-Host "`nРежим: Пропуск генерации .resources, но выполнение сборки" -ForegroundColor Cyan
}

if ($buildOnly) {
    Write-Host "`nРежим: Только сборка (пропуск генерации .resources)" -ForegroundColor Cyan
    $skipResgen = $true
}

if ($syncVersions) {
    Write-Host "`nРежим: Синхронизация версий" -ForegroundColor Cyan
}

if ($skipVersionUpdate) {
    Write-Host "`nРежим: Автоматическое обновление версии отключено" -ForegroundColor Cyan
}

if ($forceAll) {
    Write-Host "`nРежим: Принудительная конвертация всех .resx файлов" -ForegroundColor Cyan
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Очистим старые логи
Remove-Item $LogFile, $ErrorLogFile -ErrorAction SilentlyContinue

# Функция для вычисления хэша файла
function Get-FileHashSafe($filePath) {
    if (Test-Path $filePath) {
        try {
            $hash = Get-FileHash -Path $filePath -Algorithm SHA256
            return $hash.Hash
        }
        catch {
            Write-Host "Ошибка вычисления хэша для ${filePath}: $_" -ForegroundColor Red
            return $null
        }
    }
    return $null
}

# Функция для проверки изменений с возвратом списка файлов для конвертации
function Get-FilesToConvert {
    param(
        [string]$ResxFolder,
        [string]$HashesFile
    )
    
    Write-Host "`n=== Проверка изменений в .resx файлах ===" -ForegroundColor Cyan
    
    # Создаем папку build если ее нет
    $buildDir = Split-Path $HashesFile -Parent
    if (-not (Test-Path $buildDir)) {
        New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    }
    
    # Загружаем предыдущие хэши
    $previousHashes = @{}
    if (Test-Path $HashesFile) {
        try {
            $previousHashes = Get-Content $HashesFile | ConvertFrom-Json -AsHashtable
            Write-Host "Загружено хэшей из кэша: $($previousHashes.Count)" -ForegroundColor Gray
        }
        catch {
            Write-Host "Не удалось загрузить кэш хэшей, создаем новый" -ForegroundColor Yellow
            $previousHashes = @{}
        }
    }
    
    # Получаем текущие файлы
$currentFiles = @(Get-ChildItem -Path $ResxFolder -Filter '*.resx' -Recurse -File -ErrorAction SilentlyContinue)

if ($currentFiles.Count -eq 0) {
        Write-Host "Не найдено .resx файлов в папке: $ResxFolder" -ForegroundColor Yellow
        return @{
            FilesToConvert = @()
            HasChanges = $true
            ChangedFiles = @()
            NewFiles = @()
            DeletedFiles = @()
            TotalFiles = 0
        }
    }
    
    # Собираем информацию о текущих файлах
    $currentHashes = @{}
    $changedFiles = @()
    $newFiles = @()
    $unchangedFiles = @()
    $deletedFiles = @()
    
    foreach ($file in $currentFiles) {
        $relativePath = $file.FullName.Substring((Resolve-Path $ResxFolder).Path.Length + 1)
        $currentHash = Get-FileHashSafe $file.FullName
        
        if ($currentHash) {
            $currentHashes[$relativePath] = @{
                Hash = $currentHash
                LastWriteTime = $file.LastWriteTime
                Size = $file.Length
                FullPath = $file.FullName
            }
            
            # Проверяем изменения
            if ($previousHashes.ContainsKey($relativePath)) {
                if ($previousHashes[$relativePath].Hash -ne $currentHash) {
                    $changedFiles += $file
                    Write-Host "[ИЗМЕНЕН] $relativePath" -ForegroundColor Yellow
                }
                else {
                    $unchangedFiles += $file
                }
            }
            else {
                $newFiles += $file
                Write-Host "[НОВЫЙ] $relativePath" -ForegroundColor Green
            }
        }
    }
    
    # Находим удаленные файлы
    foreach ($key in $previousHashes.Keys) {
        if (-not $currentHashes.ContainsKey($key)) {
            $deletedFiles += $key
            Write-Host "[УДАЛЕН] $key" -ForegroundColor Red
        }
    }
    
    # Файлы для конвертации: измененные + новые
    $filesToConvert = $changedFiles + $newFiles
    
    # Сохраняем новые хэши
    try {
        # Удаляем информацию о полном пути перед сохранением
        $hashesToSave = @{}
        foreach ($key in $currentHashes.Keys) {
            $hashesToSave[$key] = @{
                Hash = $currentHashes[$key].Hash
                LastWriteTime = $currentHashes[$key].LastWriteTime
                Size = $currentHashes[$key].Size
            }
        }
        $hashesToSave | ConvertTo-Json -Depth 3 | Out-File $HashesFile -Encoding UTF8
        Write-Host "Сохранено хэшей в кэш: $($currentHashes.Count)" -ForegroundColor Gray
    }
    catch {
        Write-Host "Не удалось сохранить кэш хэшей: $_" -ForegroundColor Red
    }
    
    $hasChanges = ($changedFiles.Count -gt 0) -or ($newFiles.Count -gt 0) -or ($deletedFiles.Count -gt 0)
    
    # Выводим статистику
    Write-Host "`n=== Статистика изменений ===" -ForegroundColor Cyan
    Write-Host "Всего файлов: $($currentFiles.Count)" -ForegroundColor White
    Write-Host "Измененных: $($changedFiles.Count)" -ForegroundColor $(if ($changedFiles.Count -gt 0) { "Yellow" } else { "Gray" })
    Write-Host "Новых: $($newFiles.Count)" -ForegroundColor $(if ($newFiles.Count -gt 0) { "Green" } else { "Gray" })
    Write-Host "Удаленных: $($deletedFiles.Count)" -ForegroundColor $(if ($deletedFiles.Count -gt 0) { "Red" } else { "Gray" })
    Write-Host "Без изменений: $($unchangedFiles.Count)" -ForegroundColor Gray
    Write-Host "Файлов для конвертации: $($filesToConvert.Count)" -ForegroundColor $(if ($filesToConvert.Count -gt 0) { "Cyan" } else { "Gray" })
    Write-Host "Есть изменения: $(if ($hasChanges) { 'ДА' } else { 'НЕТ' })" -ForegroundColor $(if ($hasChanges) { "Yellow" } else { "Green" })
    
    return @{
        FilesToConvert = $filesToConvert
        HasChanges = $hasChanges
        ChangedFiles = $changedFiles
        NewFiles = $newFiles
        DeletedFiles = $deletedFiles
        TotalFiles = $currentFiles.Count
    }
}

# Этап 0: Синхронизация версий (если указано)
if ($syncVersions) {
    Write-Host "`n=== Этап 0: Синхронизация версий ===" -ForegroundColor Cyan
    
    try {
        Sync-Versions -ProjectRoot $PSScriptRoot -Force:$true -NewVersion $Version
        Write-Host "Синхронизация версий завершена" -ForegroundColor Green
    }
    catch {
        Write-Host "Ошибка при синхронизации версий: $_" -ForegroundColor Red
        exit 1
    }
}

# Этап 1: Генерация .resources (пропускаем если указано)
if (-not $skipResgen) {
    Write-Host "`n=== Этап 1: Конвертация resx -> resources ===" -ForegroundColor Green
    
    # Если указан ForceAll - конвертируем все файлы
    if ($forceAll) {
        Write-Host "Принудительная конвертация ВСЕХ файлов..." -ForegroundColor Cyan
        $allFiles = Get-ChildItem -Path $ResxFolder -Filter '*.resx' -Recurse -File
        $changes = @{
            FilesToConvert = $allFiles
            HasChanges = $true
            ChangedFiles = @()
            NewFiles = $allFiles
            DeletedFiles = @()
            TotalFiles = $allFiles.Count
        }
        Write-Host "Будет сконвертировано $($allFiles.Count) файлов" -ForegroundColor Cyan
    } else {
        # Проверяем изменения и получаем список файлов для конвертации
        $changes = Get-FilesToConvert -ResxFolder $ResxFolder -HashesFile $HashesFile
    }
    
	# Если есть изменения, обновляем версию (если не отключено)
	if ($changes.HasChanges -and $changes.FilesToConvert.Count -gt 0) {
		if (-not $skipVersionUpdate) {
			Write-Host "`nОбнаружены изменения, обновляю версию..." -ForegroundColor Yellow
	
			try {
				# Если версия указана вручную, используем её
				if ($Version) {
					$updateResult = Update-AllVersions -ProjectRoot $PSScriptRoot -NewVersion $Version
					Write-Host "Версия принудительно установлена: $Version" -ForegroundColor Cyan
				} else {
					# Иначе автоинкремент
					$updateResult = Update-AllVersions -ProjectRoot $PSScriptRoot
					Write-Host "Версия обновлена автоматически до: $($updateResult.Version)" -ForegroundColor Green
				}
	
				Write-Host "Обновлено файлов: $($updateResult.NuspecUpdated) nuspec, $($updateResult.ResxUpdated) resx" -ForegroundColor Green
			}
			catch {
				Write-Host "Ошибка при обновлении версии: $_" -ForegroundColor Red
				Write-Host "Продолжаю конвертацию без обновления версии" -ForegroundColor Yellow
			}
		} else {
			Write-Host "`nОбнаружены изменения, но обновление версии отключено (-SkipVersionUpdate)" -ForegroundColor Gray
		}
	}
		
    # Если нет файлов для конвертации и не указан ForceAll
    if (-not $forceAll -and $changes.FilesToConvert.Count -eq 0 -and $changes.TotalFiles -gt 0) {
        Write-Host "`n⚠️  Изменений в .resx файлах не обнаружено!" -ForegroundColor Yellow
        
        # Проверяем, существуют ли уже .resources файлы
        $resourcesExist = $false
        if (Test-Path $ResourcesOutput) {
            $resourceFiles = Get-ChildItem -Path $ResourcesOutput -Filter '*.resources' -Recurse
            if ($resourceFiles -and $resourceFiles.Count -ge $changes.TotalFiles) {
                $resourcesExist = $true
                Write-Host "Обнаружены существующие .resources файлы ($($resourceFiles.Count) шт.)" -ForegroundColor Gray
            }
        }
        
        if ($resourcesExist) {
            $response = Read-Host "`nПродолжить конвертацию всех файлов? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "Конвертация пропущена" -ForegroundColor Yellow
                
                # Пропускаем конвертацию, но продолжаем со сборкой если нужно
                $skipResgen = $true
                
                if (-not $skipBuild) {
                    Write-Host "`nПереход к этапу сборки..." -ForegroundColor Cyan
                }
            } else {
                # Пользователь хочет конвертировать все файлы
                $changes.FilesToConvert = Get-ChildItem -Path $ResxFolder -Filter '*.resx' -Recurse -File
                Write-Host "Будет выполнена конвертация всех файлов ($($changes.FilesToConvert.Count) шт.)" -ForegroundColor Cyan
            }
        }
    }
    
    # Выполняем конвертацию если не пропущена
    if (-not $skipResgen) {
        # Убедимся, что папка для .resources существует
        if (-not (Test-Path $ResourcesOutput)) {
            New-Item -ItemType Directory -Path $ResourcesOutput -Force | Out-Null
            Write-Host "Created missing output folder: $ResourcesOutput"
        }

        if ($changes.FilesToConvert.Count -eq 0) {
            Write-Host "`nНет файлов для конвертации." | Tee-Object -FilePath $LogFile -Append
            
            # Если файлов нет, но не пропускаем сборку - продолжаем
            if (-not $skipBuild) {
                Write-Host "`nРесурсные файлы не найдены или не требуют конвертации, продолжаем сборку..." -ForegroundColor Yellow
            } else {
                exit 0
            }
        } else {
            Write-Host "`nConverting $($changes.FilesToConvert.Count) file(s) in: $ResxFolder" | Tee-Object -FilePath $LogFile -Append
            
            $errIndex = 0
            $convertedCount = 0

            foreach ($f in $changes.FilesToConvert) {
                # создаём выходной путь в ResourcesOutput
                $out = Join-Path $ResourcesOutput ($f.BaseName + '.resources')
                Write-Host "Конвертация: $($f.Name) -> $($f.BaseName).resources"
                
                $result = & $resgen $f.FullName $out 2>&1
                if ($result) {
                    $result | ForEach-Object {
                        Write-Host $_
                        $_ | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    }
                }

                if ($LASTEXITCODE -ne 0) {
                    $errIndex++

                    # выделяем строки с ошибками
                    $errorLines = $result | Where-Object { $_ -match 'error RG' -or $_ -match 'Ошибка' }
                    $errorCount = ($errorLines | Measure-Object).Count

                    $block = @()
                    $block += "Ошибка №$errIndex"
                    $block += "Файл: $($f.FullName)"
                    $block += "Количество ошибок: $errorCount"
                    $block += "Описание:"
                    $block += $errorLines
                    $block += ""  # пустая строка для разделения

                    Write-Host "ERROR in $($f.Name): $errorCount error(s)" -ForegroundColor Red
                    $block | Out-File -FilePath $ErrorLogFile -Append -Encoding UTF8
                } else {
                    $convertedCount++
                }
            }
            
            if ($errIndex -gt 0) {
                Write-Host "`nОбнаружено ошибок при генерации .resources: $errIndex" -ForegroundColor Red
                Write-Host "Успешно сконвертировано: $convertedCount из $($changes.FilesToConvert.Count)" -ForegroundColor $(if ($convertedCount -eq 0) { "Red" } elseif ($convertedCount -lt $changes.FilesToConvert.Count) { "Yellow" } else { "Green" })
                Write-Host "Подробности в файле: $ErrorLogFile" -ForegroundColor Yellow
                
                # Спрашиваем продолжать ли сборку при наличии ошибок
                if (-not $skipBuild) {
                    $response = Read-Host "`nПродолжить сборку несмотря на ошибки? (y/N)"
                    if ($response -ne 'y' -and $response -ne 'Y') {
                        exit 1
                    }
                }
            } else {
                Write-Host "`nУспешно сконвертировано: $convertedCount из $($changes.FilesToConvert.Count) файлов" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "=== Этап 1: Генерация .resources пропущена ===" -ForegroundColor Yellow
    "Generation of .resources files was skipped by user request." | Tee-Object -FilePath $LogFile -Append
}

# Этап 2: Сборка (пропускаем если указано)
if (-not $skipBuild) {
    Write-Host "`n=== Этап 2: Сборка пакетов ===" -ForegroundColor Green
    
    try {
        # Получаем текущую версию для сборки из обновленного nuspec
        $nugetNuspecPath = Join-Path $PSScriptRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
        if (Test-Path $nugetNuspecPath) {
            $nuspecText = Get-Content $nugetNuspecPath -Raw
            if ($nuspecText -match '<version>(.*?)</version>') {
                $currentVersion = $Matches[1]
            } else {
                $currentVersion = Get-CurrentVersion -ProjectRoot $PSScriptRoot
            }
        } else {
            $currentVersion = Get-CurrentVersion -ProjectRoot $PSScriptRoot
        }
        
        Write-Host "=== Building NuGet package (version: $currentVersion) ==="
        & .\NugetFolder\BaHooo.ReSharper.I18n.ru\build.ps1 -Version $currentVersion -Output '..\artifacts' 2>&1 | Tee-Object -FilePath $LogFile -Append

        Write-Host "=== Building JetBrains Marketplace package (version: $currentVersion) ==="
        & .\MarketplaceFolder\BaHooo.ReSharper.I18n.ru\build.ps1 -Version $currentVersion -Output '..\artifacts' 2>&1 | Tee-Object -FilePath $LogFile -Append
        
        Write-Host "`n=== Сборка успешно завершена ===" -ForegroundColor Green
    }
    catch {
        $errMsg = "ERROR in build.ps1: $($_.Exception.Message)"
        Write-Host $errMsg -ForegroundColor Red

        $block = @()
        $block += "Ошибка сборки"
        $block += "Описание:"
        $block += $errMsg
        $block += ""

        $block | Out-File -FilePath $ErrorLogFile -Append -Encoding UTF8
        exit 1
    }
} else {
    Write-Host "`n=== Этап 2: Сборка пакетов пропущена ===" -ForegroundColor Yellow
    "Building of packages was skipped by user request." | Tee-Object -FilePath $LogFile -Append
}

