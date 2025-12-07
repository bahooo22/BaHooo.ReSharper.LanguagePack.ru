param(
    [string]$ResxFolder = '.\raw-resx-done_ru-RU',
    [string]$ResourcesOutput = '.\build\resources',   # общая папка для .resources
    [string]$Version = (Get-Date -Format 'yyyy.MM.dd'),
    [string]$LogFile = 'build.log',
    [string]$ErrorLogFile = 'build.errors.log',
    
    # Основные ключи
    [switch]$NoBuild,
    [alias("nb")][switch]$NoBuildAlias,  # Алиас для краткости
    
    [switch]$NoResgen,
    [alias("nr")][switch]$NoResgenAlias, # Пропустить генерацию .resources
    
    [switch]$BuildOnly,
    [alias("bo")][switch]$BuildOnlyAlias, # Только сборка (пропустить resgen)
    
    [switch]$Help,
    [alias("h")][switch]$HelpAlias
)

$resgen = 'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe'

# Проверяем запрос помощи
if ($Help -or $HelpAlias) {
    Show-Help
    exit 0
}

# Определяем режимы работы
$skipBuild = $NoBuild -or $NoBuildAlias
$skipResgen = $NoResgen -or $NoResgenAlias
$buildOnly = $BuildOnly -or $BuildOnlyAlias

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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Очистим старые логи
Remove-Item $LogFile, $ErrorLogFile -ErrorAction SilentlyContinue

# Этап 1: Генерация .resources (пропускаем если указано)
if (-not $skipResgen) {
    Write-Host "=== Этап 1: Конвертация resx -> resources ===" -ForegroundColor Green
    
    # Убедимся, что папка для .resources существует
    if (-not (Test-Path $ResourcesOutput)) {
        New-Item -ItemType Directory -Path $ResourcesOutput -Force | Out-Null
        Write-Host "Created missing output folder: $ResourcesOutput"
    }

    Write-Host "Converting resx -> resources in: $ResxFolder" | Tee-Object -FilePath $LogFile -Append

    $files = Get-ChildItem -Path $ResxFolder -Filter '*.resx' -Recurse
    if ($files.Count -eq 0) {
        "No .resx files found." | Tee-Object -FilePath $LogFile -Append
        
        # Если файлов нет, но не пропускаем сборку - продолжаем
        if (-not $skipBuild) {
            Write-Host "`nРесурсные файлы не найдены, но продолжаем сборку..." -ForegroundColor Yellow
        } else {
            exit 0
        }
    } else {
        $errIndex = 0

        foreach ($f in $files) {
            # создаём выходной путь в ResourcesOutput
            $out = Join-Path $ResourcesOutput ($f.BaseName + '.resources')
            $msg = "resgen $($f.FullName) -> $out"
            Write-Host $msg
            $msg | Tee-Object -FilePath $LogFile -Append

            $result = & $resgen $f.FullName $out 2>&1
            $result | Tee-Object -FilePath $LogFile -Append

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
            }
        }
        
        if ($errIndex -gt 0) {
            Write-Host "`nОбнаружено ошибок при генерации .resources: $errIndex" -ForegroundColor Red
            Write-Host "Подробности в файле: $ErrorLogFile" -ForegroundColor Yellow
            
            # Спрашиваем продолжать ли сборку при наличии ошибок
            if (-not $skipBuild) {
                $response = Read-Host "`nПродолжить сборку несмотря на ошибки? (y/N)"
                if ($response -ne 'y' -and $response -ne 'Y') {
                    exit 1
                }
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
        Write-Host "=== Building NuGet package ==="
        & .\NugetFolder\BaHooo.ReSharper.I18n.ru\build.ps1 -Version $Version -Output '..\artifacts' 2>&1 | Tee-Object -FilePath $LogFile -Append

        Write-Host "=== Building JetBrains Marketplace package ==="
        & .\MarketplaceFolder\BaHooo.ReSharper.I18n.ru\build.ps1 -Version $Version -Output '..\artifacts' 2>&1 | Tee-Object -FilePath $LogFile -Append
        
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

function Show-Help {
    Write-Host @"
ИСПОЛЬЗОВАНИЕ:
    .\build.ps1 [ПАРАМЕТРЫ]

ПАРАМЕТРЫ:
    -ResxFolder <путь>          Папка с исходными .resx файлами (по умолчанию: .\raw-resx-done_ru-RU)
    -ResourcesOutput <путь>     Папка для сгенерированных .resources файлов (по умолчанию: .\build\resources)
    -Version <версия>           Версия сборки (по умолчанию: текущая дата в формате ГГГГ.ММ.ДД)
    -LogFile <файл>             Файл лога (по умолчанию: build.log)
    -ErrorLogFile <файл>        Файл лога ошибок (по умолчанию: build.errors.log)
    
    -NoResgen, -nr              Пропустить генерацию .resources файлов
    -BuildOnly, -bo             Только сборка (пропустить генерацию .resources)
    -NoBuild, -nb               Только генерация .resources (пропустить сборку)
    
    -Help, -h                   Показать эту справку

ПРИМЕРЫ:
    .\build.ps1                                     # Полный процесс: resgen + сборка
    .\build.ps1 -NoBuild                            # Только генерация .resources
    .\build.ps1 -BuildOnly                          # Только сборка (пропустить resgen)
    .\build.ps1 -NoResgen                           # Только сборка (альтернатива -BuildOnly)
    .\build.ps1 -nb                                 # Краткая форма (только генерация)
    .\build.ps1 -bo                                 # Краткая форма (только сборка)
    .\build.ps1 -nr                                 # Краткая форма (пропустить resgen)
    
    .\build.ps1 -ResxFolder "C:\my-resx" -NoBuild   # Конвертация из указанной папки
    .\build.ps1 -BuildOnly -Version "1.0.0"         # Сборка с указанием версии
    .\build.ps1 -Help                               # Показать справку

РЕЖИМЫ РАБОТЫ:
    1. Без параметров:           resgen → сборка (полный процесс)
    2. -NoBuild (-nb):           resgen → остановка
    3. -BuildOnly (-bo):         сборка (пропуск resgen)
    4. -NoResgen (-nr):          сборка (пропуск resgen, аналогично -BuildOnly)

ОПИСАНИЕ:
    Скрипт выполняет конвертацию .resx файлов в .resources файлы с помощью ResGen
    и последующую сборку NuGet и JetBrains Marketplace пакетов.
    
    Параметры -NoResgen и -BuildOnly дают одинаковый результат: пропуск генерации
    .resources файлов и выполнение только этапа сборки.
"@
}