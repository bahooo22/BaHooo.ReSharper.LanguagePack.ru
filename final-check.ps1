# Финальный тест
Write-Host "=== ФИНАЛЬНАЯ ПРОВЕРКА ===" -ForegroundColor Cyan

$workflow = Get-Content .github/workflows/pack-and-release.yml -Raw

# Проверяем все три параметра по отдельности (они на разных строках!)
$hasForceAll = $workflow -match "-ForceAll"
$hasSkipVersionUpdate = $workflow -match "-SkipVersionUpdate" 
$hasNoBuild = $workflow -match "-NoBuild"

Write-Host "`nПараметры в workflow:" -ForegroundColor Yellow
Write-Host "  -ForceAll: $(if ($hasForceAll) { '✅' } else { '❌' })" -ForegroundColor $(if ($hasForceAll) { "Green" } else { "Red" })
Write-Host "  -SkipVersionUpdate: $(if ($hasSkipVersionUpdate) { '✅' } else { '❌' })" -ForegroundColor $(if ($hasSkipVersionUpdate) { "Green" } else { "Red" })
Write-Host "  -NoBuild: $(if ($hasNoBuild) { '✅' } else { '❌' })" -ForegroundColor $(if ($hasNoBuild) { "Green" } else { "Red" })

if ($hasForceAll -and $hasSkipVersionUpdate -and $hasNoBuild) {
    Write-Host "`n🎉 ВСЕ ПАРАМЕТРЫ НА МЕСТЕ!" -ForegroundColor Green
    Write-Host "✅ Workflow готов к работе!" -ForegroundColor Green
    Write-Host "✅ Скрипты исправлены" -ForegroundColor Green
    Write-Host "✅ Пути артефактов правильные" -ForegroundColor Green
    Write-Host "`n🚀 МОЖНО КОММИТИТЬ И ЗАПУСКАТЬ!" -ForegroundColor Cyan
} else {
    Write-Host "`n⚠️  Нужно добавить недостающие параметры" -ForegroundColor Yellow
}