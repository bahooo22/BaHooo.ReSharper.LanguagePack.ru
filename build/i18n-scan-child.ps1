#requires -Version 7
# Дочерний сканер: читает список DLL (по одному пути в строке), для каждой — GetManifestResourceNames
# + ResourceReader, дописывает JSONL-строку в $Out СРАЗУ после каждой DLL (устойчиво к крашу).
param([string]$ListFile, [string]$OutFile, [string]$StartAfter = '')
$ErrorActionPreference = 'Continue'
$started = [string]::IsNullOrEmpty($StartAfter)
foreach ($dll in Get-Content -LiteralPath $ListFile) {
    if (-not $started) { if ($dll -eq $StartAfter) { $started = $true }; continue }
    $rec = $null
    try {
        $asm = [System.Reflection.Assembly]::LoadFile($dll)
        $sets = @{}
        foreach ($rn in $asm.GetManifestResourceNames()) {
            if ($rn -notlike '*.resources' -or $rn -like '*.g.resources') { continue }
            $s = $null
            try {
                $s = $asm.GetManifestResourceStream($rn)
                if (-not $s) { continue }
                $mm = New-Object System.IO.MemoryStream; $s.CopyTo($mm); $mm.Position = 0
                $rr = New-Object System.Resources.ResourceReader($mm)
                $keys = @()
                $e = $rr.GetEnumerator()
                while ($e.MoveNext()) { if ($e.Value -is [string]) { $keys += [string]$e.Key } }
                $rr.Close()
                if ($keys.Count -gt 0) { $sets[$rn] = $keys }
            } catch { } finally { if ($s) { $s.Close() } }
        }
        $rec = [pscustomobject]@{ dll = $dll; sets = $sets }
    } catch {
        $rec = [pscustomobject]@{ dll = $dll; error = $_.Exception.GetType().Name }
    }
    [IO.File]::AppendAllText($OutFile, ($rec | ConvertTo-Json -Compress -Depth 5) + "`n")
}
