#requires -Version 7
<#
.SYNOPSIS
    I18n Studio — локальная GUI-обёртка над конвейером перевода ReSharper.
.DESCRIPTION
    Не дублирует логику сборки, а только запускает существующие скрипты и стримит их
    вывод в окно:
      - build/i18n-audit.ps1            — аудит покрытия нейтральных ресурсов DLL;
      - build/i18n-verify-translations.ps1 — проверка перевода (пустые, CJK, ключи, ru==en);
      - resx-to-resources.ps1 -svu -fa  — пересборка .resources + упаковка без инкремента версии;
      - resx-to-resources.ps1 -bo -svu  — только упаковка уже сконвертированных .resources;
      - ручной деплой build/resources/*.resources в i18n-каталог установки.
    Плюс список .resx с открытием выбранного в редакторе по двойному клику.

    Запуск:  pwsh -File i18n-studio.ps1
    Самопроверка без окна:  pwsh -File i18n-studio.ps1 -SelfTest
#>
[CmdletBinding()]
param(
    [switch]$SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root       = $PSScriptRoot
$ResxFolder = Join-Path $Root 'raw-resx-done_ru-RU'
$BuildDir   = Join-Path $Root 'build'
$Resources  = Join-Path $BuildDir 'resources'
$CoverageReport  = Join-Path $BuildDir 'i18n-coverage-report.txt'
$TranslationReport = Join-Path $BuildDir 'i18n-translation-report.txt'
$script:OemEnc = $null

function Get-Pwsh {
    $c = Get-Command pwsh.exe -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $p = 'C:\Program Files\PowerShell\7\pwsh.exe'
    if (Test-Path -LiteralPath $p) { return $p }
    throw 'PowerShell 7 (pwsh) не найден в PATH и по стандартному пути.'
}

function Find-LatestReSharperInstall {
    $roots = @(
        (Join-Path ${env:ProgramFiles(x86)} 'JetBrains\Installations'),
        "$env:LOCALAPPDATA\JetBrains\Installations"
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    $candidates = foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -Directory -Filter 'ReSharperPlatform*' -ErrorAction SilentlyContinue
    }
    $latest = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { throw "Каталог установки ReSharper не найден в: $($roots -join ', ')" }
    return $latest.FullName
}

function Quote-Arg([string]$a) {
    # Токены-параметры (-svu, -Msg, ...) передаём как есть; значения с пробелами —
    # в двойных кавычках (так их разбирает стандартный Win32-парсер аргументов pwsh).
    if ($a -match '^-') { return $a }
    if ($a -match '[\s"]') { return '"' + ($a -replace '"','\"') + '"' }
    return $a
}

# Кодовая страница OEM, которую дочерний pwsh под Windows использует для перенаправленного
# потока вывода. Жёстко не хардкодим 866: на машине с включённым «UTF-8 для всех языков»
# OEMCP=65001, и тогда дочерний вывод и так UTF-8.
function Get-OemEncoding {
    if ($script:OemEnc) { return $script:OemEnc }
    $cp = 866
    try {
        $v = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage' -ErrorAction Stop).OEMCP
        if ($v) { $cp = [int]$v }
    } catch { }
    $script:OemEnc = [System.Text.Encoding]::GetEncoding($cp)
    return $script:OemEnc
}

# Запускает дочерний скрипт через -File (только так дочерний `exit N` честно долетает
# до кода возврата: через -Command любая non-terminating ошибка обнуляет его до 1),
# а перенаправленный поток декодирует в OEM-кодовой странице. Стрим читается событиями
# процесса: отдельный поток под StandardError не поднимается (scriptblock-делегат теряет
# PS-скоуп), а события с SynchronizingObject маршалируются в UI-поток и без окна
# обрабатываются в паузах между cmdlet'ами. Возвращает @{ Exit; Lines }.
function Invoke-Tool {
    param(
        [string]$File,
        [string[]]$ToolArgs = @(),
        $Log = $null
    )
    $exe = Get-Pwsh
    $enc = Get-OemEncoding
    $p = New-Object System.Diagnostics.Process
    $si = New-Object System.Diagnostics.ProcessStartInfo
    $si.FileName = $exe
    $si.WorkingDirectory = $Root
    $si.Arguments = ((@('-NoProfile','-ExecutionPolicy','Bypass','-File', (Quote-Arg $File)) + ($ToolArgs | ForEach-Object { Quote-Arg $_ })) -join ' ')
    $si.UseShellExecute = $false
    $si.RedirectStandardOutput = $true
    $si.RedirectStandardError = $true
    $si.CreateNoWindow = $true
    $si.StandardOutputEncoding = $enc
    $si.StandardErrorEncoding  = $enc
    $p.StartInfo = $si
    if ($Log) { $p.SynchronizingObject = $Log }

    $md = @{ Lines = (New-Object System.Collections.Generic.List[string]); Log = $Log }
    $outId = 'i18nstudio_out_' + [guid]::NewGuid().ToString('N')
    $errId = 'i18nstudio_err_' + [guid]::NewGuid().ToString('N')
    Register-ObjectEvent -InputObject $p -EventName OutputDataReceived -SourceId $outId -MessageData $md -Action {
        if ($null -ne $EventArgs.Data) {
            $d = $Event.MessageData
            $d.Lines.Add($EventArgs.Data)
            if ($d.Log) {
                $d.Log.AppendText($EventArgs.Data + [Environment]::NewLine)
                $d.Log.SelectionStart = $d.Log.TextLength
                $d.Log.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
    } | Out-Null
    Register-ObjectEvent -InputObject $p -EventName ErrorDataReceived -SourceId $errId -MessageData $md -Action {
        if ($null -ne $EventArgs.Data) {
            $d = $Event.MessageData
            $d.Lines.Add('  ! ' + $EventArgs.Data)
            if ($d.Log) {
                $d.Log.AppendText('  ! ' + $EventArgs.Data + [Environment]::NewLine)
                $d.Log.SelectionStart = $d.Log.TextLength
                $d.Log.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
    } | Out-Null

    [void]$p.Start()
    $p.BeginOutputReadLine()
    $p.BeginErrorReadLine()

    while (-not $p.WaitForExit(50)) {
        if ($Log) { [System.Windows.Forms.Application]::DoEvents() }
        else { Start-Sleep -Milliseconds 20 }
    }
    $p.WaitForExit()

    Unregister-Event -SourceId $outId -ErrorAction SilentlyContinue
    Unregister-Event -SourceId $errId -ErrorAction SilentlyContinue
    [void]$md.Lines.Add(('[код выхода: {0}]' -f $p.ExitCode))
    if ($Log) { $Log.AppendText('[код выхода: ' + $p.ExitCode + ']' + [Environment]::NewLine) }
    return [pscustomobject]@{ Exit = $p.ExitCode; Lines = $md.Lines }
}

function Invoke-Deploy {
    param($Log = $null)
    $lines = New-Object System.Collections.Generic.List[string]
    $emit = { param($s) $lines.Add($s); if ($Log) { $Log.AppendText($s + [Environment]::NewLine); [System.Windows.Forms.Application]::DoEvents() } }
    $install = Find-LatestReSharperInstall
    $i18n = Join-Path $install 'Extensions\BaHooo.ReSharper.I18n.ru\i18n'
    if (-not (Test-Path -LiteralPath $i18n)) { & $emit "Каталог i18n не существует: $i18n"; return [pscustomobject]@{Exit=1;Lines=$lines} }
    if (-not (Test-Path -LiteralPath $Resources)) { & $emit "Нет $Resources — сначала выполните пересборку."; return [pscustomobject]@{Exit=1;Lines=$lines} }
    $src = Get-ChildItem -LiteralPath $Resources -Filter *.resources -File
    $n = 0
    foreach ($f in $src) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $i18n $f.Name) -Force; $n++ }
    & $emit "Задеплоировано $n .resources -> $i18n"
    return [pscustomobject]@{Exit=0;Lines=$lines}
}

function Open-InEditor([string]$path) {
    Start-Process -FilePath $path
}

if ($SelfTest) {
    # Проверка без графического окна: окружение + сквозной прогон Run-Tool на ephemeral-скрипте.
    $out = New-Object System.Collections.Generic.List[string]
    $out.Add("pwsh=" + (Get-Pwsh))
    $out.Add("install=" + (Find-LatestReSharperInstall))
    $out.Add("resxfolder-exists=" + (Test-Path -LiteralPath $ResxFolder))
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("i18n_studio_selftest_{0}.ps1" -f [guid]::NewGuid().ToString('N'))
    # Пишем UTF-8 без BOM: дочерний pwsh7 читает корректно.
    [System.IO.File]::WriteAllText($tmp, "param([string]`$Msg)`nWrite-Output ('СТРОКА=' + `$Msg)`nWrite-Error 'проверка-stderr'`nexit 3`n", (New-Object System.Text.UTF8Encoding($false)))
    try {
        $r = Invoke-Tool -File $tmp -ToolArgs @('-Msg','привет мир')
        $joined = $r.Lines -join ' | '
        $hasRu = (@($r.Lines | Where-Object { $_ -like '*СТРОКА=привет мир*' }).Count -gt 0)
        $hasErr = (@($r.Lines | Where-Object { $_ -like '*проверка-stderr*' }).Count -gt 0)
        Write-Host ("SELFTEST exit={0} utf8-stdout={1} utf8-stderr={2}" -f $r.Exit, $hasRu, $hasErr)
        Write-Host ("LINES: " + $joined)
        if ($r.Exit -eq 3 -and $hasRu -and $hasErr) { Write-Host 'SELFTEST=OK'; exit 0 }
        else { Write-Host 'SELFTEST=FAIL'; exit 1 }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

# ---------- GUI ----------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'I18n Studio — ReSharper RU'
$form.Size = New-Object System.Drawing.Size(1000, 640)
$form.StartPosition = 'CenterScreen'

$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.Orientation = 'Vertical'
[void]$form.Controls.Add($split)
$split.SplitterDistance = 600

# --- Левая часть: кнопки действий сверху, лог снизу ---
$btnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$btnPanel.Dock = 'Top'
$btnPanel.Height = 92
$btnPanel.WrapContents = $true
$btnPanel.Padding = 6
[void]$split.Panel1.Controls.Add($btnPanel)

$log = New-Object System.Windows.Forms.RichTextBox
$log.Dock = 'Fill'
$log.ReadOnly = $true
$log.Font = New-Object System.Drawing.Font('Consolas', 9)
$log.BackColor = [System.Drawing.Color]::White
[void]$split.Panel1.Controls.Add($log)

function Add-MkButton {
    param([string]$text, [scriptblock]$body, [string]$hint)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Width = 180
    $b.Height = 34
    $b.Margin = New-Object System.Windows.Forms.Padding(4)
    if ($hint) {
        $tt = New-Object System.Windows.Forms.ToolTip
        $tt.SetToolTip($b, $hint)
    }
    $b.Add_Click({
        $log.AppendText([Environment]::NewLine + '=== ' + $text + ' ===' + [Environment]::NewLine)
        & $body
    })
    [void]$btnPanel.Controls.Add($b)
    return $b
}

function Clear-Log { $log.Clear() }

$actAudit = Add-MkButton 'Аудит покрытия' {
    Invoke-Tool -File (Join-Path $BuildDir 'i18n-audit.ps1') -Log $log | Out-Null
    if (Test-Path -LiteralPath $CoverageReport) { Open-InEditor $CoverageReport }
} 'Сравнить нейтральные ресурсы DLL с пакетом; пишет build/i18n-coverage-report.txt и открывает его.'

$actVerify = Add-MkButton 'Проверка перевода' {
    Invoke-Tool -File (Join-Path $BuildDir 'i18n-verify-translations.ps1') -Log $log | Out-Null
    if (Test-Path -LiteralPath $TranslationReport) { Open-InEditor $TranslationReport }
} 'XML-валидность, пустые значения, CJK, наборы ключей, ru==en; пишет build/i18n-translation-report.txt.'

$actRebuild = Add-MkButton 'Пересобрать без bump' {
    Invoke-Tool -File (Join-Path $Root 'resx-to-resources.ps1') -ToolArgs @('-svu','-aa','-t','4') -Log $log | Out-Null
} 'resx-to-resources.ps1 -svu -aa -t 4: конвертация всех .resx и сборка пакетов без инкремента версии.'

$actPack = Add-MkButton 'Только упаковка' {
    Invoke-Tool -File (Join-Path $Root 'resx-to-resources.ps1') -ToolArgs @('-bo','-svu','-aa') -Log $log | Out-Null
} 'resx-to-resources.ps1 -bo -svu: пересобрать пакеты из готовых .resources, без конвертации.'

$actDeploy = Add-MkButton 'Деплой в установку' {
    Invoke-Deploy -Log $log | Out-Null
} 'Скопировать build/resources/*.resources в i18n-каталог последней установки ReSharper.'

Add-MkButton 'Открыть отчёт покрытия' {
    if (Test-Path -LiteralPath $CoverageReport) { Open-InEditor $CoverageReport } else { $log.AppendText('Отчёт ещё не создан.') }
} $null
Add-MkButton 'Очистить лог' { Clear-Log } $null

# --- Правая часть: список .resx, двойной клик открывает в редакторе ---
$lbl = New-Object System.Windows.Forms.Label
$lbl.Dock = 'Top'
$lbl.Height = 22
$lbl.Text = "Файлы .resx (двойной клик — открыть в редакторе): $ResxFolder"
$lbl.Padding = 4
[void]$split.Panel2.Controls.Add($lbl)

$list = New-Object System.Windows.Forms.ListView
$list.Dock = 'Fill'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.HideSelection = $false
[void]$list.Columns.Add('Файл .resx', 420)
[void]$split.Panel2.Controls.Add($list)
$list.BringToFront()

if (Test-Path -LiteralPath $ResxFolder) {
    foreach ($f in (Get-ChildItem -LiteralPath $ResxFolder -Filter *.resx -File | Sort-Object Name)) {
        $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
        $item.Tag = $f.FullName
        [void]$list.Items.Add($item)
    }
}
$list.Add_MouseDoubleClick({
    if ($list.SelectedItems.Count -gt 0) { Open-InEditor $list.SelectedItems[0].Tag }
})

$log.AppendText("I18n Studio. Файлов .resx: $($list.Items.Count).`r`n")

[void]$form.ShowDialog()
