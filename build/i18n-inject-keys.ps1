# Инъекция недостающих ключей в существующие .resx пакета по файлу переводов.
#
# Чем отличается от i18n-generate-new-resx.ps1: тот создаёт новые файлы для таблиц, которых у нас
# не было вовсе. Здесь таблицы уже есть, и в них нужно довнести несколько ключей, не трогая
# остальное содержимое файла — иначе git diff на 3855-строчном resx скроет реальный объём правки.
#
# Формат входа (JSON, массив):
#   [{ "Resource": "<имя без .ru-RU>", "Entries": [
#        { "Key": "K", "Ru": "перевод" },
#        { "Key": "K2", "CopyFrom": "<другой Resource>" },   # скопировать готовый <data> из донора
#        { "Key": "K3", "Ru": "...", "KeepAsIs": true }      # значение не переводится (формат/метка)
#   ]}]
#requires -Version 5
param(
    [string]$ResxFolder = (Join-Path $PSScriptRoot '..\raw-resx-done_ru-RU'),
    [string]$Translations = (Join-Path $PSScriptRoot 'parity-gap-translations.json')
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-ResxText([string]$path) {
    # UTF-8 без BOM + CRLF — как лежат в пакете; BOM читать умеем, но не добавляем.
    $b = [System.IO.File]::ReadAllBytes($path)
    $hasBom = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
    $text = [System.Text.Encoding]::UTF8.GetString($b)
    if ($hasBom) { $text = $text.Substring(1) }   # съеденный BOM-символ
    return [pscustomobject]@{ Text = $text; HasBom = $hasBom }
}

function Get-DataBlock([string]$text, [string]$key) {
    $m = [Regex]::Match($text, '(?s)[ \t]*<data name="' + [Regex]::Escape($key) + '".*?</data>')
    if (-not $m.Success) { return $null }
    return $m.Value
}

$plan = Get-Content -LiteralPath $Translations -Raw -Encoding UTF8 | ConvertFrom-Json
$totalAdded = 0
$touched = @()

foreach ($table in $plan) {
    $resx = Join-Path $ResxFolder ("{0}.ru-RU.resx" -f $table.Resource)
    if (-not (Test-Path -LiteralPath $resx)) { Write-Host "НЕТ ФАЙЛА: $resx"; continue }
    $cur = Read-ResxText $resx
    $text = $cur.Text

    $blocks = @()
    foreach ($e in $table.Entries) {
        if ($text -match ('<data name="' + [Regex]::Escape($e.Key) + '"')) {
            Write-Host "  уже есть, пропущен: $($table.Resource) / $($e.Key)"
            continue
        }
        if ($e.CopyFrom) {
            $donorPath = Join-Path $ResxFolder ("{0}.ru-RU.resx" -f $e.CopyFrom)
            if (-not (Test-Path -LiteralPath $donorPath)) { throw "донор не найден: $donorPath" }
            $donor = (Read-ResxText $donorPath).Text
            $block = Get-DataBlock $donor $e.Key
            if (-not $block) { throw "ключ $($e.Key) не найден в доноре $($e.CopyFrom)" }
            $blocks += $block
            Write-Host "  скопирован из $($e.CopyFrom): $($e.Key)"
        }
        else {
            $value = [System.Security.SecurityElement]::Escape($e.Ru)
            $blocks += ('  <data name="' + $e.Key + '" xml:space="preserve">' + "`r`n" +
                        '    <value>' + $value + '</value>' + "`r`n" +
                        '  </data>')
            Write-Host "  добавлен перевод: $($e.Key)"
        }
    }

    if ($blocks.Count -eq 0) { Write-Host "в $($table.Resource) добавлять нечего"; continue }

    $idx = $text.LastIndexOf('</root>')
    if ($idx -lt 0) { throw "в файле нет </root>: $resx" }
    $insert = ($blocks -join "`r`n") + "`r`n"
    $newText = $text.Substring(0, $idx) + $insert + $text.Substring($idx)

    $bytes = $utf8NoBom.GetBytes($newText)
    if ($cur.HasBom) {
        $bom = [byte[]](0xEF,0xBB,0xBF)
        [System.IO.File]::WriteAllBytes($resx, $bom + $bytes)
    } else {
        [System.IO.File]::WriteAllBytes($resx, $bytes)
    }
    $totalAdded += $blocks.Count
    $touched += $resx
    Write-Host ("{0}: добавлено блоков {1}" -f (Split-Path $resx -Leaf), $blocks.Count)
}

Write-Host ""
Write-Host ("ИТОГО: файлов {0}, добавлено записей {1}" -f $touched.Count, $totalAdded)
