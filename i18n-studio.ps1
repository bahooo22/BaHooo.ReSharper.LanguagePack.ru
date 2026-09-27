#requires -Version 7
<#
.SYNOPSIS
    I18n Studio — локальная GUI-обёртка над конвейером перевода ReSharper.
.DESCRIPTION
    Не дублирует логику сборки, а только запускает существующие скрипты и стримит их
    вывод в окно:
      - build/i18n-audit.ps1            — аудит покрытия нейтральных ресурсов DLL;
      - build/i18n-verify-translations.ps1 — проверка перевода (пустые, CJK, ключи, ru==en);
      - resx-to-resources.ps1           — полный конвейер: GUI-панель настроек покрывает
        ВСЕ параметры скрипта (пути, версия, оба лога, режимы nb/nr/bo, sv/svu/fa,
        потоки up, aa, CleanTools, NoNetwork, Help) и показывает точную командную строку;
      - ручной деплой build/resources/*.resources в i18n-каталог установки;
      - build/i18n-offline-deploy.ps1 — оффлайн-деплой на standalone-приложения
        (плоские сателлиты в локальную папку + .bat-запускатели dotPeek/dotTrace/
        dotMemory/dotCover с JET_BACKEND_CULTURE и JET_BACKEND_LOCALIZATION_FOLDERS).
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
# Совпадает с дефолтом build/i18n-offline-deploy.ps1: студию и скрипт не должно
# уводить в две разные оффлайн-папки.
$OfflineDefault = Join-Path $env:LOCALAPPDATA 'JetBrains\i18n-ru'
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
# а перенаправленный поток декодирует в OEM-кодовой странице.
#
# ВАЖНО: стриминг нельзя делать ни через Register-ObjectEvent -Action (обработчики
# PS-событий исполняются только когда движок PowerShell свободен, а во время модального
# ShowDialog он занят внутри обработчика клика; DoEvents прокачивает только Win32-
# сообщения), ни через .NET-делегат из scriptblock на add_OutputDataReceived (делегат
# падает на пул-потоке с «нет доступного runspace», и это unreraised-exception убивает
# процесс). Единственный безопасный вариант — UI-поток сам опрашивает задачи
# StandardOutput/StandardError.ReadLineAsync() в цикле ожидания и печатает готовые
# строки. Возвращает @{ Exit; Lines }.
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

    $lines = New-Object System.Collections.Generic.List[string]
    $emit = {
        param([bool]$IsErr, [string]$Text)
        $prefixed = if ($IsErr) { '  ! ' + $Text } else { $Text }
        $lines.Add($prefixed)
        if ($Log) {
            $Log.AppendText($prefixed + [Environment]::NewLine)
            $Log.SelectionStart = $Log.TextLength
            $Log.ScrollToCaret()
        }
    }

    [void]$p.Start()
    $so = $p.StandardOutput
    $se = $p.StandardError
    $tOut = $null; $tErr = $null
    $outEof = $false; $errEof = $false
    while (-not ($outEof -and $errEof)) {
        if (-not $outEof) {
            if ($null -eq $tOut) { $tOut = $so.ReadLineAsync() }
            if ($tOut.Wait(0)) {
                $line = $tOut.Result; $tOut = $null
                if ($null -eq $line) { $outEof = $true } else { & $emit $false $line }
            }
        }
        if (-not $errEof) {
            if ($null -eq $tErr) { $tErr = $se.ReadLineAsync() }
            if ($tErr.Wait(0)) {
                $line = $tErr.Result; $tErr = $null
                if ($null -eq $line) { $errEof = $true } else { & $emit $true $line }
            }
        }
        if ($Log) { [System.Windows.Forms.Application]::DoEvents() }
        Start-Sleep -Milliseconds 20
    }
    $p.WaitForExit()

    [void]$lines.Add(('[код выхода: {0}]' -f $p.ExitCode))
    if ($Log) { $Log.AppendText('[код выхода: ' + $p.ExitCode + ']' + [Environment]::NewLine) }
    return [pscustomobject]@{ Exit = $p.ExitCode; Lines = $lines }
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

# %LOCALAPPDATA% на некоторых машинах ведёт через симлинк (здесь: C:\Users\eXample\AppData
# -> G:\eXample\AppData), поэтому путь из переменной окружения и путь на букве G —
# одна и та же папка. Разворачиваем цепочку симлинков по компонентам, чтобы в логе
# и подписи показывать реальный адрес, а не два «разных».
function Get-ResolvedRealPath([string]$Path) {
    if (-not $Path) { return '' }
    try { $full = [IO.Path]::GetFullPath($Path).TrimEnd('\') } catch { return $Path }
    $root = [IO.Path]::GetPathRoot($full)
    $cur = $full
    while ($cur.Length -gt $root.Length) {
        $t = $null
        try { $t = [IO.Directory]::ResolveLinkTarget($cur, $false) } catch { }
        if ($t) {
            $rest = $full.Substring($cur.Length).TrimStart('\')
            return $(if ($rest) { [IO.Path]::Combine($t.FullName, $rest) } else { $t.FullName })
        }
        $cur = [IO.Path]::GetDirectoryName($cur)
    }
    return $full
}

# Собирает аргументы resx-to-resources.ps1 из GUI-контролов. Отделено от окна,
# чтобы прогонять проверки в -SelfTest. Возвращает @{ Errors; Args }.
function Build-PipelineArgs {
    $ret = @{ Errors = (New-Object System.Collections.Generic.List[string]); Args = (New-Object System.Collections.Generic.List[string]) }
    $e = $ret.Errors; $a = $ret.Args
    $v  = { param($c) if ($null -eq $c) { '' }
                        elseif ($c -is [string]) { $c.Trim() }
                        else { $c.Text.Trim() } }
    $ck = { param($c) if ($null -ne $c) { [bool]$c.Checked } else { $false } }

    $modeNB = & $ck $script:ckNoBuild; $modeNR = & $ck $script:ckNoResgen; $modeBO = & $ck $script:ckBuildOnly
    $helpOn = & $ck $script:ckHelp
    if (@($modeNB, $modeNR, $modeBO) -contains $true -and $helpOn) {
        $e.Add('Справка (-Help) несовместима с режимами сборки и другими параметрами.')
    }
    if ($helpOn) {
        $a.Add('-Help')
        $t = & $v $script:cbTopic; if ($t) { [void]$a.AddRange([string[]]@('-Topic', $t)) }
        if (& $ck $script:ckFull) { $a.Add('-Full') }
        return $ret
    }
    $sel = @(@('NoBuild', 'NoResgen', 'BuildOnly') | Where-Object {
        (& $ck $script:ckNoBuild -and $_ -eq 'NoBuild') -or
        (& $ck $script:ckNoResgen -and $_ -eq 'NoResgen') -or
        (& $ck $script:ckBuildOnly -and $_ -eq 'BuildOnly')
    })
    if ($sel.Count -gt 1) {
        $e.Add("Режимы -NoBuild / -NoResgen / -BuildOnly взаимоисключающи (разные parameter sets): выбрано $($sel -join ', ').")
    }
    $rx  = & $v $script:txResx;  if ($rx)  { [void]$a.AddRange([string[]]@('-ResxFolder',    $rx)) }
    $ro  = & $v $script:txOut;   if ($ro)  { [void]$a.AddRange([string[]]@('-ResourcesOutput', $ro)) }
    $ver = & $v $script:txVersion
    if ($ver -and $ver -notmatch '^\d+(\.\d+){0,3}$') { $e.Add("Версия '$ver' — ожидалось MAJOR.MINOR.PATCH.REVISION, например 2026.2.2.1.") }
    if ($ver) { [void]$a.AddRange([string[]]@('-Version', $ver)) }
    $lf  = & $v $script:txLog;   if ($lf)  { [void]$a.AddRange([string[]]@('-LogFile',       $lf)) }
    $elf = & $v $script:txErr;   if ($elf) { [void]$a.AddRange([string[]]@('-ErrorLogFile',  $elf)) }
    if (& $ck $script:ckNoBuild)  { $a.Add('-NoBuild') }
    if (& $ck $script:ckNoResgen) { $a.Add('-NoResgen') }
    if (& $ck $script:ckBuildOnly){ $a.Add('-BuildOnly') }
    if (& $ck $script:ckSync)     { $a.Add('-SyncVersions') }
    if (& $ck $script:ckSkipVU)   { $a.Add('-SkipVersionUpdate') }
    if (& $ck $script:ckForceAll) { $a.Add('-ForceAll') }
    $th = 0
    if (-not [int]::TryParse((& $v $script:cbThreads), [ref]$th) -or $th -lt 0 -or $th -gt 64) {
        $e.Add('Потоки: целое 0 (выкл), 1 (авто) или 2..64.')
    } else { [void]$a.AddRange([string[]]@('-UseParallel', "$th")) }
    if (& $ck $script:ckAcceptAll){ $a.Add('-AcceptAll') }
    if (& $ck $script:ckCleanTools){ $a.Add('-CleanTools') }
    if (& $ck $script:ckNoNetwork){ $a.Add('-NoNetwork') }
    return $ret
}

# Аргументы build/i18n-offline-deploy.ps1 из GUI-полей. Как и Build-PipelineArgs —
# отдельно от окна, чтобы проверять в -SelfTest. Возвращает @{ Errors; Args }.
function Build-OfflineArgs {
    $ret = @{ Errors = (New-Object System.Collections.Generic.List[string]); Args = (New-Object System.Collections.Generic.List[string]) }
    $a = $ret.Args
    $v  = { param($c) if ($null -eq $c) { '' }
                        elseif ($c -is [string]) { $c.Trim() }
                        else { $c.Text.Trim() } }
    # Относительные пути панели понимаются относительно корня репозитория: дочерний
    # pwsh запускается с WorkingDirectory=$Root, но base64 пути в .bat обязан быть
    # абсолютным, поэтому раскрываем здесь, а не на усмотрение CWD.
    $abs = { param($p) if ([IO.Path]::IsPathRooted($p)) { $p } else { Join-Path $Root $p } }

    $srcDir = & $v $script:txOut
    if (-not $srcDir) { $srcDir = $Resources }
    [void]$a.AddRange([string[]]@('-ResourcesDir', (& $abs $srcDir)))

    $dir = & $v $script:txOfflineTarget
    if ($dir) {
        $dir = [Environment]::ExpandEnvironmentVariables($dir)   # допускаем %LOCALAPPDATA%\...
        if ($dir -match '%') {
            $ret.Errors.Add("Оффлайн-папка: не развёрнута переменная окружения в '$dir'.")
            return $ret
        }
        $dir = & $abs $dir
    } else {
        $dir = $OfflineDefault
    }
    [void]$a.AddRange([string[]]@('-TargetDir', $dir))
    return $ret
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
        $toolOk = ($r.Exit -eq 3 -and $hasRu -and $hasErr)
        if ($toolOk) { Write-Host 'SELFTEST=OK' } else { Write-Host 'SELFTEST=FAIL' }
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }

    # --- проверка сборщика аргументов конвейера на фейковых контролах (без окна) ---
    $script:txResx = $null; $script:txOut = $null; $script:txVersion = $null
    $script:txLog = $null;  $script:txErr  = $null
    $script:ckNoBuild = $null; $script:ckNoResgen = $null; $script:ckBuildOnly = $null
    $script:ckHelp = $null; $script:ckFull = $null; $script:cbTopic = 'Basic'
    $script:ckSync = $null; $script:ckSkipVU = $null; $script:ckForceAll = $null
    $script:cbThreads = '0'; $script:ckAcceptAll = $null; $script:ckCleanTools = $null; $script:ckNoNetwork = $null
    $script:txOfflineTarget = $null
    $caseFails = 0
    $chk = { param($cond, $name) if ($cond) { Write-Host "  [ok] $name" } else { $script:caseFails++; Write-Host "  [FAIL] $name" } }
    $mk = { param($on = $false) [pscustomobject]@{ Checked = $on } }

    $r = Build-PipelineArgs
    & $chk ($r.Errors.Count -eq 0 -and ($r.Args -join ' ') -eq '-UseParallel 0') 'defaults -> -UseParallel 0, no errors'

    $script:txResx = [pscustomobject]@{ Text = ' C:\my resx ' }
    $script:txVersion = [pscustomobject]@{ Text = '2026.2.2.1' }
    $script:ckSkipVU = & $mk $true; $script:ckAcceptAll = & $mk $true; $script:cbThreads = '8'
    $r = Build-PipelineArgs
    & $chk (($r.Args -join ' ') -eq '-ResxFolder C:\my resx -Version 2026.2.2.1 -SkipVersionUpdate -UseParallel 8 -AcceptAll') 'trim + order (raw values, quoting is Invoke-Tool job)'

    $script:txVersion = [pscustomobject]@{ Text = '2026.2.x' }
    $r = Build-PipelineArgs
    & $chk ($r.Errors.Count -eq 1 -and $r.Errors[0] -like 'Версия*') 'bad version rejected'

    $script:txVersion = [pscustomobject]@{ Text = '' }
    $script:ckNoBuild = & $mk $true; $script:ckBuildOnly = & $mk $true
    $r = Build-PipelineArgs
    & $chk ($r.Errors.Count -eq 1 -and $r.Errors[0] -like '*взаимоисключающи*') 'NoBuild+BuildOnly rejected'
    & $chk (($r.Args -join ' ') -like '*-NoBuild*-BuildOnly*' -or ($r.Args -join ' ') -like '*-BuildOnly*-NoBuild*') ('both modes still listed | got: [' + ($r.Args -join ' ') + ']')

    $script:ckNoBuild = & $mk $false; $script:ckBuildOnly = & $mk $false; $script:ckSkipVU = $null; $script:ckAcceptAll = $null; $script:cbThreads = '0'; $script:txResx = $null
    $script:ckHelp = & $mk $true; $script:ckFull = & $mk $true; $script:cbTopic = 'Parallelism'
    $r = Build-PipelineArgs
    & $chk (($r.Args -join ' ') -eq '-Help -Topic Parallelism -Full') 'help preset'

    $script:ckNoBuild = & $mk $true
    $r = Build-PipelineArgs
    & $chk ($r.Errors.Count -ge 1 -and $r.Errors[0] -like 'Справка*') 'Help+mode rejected'

    Write-Host ('PIPELINE-ARGCASES=' + $(if ($caseFails -eq 0) { 'OK' } else { "FAIL($caseFails)" }))

    # --- проверка аргументов оффлайн-деплоя и развёртки реального пути (без окна) ---
    $script:offFails = 0
    $chk2 = { param($cond, $name) if ($cond) { Write-Host "  [ok] $name" } else { $script:offFails++; Write-Host "  [FAIL] $name" } }

    $r = Build-OfflineArgs
    & $chk2 ($r.Errors.Count -eq 0 -and ($r.Args -join ' ') -eq "-ResourcesDir $Resources -TargetDir $OfflineDefault") 'offline defaults -> build\resources + LOCALAPPDATA\JetBrains\i18n-ru'

    $script:txOut = [pscustomobject]@{ Text = 'build\res2' }
    $script:txOfflineTarget = [pscustomobject]@{ Text = ' D:\other i18n ' }
    $r = Build-OfflineArgs
    & $chk2 (($r.Args -join ' ') -eq ('-ResourcesDir ' + (Join-Path $Root 'build\res2') + ' -TargetDir D:\other i18n')) 'relative src absolutized to repo root; target trimmed'

    $script:txOfflineTarget = [pscustomobject]@{ Text = '%LOCALAPPDATA%\JetBrains\i18n-ru' }
    $r = Build-OfflineArgs
    & $chk2 (($r.Args -join ' ') -like ('*-TargetDir ' + (Join-Path $env:LOCALAPPDATA 'JetBrains\i18n-ru'))) '%LOCALAPPDATA% expanded'

    $script:txOfflineTarget = [pscustomobject]@{ Text = '%NO_SUCH_DIR_XYZ%\a' }
    $r = Build-OfflineArgs
    & $chk2 ($r.Errors.Count -eq 1 -and $r.Errors[0] -like 'Оффлайн-папка*') 'unexpanded env var rejected'
    $script:txOut = $null; $script:txOfflineTarget = $null

    & $chk2 ((Get-ResolvedRealPath '') -eq '') 'real path of empty input = empty'
    & $chk2 ((Get-ResolvedRealPath $env:SystemRoot) -eq $env:SystemRoot) ('not a link -> unchanged | got: [' + (Get-ResolvedRealPath $env:SystemRoot) + ']')
    $realDefault = Get-ResolvedRealPath $OfflineDefault
    Write-Host ('  offline-default=' + $OfflineDefault + '  real=' + $realDefault)
    & $chk2 ($realDefault -and [IO.Path]::IsPathRooted($realDefault) -and -not ($realDefault -match '%') -and (Test-Path -LiteralPath $realDefault)) 'real offline path absolute, expanded, reachable'

    Write-Host ('OFFLINE-ARGCASES=' + $(if ($script:offFails -eq 0) { 'OK' } else { "FAIL($($script:offFails))" }))
    exit $(if ($toolOk -and $caseFails -eq 0 -and $script:offFails -eq 0) { 0 } else { 1 })
}

# ---------- GUI ----------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'I18n Studio — ReSharper RU'
$form.Size = New-Object System.Drawing.Size(1000, 780)
$form.StartPosition = 'CenterScreen'

$split = New-Object System.Windows.Forms.SplitContainer
$split.Dock = 'Fill'
$split.Orientation = 'Vertical'
# Фиксируем левую колонку: по умолчанию (FixedPanel=None) при развороте окна панели
# растягиваются пропорционально, левая колонка расползается, 584-пиксельные
# разделители строк перестают доходить до края, и ряды настроек перемешиваются.
$split.FixedPanel = 'Panel1'
[void]$form.Controls.Add($split)
$split.SplitterDistance = 600

# --- Левая часть (сверху вниз): панель настроек, кнопки, лог ---
# Порядок добавления обратный зрительному: каждый следующий Dock='Top' встаёт
# ВЫШЕ предыдущего, Fill — последним (замерено на живом окне).
$btnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$btnPanel.Dock = 'Top'
$btnPanel.WrapContents = $true
$btnPanel.Height = 140
$btnPanel.Padding = 6
[void]$split.Panel1.Controls.Add($btnPanel)

# --- Панель полных настроек конвейера: покрывает все параметры resx-to-resources.ps1 ---
# Единый FlowLayoutPanel с переносом по ширине и AutoSize: при 125-150% DPI
# жёсткие ряды влезают не всегда, а перенос + авторост высоты работает при любом.
$cfgPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$cfgPanel.Dock = 'Top'
$cfgPanel.WrapContents = $true
$cfgPanel.AutoSize = $true
$cfgPanel.AutoSizeMode = 'GrowAndShrink'
$cfgPanel.Padding = 4
$cfgPanel.Width = 600
[void]$split.Panel1.Controls.Add($cfgPanel)

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
    # Обработчик клика живёт ПОСЛЕ возврата из функции, поэтому обязан замкнуть
    # локальные $text/$body через GetNewClosure — иначе это динамический поиск в
    # уже свёрнутой области Add-MkButton, $text пуст, а & $body падает на null.
    $handler = {
        $log.AppendText([Environment]::NewLine + '=== ' + $text + ' ===' + [Environment]::NewLine)
        & $body
    }.GetNewClosure()
    $b.Add_Click($handler)
    [void]$btnPanel.Controls.Add($b)
    return $b
}

function Clear-Log { $log.Clear() }

$cfgFont = New-Object System.Drawing.Font('Segoe UI', 9)
# Ширина «переноса строки» для FlowLayoutPanel: неширокий невидимый контрол
# шириной во всю клиентскую область заставляет следующий элемент начать новую строку.
function New-CfgRow {
    $brk = New-Object System.Windows.Forms.Label
    $brk.Width = 584; $brk.Height = 1; $brk.Margin = New-Object System.Windows.Forms.Padding(0)
    [void]$cfgPanel.Controls.Add($brk)
}
function Add-CfgControl([System.Windows.Forms.Control]$c) {
    [void]$cfgPanel.Controls.Add($c); return $c
}
function New-LabeledText {
    param([string]$Caption, [string]$Initial, [int]$Width = 150)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Caption; $lbl.AutoSize = $true; $lbl.Font = $cfgFont
    $lbl.Margin = New-Object System.Windows.Forms.Padding(6, 7, 2, 3)
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Text = $Initial; $tb.Width = $Width; $tb.Font = $cfgFont
    $tb.Margin = New-Object System.Windows.Forms.Padding(2, 3, 2, 2)
    [void](Add-CfgControl $lbl); [void](Add-CfgControl $tb)
    return $tb
}
function New-CfgCheck {
    param([string]$Caption, [string]$Hint)
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $Caption; $cb.AutoSize = $true; $cb.Font = $cfgFont
    $cb.Margin = New-Object System.Windows.Forms.Padding(6, 5, 2, 2)
    if ($Hint) { $script:cfgTip.SetToolTip($cb, $Hint) }
    return (Add-CfgControl $cb)
}
$script:cfgTip = New-Object System.Windows.Forms.ToolTip
function New-CfgCombo {
    param([string]$Caption, [string[]]$Items, [string]$Selected, [int]$Width = 80)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Caption; $lbl.AutoSize = $true; $lbl.Font = $cfgFont
    $lbl.Margin = New-Object System.Windows.Forms.Padding(6, 7, 2, 3)
    $cmb = New-Object System.Windows.Forms.ComboBox
    $cmb.DropDownStyle = 'DropDownList'
    [void]$cmb.Items.AddRange($Items)
    $cmb.SelectedItem = $Selected; $cmb.Width = $Width; $cmb.Font = $cfgFont
    $cmb.Margin = New-Object System.Windows.Forms.Padding(2, 3, 2, 2)
    [void](Add-CfgControl $lbl); [void](Add-CfgControl $cmb)
    return $cmb
}

New-CfgRow   # ряд 1: пути, версия, логи, потоки
$script:txResx = New-LabeledText '.resx-папка' 'raw-resx-done_ru-RU' 160
$script:txOut  = New-LabeledText '.resources-папка' 'build\resources' 120
$script:txVersion = New-LabeledText 'Версия (пусто = авто)' '' 90
$script:txLog  = New-LabeledText 'Лог' 'build.log' 90
$script:txErr  = New-LabeledText 'Лог ошибок' 'build.errors.log' 110
$script:cbThreads = New-CfgCombo 'Потоки (0=выкл, 1=авто)' @('0', '1', '2', '4', '8') '0' 55

New-CfgRow   # ряд 2: взаимоисключающие режимы + версии/кэш
$script:ckNoBuild   = New-CfgCheck 'NoBuild (без упаковки)' 'Конвертировать .resx, но не собирать пакеты (parameter set NoBuild).'
$script:ckNoResgen  = New-CfgCheck 'NoResgen' 'Пропустить генерацию .resources через ResGen (parameter set NoResgen).'
$script:ckBuildOnly = New-CfgCheck 'BuildOnly (без конвертации)' 'Только сборка пакетов из готовых .resources (parameter set BuildOnly).'
$script:ckSync      = New-CfgCheck 'SyncVersions' 'Синхронизировать версии nuspec/resx перед выполнением.'
$script:ckSkipVU    = New-CfgCheck 'SkipVerUpdate' 'SkipVersionUpdate: не инкрементировать версию (режим CI/CD и перевыпуска). В GUI включён по умолчанию: обычный прогон без него молча поднимает версию в nuspec и в строке About двух resx.'
$script:ckSkipVU.Checked = $true
$script:ckForceAll  = New-CfgCheck 'ForceAll'

New-CfgRow   # ряд 3: прочее + справка
$script:ckAcceptAll = New-CfgCheck 'AcceptAll'
$script:ckCleanTools= New-CfgCheck 'CleanTools'
$script:ckNoNetwork = New-CfgCheck 'NoNetwork'
$script:ckHelp      = New-CfgCheck 'Help'
$script:cbTopic     = New-CfgCombo 'Topic' @('Basic','Paths','Modes','Parallelism','History','Tools','Config','Examples','Versioning','All') 'Basic' 110
$script:ckFull      = New-CfgCheck 'Full'

# NoBuild/NoResgen/BuildOnly — разные parameter sets: включение одного снимает остальные.
$exclusive = {
    param($self, $others)
    $self.Add_Click({
        if ($self.Checked) { foreach ($o in $others) { $o.Checked = $false } }
        Update-PipelinePreview
    }.GetNewClosure())
}
& $exclusive $script:ckNoBuild   @($script:ckNoResgen, $script:ckBuildOnly)
& $exclusive $script:ckNoResgen  @($script:ckNoBuild, $script:ckBuildOnly)
& $exclusive $script:ckBuildOnly @($script:ckNoBuild, $script:ckNoResgen)

New-CfgRow   # ряд 4: оффлайн-деплой (standalone dotPeek/dotTrace/dotMemory/dotCover)
$script:txOfflineTarget = New-LabeledText 'Оффлайн-папка (standalone)' $OfflineDefault 250
$offlineRealLbl = New-Object System.Windows.Forms.Label
$offlineRealLbl.AutoSize = $true
$offlineRealLbl.Font = New-Object System.Drawing.Font('Consolas', 8)
$offlineRealLbl.ForeColor = [System.Drawing.Color]::DarkSlateGray
$offlineRealLbl.UseMnemonic = $false
$offlineRealLbl.Margin = New-Object System.Windows.Forms.Padding(6, 7, 2, 2)
[void](Add-CfgControl $offlineRealLbl)

function Update-OfflineRealPath {
    $r = Build-OfflineArgs
    if ($r.Errors.Count -gt 0) {
        $offlineRealLbl.ForeColor = [System.Drawing.Color]::Firebrick
        $offlineRealLbl.Text = ($r.Errors -join ' ')
        return
    }
    $target = $r.Args[$r.Args.Count - 1]   # -TargetDir <значение>
    $real = Get-ResolvedRealPath $target
    $offlineRealLbl.ForeColor = [System.Drawing.Color]::DarkSlateGray
    # Показываем реальный адрес: %LOCALAPPDATA% может вести через симлинк на другой диск.
    $offlineRealLbl.Text = $(if ($real -and ($real -ne $target)) { '→ ' + $real } else { '→ (как в поле)' })
}
$script:txOfflineTarget.Add_TextChanged({ Update-OfflineRealPath })
$script:cfgTip.SetToolTip($script:txOfflineTarget,
    'Папка плоских сателлитов "<Set>.<culture>.resources" для standalone-приложений: ' +
    'её base64(UTF8) попадает в JET_BACKEND_LOCALIZATION_FOLDERS в .bat-запускателях. ' +
    'Пусто = ' + $OfflineDefault + '; допустимы переменные окружения (%LOCALAPPDATA%).')
Update-OfflineRealPath

New-CfgRow   # последняя строка: предпросмотр итоговой командной строки
$previewLbl = New-Object System.Windows.Forms.Label
$previewLbl.AutoSize = $false
$previewLbl.AutoEllipsis = $true
$previewLbl.Width = 580; $previewLbl.Height = 16
$previewLbl.UseMnemonic = $false
$previewLbl.Font = New-Object System.Drawing.Font('Consolas', 8)
$previewLbl.ForeColor = [System.Drawing.Color]::DarkSlateGray
$previewLbl.Margin = New-Object System.Windows.Forms.Padding(6, 4, 2, 2)
[void](Add-CfgControl $previewLbl)

function Update-PipelinePreview {
    $r = Build-PipelineArgs
    $txt = 'pwsh -File resx-to-resources.ps1 ' + (($r.Args | ForEach-Object { Quote-Arg $_ }) -join ' ')
    if ($r.Errors.Count -gt 0) {
        $previewLbl.ForeColor = [System.Drawing.Color]::Firebrick
        $previewLbl.Text = ($r.Errors -join ' ')
    } else {
        $previewLbl.ForeColor = [System.Drawing.Color]::DarkSlateGray
        $previewLbl.Text = $txt
    }
}
# Любое изменение настройки обновляет предпросмотр командной строки.
foreach ($c in @($script:txResx, $script:txOut, $script:txVersion, $script:txLog, $script:txErr)) {
    $c.Add_TextChanged({ Update-PipelinePreview })
}
foreach ($c in @($script:cbThreads, $script:cbTopic)) {
    $c.Add_SelectedIndexChanged({ Update-PipelinePreview })
}
foreach ($c in @($script:ckNoBuild, $script:ckNoResgen, $script:ckBuildOnly, $script:ckSync, $script:ckSkipVU,
                 $script:ckForceAll, $script:ckAcceptAll, $script:ckCleanTools, $script:ckNoNetwork,
                 $script:ckHelp, $script:ckFull)) {
    $c.Add_CheckedChanged({ Update-PipelinePreview })
}
Update-PipelinePreview

$actAudit = Add-MkButton 'Аудит покрытия' {
    Invoke-Tool -File (Join-Path $BuildDir 'i18n-audit.ps1') -Log $log | Out-Null
    if (Test-Path -LiteralPath $CoverageReport) { Open-InEditor $CoverageReport }
} 'Сравнить нейтральные ресурсы DLL с пакетом; пишет build/i18n-coverage-report.txt и открывает его.'

$actVerify = Add-MkButton 'Проверка перевода' {
    Invoke-Tool -File (Join-Path $BuildDir 'i18n-verify-translations.ps1') -Log $log | Out-Null
    if (Test-Path -LiteralPath $TranslationReport) { Open-InEditor $TranslationReport }
} 'XML-валидность, пустые значения, CJK, наборы ключей, ru==en; пишет build/i18n-translation-report.txt.'

$actRun = Add-MkButton '▶ Запустить по настройкам' {
    $r = Build-PipelineArgs
    if ($r.Errors.Count -gt 0) {
        $log.AppendText([Environment]::NewLine + '[ОШИБКА] ' + ($r.Errors -join ' ') + [Environment]::NewLine)
        [void][System.Windows.Forms.MessageBox]::Show($form, ($r.Errors -join [Environment]::NewLine),
            'Параметры конвейера', 'OK', 'Error')
        return
    }
    $log.AppendText('> resx-to-resources.ps1 ' + (($r.Args | ForEach-Object { Quote-Arg $_ }) -join ' ') + [Environment]::NewLine)
    Invoke-Tool -File (Join-Path $Root 'resx-to-resources.ps1') -ToolArgs ([string[]]$r.Args) -Log $log | Out-Null
} 'Полный запуск resx-to-resources.ps1 с параметрами из панели настроек (командная строка видна в предпросмотре).'

$actRebuild = Add-MkButton 'Пересобрать без bump' {
    $savedVU = $script:ckSkipVU.Checked; $savedFA = $script:ckForceAll.Checked
    $script:ckSkipVU.Checked = $true; $script:ckForceAll.Checked = $true
    try { $actRun.PerformClick() } finally {
        $script:ckSkipVU.Checked = $savedVU; $script:ckForceAll.Checked = $savedFA
        Update-PipelinePreview
    }
} 'Пресет: -SkipVersionUpdate -ForceAll поверх настроек панели (без инкремента версии).'

$actPack = Add-MkButton 'Только упаковка' {
    $savedBO = $script:ckBuildOnly.Checked; $savedVU = $script:ckSkipVU.Checked
    $script:ckBuildOnly.Checked = $true; $script:ckSkipVU.Checked = $true
    try { $actRun.PerformClick() } finally {
        $script:ckBuildOnly.Checked = $savedBO; $script:ckSkipVU.Checked = $savedVU
        Update-PipelinePreview
    }
} 'Пресет: -BuildOnly -SkipVersionUpdate — пересобрать пакеты из готовых .resources, без конвертации.'

$actDeploy = Add-MkButton 'Деплой в установку' {
    Invoke-Deploy -Log $log | Out-Null
} 'Скопировать build/resources/*.resources в i18n-каталог последней установки ReSharper.'

$actOffline = Add-MkButton 'Деплой оффлайн (standalone)' {
    $r = Build-OfflineArgs
    if ($r.Errors.Count -gt 0) {
        $log.AppendText([Environment]::NewLine + '[ОШИБКА] ' + ($r.Errors -join ' ') + [Environment]::NewLine)
        [void][System.Windows.Forms.MessageBox]::Show($form, ($r.Errors -join [Environment]::NewLine),
            'Оффлайн-папка', 'OK', 'Error')
        return
    }
    $target = $r.Args[$r.Args.Count - 1]
    $real = Get-ResolvedRealPath $target
    $log.AppendText('> i18n-offline-deploy.ps1 ' + (($r.Args | ForEach-Object { Quote-Arg $_ }) -join ' ') + [Environment]::NewLine)
    if ($real -and ($real -ne $target)) { $log.AppendText('  (то же место по-настоящему: ' + $real + ')' + [Environment]::NewLine) }
    Invoke-Tool -File (Join-Path $BuildDir 'i18n-offline-deploy.ps1') -ToolArgs ([string[]]$r.Args) -Log $log | Out-Null
    $n = @(Get-ChildItem -LiteralPath $target -Filter *.resources -File -ErrorAction SilentlyContinue).Count
    $log.AppendText("В оффлайн-папке теперь .resources: $n`r`n")
} 'build/i18n-offline-deploy.ps1: зеркалит .resources в оффлайн-папку и пишет .bat-запускатели standalone-продуктов (JET_BACKEND_CULTURE + JET_BACKEND_LOCALIZATION_FOLDERS).'

[void](Add-MkButton 'Открыть отчёт покрытия' {
    if (Test-Path -LiteralPath $CoverageReport) { Open-InEditor $CoverageReport } else { $log.AppendText('Отчёт ещё не создан.') }
} $null)
[void](Add-MkButton 'Очистить лог' { Clear-Log } $null)

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
