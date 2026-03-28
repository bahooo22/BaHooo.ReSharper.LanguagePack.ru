<#
.SYNOPSIS
    Конвертер .resx -> .resources с поддержкой параллелизма и авто-обновления версий.
.DESCRIPTION
    Автоматизирует конвертацию ресурсов, управление версиями и сборку пакетов.
    Все алгоритмы вынесены в функции с ограниченной ответственностью.
    Поддерживает инкрементальную сборку по хэшам, параллельную обработку (PS7+) и автономный режим.
    При запуске без параметров показывает справку и запрашивает подтверждение.
.LINK
    https://github.com/PowerShell/PowerShell
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
param(
<#
.SYNOPSIS
    -ResxFolder [string]
.DESCRIPTION
    Папка с исходными .resx файлами для конвертации.
    Скрипт рекурсивно ищет все .resx файлы в указанной папке.
.PARAMETER ResxFolder
    Путь к папке с .resx файлами (относительный или абсолютный).
.DEFAULT
    .\raw-resx-done_ru-RU
.EXAMPLE
    .\resx-to-resources.ps1 -ResxFolder '.\raw-resx-done_ru-RU'
.EXAMPLE
    .\resx-to-resources.ps1 -ResxFolder 'C:\Projects\MyApp\Resources'
.EXAMPLE
    .\resx-to-resources.ps1 -ResxFolder '..\i18n\ru-RU'
#>
    [Parameter(Position = 0, HelpMessage = 'Папка с исходными .resx файлами')]
    [string]$ResxFolder = '.\raw-resx-done_ru-RU',

<#
.SYNOPSIS
    -ResourcesOutput [string]
.DESCRIPTION
    Папка для сгенерированных .resources файлов.
    Скрипт создаёт эту папку автоматически, если она не существует.
.PARAMETER ResourcesOutput
    Путь к выходной папке для .resources файлов.
.DEFAULT
    .\build\resources
.EXAMPLE
    .\resx-to-resources.ps1 -ResourcesOutput '.\build\resources'
.EXAMPLE
    .\resx-to-resources.ps1 -ResourcesOutput 'C:\Output\resources'
.EXAMPLE
    .\resx-to-resources.ps1 -ResxFolder '.\src' -ResourcesOutput '.\bin\resources'
#>
    [Parameter(HelpMessage = 'Папка для сгенерированных .resources файлов')]
    [string]$ResourcesOutput = '.\build\resources',

<#
.SYNOPSIS
    -Version [string]
.DESCRIPTION
    Версия сборки для установки вручную.
    Если не указана — используется автоинкремент текущей версии.
    Формат: MAJOR.MINOR.PATCH.REVISION (например, 2025.3.3.13).
.PARAMETER Version
    Строка версии для принудительной установки.
.DEFAULT
    (автоматическое определение из nuspec)
.EXAMPLE
    .\resx-to-resources.ps1 -Version '2025.3.4.0'
.EXAMPLE
    .\resx-to-resources.ps1 -Version '1.0.0.0' -SkipVersionUpdate
.EXAMPLE
    .\resx-to-resources.ps1 -Version '2025.3.3.13' -SyncVersions
#>
    [Parameter(HelpMessage = 'Версия сборки вручную (иначе автоинкремент)')]
    [string]$Version,

<#
.SYNOPSIS
    -LogFile [string]
.DESCRIPTION
    Путь к файлу основного лога.
    Лог записывается в режиме приложения (не перезаписывается).
    Содержит временные метки и все выводы скрипта.
.PARAMETER LogFile
    Путь к файлу лога (относительный или абсолютный).
.DEFAULT
    build.log
.EXAMPLE
    .\resx-to-resources.ps1 -LogFile 'build.log'
.EXAMPLE
    .\resx-to-resources.ps1 -LogFile '.\logs\build.log'
.EXAMPLE
    .\resx-to-resources.ps1 -LogFile 'C:\Logs\resx-build.log'
#>
    [Parameter(HelpMessage = 'Файл основного лога')]
    [string]$LogFile = 'build.log',

<#
.SYNOPSIS
    -ErrorLogFile [string]
.DESCRIPTION
    Путь к файлу лога ошибок.
    Записываются только ошибки конвертации и сборки.
    Лог записывается в режиме приложения (не перезаписывается).
.PARAMETER ErrorLogFile
    Путь к файлу лога ошибок.
.DEFAULT
    build.errors.log
.EXAMPLE
    .\resx-to-resources.ps1 -ErrorLogFile 'build.errors.log'
.EXAMPLE
    .\resx-to-resources.ps1 -ErrorLogFile '.\logs\errors.log'
.EXAMPLE
    .\resx-to-resources.ps1 -LogFile 'build.log' -ErrorLogFile 'build.errors.log'
#>
    [Parameter(HelpMessage = 'Файл лога ошибок')]
    [string]$ErrorLogFile = 'build.errors.log',

<#
.SYNOPSIS
    -NoBuild, -nb [switch]
.DESCRIPTION
    Пропустить этап сборки пакетов (NuGet и Marketplace).
    Используется для проверки только конвертации .resx → .resources.
.PARAMETER NoBuild
    Переключатель для пропуска сборки.
.ALIAS
    -nb
.EXAMPLE
    .\resx-to-resources.ps1 -NoBuild
.EXAMPLE
    .\resx-to-resources.ps1 -nb
.EXAMPLE
    .\resx-to-resources.ps1 -nb -fa  # Конвертировать все, без сборки
#>
    [Parameter(ParameterSetName = 'NoBuild')][alias('nb')][switch]$NoBuild,
    [Parameter(ParameterSetName = 'NoBuild')][switch]$NoBuildAlias,

<#
.SYNOPSIS
    -NoResgen, -nr [switch]
.DESCRIPTION
    Пропустить генерацию .resources файлов.
    Используется когда ресурсы уже сконвертированы и нужна только сборка.
.PARAMETER NoResgen
    Переключатель для пропуска конвертации.
.ALIAS
    -nr
.EXAMPLE
    .\resx-to-resources.ps1 -NoResgen
.EXAMPLE
    .\resx-to-resources.ps1 -nr
.EXAMPLE
    .\resx-to-resources.ps1 -nr -bo  # Пропустить resgen, только сборка
#>
    [Parameter(ParameterSetName = 'NoResgen')][alias('nr')][switch]$NoResgen,
    [Parameter(ParameterSetName = 'NoResgen')][switch]$NoResgenAlias,

<#
.SYNOPSIS
    -BuildOnly, -bo [switch]
.DESCRIPTION
    Только сборка пакетов (пропустить конвертацию .resx → .resources).
    Эквивалентно комбинации -NoResgen + выполнение сборки.
.PARAMETER BuildOnly
    Переключатель для режима "только сборка".
.ALIAS
    -bo
.EXAMPLE
    .\resx-to-resources.ps1 -BuildOnly
.EXAMPLE
    .\resx-to-resources.ps1 -bo
.EXAMPLE
    .\resx-to-resources.ps1 -bo -Version '2025.3.4.0'
#>
    [Parameter(ParameterSetName = 'BuildOnly')][alias('bo')][switch]$BuildOnly,
    [Parameter(ParameterSetName = 'BuildOnly')][switch]$BuildOnlyAlias,

<#
.SYNOPSIS
    -SyncVersions, -sv [switch]
.DESCRIPTION
    Синхронизировать версии перед выполнением.
    Приводит все версии (nuspec, .resx, AssemblyInfo) к единому значению.
.PARAMETER SyncVersions
    Переключатель для синхронизации версий.
.ALIAS
    -sv
.EXAMPLE
    .\resx-to-resources.ps1 -SyncVersions
.EXAMPLE
    .\resx-to-resources.ps1 -sv
.EXAMPLE
    .\resx-to-resources.ps1 -sv -Version '2025.3.4.0'
#>
    [alias('sv')][switch]$SyncVersions,
    [switch]$SyncVersionsAlias,

<#
.SYNOPSIS
    -SkipVersionUpdate, -svu [switch]
.DESCRIPTION
    Отключить автоматическое обновление версии (автоинкремент).
    Используется в CI/CD, где версия контролируется внешним скриптом.
.PARAMETER SkipVersionUpdate
    Переключатель для отключения автоинкремента.
.ALIAS
    -svu
.EXAMPLE
    .\resx-to-resources.ps1 -SkipVersionUpdate
.EXAMPLE
    .\resx-to-resources.ps1 -svu
.EXAMPLE
    .\resx-to-resources.ps1 -svu -fa -nb  # CI/CD режим
#>
    [alias('svu')][switch]$SkipVersionUpdate,
    [switch]$SkipVersionUpdateAlias,

<#
.SYNOPSIS
    -ForceAll, -fa [switch]
.DESCRIPTION
    Принудительная конвертация ВСЕХ .resx файлов (игнорируя кэш хэшей).
    Используется в CI/CD, при сбросе кэша, или для полной пересборки.
.PARAMETER ForceAll
    Переключатель для принудительной конвертации всех файлов.
.ALIAS
    -fa
.EXAMPLE
    .\resx-to-resources.ps1 -ForceAll
.EXAMPLE
    .\resx-to-resources.ps1 -fa
.EXAMPLE
    .\resx-to-resources.ps1 -fa -svu -nb  # CI/CD: все файлы, без инкремента
#>
    [alias('fa')][switch]$ForceAll,
    [switch]$ForceAllAlias,

<#
.SYNOPSIS
    -UseParallel, -up, -t, -Threads [int]
.DESCRIPTION
    Количество потоков для параллельной конвертации .resx файлов.
    Требуется PowerShell 7+ (скачивается автоматически в ./Tools при необходимости).
    
    Значения:
      0 = без параллелизма (последовательная обработка)
      1 = авто-выбор (половина ядер CPU)
      2..N = указанное количество потоков
    
    Для i7-4790K (8 ядер): -up 1 = 4 потока, -up 8 = 8 потоков.
.PARAMETER UseParallel
    Количество потоков для параллельной обработки.
.ALIAS
    -up, -t, -Threads
.DEFAULT
    0 (без параллелизма)
.EXAMPLE
    .\resx-to-resources.ps1 -UseParallel
.EXAMPLE
    .\resx-to-resources.ps1 -up 8
.EXAMPLE
    .\resx-to-resources.ps1 -up 1 -sv  # Авто-выбор потоков + синхронизация
.EXAMPLE
    .\resx-to-resources.ps1 -t 4  # Альтернативный алиас
#>
    [alias('up','t','Threads')][int]$UseParallel = 0,

<#
.SYNOPSIS
    -AcceptAll, -aa [switch]
.DESCRIPTION
    Автоматическое согласие на загрузку инструментов из сети.
    Пропускает интерактивные запросы подтверждения загрузок.
    Используется в CI/CD (GitHub Actions, Azure DevOps).
.PARAMETER AcceptAll
    Переключатель для автоматического согласия на загрузку.
.ALIAS
    -aa
.EXAMPLE
    .\resx-to-resources.ps1 -AcceptAll
.EXAMPLE
    .\resx-to-resources.ps1 -aa
.EXAMPLE
    .\resx-to-resources.ps1 -aa -fa -svu -nb  # Полностью неинтерактивный CI/CD
#>
    [alias('aa')][switch]$AcceptAll,
    [switch]$AcceptAllAlias,

<#
.SYNOPSIS
    -CleanTools [switch]
.DESCRIPTION
    Очистить папку ./Tools перед запуском.
    Удаляет скачанные инструменты (PS7, ResGen, NuGet) для сброса окружения.
    Не удаляет сам скрипт и рабочие файлы.
.PARAMETER CleanTools
    Переключатель для очистки папки инструментов.
.EXAMPLE
    .\resx-to-resources.ps1 -CleanTools
.EXAMPLE
    .\resx-to-resources.ps1 -CleanTools -aa  # Очистить и заново скачать
#>
    [switch]$CleanTools,

<#
.SYNOPSIS
    -NoNetwork [switch]
.DESCRIPTION
    Запретить любые сетевые запросы.
    Скрипт работает только с локально установленными инструментами.
    Если инструмент не найден — соответствующий этап пропускается с предупреждением.
.PARAMETER NoNetwork
    Переключатель для оффлайн-режима.
.EXAMPLE
    .\resx-to-resources.ps1 -NoNetwork
.EXAMPLE
    .\resx-to-resources.ps1 -NoNetwork -nr  # Оффлайн, пропуск resgen
.EXAMPLE
    .\resx-to-resources.ps1 -NoNetwork -bo  # Оффлайн, только сборка
#>
    [switch]$NoNetwork,

<#
.SYNOPSIS
    -Help, -h [switch]
.DESCRIPTION
    Показать справку по скрипту.
    Поддерживает динамические разделы через -Topic и полную справку через -Full.
.PARAMETER Help
    Переключатель для показа справки.
.ALIAS
    -h
.PARAMETER Topic
    Тема справки: Basic, Paths, Modes, Parallelism, History, Tools, Config, Examples, Versioning, All
.PARAMETER Full
    Показать полную справку со всеми разделами.
.EXAMPLE
    .\resx-to-resources.ps1 -Help
.EXAMPLE
    .\resx-to-resources.ps1 -h
.EXAMPLE
    .\resx-to-resources.ps1 -Help -Topic History
.EXAMPLE
    .\resx-to-resources.ps1 -Help -Full
#>
    [alias('h')][switch]$Help,
    [switch]$HelpAlias,

<#
.SYNOPSIS
    -Topic [string] (для -Help)
.DESCRIPTION
    Тема справки для детальной информации по разделам.
    Доступные темы: Basic, Paths, Modes, Parallelism, History, Tools, Config, Examples, Versioning, All.
.PARAMETER Topic
    Название раздела справки.
.DEFAULT
    Basic
.EXAMPLE
    .\resx-to-resources.ps1 -Help -Topic Paths
.EXAMPLE
    .\resx-to-resources.ps1 -Help -Topic Tools
.EXAMPLE
    .\resx-to-resources.ps1 -h -Topic History
#>
    [Parameter(ParameterSetName = 'Help')][ValidateSet('Basic', 'Paths', 'Modes', 'Parallelism', 'History', 'Tools', 'Config', 'Examples', 'Versioning', 'All')][string]$Topic = 'Basic',

<#
.SYNOPSIS
    -Full [switch] (для -Help)
.DESCRIPTION
    Показать полную справку со всеми разделами.
    Эквивалентно -Help -Topic All.
.PARAMETER Full
    Переключатель для полной справки.
.EXAMPLE
    .\resx-to-resources.ps1 -Help -Full
.EXAMPLE
    .\resx-to-resources.ps1 -h -Full
#>
    [Parameter(ParameterSetName = 'Help')][switch]$Full
)

#region === КОНФИГУРАЦИЯ И КОНСТАНТЫ ===
$Script:Config = @{
    ScriptRoot = $PSScriptRoot
    ToolsDir = Join-Path $PSScriptRoot 'Tools'
    Pwsh7Dir = Join-Path (Join-Path $PSScriptRoot 'Tools') 'PWSH7'
    Pwsh7Exe = Join-Path (Join-Path (Join-Path $PSScriptRoot 'Tools') 'PWSH7') 'pwsh.exe'
    HashesFile = '.\build\resx-hashes.json'
    MinFreeSpaceMB = 500
    OriginalResGenPath = 'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe'
    ResGenPath = $null
    NuGetPath = $null
    MaxThreads = 1
    # Копируем значения из параметров скрипта
    ResxFolder = $ResxFolder
    ResourcesOutput = $ResourcesOutput
    LogFile = $LogFile
    ErrorLogFile = $ErrorLogFile
    Version = $Version
    UseParallel = $UseParallel
    NoBuild = $NoBuild
    NoBuildAlias = $NoBuildAlias
    NoResgen = $NoResgen
    NoResgenAlias = $NoResgenAlias
    BuildOnly = $BuildOnly
    BuildOnlyAlias = $BuildOnlyAlias
	VersionAlreadyUpdated = $false  # Флаг: версия уже обновлена в этом запуске
    SyncVersions = $SyncVersions
    SyncVersionsAlias = $SyncVersionsAlias
    SkipVersionUpdate = $SkipVersionUpdate
    SkipVersionUpdateAlias = $SkipVersionUpdateAlias
    ForceAll = $ForceAll
    ForceAllAlias = $ForceAllAlias
    AcceptAll = $AcceptAll
    AcceptAllAlias = $AcceptAllAlias
    CleanTools = $CleanTools
    NoNetwork = $NoNetwork
    Help = $Help
    HelpAlias = $HelpAlias
    # Флаги режимов (вычисляются позже)
    SkipBuild = $false
    SkipResgen = $false
}
#endregion

#region === УТИЛИТЫ: ЛОГИРОВАНИЕ И ПРОВЕРКИ ===
<#
.SYNOPSIS
    Вывод сообщения в консоль с цветом
#>
function Write-ColoredMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Gray','Green','Yellow','Red','Cyan','White')][string]$Color = 'Gray'
    )
    Write-Host $Message -ForegroundColor $Color
}

<#
.SYNOPSIS
    Запись сообщения в лог-файл с временной меткой
#>
function Write-ToLogFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$LogFilePath
    )
    $ts = Get-Date -Format 'HH:mm:ss'
    "[$ts] $Message" | Out-File -FilePath $LogFilePath -Append -Encoding UTF8
}

<#
.SYNOPSIS
    Вывод сообщения в консоль и в лог-файл
#>
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Gray','Green','Yellow','Red','Cyan','White')][string]$Color = 'Gray',
        [switch]$SkipFileLog
    )
    Write-ColoredMessage -Message $Message -Color $Color
    if (-not $SkipFileLog) {
        Write-ToLogFile -Message $Message -LogFilePath $Script:Config.LogFile
    }
}

<#
.SYNOPSIS
    Проверка наличия свободного места на диске
#>
function Test-DiskSpaceSufficient {
    [CmdletBinding()]
    [OutputType([bool])]
    param([long]$RequiredMB)
    $drive = (Get-Location).Drive.Name
    $freeMB = [math]::Round((Get-PSDrive $drive).Free / 1MB)
    if ($freeMB -lt $RequiredMB) {
        Write-Log "Недостаточно места на $drive\: свободно ${freeMB}МБ, нужно ${RequiredMB}МБ" 'Red'
        return $false
    }
    return $true
}

<#
.SYNOPSIS
    Запрос согласия пользователя на загрузку из сети
#>
function Request-DownloadPermission {
    [CmdletBinding()]
    [OutputType([bool])]
    param([string]$ItemName, [long]$SizeMB)
    if ($Script:Config.AcceptAll -or $Script:Config.AcceptAllAlias) {
        Write-Log "[-aa] Авто-согласие: загрузка $ItemName (~${SizeMB}МБ)" 'Yellow'
        return $true
    }
    if ($Script:Config.NoNetwork) {
        Write-Log "[-NoNetwork] Загрузка отключена: $ItemName" 'Yellow'
        return $false
    }
    $answer = Read-Host "Скачать $ItemName (~${SizeMB}МБ)? (y/N)"
    return ($answer -eq 'y' -or $answer -eq 'Y')
}

<#
.SYNOPSIS
    Скачивание файла по URL с распаковкой если нужно
#>
function Invoke-FileDownload {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$DestinationDir,
        [Parameter(Mandatory)][string]$DestinationFile,
        [long]$SizeMB
    )
    if (-not (Test-DiskSpaceSufficient -RequiredMB $Script:Config.MinFreeSpaceMB)) { return $false }
    if (-not (Request-DownloadPermission -ItemName $Name -SizeMB $SizeMB)) {
        Write-Log "Загрузка $Name отменена пользователем" 'Yellow'
        return $false
    }
    try {
        Write-Log "Загрузка $Name..." 'Cyan'
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
        $tempZip = Join-Path $env:TEMP "$Name.zip"
        Invoke-WebRequest -Uri $Url -OutFile $tempZip -UseBasicParsing -TimeoutSec 60
        if ($DestinationFile -like '*.zip') {
            Expand-Archive -Path $tempZip -DestinationPath $DestinationDir -Force
        } else {
            Move-Item $tempZip (Join-Path $DestinationDir $DestinationFile) -Force
        }
        Remove-Item $tempZip -ErrorAction SilentlyContinue
        Write-Log "$Name успешно установлен в $DestinationDir" 'Green'
        return $true
    }
    catch {
        Write-Log "Ошибка при загрузке $Name`: $_" 'Red'
        return $false
    }
}

<#
.SYNOPSIS
    Гарантирует существование директории для файла
#>
function Ensure-DirectoryForFile {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FilePath)
    $dir = if ($FilePath -match '[\\/]') { Split-Path $FilePath -Parent } else { '.' }
    if ($dir -and $dir -ne '.' -and -not (Test-Path $dir -PathType Container)) {
        New-Item -ItemType Directory -Path $dir -Force -ErrorAction SilentlyContinue | Out-Null
    }
}
#endregion

#region === УТИЛИТЫ: ПОИСК ИНСТРУМЕНТОВ ===
<#
.SYNOPSIS
    Поиск исполняемого файла в системном PATH
#>
function Find-ToolInPath {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$ToolName)
    $cmd = Get-Command $ToolName -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Log "Найден в PATH: $($cmd.Source)" 'Gray'
        return $cmd.Source
    }
    return $null
}

<#
.SYNOPSIS
    Поиск ResGen.exe в стандартных путях SDK Windows
#>
function Find-ResGenInSdkPaths {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $sdkPaths = @(
        'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe',
        'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\ResGen.exe',
        'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.2 Tools\ResGen.exe',
        'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7 Tools\ResGen.exe',
        'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.2 Tools\ResGen.exe'
    )
    foreach ($path in $sdkPaths) {
        if (Test-Path $path) {
            Write-Log "Найден в стандартном пути: $path" 'Gray'
            return $path
        }
    }
    return $null
}

<#
.SYNOPSIS
    Поиск инструмента в папке ./Tools
#>
function Find-ToolInToolsFolder {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$ToolName, [Parameter(Mandatory)][string]$SubFolder)
    $toolsPath = Join-Path (Join-Path $Script:Config.ToolsDir $SubFolder) $ToolName
    if (Test-Path $toolsPath) {
        Write-Log "Найден в Tools: $toolsPath" 'Gray'
        return $toolsPath
    }
    return $null
}

<#
.SYNOPSIS
    Полный цикл поиска/загрузки ResGen.exe
#>
function Resolve-ResGenPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $path = Find-ToolInPath -ToolName 'ResGen.exe'
    if ($path) { return $path }
    $path = Find-ResGenInSdkPaths
    if ($path) { return $path }
    $path = Find-ToolInToolsFolder -ToolName 'ResGen.exe' -SubFolder 'ResGen'
    if ($path) { return $path }
    Write-Log "ResGen.exe не найден, требуется загрузка" 'Yellow'
    if ($Script:Config.NoNetwork) {
        Write-Log "[-NoNetwork] Пропускаем загрузку ResGen.exe" 'Yellow'
        return $null
    }
    $destDir = Join-Path $Script:Config.ToolsDir 'ResGen'
    $downloadUrl = 'https://download.microsoft.com/download/5/5/1/5515a3f6-8e8f-4e8e-8e8f-8e8f8e8f8e8f/ResGen.exe'
    if (Invoke-FileDownload -Name 'ResGen.exe' -Url $downloadUrl -DestinationDir $destDir -DestinationFile 'ResGen.exe' -SizeMB 1) {
        return (Join-Path $destDir 'ResGen.exe')
    }
    return $null
}

<#
.SYNOPSIS
    Полный цикл поиска/загрузки nuget.exe
#>
function Resolve-NuGetPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $path = Find-ToolInPath -ToolName 'nuget.exe'
    if ($path) { return $path }
    $path = Find-ToolInToolsFolder -ToolName 'nuget.exe' -SubFolder 'NuGet'
    if ($path) { return $path }
    Write-Log "nuget.exe не найден, требуется загрузка" 'Yellow'
    if ($Script:Config.NoNetwork) {
        Write-Log "[-NoNetwork] Пропускаем загрузку nuget.exe" 'Yellow'
        return $null
    }
    $destDir = Join-Path $Script:Config.ToolsDir 'NuGet'
    $downloadUrl = 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe'
    if (Invoke-FileDownload -Name 'nuget.exe' -Url $downloadUrl -DestinationDir $destDir -DestinationFile 'nuget.exe' -SizeMB 6) {
        return (Join-Path $destDir 'nuget.exe')
    }
    return $null
}
#endregion

#region === УТИЛИТЫ: POWERSHELL 7 ДЛЯ ПАРАЛЛЕЛИЗМА ===
<#
.SYNOPSIS
    Получение информации о последнем релизе PowerShell 7 с GitHub API
#>
function Fetch-LatestPwsh7ReleaseInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    try {
        $apiUrl = 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
        $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing -TimeoutSec 30
        $asset = $release.assets | Where-Object {
            $_.name -like '*PowerShell-*-win-x64.zip' -and $_.name -notlike '*musl*'
        } | Select-Object -First 1
        if ($asset) {
            return @{
                Version = $release.tag_name -replace '^v',''
                DownloadUrl = $asset.browser_download_url
                SizeMB = [math]::Round($asset.size / 1MB)
            }
        }
        Write-Log "Не найдено подходящее издание PS7 для Windows x64" 'Red'
        return $null
    }
    catch {
        Write-Log "Ошибка GitHub API (PS7): $_" 'Red'
        return $null
    }
}

<#
.SYNOPSIS
    Проверка и авто-установка PowerShell 7 для параллельной обработки
#>
function Ensure-PowerShell7Available {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    if ($Script:Config.UseParallel -le 0 -or $PSVersionTable.PSVersion.Major -ge 7) {
        return $true
    }
    Write-Log "⚠️ Для -up требуется PowerShell 7+. Текущая: $($PSVersionTable.PSVersion)" 'Yellow'
    if ($Script:Config.NoNetwork) {
        Write-Log "[-NoNetwork] Откат к однопоточному режиму" 'Yellow'
        $Script:Config.UseParallel = 0
        return $false
    }
    if (-not (Test-Path $Script:Config.Pwsh7Exe)) {
        $pwshInfo = Fetch-LatestPwsh7ReleaseInfo
        if (-not $pwshInfo) {
            Write-Log "Не удалось получить информацию о релизе PS7. Откат к однопоточному режиму." 'Yellow'
            $Script:Config.UseParallel = 0
            return $false
        }
        Write-Log "Доступна PowerShell v$($pwshInfo.Version) (~$($pwshInfo.SizeMB)МБ)" 'Gray'
        if (-not (Invoke-FileDownload -Name "PowerShell-$($pwshInfo.Version)" -Url $pwshInfo.DownloadUrl -DestinationDir $Script:Config.Pwsh7Dir -DestinationFile 'pwsh.zip' -SizeMB $pwshInfo.SizeMB)) {
            $Script:Config.UseParallel = 0
            return $false
        }
    }
    Write-Log "🔄 Перезапуск через PowerShell 7 (Portable)..." 'Cyan'
    $argList = @()
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [switch]) {
            if ($_.Value.IsPresent) { $argList += "-$($_.Key)" }
        } else {
            $argList += "-$($_.Key)"; $argList += $_.Value
        }
    }
    & $Script:Config.Pwsh7Exe -File $PSCommandPath @argList
    exit $LASTEXITCODE
}

<#
.SYNOPSIS
    Расчёт оптимального количества потоков для параллельной обработки
#>
function Calculate-OptimalThreadCount {
    [CmdletBinding()]
    [OutputType([int])]
    param()
    $logicalCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    if ($Script:Config.UseParallel -eq 1) {
        return [math]::Max(1, [math]::Floor($logicalCores / 2))
    }
    if ($Script:Config.UseParallel -gt $logicalCores) {
        Write-Log "Запрошено $($Script:Config.UseParallel) потоков, доступно $logicalCores. Используем $logicalCores." 'Yellow'
        return $logicalCores
    }
    return $Script:Config.UseParallel
}
#endregion

#region === УТИЛИТЫ: ВЕРСИОНИРОВАНИЕ (FALLBACK) ===
<#
.SYNOPSIS
    Инициализация запасных функций управления версиями
#>
function Initialize-VersionFunctionsFallback {
    Write-Log "Инициализация запасных функций версионирования..." 'Yellow'
    function global:Update-AllVersions {
        param([string]$ProjectRoot, [string]$NewVersion)
        Write-Log "Запасная функция Update-AllVersions: обновление версии пропущено" 'Yellow'
        Write-Log "Используйте параметр -SyncVersions для полной синхронизации версий" 'Yellow'
        return @{ Version = "0.0.0.0"; NuspecUpdated = 0; ResxUpdated = 0 }
    }
    function global:Sync-Versions {
        param([string]$ProjectRoot, [switch]$Force)
        Write-Log "Запасная функция Sync-Versions: синхронизация версий пропущена" 'Yellow'
        Write-Log "Пожалуйста, проверьте наличие файла VersionManager.psm1" 'Yellow'
        return $false
    }
    function global:Get-CurrentVersion {
        param([string]$ProjectRoot)
        return "0.0.0.0"
    }
}
#endregion

#region === УТИЛИТЫ: РАБОТА С ХЭШАМИ И ФАЙЛАМИ ===
<#
.SYNOPSIS
    Безопасное вычисление SHA256 хэша файла
#>
function Compute-FileHashSafe {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    try {
        return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    }
    catch {
        Write-Log "Ошибка вычисления хэша для ${FilePath}: $_" 'Red'
        return $null
    }
}

<#
.SYNOPSIS
    Загрузка предыдущих хэшей из кэш-файла
#>
function Load-PreviousFileHashes {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][string]$HashesFilePath)
    if (-not (Test-Path $HashesFilePath)) { return @{} }
    try {
        $hashes = Get-Content $HashesFilePath | ConvertFrom-Json -AsHashtable
        Write-Host "Загружено хэшей из кэша: $($hashes.Count)" -ForegroundColor Gray
        return $hashes
    }
    catch {
        Write-Host "Не удалось загрузить кэш хэшей, создаем новый" -ForegroundColor Yellow
        return @{}
    }
}

<#
.SYNOPSIS
    Сохранение текущих хэшей в кэш-файл + история изменений
#>
function Save-CurrentFileHashes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Hashes,
        [Parameter(Mandatory)][string]$OutputPath
    )
    try {
        $toSave = @{}
        foreach ($key in $Hashes.Keys) {
            $toSave[$key] = @{
                Hash = $Hashes[$key].Hash
                LastWriteTime = $Hashes[$key].LastWriteTime.ToString('o')
                Size = $Hashes[$key].Size
            }
        }
        $toSave | ConvertTo-Json -Depth 3 | Out-File $OutputPath -Encoding UTF8 -Force
        $historyPath = $OutputPath -replace '\.json$', '.history.json'
        $historyEntry = @{
            Timestamp = Get-Date -Format 'o'
            FileCount = $Hashes.Count
            Snapshot = $toSave
        }
        $history = @()
        if (Test-Path $historyPath) {
            try {
                $existing = Get-Content $historyPath | ConvertFrom-Json -Depth 3
                if ($existing -is [array]) { $history = @($existing) }
                elseif ($existing -is [object]) { $history = @($existing) }
            }
            catch { Write-Host "История повреждена, создаём новую" -ForegroundColor Yellow }
        }
        $history = @($historyEntry) + $history
        if ($history.Count -gt 10) { $history = $history | Select-Object -First 10 }
        $history | ConvertTo-Json -Depth 3 | Out-File $historyPath -Encoding UTF8 -Force
        Write-Host "Сохранено хэшей в кэш: $($Hashes.Count) | История: $($history.Count) версий" -ForegroundColor Gray
    }
    catch {
        Write-Host "Не удалось сохранить кэш хэшей: $_" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Показать историю изменений хэш-файла
#>
function Get-HashHistory {
    [CmdletBinding()]
    param([string]$HashesFilePath = '.\build\resx-hashes.json')
    $historyPath = $HashesFilePath -replace '\.json$', '.history.json'
    if (-not (Test-Path $historyPath)) {
        Write-Host "История не найдена: $historyPath" -ForegroundColor Yellow
        return
    }
    try {
        $history = Get-Content $historyPath | ConvertFrom-Json
        Write-Host "`n=== История изменений хэшей ===" -ForegroundColor Cyan
        Write-Host "Всего версий: $($history.Count)" -ForegroundColor Gray
        for ($i = 0; $i -lt $history.Count; $i++) {
            $entry = $history[$i]
            $date = [DateTime]::Parse($entry.Timestamp).ToString('dd.MM.yyyy HH:mm:ss')
            $marker = if ($i -eq 0) { '← текущая' } else { '' }
            Write-Host "[$($i + 1)] $date — $($entry.FileCount) файлов $marker" -ForegroundColor $(if($i -eq 0){'Green'}else{'Gray'})
        }
    }
    catch {
        Write-Host "Ошибка чтения истории: $_" -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Анализ изменений в .resx файлах по хэшам
#>
function Analyze-ResxFileChanges {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$ResxFolder,
        [Parameter(Mandatory)][hashtable]$PreviousHashes
    )
    $currentFiles = @(Get-ChildItem -Path $ResxFolder -Filter '*.resx' -Recurse -File -ErrorAction SilentlyContinue)
    if ($currentFiles.Count -eq 0) {
        Write-Host "Не найдено .resx файлов в папке: $ResxFolder" -ForegroundColor Yellow
        return @{Files=@(); Hashes=@{}; Changed=@(); New=@(); Unchanged=@(); Deleted=@()}
    }
    $currentHashes = @{}
    $changed = @(); $new = @(); $unchanged = @()
    foreach ($file in $currentFiles) {
        $relativePath = $file.FullName.Substring((Resolve-Path $ResxFolder).Path.Length + 1)
        $hash = Compute-FileHashSafe -FilePath $file.FullName
        if ($hash) {
            $currentHashes[$relativePath] = @{
                Hash = $hash
                LastWriteTime = $file.LastWriteTime
                Size = $file.Length
                FullPath = $file.FullName
            }
            if ($PreviousHashes.ContainsKey($relativePath)) {
                if ($PreviousHashes[$relativePath].Hash -ne $hash) {
                    $changed += $file
                    Write-Host "[ИЗМЕНЕН] $relativePath" -ForegroundColor Yellow
                } else {
                    $unchanged += $file
                }
            } else {
                $new += $file
                Write-Host "[НОВЫЙ] $relativePath" -ForegroundColor Green
            }
        }
    }
    $deleted = @()
    foreach ($key in $PreviousHashes.Keys) {
        if (-not $currentHashes.ContainsKey($key)) {
            $deleted += $key
            Write-Host "[УДАЛЕН] $key" -ForegroundColor Red
        }
    }
    return @{Files=$currentFiles; Hashes=$currentHashes; Changed=$changed; New=$new; Unchanged=$unchanged; Deleted=$deleted}
}

<#
.SYNOPSIS
    Вывод статистики изменений в консоль
#>
function Display-ChangeStatistics {
    [CmdletBinding()]
    param(
        [int]$Total, [int]$Changed, [int]$New, [int]$Deleted, [int]$Unchanged, [int]$ToConvert
    )
    Write-Host "`n=== Статистика изменений ===" -ForegroundColor Cyan
    Write-Host "Всего файлов: $Total" -ForegroundColor White
    Write-Host "Измененных: $Changed" -ForegroundColor $(if($Changed -gt 0){'Yellow'}else{'Gray'})
    Write-Host "Новых: $New" -ForegroundColor $(if($New -gt 0){'Green'}else{'Gray'})
    Write-Host "Удаленных: $Deleted" -ForegroundColor $(if($Deleted -gt 0){'Red'}else{'Gray'})
    Write-Host "Без изменений: $Unchanged" -ForegroundColor Gray
    Write-Host "Файлов для конвертации: $ToConvert" -ForegroundColor $(if($ToConvert -gt 0){'Cyan'}else{'Gray'})
    $hasChanges = ($Changed -gt 0) -or ($New -gt 0) -or ($Deleted -gt 0)
    Write-Host "Есть изменения: $(if($hasChanges){'ДА'}else{'НЕТ'})" -ForegroundColor $(if($hasChanges){'Yellow'}else{'Green'})
}

<#
.SYNOPSIS
    Получение списка файлов, требующих конвертации
#>
function Get-FilesToConvert {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$ResxFolder,
        [Parameter(Mandatory)][string]$HashesFile
    )
    Write-Host "`n=== Проверка изменений в .resx файлах ===" -ForegroundColor Cyan
    Ensure-DirectoryForFile -FilePath $HashesFile
    $previousHashes = Load-PreviousFileHashes -HashesFilePath $HashesFile
    $analysis = Analyze-ResxFileChanges -ResxFolder $ResxFolder -PreviousHashes $previousHashes
    $toConvert = $analysis.Changed + $analysis.New
    Save-CurrentFileHashes -Hashes $analysis.Hashes -OutputPath $HashesFile
    Display-ChangeStatistics -Total $analysis.Files.Count -Changed $analysis.Changed.Count -New $analysis.New.Count -Deleted $analysis.Deleted.Count -Unchanged $analysis.Unchanged.Count -ToConvert $toConvert.Count
    $hasChanges = ($analysis.Changed.Count -gt 0) -or ($analysis.New.Count -gt 0) -or ($analysis.Deleted.Count -gt 0)
    return @{
        FilesToConvert = $toConvert
        HasChanges = $hasChanges
        ChangedFiles = $analysis.Changed
        NewFiles = $analysis.New
        DeletedFiles = $analysis.Deleted
        TotalFiles = $analysis.Files.Count
        UnchangedFiles = $analysis.Unchanged
    }
}
#endregion

#region === УТИЛИТЫ: КОНВЕРТАЦИЯ ФАЙЛОВ ===
<#
.SYNOPSIS
    Конвертация одного .resx файла с выводом статистики и детализацией ошибок
#>
function Convert-SingleResxFile {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$InputFile,
        [Parameter(Mandatory)][string]$OutputFile,
        [Parameter(Mandatory)][string]$ResGenPath
    )
    
    $fileName = Split-Path $InputFile -Leaf
    $result = & $ResGenPath $InputFile $OutputFile 2>&1
    $success = ($LASTEXITCODE -eq 0)
    
    # Парсим вывод ResGen для статистики и ошибок
    $resourceCount = 0
    $errorDetails = @()
    $errorLocations = @()
    
    if ($result) {
        foreach ($line in $result) {
            # Ищем строку "Чтение в N ресурсов из ..."
            if ($line -match 'Чтение в\s+(\d+)\s+ресурсов') {
                $resourceCount = [int]$Matches[1]
            }
            
            # Собираем ошибки с парсингом позиции
            if ($line -match 'error RG|Ошибка|Error') {
                $errorDetails += $line.Trim()
                
                # Парсим строку и позицию: "line 42", "строка 42", "position 15", "позиция 15"
                $lineNum = $null
                $position = $null
                
                if ($line -match '(?:line|строка)\s+(\d+)') {
                    $lineNum = [int]$Matches[1]
                }
                if ($line -match '(?:position|позиция)\s+(\d+)') {
                    $position = [int]$Matches[1]
                }
                
                if ($lineNum -or $position) {
                    $errorLocations += @{
                        Line = $lineNum
                        Position = $position
                        Message = $line.Trim()
                    }
                }
            }
        }
        # Логируем полный вывод
        $result | Out-File -FilePath $Script:Config.LogFile -Append -Encoding UTF8
    }
    
    # Формируем вывод
    if ($success) {
        Write-Host "  [✓] $fileName" -ForegroundColor Green
        Write-Host "      Ресурсов: $resourceCount | Выход: $(Split-Path $OutputFile -Leaf)" -ForegroundColor Gray
    } else {
        Write-Host "  [!] $fileName" -ForegroundColor Red
        
        if ($errorLocations.Count -gt 0) {
            foreach ($err in $errorLocations) {
                $location = ""
                if ($err.Line) { $location += "Строка $($err.Line)" }
                if ($err.Position) { $location += ", Позиция $($err.Position)" }
                
                Write-Host "      $location" -ForegroundColor Yellow
                Write-Host "      $($err.Message)" -ForegroundColor Yellow
                
                # Показываем проблемную строку из файла (если есть номер строки)
                if ($err.Line -and (Test-Path $InputFile)) {
                    try {
                        $lines = Get-Content $InputFile -Encoding UTF8
                        if ($err.Line -le $lines.Count) {
                            $problemLine = $lines[$err.Line - 1].Trim()
                            Write-Host "      Код: $problemLine" -ForegroundColor DarkGray
                            
                            # Показываем позицию символом ^
                            if ($err.Position -and $err.Position -le $problemLine.Length) {
                                $pointer = " " * ($err.Position - 1) + "^"
                                Write-Host "      $pointer" -ForegroundColor Red
                            }
                        }
                    }
                    catch {
                        Write-Host "      (Не удалось прочитать строку из файла)" -ForegroundColor DarkGray
                    }
                }
            }
        } elseif ($errorDetails) {
            Write-Host "      Ошибка: $($errorDetails[0])" -ForegroundColor Yellow
        }
    }
    
    return @{
        Success = $success
        ResourceCount = $resourceCount
        ErrorCount = if ($success) { 0 } else { $errorDetails.Count }
        ErrorDetails = $errorDetails
        ErrorLocations = $errorLocations
    }
}

<#
.SYNOPSIS
    Форматирование блока ошибки для лог-файла
#>
function Format-ErrorBlock {
    [CmdletBinding()]
    [OutputType([string[]])]
    param([int]$ErrorIndex, [string]$FilePath, [int]$ErrorCount, [object[]]$ErrorLines)
    $block = @()
    $block += "Ошибка №$ErrorIndex"
    $block += "Файл: $FilePath"
    $block += "Количество ошибок: $ErrorCount"
    $block += "Описание:"
    $block += $ErrorLines
    $block += ""
    return $block
}

<#
.SYNOPSIS
    Конвертация файлов в последовательном режиме с детальной статистикой
#>
function Convert-FilesSequential {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][object[]]$Files,
        [Parameter(Mandatory)][string]$OutputDir,
        [Parameter(Mandatory)][string]$ResGenPath
    )
    
    $stats = @{
        Success = 0
        Errors = 0
        TotalResources = 0
        ErrorDetails = @()
        StartTime = Get-Date
    }
    
    Write-Host "`n  Исходная папка: $($Script:Config.ResxFolder)" -ForegroundColor Gray
    Write-Host "  Выходная папка: $OutputDir" -ForegroundColor Gray
    Write-Host "  Файлов к конвертации: $($Files.Count)" -ForegroundColor Gray
    Write-Host ""
    
    foreach ($file in $Files) {
        $outputPath = Join-Path $OutputDir ($file.BaseName + '.resources')
        $result = Convert-SingleResxFile -InputFile $file.FullName -OutputFile $outputPath -ResGenPath $ResGenPath
        
        if ($result.Success) {
            $stats.Success++
            $stats.TotalResources += $result.ResourceCount
        } else {
            $stats.Errors++
            $stats.ErrorDetails += @{File = $file.Name; Errors = $result.ErrorDetails}
        }
    }
    
    $stats.Elapsed = (Get-Date) - $stats.StartTime
    return $stats
}

<#
.SYNOPSIS
    Конвертация файлов в параллельном режиме с детальной статистикой
#>
function Convert-FilesParallel {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][object[]]$Files,
        [Parameter(Mandatory)][string]$OutputDir,
        [Parameter(Mandatory)][string]$ResGenPath,
        [Parameter(Mandatory)][int]$ThreadLimit
    )
    
    Write-Host "`n  Исходная папка: $($Script:Config.ResxFolder)" -ForegroundColor Gray
    Write-Host "  Выходная папка: $OutputDir" -ForegroundColor Gray
    Write-Host "  Файлов к конвертации: $($Files.Count) | Потоков: $ThreadLimit" -ForegroundColor Gray
    Write-Host ""
    
    $results = $Files | ForEach-Object -Parallel {
        $f = $_
        $rg = $using:ResGenPath
        $outDir = $using:OutputDir
        $logFile = $using:Script:Config.LogFile
        
        $fileName = Split-Path $f.FullName -Leaf
        $outputPath = Join-Path $outDir ($f.BaseName + '.resources')
        
        $result = & $rg $f.FullName $outputPath 2>&1
        $success = ($LASTEXITCODE -eq 0)
        
        # Парсим вывод для статистики
        $resourceCount = 0
        $errorDetails = @()
        if ($result) {
            foreach ($line in $result) {
                if ($line -match 'Чтение в\s+(\d+)\s+ресурсов') {
                    $resourceCount = [int]$Matches[1]
                }
                if ($line -match 'error RG|Ошибка|Error') {
                    $errorDetails += $line.Trim()
                }
            }
            # Логируем в общий файл (с блокировкой для безопасности)
			try {
				# Формируем блок с заголовком
				$logBlock = @(
					"=== [$fileName] ===",
					"Input:  $($f.FullName)",
					"Output: $outputPath", 
					"Time:   $(Get-Date -Format 'HH:mm:ss')",
					""
				)
				
				# Добавляем вывод ResGen
				if ($result) {
					$logBlock += $result
				}
				$logBlock += ""  # Пустая строка между файлами
				
				# Атомарная запись всего блока
				$logContent = $logBlock -join "`n"
				[System.IO.File]::AppendAllText($logFile, $logContent + "`n", [System.Text.Encoding]::UTF8)
			}
			catch {
				# Игнорируем ошибки логирования в параллельном режиме
			}
        }
        
        # Вывод в консоль (может быть не в порядке файлов, но это ок для параллелизма)
		if ($success) {
			Write-Host "  [✓] $fileName" -ForegroundColor Green
		} else {
			Write-Host "  [!] $fileName" -ForegroundColor Red
		}
        
        return @{
            Success = $success
            ResourceCount = $resourceCount
            ErrorCount = if ($success) { 0 } else { 1 }
            ErrorDetails = $errorDetails
            FileName = $fileName
        }
    } -ThrottleLimit $ThreadLimit
    
    # Агрегируем статистику
    $stats = @{
        Success = ($results | Where-Object { $_.Success }).Count
        Errors = ($results | Where-Object { -not $_.Success }).Count
        TotalResources = ($results | Where-Object { $_.Success } | Measure-Object -Property ResourceCount -Sum).Sum
        ErrorDetails = ($results | Where-Object { -not $_.Success } | ForEach-Object { @{File = $_.FileName; Errors = $_.ErrorDetails } })
        StartTime = (Get-Date).AddSeconds(-1)  # Приблизительно, т.к. параллельно
    }
    $stats.Elapsed = (Get-Date) - $stats.StartTime
    
    return $stats
}

<#
.SYNOPSIS
    Универсальный запрос Yes/No с поддержкой русской раскладки
#>
function Request-YesNo {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Question,
        [ValidateSet('Y', 'N')][string]$Default = 'N'
    )
    $defaultValue = $Default.ToUpper()
    $suffix = if ($defaultValue -eq 'Y') { 'Y/n' } else { 'y/N' }
    $answer = Read-Host "$Question ($suffix)"
    $normalized = $answer.Trim().ToLower()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        Write-Host "Использовано значение по умолчанию: $defaultValue" -ForegroundColor Gray
        return ($defaultValue -eq 'Y')
    }
    if ($normalized -in @('y', 'т', 'да', 'д')) { return $true }
    if ($normalized -in @('n', 'н', 'нет')) { return $false }
    Write-Host "Непонятный ввод '$answer', используем значение по умолчанию: $defaultValue" -ForegroundColor Yellow
    return ($defaultValue -eq 'Y')
}

<#
.SYNOPSIS
    Запрос пользователя о конвертации всех файлов при отсутствии изменений
#>
function Prompt-ConvertAllIfNoChanges {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][int]$TotalFiles,
        [Parameter(Mandatory)][string]$ResourcesOutput
    )
    Write-Host "`n⚠️  Изменений в .resx файлах не обнаружено!" -ForegroundColor Yellow
    $resourcesExist = $false
    if (Test-Path $ResourcesOutput) {
        $rf = @(Get-ChildItem -Path $ResourcesOutput -Filter '*.resources' -Recurse)
        if ($rf.Count -ge $TotalFiles) {
            $resourcesExist = $true
            Write-Host "Обнаружены существующие .resources файлы ($($rf.Count) шт.)" -ForegroundColor Gray
        }
    }
    if (-not $resourcesExist) { 
        Write-Host ".resources файлы не найдены. Конвертация будет выполнена." -ForegroundColor Cyan
        return $true 
    }
    return Request-YesNo -Question "Продолжить конвертацию всех файлов" -Default 'N'
}
#endregion

#region === УТИЛИТЫ: СБОРКА ПАКЕТОВ ===
<#
.SYNOPSIS
    Получение текущей версии для сборки из nuspec или модуля
#>
function Resolve-BuildVersion {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $nuspecPath = Join-Path $ProjectRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
    if (Test-Path $nuspecPath) {
        $content = Get-Content $nuspecPath -Raw
        if ($content -match '<version>(.*?)</version>') {
            return $Matches[1]
        }
    }
    return Get-CurrentVersion -ProjectRoot $ProjectRoot
}

<#
.SYNOPSIS
    Запуск скрипта сборки NuGet пакета
#>
function Invoke-NuGetBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BuildScriptPath,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$OutputDir
    )
    if (-not (Test-Path $BuildScriptPath)) {
        Write-Log "Скрипт сборки не найден: $BuildScriptPath" 'Yellow'
        return $false
    }
    Write-Host "=== Building NuGet package (version: $Version) ==="
    & $BuildScriptPath -Version $Version -Output $OutputDir 2>&1 | Tee-Object -FilePath $Script:Config.LogFile -Append
    return ($LASTEXITCODE -eq 0)
}

<#
.SYNOPSIS
    Запуск скрипта сборки JetBrains Marketplace пакета
#>
function Invoke-MarketplaceBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BuildScriptPath,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$OutputDir
    )
    if (-not (Test-Path $BuildScriptPath)) {
        Write-Log "Скрипт сборки не найден: $BuildScriptPath" 'Yellow'
        return $false
    }
    Write-Host "=== Building JetBrains Marketplace package (version: $Version) ==="
    & $BuildScriptPath -Version $Version -Output $OutputDir 2>&1 | Tee-Object -FilePath $Script:Config.LogFile -Append
    return ($LASTEXITCODE -eq 0)
}
#endregion

#region === ИНФРАСТРУКТУРА: СПРАВКА И ИНИЦИАЛИЗАЦИЯ ===
<#
.SYNOPSIS
    Отображение полной справки по скрипту
#>
function Show-ScriptHelp {
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
    
    # ПАРАЛЛЕЛИЗМ И ИНФРАСТРУКТУРА
    -UseParallel, -up [int]     Потоки для ResGen (PS7+). 1 = авто (половина ядер). Алиасы: -t, -Threads
    -AcceptAll, -aa             Авто-согласие на загрузку инструментов (для CI/CD)
    -CleanTools                 Очистить папку ./Tools перед запуском
    -NoNetwork                  Запретить сетевые запросы
    
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
    
    С ПАРАЛЛЕЛИЗМОМ:
    .\resx-to-resources.ps1 -up 8 -sv                # 8 потоков + синхронизация версий
    
    УМНЫЙ ПАРАЛЛЕЛИЗМ:
    .\resx-to-resources.ps1 -up                      # Авто-выбор потоков (половина ядер)
    
    CI/CD (без автоинкремента):
    .\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild -aa  # Только конвертация всех файлов
    
    Только сборка:
    .\resx-to-resources.ps1 -BuildOnly               # Только сборка (пропустить resgen)
    
    Только конвертация:
    .\resx-to-resources.ps1 -NoBuild                 # Только генерация .resources
    
    ОФФЛАЙН РЕЖИМ:
    .\resx-to-resources.ps1 -NoNetwork -nr           # Работа только с установленными инструментами
    
    Краткие формы:
    .\resx-to-resources.ps1 -fa -svu -nb -aa         # Для CI/CD
    .\resx-to-resources.ps1 -bo                      # Только сборка
    .\resx-to-resources.ps1 -nr                      # Пропустить resgen
    .\resx-to-resources.ps1 -sv                      # Синхронизация версий

РЕЖИМЫ РАБОТЫ:
    1. Без параметров:           проверка → resgen → сборка (полный процесс с автоинкрементом)
    2. -NoBuild (-nb):           проверка → resgen → остановка
    3. -BuildOnly (-bo):         проверка → сборка (пропуск resgen)
    4. -ForceAll -SkipVersionUpdate: CI/CD режим (все файлы, без инкремента версии)
    5. -UseParallel (-up):       Ускоренная обработка (требует PS7, автоматически разворачивается в ./Tools)

PORTABLE-ИНФРАСТРУКТУРА:
    Скрипт поддерживает автономную работу в папке ./Tools:
    - При отсутствии ResGen.exe/NuGet.exe предложит скачать их
    - При использовании -up и отсутствии PS7 скачает Portable PowerShell 7
    - Все загрузки требуют подтверждения (если не указан -aa)
    - Перед загрузкой проверяется наличие 500МБ свободного места
    - Используйте -CleanTools для сброса кэша инструментов
"@
}

<#
.SYNOPSIS
    Инициализация параметров режимов работы
#>
function Initialize-ModeFlags {
    [CmdletBinding()]
    param()
    $Script:Config.SkipBuild = $Script:NoBuild -or $Script:NoBuildAlias
    $Script:Config.SkipResgen = $Script:NoResgen -or $Script:NoResgenAlias
    $Script:Config.BuildOnly = $Script:BuildOnly -or $Script:BuildOnlyAlias
    $Script:Config.SyncVersionsFlag = $Script:SyncVersions -or $Script:SyncVersionsAlias
    $Script:Config.SkipVersionUpdateFlag = $Script:SkipVersionUpdate -or $Script:SkipVersionUpdateAlias
    $Script:Config.ForceAllFlag = $Script:ForceAll -or $Script:ForceAllAlias
}

<#
.SYNOPSIS
    Проверка конфликтующих параметров
#>
function Validate-ParameterConflicts {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    if ($Script:Config.SkipBuild -and $Script:Config.BuildOnly) {
        Write-Host "Ошибка: Параметры -NoBuild и -BuildOnly не могут быть использованы вместе!" -ForegroundColor Red
        Write-Host "Используйте один из них." -ForegroundColor Red
        return $false
    }
    return $true
}

<#
.SYNOPSIS
    Вывод информации о текущих режимах работы
#>
function Display-ActiveModes {
    [CmdletBinding()]
    param()
    if ($Script:Config.SkipResgen -and -not $Script:Config.SkipBuild -and -not $Script:Config.BuildOnly) {
        Write-Host "`nРежим: Пропуск генерации .resources, но выполнение сборки" -ForegroundColor Cyan
    }
    if ($Script:Config.BuildOnly) {
        Write-Host "`nРежим: Только сборка (пропуск генерации .resources)" -ForegroundColor Cyan
        $Script:Config.SkipResgen = $true
    }
    if ($Script:Config.SyncVersionsFlag) { Write-Host "`nРежим: Синхронизация версий" -ForegroundColor Cyan }
    if ($Script:Config.SkipVersionUpdateFlag) { Write-Host "`nРежим: Автоматическое обновление версии отключено" -ForegroundColor Cyan }
    if ($Script:Config.ForceAllFlag) { Write-Host "`nРежим: Принудительная конвертация всех .resx файлов" -ForegroundColor Cyan }
}

<#
.SYNOPSIS
    Проверка наличия инструментов и деградация функционала
#>
function Validate-ToolAvailability {
    [CmdletBinding()]
    param()
    if (-not $Script:Config.ResGenPath -and -not $Script:Config.SkipResgen -and -not $Script:Config.BuildOnly) {
        Write-Host "ResGen.exe не найден. Пропускаем генерацию .resources" -ForegroundColor Yellow
        $Script:Config.SkipResgen = $true
    }
    if (-not $Script:Config.NuGetPath -and -not $Script:Config.SkipBuild) {
        Write-Host "NuGet.exe не найден. Сборка может завершиться ошибкой" -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Загрузка модуля управления версиями или инициализация фоллбэка
#>
function Initialize-VersionModule {
    [CmdletBinding()]
    param()
    $modulePath = Join-Path $Script:Config.ScriptRoot 'VersionManager.psm1'
    if (Test-Path $modulePath) {
        try {
            Import-Module $modulePath -Force -ErrorAction Stop
            Write-Host "Модуль VersionManager успешно загружен" -ForegroundColor Gray
        }
        catch {
            Write-Host "Ошибка при загрузке модуля VersionManager: $_" -ForegroundColor Red
            Initialize-VersionFunctionsFallback
        }
    } else {
        Write-Host "Модуль VersionManager не найден: $modulePath" -ForegroundColor Red
        Initialize-VersionFunctionsFallback
    }
}

<#
.SYNOPSIS
    Полная инициализация скрипта перед выполнением
#>
function Initialize-Script {
    [CmdletBinding()]
    param()
    if ($Script:Help -or $Script:HelpAlias) { Show-ScriptHelp; exit 0 }
    if ($Script:CleanTools) {
        if (Test-Path $Script:Config.ToolsDir) {
            Write-Host "Очистка $($Script:Config.ToolsDir)..." -ForegroundColor Yellow
            Get-ChildItem $Script:Config.ToolsDir -Exclude 'README.txt' | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Очистка завершена" -ForegroundColor Green
        }
    }
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $cpuName = $cpu.Name -replace '\s+',' ' -replace '\(R\)|\(TM\)','' -replace '^\s+|\s+$',''
    $psVer = $PSVersionTable.PSVersion.ToString()
    $portable = if ($PSScriptRoot -like '*Tools*') { 'Yes' } else { 'No' }
    Write-Host "[INFO] PowerShell v$psVer | Portable: $portable | CPU: $cpuName" -ForegroundColor Gray
    Ensure-DirectoryForFile -FilePath $Script:Config.LogFile
    Ensure-DirectoryForFile -FilePath $Script:Config.ErrorLogFile
    Remove-Item $Script:Config.LogFile, $Script:Config.ErrorLogFile -ErrorAction SilentlyContinue
    Ensure-PowerShell7Available | Out-Null
    if ($Script:Config.UseParallel -gt 0 -and $PSVersionTable.PSVersion.Major -ge 7) {
        $Script:Config.MaxThreads = Calculate-OptimalThreadCount
        Write-Host "Потоков: $($Script:Config.MaxThreads) (из $((Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors) доступных)" -ForegroundColor Gray
    } elseif ($Script:Config.UseParallel -gt 0) {
        Write-Host "Параллелизм требует PS7+. Работа в 1 поток." -ForegroundColor Yellow
        $Script:Config.UseParallel = 0
    }
    $Script:Config.ResGenPath = Resolve-ResGenPath
    if (-not $Script:Config.ResGenPath -and (Test-Path $Script:Config.OriginalResGenPath)) {
        $Script:Config.ResGenPath = $Script:Config.OriginalResGenPath
        Write-Host "Используется оригинальный путь к ResGen: $($Script:Config.OriginalResGenPath)" -ForegroundColor Gray
    }
    $Script:Config.NuGetPath = Resolve-NuGetPath
    Initialize-ModeFlags
    if (-not (Validate-ParameterConflicts)) { exit 1 }
    Display-ActiveModes
    Validate-ToolAvailability
    Initialize-VersionModule
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
}
#endregion

#region === ОСНОВНЫЕ ЭТАПЫ ВЫПОЛНЕНИЯ ===
<#
.SYNOPSIS
    Этап 0: Синхронизация версий (если запрошено)
#>
function Invoke-VersionSyncStage {
    [CmdletBinding()]
    param()
    if (-not $Script:Config.SyncVersionsFlag) { return }
    
    Write-Host "`n=== Этап 0: Синхронизация версий ===" -ForegroundColor Cyan
    try {
        $result = Sync-Versions -ProjectRoot $Script:Config.ScriptRoot -Force:$true -NewVersion $Script:Version
        Write-Host "Синхронизация версий завершена" -ForegroundColor Green
        
        # ✅ Помечаем, что версия уже обновлена
        if ($result -and $result.Version) {
            $Script:Config.VersionAlreadyUpdated = $true
            Write-Log "Версия обновлена до: $($result.Version)" 'Gray'
        }
    }
    catch {
        Write-Host "Ошибка при синхронизации версий: $_" -ForegroundColor Red
        exit 1
    }
}

<#
.SYNOPSIS
    Обновление версии при обнаружении изменений в .resx
#>
function Update-VersionIfChangesDetected {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Changes)
    
    # Если нет изменений или файлов — выходим
    if (-not $Changes.HasChanges -or $Changes.FilesToConvert.Count -eq 0) { return }
    
    # Если версия уже обновлена в этом запуске — не инкрементим повторно
    if ($Script:Config.VersionAlreadyUpdated) {
        Write-Log "Версия уже обновлена в этом запуске, пропускаю повторный инкремент" 'Gray'
        return
    }
    
    # Если автоинкремент отключен — выходим
    if ($Script:Config.SkipVersionUpdateFlag) {
        Write-Host "`nОбнаружены изменения, но обновление версии отключено (-SkipVersionUpdate)" -ForegroundColor Gray
        return
    }
    
    Write-Host "`nОбнаружены изменения, обновляю версию..." -ForegroundColor Yellow
    try {
        if ($Script:Version) {
            $result = Update-AllVersions -ProjectRoot $Script:Config.ScriptRoot -NewVersion $Script:Version
            Write-Host "Версия принудительно установлена: $($Script:Version)" -ForegroundColor Cyan
        } else {
            $result = Update-AllVersions -ProjectRoot $Script:Config.ScriptRoot
            Write-Host "Версия обновлена автоматически до: $($result.Version)" -ForegroundColor Green
        }
        Write-Host "Обновлено файлов: $($result.NuspecUpdated) nuspec, $($result.ResxUpdated) resx" -ForegroundColor Green
        
        # ✅ Помечаем, что версия обновлена
        $Script:Config.VersionAlreadyUpdated = $true
    }
    catch {
        Write-Host "Ошибка при обновлении версии: $_" -ForegroundColor Red
        Write-Host "Продолжаю конвертацию без обновления версии" -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Этап 1: Конвертация .resx -> .resources
#>
function Invoke-ResgenConversionStage {
    [CmdletBinding()]
    param()
    if ($Script:Config.SkipResgen) {
        Write-Host "`n=== Этап 1: Генерация .resources пропущена ===" -ForegroundColor Yellow
        "Generation of .resources files was skipped by user request." | Tee-Object -FilePath $Script:Config.LogFile -Append
        return
    }
    Write-Host "`n=== Этап 1: Конвертация resx -> resources ===" -ForegroundColor Green
    if ($Script:Config.ForceAllFlag) {
        Write-Host "Принудительная конвертация ВСЕХ файлов..." -ForegroundColor Cyan
        $all = @(Get-ChildItem -Path $Script:Config.ResxFolder -Filter '*.resx' -Recurse -File)
        $changes = @{FilesToConvert=$all; HasChanges=$true; ChangedFiles=@(); NewFiles=$all; DeletedFiles=@(); TotalFiles=$all.Count}
        Write-Host "Будет сконвертировано $($all.Count) файлов" -ForegroundColor Cyan
    } else {
        $changes = Get-FilesToConvert -ResxFolder $Script:Config.ResxFolder -HashesFile $Script:Config.HashesFile
    }
    Update-VersionIfChangesDetected -Changes $changes
    if (-not $Script:Config.ForceAllFlag -and $changes.FilesToConvert.Count -eq 0 -and $changes.TotalFiles -gt 0) {
        if (Prompt-ConvertAllIfNoChanges -TotalFiles $changes.TotalFiles -ResourcesOutput $Script:Config.ResourcesOutput) {
            $changes.FilesToConvert = @(Get-ChildItem -Path $Script:Config.ResxFolder -Filter '*.resx' -Recurse -File)
            Write-Host "Будет выполнена конвертация всех файлов ($($changes.FilesToConvert.Count) шт.)" -ForegroundColor Cyan
        } else {
            Write-Host "Конвертация пропущена" -ForegroundColor Yellow
            $Script:Config.SkipResgen = $true
            if (-not $Script:Config.SkipBuild) { Write-Host "`nПереход к этапу сборки..." -ForegroundColor Cyan }
            return
        }
    }
    if ($changes.FilesToConvert.Count -eq 0) {
        Write-Host "`nНет файлов для конвертации." | Tee-Object -FilePath $Script:Config.LogFile -Append
        if (-not $Script:Config.SkipBuild) {
            Write-Host "`nРесурсные файлы не найдены или не требуют конвертации, продолжаем сборку..." -ForegroundColor Yellow
        } else { exit 0 }
        return
    }
    Ensure-DirectoryForFile -FilePath (Join-Path $Script:Config.ResourcesOutput 'dummy.resources')
    Write-Host "`nConverting $($changes.FilesToConvert.Count) file(s) in: $($Script:Config.ResxFolder)" | Tee-Object -FilePath $Script:Config.LogFile -Append
    $start = Get-Date
    if ($Script:Config.MaxThreads -gt 1 -and $Script:Config.ResGenPath) {
        Write-Host "🚀 Режим: Параллельный ($($Script:Config.MaxThreads) потоков)" -ForegroundColor Cyan
        $stats = Convert-FilesParallel -Files $changes.FilesToConvert -OutputDir $Script:Config.ResourcesOutput -ResGenPath $Script:Config.ResGenPath -ThreadLimit $Script:Config.MaxThreads
    } else {
        $stats = Convert-FilesSequential -Files $changes.FilesToConvert -OutputDir $Script:Config.ResourcesOutput -ResGenPath $Script:Config.ResGenPath
    }
    $elapsed = $stats.Elapsed
	$totalFiles = $changes.FilesToConvert.Count
	
	Write-Host ""
	Write-Host "  ═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
	Write-Host "  ИТОГИ КОНВЕРТАЦИИ" -ForegroundColor Cyan
	Write-Host "  ═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
	Write-Host "  Файлов обработано: $totalFiles" -ForegroundColor White
	Write-Host "  Успешно:           $($stats.Success)" -ForegroundColor $(if($stats.Success -eq $totalFiles){'Green'}else{'Yellow'})
	Write-Host "  Ошибок:            $($stats.Errors)" -ForegroundColor $(if($stats.Errors -eq 0){'Green'}else{'Red'})
	Write-Host "  Всего ресурсов:    $($stats.TotalResources)" -ForegroundColor Gray
	Write-Host "  Время:             $($elapsed.TotalSeconds.ToString('F2')) сек." -ForegroundColor Gray
	Write-Host "  Скорость:          $([math]::Round($totalFiles / $elapsed.TotalSeconds, 2)) файлов/сек." -ForegroundColor Gray
	Write-Host "  ═════════════════════════════════════════════════════════════" -ForegroundColor Cyan
	Write-Host ""

    if ($stats.Errors -gt 0 -and -not $Script:Config.SkipBuild) {
        $answer = Read-Host "`nПродолжить сборку несмотря на ошибки? (y/N)"
        if ($answer -ne 'y' -and $answer -ne 'Y') { exit 1 }
    }
}

<#
.SYNOPSIS
    Этап 2: Сборка пакетов
#>
function Invoke-PackageBuildStage {
    [CmdletBinding()]
    param()
    if ($Script:Config.SkipBuild) {
        Write-Host "`n=== Этап 2: Сборка пакетов пропущена ===" -ForegroundColor Yellow
        "Building of packages was skipped by user request." | Tee-Object -FilePath $Script:Config.LogFile -Append
        return
    }
    Write-Host "`n=== Этап 2: Сборка пакетов ===" -ForegroundColor Green
    try {
        $version = Resolve-BuildVersion -ProjectRoot $Script:Config.ScriptRoot
        $nugetScript = Join-Path $Script:Config.ScriptRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\build.ps1'
        Invoke-NuGetBuild -BuildScriptPath $nugetScript -Version $version -OutputDir '..\artifacts' | Out-Null
        $marketplaceScript = Join-Path $Script:Config.ScriptRoot 'MarketplaceFolder\BaHooo.ReSharper.I18n.ru\build.ps1'
        Invoke-MarketplaceBuild -BuildScriptPath $marketplaceScript -Version $version -OutputDir '..\artifacts' | Out-Null
        Write-Host "`n=== Сборка успешно завершена ===" -ForegroundColor Green
    }
    catch {
        $msg = "ERROR in build.ps1: $($_.Exception.Message)"
        Write-Host $msg -ForegroundColor Red
        $msg | Out-File -FilePath $Script:Config.ErrorLogFile -Append -Encoding UTF8
        exit 1
    }
}
#endregion

#region === ЗАПРОС ПОДТВЕРЖДЕНИЯ И ТОЧКА ВХОДА ===
<#
.SYNOPSIS
    Запрос подтверждения на запуск скрипта по умолчанию.
#>
function Request-ScriptExecution {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    Write-Host @"
═══════════════════════════════════════════════════════════════════════════════
  RESX TO RESOURCES CONVERTER — БАЗОВАЯ СПРАВКА
═══════════════════════════════════════════════════════════════════════════════

ИСПОЛЬЗОВАНИЕ:
    .\resx-to-resources.ps1 [ПАРАМЕТРЫ]

КРАТКОЕ ОПИСАНИЕ:
    Скрипт автоматизирует конвертацию .resx → .resources, управление версиями
    и сборку пакетов. Поддерживает инкрементальную сборку по хэшам и параллелизм.

БЫСТРЫЕ КОМАНДЫ:
    .\resx-to-resources.ps1              # Полный процесс
    .\resx-to-resources.ps1 -up -sv      # Параллельно + синхронизация
    .\resx-to-resources.ps1 -fa -svu -nb # CI/CD режим
    .\resx-to-resources.ps1 -Help        # Подробная справка

═══════════════════════════════════════════════════════════════════════════════
  ЗАПУСК СКРИПТА
═══════════════════════════════════════════════════════════════════════════════

"@ -ForegroundColor Cyan
    $answer = Request-YesNo -Question "Хотите запустить скрипт с параметрами по умолчанию" -Default 'N'
    if ($answer) {
        Write-Host "Запуск скрипта..." -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "Запуск отменён. Используйте -Help для подробной справки." -ForegroundColor Yellow
        Write-Host ""
    }
    return $answer
}

# === ТОЧКА ВХОДА ===
$hasParameters = $PSBoundParameters.Count -gt 0
if (-not $hasParameters) {
    $shouldRun = Request-ScriptExecution
    if (-not $shouldRun) { exit 0 }
}
if ($Help -or $HelpAlias) {
    Show-ScriptHelp
    exit 0
}
Initialize-Script
Invoke-VersionSyncStage
Invoke-ResgenConversionStage
Invoke-PackageBuildStage
Write-Log "`n[INFO] Script completed" 'Gray'
#endregion