# Временные функции, если модуль не загружен
if (-not (Get-Command -Name Update-AllVersions -ErrorAction SilentlyContinue)) {
    function Update-AllVersions {
        param([string]$ProjectRoot)
        
        # Получаем текущую версию
        $nuspecPath = Join-Path $ProjectRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
        if (Test-Path $nuspecPath) {
            $nuspecText = Get-Content $nuspecPath -Raw
            if ($nuspecText -match '<version>(.*?)</version>') {
                $currentVersion = $Matches[1]
                $versionParts = $currentVersion.Split('.')
                
                if ($versionParts.Length -eq 4) {
                    $newBuild = [int]::Parse($versionParts[3]) + 1
                    $newVersion = "$($versionParts[0]).$($versionParts[1]).$($versionParts[2]).$newBuild"
                    
                    # Обновляем nuspec файлы
                    $nuspecFiles = @(
                        Join-Path $ProjectRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
                        Join-Path $ProjectRoot 'MarketplaceFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
                    )
                    
                    $nuspecUpdated = 0
                    foreach ($file in $nuspecFiles) {
                        if (Test-Path $file) {
                            $content = Get-Content $file -Raw
                            $content = $content -replace '<version>.*?</version>', "<version>$newVersion</version>"
                            $content | Out-File $file -Encoding UTF8 -Force
                            $nuspecUpdated++
                        }
                    }
                    
                    # Обновляем resx файлы
                    $resxFiles = @(
                        Join-Path $ProjectRoot 'raw-resx-done_ru-RU\JetBrains.UI.Avalonia.Resources.Strings.ru-RU.resx'
                        Join-Path $ProjectRoot 'raw-resx-done_ru-RU\JetBrains.UI.Resources.Strings.ru-RU.resx'
                    )
                    
                    $resxUpdated = 0
                    foreach ($resxFile in $resxFiles) {
                        if (Test-Path $resxFile) {
                            $content = Get-Content $resxFile -Raw -Encoding UTF8
                            if ($content -match 'BaHooo\.ReSharper\.I18n\.ru,\s*v\.\s*\d{4}\.\d+\.\d+\.\d+') {
                                $content = $content -replace 'BaHooo\.ReSharper\.I18n\.ru,\s*v\.\s*\d{4}\.\d+\.\d+\.\d+', "BaHooo.ReSharper.I18n.ru, v. $newVersion"
                                $content | Out-File $resxFile -Encoding UTF8 -Force
                                $resxUpdated++
                            }
                        }
                    }
                    
                    Write-Host "Версия обновлена: $currentVersion → $newVersion" -ForegroundColor Green
                    
                    return @{
                        Version = $newVersion
                        NuspecUpdated = $nuspecUpdated
                        ResxUpdated = $resxUpdated
                    }
                }
            }
        }
        
        Write-Host "Не удалось обновить версию" -ForegroundColor Red
        return @{
            Version = "0.0.0.0"
            NuspecUpdated = 0
            ResxUpdated = 0
        }
    }
}