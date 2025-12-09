Write-Host "=== ТЕСТ ПУТЕЙ ===" -ForegroundColor Cyan

# 1. Проверяем текущую директорию
Write-Host "`n1. Текущая директория:" -ForegroundColor Yellow
Get-Location

# 2. Тестируем build.ps1 с разными параметрами
Write-Host "`n2. Тест build.ps1:" -ForegroundColor Yellow
cd "NugetFolder\BaHooo.ReSharper.I18n.ru"

# Тест с 'artifacts'
$output1 = "artifacts"
$scriptDir = $PSScriptRoot
$path1 = Join-Path $scriptDir $output1
Write-Host "  С 'artifacts': $path1" -ForegroundColor $(if ($path1 -like "*BaHooo.ReSharper.I18n.ru\artifacts") { "Red" } else { "Green" })

# Тест с '..\artifacts'  
$output2 = "..\artifacts"
$path2 = Join-Path $scriptDir $output2
Write-Host "  С '..\artifacts': $path2" -ForegroundColor $(if ($path2 -like "*NugetFolder\artifacts") { "Green" } else { "Red" })

# 3. Возвращаемся
cd ..\..

# 4. Проверяем workflow
Write-Host "`n3. Проверка workflow:" -ForegroundColor Yellow
if (Test-Path ".github/workflows/pack-and-release.yml") {
    $workflow = Get-Content ".github/workflows/pack-and-release.yml" -Raw
    if ($workflow -match '-Output "\.\.\\\\artifacts"') {
        Write-Host "  ✅ Workflow использует '..\artifacts'" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Workflow не использует '..\artifacts'" -ForegroundColor Red
    }
}
