# Дамп содержимого конкретных внедрённых ресурсов (для оценки: строки UI или данные).
#requires -Version 5
param(
    [string]$InstallDir = 'G:\eXample\AppData\Local\JetBrains\Installations\ReSharperPlatformVs18_23258025',
    [int]$Take = 6
)

$targets = @(
    @{ Dll = 'JetBrains.Platform.Shell.dll';                Res = 'JetBrains.Application.Res.StringTable.resources' },
    @{ Dll = 'JetBrains.Platform.Shell.dll';                Res = 'JetBrains.Application.Resources.VsResources.resources' },
    @{ Dll = 'JetBrains.Platform.UIInteractive.Shell.dll';  Res = 'JetBrains.UI.Resources.StringTable.resources' },
    @{ Dll = 'JetBrains.SignatureVerifier.dll';             Res = 'JetBrains.SignatureVerifier.Messages.resources' },
    @{ Dll = 'JetBrains.ReSharper.Feature.Services.dll';    Res = 'JetBrains.ReSharper.Feature.Services.Src.Explanatory.CodeInspectionWikiResources.resources' },
    @{ Dll = 'JetBrains.Platform.Standalone.TabWell.dll';   Res = 'JetBrains.Standalone.TabWell.Resources.Strings.resources' },
    @{ Dll = 'JetBrains.DPA.Ide.VS.dll';                    Res = 'JetBrains.DPA.Ide.VS.Resources.Strings.resources' },
    @{ Dll = 'JetBrains.Profiler.Windows.Impl.dll';         Res = 'JetBrains.Profiler.Windows.Resources.Strings.resources' }
)

foreach ($t in $targets) {
    $path = Join-Path $InstallDir $t.Dll
    Write-Host ""
    Write-Host "=== $($t.Res)  ($($t.Dll)) ===" -ForegroundColor Cyan
    try {
        $asm = [System.Reflection.Assembly]::LoadFile($path)
        $stream = $asm.GetManifestResourceStream($t.Res)
        if (-not $stream) { Write-Host '  <ресурс не найден>' -ForegroundColor Yellow; continue }
        $reader = New-Object System.Resources.ResourceReader($stream)
        $i = 0; $total = 0
        foreach ($entry in $reader) {
            $total++
            if ($i -lt $Take) {
                $key = $entry.Key; $val = $entry.Value
                if ($val -is [byte[]]) { $val = '<binary ' + $val.Length + ' bytes>' }
                $valText = "$val" -replace "`r?`n", ' \n '
                if ($valText.Length -gt 160) { $valText = $valText.Substring(0, 160) + '…' }
                Write-Host ("  {0} = {1}" -f $key, $valText)
                $i++
            }
        }
        $reader.Close()
        Write-Host "  (всего записей: $total)" -ForegroundColor DarkGray
    }
    catch {
        Write-Host "  ОШИБКА: $($_.Exception.Message)" -ForegroundColor Red
    }
}
