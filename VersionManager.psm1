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
                $nuspecText = Get-Content $nuspecPath -Raw -Encoding UTF8
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
            return @{ Version = "0.0.0.0"; NuspecUpdated = 0; ResxUpdated = 0; DocsUpdated = 0 }
        }

        # Обновляем nuspec файлы
        $nuspecFiles = @(
            Join-Path $ProjectRoot 'NugetFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
            Join-Path $ProjectRoot 'MarketplaceFolder\BaHooo.ReSharper.I18n.ru\BaHooo.ReSharper.I18n.ru.nuspec'
        )
        $nuspecUpdated = 0
        foreach ($file in $nuspecFiles) {
            if (Test-Path $file) {
                # Читаем файл как UTF-8 (с BOM или без)
                $content = [System.IO.File]::ReadAllText($file, [System.Text.Encoding]::UTF8)
                # Заменяем версию
                $content = $content -replace '<version>.*?</version>', "<version>$targetVersion</version>"
                # Сохраняем как UTF-8 без BOM (чтобы не плодить лишний BOM, если его не было)
                [System.IO.File]::WriteAllText($file, $content, [System.Text.UTF8Encoding]::new($false))
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
                    [System.IO.File]::WriteAllText($resxFile, $content, [System.Text.UTF8Encoding]::new($false))
                    $resxUpdated++
                }
            }
        }

        # Документация, которую конвейер иначе не трогает (боковые README и пр.)
        $docsUpdated = Update-DocsVersions -ProjectRoot $ProjectRoot -TargetVersion $targetVersion
        return @{
            Version = $targetVersion
            NuspecUpdated = $nuspecUpdated
            ResxUpdated = $resxUpdated
            DocsUpdated = $docsUpdated
        }
    }

    function Update-DocsVersions {
        # Синхронизирует версию в документации, которую конвейер иначе не трогает:
        # боковые README пакетов (встраиваются в .nupkg), «Текущая/Current version»
        # в README.md/README.en.md и заголовок релиза в TODO.md.
        param(
            [Parameter(Mandatory)][string]$ProjectRoot,
            [Parameter(Mandatory)][string]$TargetVersion
        )

        $semver = '\d+(?:\.\d+){1,3}'
        $docsJobs = @(
            @{ File = 'NugetFolder\BaHooo.ReSharper.I18n.ru\README.md'
               Rules = @( @{ Find = 'пакет `' + $semver + '`'; Replace = 'пакет `' + $TargetVersion + '`' } ) }
            @{ File = 'MarketplaceFolder\BaHooo.ReSharper.I18n.ru\README.md'
               Rules = @( @{ Find = 'пакет `' + $semver + '`'; Replace = 'пакет `' + $TargetVersion + '`' } ) }
            @{ File = 'README.md'
               Rules = @(
                   @{ Find = '\*\*Текущая версия:\*\* ' + $semver; Replace = '**Текущая версия:** ' + $TargetVersion }
                   @{ Find = 'BaHooo\.ReSharper\.I18n\.ru\.' + $semver + '\.nupkg'; Replace = 'BaHooo.ReSharper.I18n.ru.' + $TargetVersion + '.nupkg' }
                   @{ Find = '- \*\*Версия:\*\* `' + $semver + '`'; Replace = '- **Версия:** `' + $TargetVersion + '`' }
               ) }
            @{ File = 'README.en.md'
               Rules = @(
                   @{ Find = '\*\*Current version:\*\* ' + $semver; Replace = '**Current version:** ' + $TargetVersion }
                   @{ Find = 'BaHooo\.ReSharper\.I18n\.ru\.' + $semver + '\.nupkg'; Replace = 'BaHooo.ReSharper.I18n.ru.' + $TargetVersion + '.nupkg' }
                   @{ Find = '- \*\*Version:\*\* `' + $semver + '`'; Replace = '- **Version:** `' + $TargetVersion + '`' }
               ) }
            @{ File = 'TODO.md'
               Rules = @(
                   @{ Find = '## 🔥 Ближайший релиз: ' + $semver; Replace = '## 🔥 Ближайший релиз: ' + $TargetVersion }
                   @{ Find = '(Выложить `(?:NugetFolder|MarketplaceFolder)/artifacts/BaHooo\.ReSharper\.I18n\.ru\.)' + $semver + '(\.nupkg)'; Replace = '${1}' + $TargetVersion + '${2}' }
                   @{ Find = '`' + $semver + '` никогда не публиковался'; Replace = '`' + $TargetVersion + '` никогда не публиковался' }
               ) }
        )

        $docsUpdated = 0
        foreach ($job in $docsJobs) {
            $path = Join-Path $ProjectRoot $job.File
            if (-not (Test-Path $path)) { continue }
            $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
            $original = $content
            foreach ($rule in $job.Rules) {
                $content = $content -replace $rule.Find, $rule.Replace
            }
            if ($content -cne $original) {
                [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
                $docsUpdated++
                Write-Host ("Версия в документации обновлена: {0} → {1}" -f $job.File, $TargetVersion) -ForegroundColor Gray
            }
        }
        return $docsUpdated
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
            $nuspecText = Get-Content $nuspecPath -Raw -Encoding UTF8
            if ($nuspecText -match '<version>(.*?)</version>') {
                return $Matches[1]
            }
        }
        return "0.0.0.0"
    }
}
