# Общий автопоиск каталога установки ReSharper для скриптов анализа.
#
# Зачем: путь установки содержит хэш (`ReSharperPlatformVs18_e6a7a229`) и меняется при каждом
# обновлении платформы. Константы вида `G:\...\ReSharperPlatformVs18_23258025` уже успели
# протухнуть дважды, и скрипт падал с «не удается найти путь» вместо замера.
#
# Тот же алгоритм, что инлайн в i18n-audit.ps1 / i18n-verify-translations.ps1: берётся самый
# свежий по LastWriteTime каталог `ReSharperPlatform*` в Program Files (x86) и в LOCALAPPDATA.
function Find-LatestReSharperInstall {
    $roots = @(
        (Join-Path ${env:ProgramFiles(x86)} 'JetBrains\Installations'),
        "$env:LOCALAPPDATA\JetBrains\Installations"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    $candidates = foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -Directory -Filter 'ReSharperPlatform*' -ErrorAction SilentlyContinue
    }
    $latest = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        throw "Каталог установки ReSharper не найден в: $($roots -join ', '). Передайте -InstallDir явно."
    }
    return $latest.FullName
}

# Resolve-InstallDir -Param $InstallDir : значение из параметра, иначе автопоиск с печатью.
function Resolve-InstallDir([string]$Param) {
    if ($Param) { return $Param }
    $found = Find-LatestReSharperInstall
    Write-Host "Каталог установки определён автоматически: $found"
    return $found
}

Export-ModuleMember -Function Find-LatestReSharperInstall, Resolve-InstallDir
