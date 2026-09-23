# Дамп neutral-значений конкретных ключей проблемных записей.
#requires -Version 5
param([string]$InstallDir = 'G:\eXample\AppData\Local\JetBrains\Installations\ReSharperPlatformVs18_23258025')

$ErrorActionPreference = 'Stop'

$want = @{
    'JetBrains.dotTrace.VS.Resources.Strings.resources'                        = @('ActionText')
    'JetBrains.ReSharper.Daemon.VB.Resources.LocalizedStrings.resources'       = @('Message6')
    'JetBrains.ReSharper.ExternalSources.Resources.Strings.resources'          = @('DiffModeShowAll_Comment_Text')
    'JetBrains.ReSharper.Feature.Services.Resources.Strings.resources'         = @('_Description_Text')
    'JetBrains.Application.Resources.Strings.resources'                        = @('LicenseTo_Key__Text')
    'JetBrains.ReSharper.Intentions.CSharp.Resources.Strings.resources'        = @('RemoveRedundantAttribute_Text')
    'JetBrains.ReSharper.Intentions.Resources.Strings.resources'               = @('MoveFileTo_Text')
    'JetBrains.ReSharper.Refactorings.CSharp.Resources.Strings.resources'      = @('Field0InitializerWillBeReplacedWith_Text', 'ConfigureAwait0CallWillNotBeTransferred_Text', 'UnableToPartiallyEncapsulateField0Usage_Text')
    'JetBrains.ReSharper.Refactorings.Xaml.Resources.Strings.resources'        = @('ExistingResource0ReferenceWillBeHidden_Text', 'Resource0UsageInsideDeclaration_Text', 'ExistingResource0ReferenceWillBeHiddenByExtractedResource_Text', 'StaticResource_0Usage_WillBeBroken_Text', 'DynamicResource_0Usage_WillBeBroken_Text')
}

$out = @()
Get-ChildItem -LiteralPath $InstallDir -Filter *.dll -File | ForEach-Object {
    try {
        $asm = [System.Reflection.Assembly]::LoadFile($_.FullName)
        foreach ($rn in $asm.GetManifestResourceNames()) {
            if ($want.ContainsKey($rn)) {
                $stream = $asm.GetManifestResourceStream($rn)
                if (-not $stream) { continue }
                try {
                    $rd = New-Object System.Resources.ResourceReader($stream)
                    foreach ($e in $rd) {
                        if ($want[$rn] -contains $e.Key) {
                            $val = "$($e.Value)" -replace "`r", '\r' -replace "`n", '\n'
                            $out += [pscustomobject]@{ Res = $rn; Key = $e.Key; En = $val }
                        }
                    }
                    $rd.Close()
                } finally { $stream.Close() }
            }
        }
    } catch { }
}
$out | ForEach-Object { "{0} [{1}] = {2}" -f $_.Res, $_.Key, $_.En }
