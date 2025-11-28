# Путь к утилите ResGen.exe
$ResGen = ".\ResGen.exe"

# Исходная папка с китайскими ресурсами
$srcDir = "C:\Users\eXample\Downloads\JetBrains.dotUltimate.2025.2.3\1\DotFiles\Extensions\JetBrains.I18n.zh\i18n"

# Целевая папка для русских resx
$dstDir = "C:\Users\eXample\Downloads\JetBrains.dotUltimate.2025.2.3\1\DotFiles\Extensions\JetBrains.I18n.ru\i18n"

# Создать целевую папку, если её нет
if (!(Test-Path $dstDir)) {
    New-Item -ItemType Directory -Path $dstDir | Out-Null
}

# Перебор всех .resources файлов
Get-ChildItem -Path $srcDir -Filter *.resources | ForEach-Object {
    $srcFile = $_.FullName

    # Имя файла для выхода: заменяем zh-CN на ru-RU
    $baseName = $_.BaseName -replace "zh-CN", "ru-RU"
    $dstFile = Join-Path $dstDir ($baseName + ".resx")

    Write-Host "Конвертация $srcFile -> $dstFile"
    & $ResGen $srcFile $dstFile

    # Дополнительно: если внутри resx остались упоминания zh-CN, заменим их на ru-RU
    if (Test-Path $dstFile) {
        (Get-Content $dstFile) -replace "zh-CN", "ru-RU" | Set-Content $dstFile -Encoding UTF8
    }
}
