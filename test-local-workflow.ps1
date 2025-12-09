Write-Host "=== ЛОКАЛЬНЫЙ ТЕСТ РАБОЧЕЙ ЛОГИКИ ===" -ForegroundColor Cyan

# 1. Проверяем что build.ps1 работает правильно
Write-Host "`n1. Тест build.ps1:" -ForegroundColor Yellow
cd "NugetFolder\BaHooo.ReSharper.I18n.ru"
.\build.ps1 -Version "2025.3.0.7" -Output "artifacts" -Verbose | Select-String -Pattern "Output directory:|Пакеты успешно созданы" | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

# 2. Проверяем что пакет создан в правильном месте
Write-Host "`n2. Проверка созданного пакета:" -ForegroundColor Yellow
cd ..\..
$nugetPackage = Get-ChildItem "NugetFolder\artifacts\*.nupkg" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($nugetPackage) {
    Write-Host "  ✅ NuGet пакет найден: $($nugetPackage.Name)" -ForegroundColor Green
    Write-Host "  Путь: $($nugetPackage.FullName)" -ForegroundColor Gray
} else {
    Write-Host "  ❌ NuGet пакет не найден!" -ForegroundColor Red
}

# 3. Проверяем workflow пути
Write-Host "`n3. Проверка workflow путей:" -ForegroundColor Yellow
$testPath1 = ".\NugetFolder\artifacts\*.nupkg"
$testPath2 = ".\MarketplaceFolder\artifacts\*.nupkg"

Write-Host "  NuGet путь: $testPath1" -ForegroundColor $(if (Test-Path "NugetFolder\artifacts") { "Green" } else { "Yellow" })
Write-Host "  Marketplace путь: $testPath2" -ForegroundColor $(if (Test-Path "MarketplaceFolder\artifacts") { "Green" } else { "Yellow" })
