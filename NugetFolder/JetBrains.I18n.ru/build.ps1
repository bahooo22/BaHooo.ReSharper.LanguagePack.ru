<# build.ps1
Usage: .\build.ps1 [-Configuration Release] [-Version 2025.11.27]
#>
param(
[string]$Configuration = 'Release',
[string]$Version = '1.0',
[string]$Output = 'artifacts'
)


Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'


Write-Host "Building JetBrains.I18n.ru language pack (version $Version)"


# Ensure artifacts folder
if (-not (Test-Path $Output)) { New-Item -ItemType Directory -Path $Output | Out-Null }


# Update nuspec version (simple replace; keep a backup if needed)
$nuspecPath = Join-Path (Get-Location) 'JetBrains.I18n.ru.nuspec'
$nuspecText = Get-Content $nuspecPath -Raw
$nuspecText = [Regex]::Replace($nuspecText, '<version>.*?</version>', "<version>$Version</version>", 'IgnoreCase')
$nuspecText | Set-Content $nuspecPath -Encoding utf8


# Pack using nuget.exe (expect nuget.exe available in PATH)
$nuget = 'nuget'
$packArgs = @('pack', $nuspecPath, '-OutputDirectory', $Output, '-NoDefaultExcludes')
Write-Host "Running: $nuget $($packArgs -join ' ')"
& dotnet pack $nuspecPath -o $Output


Write-Host "Package created in: $Output"