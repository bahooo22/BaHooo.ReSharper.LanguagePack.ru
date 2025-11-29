$resgen = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe"
$inputFolder = "c:\Users\eXample\Documents\GitHub\bahooo22\RuReSharper\NugetFolder\DotFiles\Extensions\JetBrains.I18n.ru\i18n"
$outputFolder = "c:\Users\eXample\Documents\GitHub\bahooo22\RuReSharper\NugetFolder\DotFiles\Extensions\JetBrains.I18n.ru\i18n_resources"

# Проверка: если папки нет — создать
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null
}

Get-ChildItem $inputFolder -Filter *.resx | ForEach-Object {
    $inFile = $_.FullName
    $outFile = Join-Path $outputFolder ($_.BaseName + ".resources")
    & $resgen $inFile $outFile
}
