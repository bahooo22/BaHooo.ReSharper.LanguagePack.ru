# Временные функции, если модуль не загружен
if (-not (Get-Command -Name Update-AllVersions -ErrorAction SilentlyContinue)) {
    function Update-AllVersions {
        param(
            [string]$ProjectRoot,
            [string]$NewVersion
        )

        $targetVersion = $null

        # Если версия задана вручную
        if ($NewVersion) {
            $targetVersion = $NewVersion
            Write-Host "Принудительно устанавливаю версию: $targetVersion" -ForegroundColor Cyan
        } else {
            # Получаем текущую версию из nuspec
            $nuspecPath = Join-Path $ProjectRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
            if (Test-Path $nuspecPath) {
                $nuspecText = Get-Content $nuspecPath -Raw
                if ($nuspecText -match '<version>(.*?)</version>') {
                    $currentVersion = $Matches[1]
                    $versionParts = $currentVersion.Split('.')
                    if ($versionParts.Length -eq 4) {
                        $newBuild = [int]::Parse($versionParts[3]) + 1
                        $targetVersion = "$($versionParts[0]).$($versionParts[1]).$($versionParts[2]).$newBuild"
                        Write-Host "Автоинкремент версии: $currentVersion → $targetVersion" -ForegroundColor Yellow
                    }
                }
            }
        }

        if (-not $targetVersion) {
            Write-Host "Не удалось определить новую версию" -ForegroundColor Red
            return @{ Version = "0.0.0.0"; NuspecUpdated = 0; ResxUpdated = 0 }
        }

        # Обновляем nuspec файлы
        $nuspecFiles = @(
            Join-Path $ProjectRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
            Join-Path $ProjectRoot 'MarketplaceFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
        )
        $nuspecUpdated = 0
        foreach ($file in $nuspecFiles) {
            if (Test-Path $file) {
                $content = Get-Content $file -Raw
                $content = $content -replace '<version>.*?</version>', "<version>$targetVersion</version>"
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
                    $content = $content -replace 'BaHooo\.ReSharper\.I18n\.ru,\s*v\.\s*\d{4}\.\d+\.\d+\.\d+', "BaHooo.ReSharper.I18n.ru, v. $targetVersion"
                    $content | Out-File $resxFile -Encoding UTF8 -Force
                    $resxUpdated++
                }
            }
        }

        return @{
            Version = $targetVersion
            NuspecUpdated = $nuspecUpdated
            ResxUpdated = $resxUpdated
        }
    }

    function Sync-Versions {
        param(
            [string]$ProjectRoot,
            [switch]$Force,
            [string]$NewVersion
        )
        Write-Host "Запасная функция Sync-Versions" -ForegroundColor Yellow
        return (Update-AllVersions -ProjectRoot $ProjectRoot -NewVersion $NewVersion)
    }

    function Get-CurrentVersion {
        param([string]$ProjectRoot)
        $nuspecPath = Join-Path $ProjectRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
        if (Test-Path $nuspecPath) {
            $nuspecText = Get-Content $nuspecPath -Raw
            if ($nuspecText -match '<version>(.*?)</version>') {
                return $Matches[1]
            }
        }
        return "0.0.0.0"
    }
}
