param(
    [string]$ResxFolder = '..\..\raw-resx-done_ru-RU',
    [string]$Output = 'artifacts',              # для NuGet пакета
    [string]$ResourcesOutput = 'DotFiles\Extensions\JetBrains.I18n.ru\i18n\',     # для .resources файлов
    [string]$Version = (Get-Date -Format 'yyyy.MM.dd'),
    [string]$LogFile = 'build.log',
    [string]$ErrorLogFile = 'build.errors.log'
)

$resgen = 'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Очистим старые логи
Remove-Item $LogFile, $ErrorLogFile -ErrorAction SilentlyContinue

Write-Host "Converting resx -> resources in: $ResxFolder" | Tee-Object -FilePath $LogFile -Append

$files = Get-ChildItem -Path $ResxFolder -Filter '*.resx' -Recurse
if ($files.Count -eq 0) {
    "No .resx files found." | Tee-Object -FilePath $LogFile -Append
    exit 0
}

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

# Затем вызываем build.ps1
try {
    & .\build.ps1 -Version $Version -Output $Output 2>&1 | Tee-Object -FilePath $LogFile -Append
}
catch {
    $errIndex++
    $errMsg = "ERROR in build.ps1: $($_.Exception.Message)"
    Write-Host $errMsg -ForegroundColor Red

    $block = @()
    $block += "Ошибка №$errIndex"
    $block += "Файл: build.ps1"
    $block += "Количество ошибок: 1"
    $block += "Описание:"
    $block += $errMsg
    $block += ""

    $block | Out-File -FilePath $ErrorLogFile -Append -Encoding UTF8
}
