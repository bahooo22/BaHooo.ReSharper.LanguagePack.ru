# Извлечение полных key/value списков 7 недостающих нейтральных ресурсов в JSON (для перевода).
#requires -Version 5
param(
    # Каталог установки не захардкожен: хэш в имени (`ReSharperPlatformVs18_<hash>`) меняется при
    # каждом обновлении платформы, и прошлая константа `..._23258025` перестала существовать 28.10.
    [string]$InstallDir,
    [string]$OutJson = "$PSScriptRoot\missing-strings.json"
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'i18n-install.psm1')
$InstallDir = Resolve-InstallDir $InstallDir

$targets = @(
    @{ Dll = 'JetBrains.Platform.Shell.dll';               Res = 'JetBrains.Application.Res.StringTable.resources' },
    @{ Dll = 'JetBrains.Platform.UIInteractive.Shell.dll'; Res = 'JetBrains.UI.Resources.StringTable.resources' },
    @{ Dll = 'JetBrains.Platform.Shell.dll';               Res = 'JetBrains.Application.Resources.VsResources.resources' },
    @{ Dll = 'JetBrains.DPA.Ide.VS.dll';                   Res = 'JetBrains.DPA.Ide.VS.Resources.Strings.resources' },
    @{ Dll = 'JetBrains.Profiler.Windows.Impl.dll';        Res = 'JetBrains.Profiler.Windows.Resources.Strings.resources' },
    @{ Dll = 'JetBrains.SignatureVerifier.dll';            Res = 'JetBrains.SignatureVerifier.Messages.resources' },
    @{ Dll = 'JetBrains.Platform.Standalone.TabWell.dll';  Res = 'JetBrains.Standalone.TabWell.Resources.Strings.resources' }
)

$result = @()
foreach ($t in $targets) {
    $asm = [System.Reflection.Assembly]::LoadFile((Join-Path $InstallDir $t.Dll))
    $stream = $asm.GetManifestResourceStream($t.Res)
    if (-not $stream) { throw "Ресурс не найден: $($t.Res) в $($t.Dll)" }
    $reader = New-Object System.Resources.ResourceReader($stream)
    $entries = @()
    foreach ($entry in $reader) {
        if ($entry.Value -isnot [string]) { throw "Нестроковое значение в $($t.Res): $($entry.Key)" }
        $entries += [pscustomobject]@{ Key = $entry.Key; En = $entry.Value }
    }
    $reader.Close(); $stream.Close()
    $result += [pscustomobject]@{ Resource = $t.Res; Dll = $t.Dll; Count = $entries.Count; Entries = $entries }
}

$json = ConvertTo-Json -InputObject $result -Depth 4
[System.IO.File]::WriteAllText($OutJson, $json, (New-Object System.Text.UTF8Encoding($true)))
Write-Host "OK: $OutJson"
foreach ($r in $result) { Write-Host ("  {0}: {1} строк" -f $r.Resource, $r.Count) }
