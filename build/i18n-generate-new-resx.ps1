# Генерация 7 новых .ru-RU.resx из перевода (missing-translations.json)
# с проверкой против neutral-ресурсов (missing-strings.json):
#   - совпадение наборов ключей
#   - совпадение плейсхолдеров {n}
#   - непустые значения
# После записи — round-trip: перечитать resx через ResXResourceReader и сравнить с JSON.
#requires -Version 5
param(
    [string]$ResxFolder = "$PSScriptRoot\..\raw-resx-done_ru-RU",
    [string]$EnJson = "$PSScriptRoot\missing-strings.json",
    [string]$RuJson = "$PSScriptRoot\missing-translations.json"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$en = ConvertFrom-Json ([System.IO.File]::ReadAllText($EnJson, [System.Text.Encoding]::UTF8))
$ru = ConvertFrom-Json ([System.IO.File]::ReadAllText($RuJson, [System.Text.Encoding]::UTF8))

function Get-Placeholders {
    param([string]$Text)
    [regex]::Matches($Text, '\{\d+\}') | ForEach-Object { $_.Value } | Sort-Object
}

$fail = 0
foreach ($ruRes in $ru) {
    $enRes = $en | Where-Object { $_.Resource -eq $ruRes.Resource }
    if (-not $enRes) { Write-Host "НЕТ NEUTRAL-ИСТОЧНИКА: $($ruRes.Resource)" -ForegroundColor Red; $fail++; continue }

    $outPath = Join-Path $ResxFolder $ruRes.File

    # --- проверки до записи ---
    $enKeys = @($enRes.Entries | ForEach-Object { $_.Key })
    $ruKeys = @($ruRes.Entries | ForEach-Object { $_.Key })
    $dupRu = @($ruKeys | Group-Object | Where-Object { $_.Count -gt 1 })
    if ($dupRu.Count -gt 0) { Write-Host "ДУБЛИ КЛЮЧЕЙ в $($ruRes.File): $($dupRu.Name -join ', ')" -ForegroundColor Red; $fail++; continue }
    $missingInRu = @($enKeys | Where-Object { $ruKeys -notcontains $_ })
    $extraInRu   = @($ruKeys | Where-Object { $enKeys -notcontains $_ })
    if ($missingInRu.Count -gt 0 -or $extraInRu.Count -gt 0) {
        Write-Host "РАСХОЖДЕНИЕ КЛЮЧЕЙ в $($ruRes.File):"
        if ($missingInRu.Count) { Write-Host "  нет в переводе: $($missingInRu -join ', ')" -ForegroundColor Red }
        if ($extraInRu.Count)   { Write-Host "  лишние в переводе: $($extraInRu -join ', ')" -ForegroundColor Red }
        $fail++; continue
    }

    $empty = @($ruRes.Entries | Where-Object { [string]::IsNullOrWhiteSpace($_.Ru) })
    if ($empty.Count -gt 0) { Write-Host "ПУСТЫЕ ЗНАЧЕНИЯ: $(($empty | ForEach-Object Key) -join ', ')" -ForegroundColor Red; $fail++; continue }

    $phProblems = @()
    foreach ($ruE in $ruRes.Entries) {
        $enE = $enRes.Entries | Where-Object { $_.Key -eq $ruE.Key }
        $enPh = @(Get-Placeholders $enE.En) -join ','
        $ruPh = @(Get-Placeholders $ruE.Ru) -join ','
        if ($enPh -ne $ruPh) { $phProblems += "$($ruE.Key): en[$enPh] ru[$ruPh]" }
    }
    if ($phProblems.Count -gt 0) { Write-Host "ПЛЕЙСХОЛДЕРЫ: $($phProblems -join '; ')" -ForegroundColor Red; $fail++; continue }

    # --- запись resx ---
    if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }
    $writer = New-Object System.Resources.ResXResourceWriter($outPath)
    foreach ($ruE in $ruRes.Entries) { $writer.AddResource($ruE.Key, $ruE.Ru) }
    $writer.Close()

    # BOM (как у остальных resx репозитория)
    $raw = [System.IO.File]::ReadAllBytes($outPath)
    if ($raw.Length -lt 3 -or $raw[0] -ne 0xEF -or $raw[1] -ne 0xBB -or $raw[2] -ne 0xBF) {
        $text = [System.IO.File]::ReadAllText($outPath, [System.Text.Encoding]::UTF8)
        [System.IO.File]::WriteAllText($outPath, $text, (New-Object System.Text.UTF8Encoding($true)))
    }

    # --- round-trip ---
    $rtValues = @{}
    $rr = New-Object System.Resources.ResXResourceReader($outPath)
    foreach ($e in $rr) { $rtValues[$e.Key] = $e.Value }
    $rr.Close()

    $rtProblems = @()
    foreach ($ruE in $ruRes.Entries) {
        if (-not $rtValues.ContainsKey($ruE.Key)) { $rtProblems += "$($ruE.Key): ключ потерян"; continue }
        if ($rtValues[$ruE.Key] -cne $ruE.Ru)    { $rtProblems += "$($ruE.Key): значение искажено" }
    }
    if ($rtValues.Count -ne $ruRes.Entries.Count) { $rtProblems += "число записей: ждали $($ruRes.Entries.Count), прочитали $($rtValues.Count)" }

    if ($rtProblems.Count -gt 0) {
        Write-Host "ROUND-TRIP ОШИБКИ в $($ruRes.File): $($rtProblems -join '; ')" -ForegroundColor Red
        $fail++; continue
    }

    Write-Host ("[✓] {0}  ({1} записей)" -f $ruRes.File, $ruRes.Entries.Count) -ForegroundColor Green
}

Write-Host ''
if ($fail -gt 0) { Write-Host "ОШИБОК: $fail" -ForegroundColor Red; exit 1 }
Write-Host 'Все 7 файлов сгенерированы и проверены.' -ForegroundColor Green
