param(
[string]$ResxFolder = 'DotFiles\Extensions\JetBrains.I18n.ru\i18n',
[string]$Output = 'artifacts',
[string]$Version = '2025.11.27'
)
$resgen = 'c:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe'

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


Write-Host "Converting resx -> resources in: $ResxFolder"


$files = Get-ChildItem -Path $ResxFolder -Filter '*.resx' -Recurse
if ($files.Count -eq 0) { Write-Host 'No .resx files found.'; exit 0 }


foreach ($f in $files) {
$out = [System.IO.Path]::ChangeExtension($f.FullName, '.resources')
Write-Host "resgen $($f.FullName) -> $out"
& $resgen $f.FullName $out
}


# Затем вызываем build.ps1
& .\build.ps1 -Version $Version -Output $Output