# 📘 BaHooo.ReSharper.LanguagePack.ru

![ReSharper Russian Language Pack Icon](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/NugetFolder/BaHooo.ReSharper.I18n.ru/icon.png)

# Russian Language Pack, author BaHooo for JetBrains ReSharper

[![NuGet Version](https://img.shields.io/nuget/v/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru)
[![NuGet Downloads](https://img.shields.io/nuget/dt/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru)
[![GitHub Release](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/actions/workflows/pack-and-release.yml)
[![Last Commit](https://img.shields.io/github/last-commit/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/commits/main)
[![Issues](https://img.shields.io/github/issues/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pulls)
[![Repo Size](https://img.shields.io/github/repo-size/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru)
[![Stars](https://img.shields.io/github/stars/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/stargazers)
[![Forks](https://img.shields.io/github/forks/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/network/members)
[![Platform](https://img.shields.io/badge/platform-.NET-blue)](#)
[![Language](https://img.shields.io/github/languages/top/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](#)
[![Donate](https://img.shields.io/badge/donate-red)]()
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-lightgrey)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/LICENSE)
[![README Русский](https://img.shields.io/badge/README-Русский-blue)](./README.md)

A plugin for Russian localization of the **ReSharper** UI in Visual Studio.

---

## 📁 Project Structure

```
├───.github/
│   └───workflows/              # GitHub Actions workflows
│       └───pack-and-release.yml
├───MarketplaceFolder/          # Package for JetBrains Marketplace
│   └───BaHooo.ReSharper.I18n.ru/
│       ├───DotFiles/
│       ├───package/
│       └───build.ps1
├───NugetFolder/                # Package for NuGet
│   └───BaHooo.ReSharper.I18n.ru/
│       ├───DotFiles/
│       ├───package/
│       └───build.ps1
├───build/                      # Intermediate material and reports
│   ├───resources/             # .resources produced by ResGen (not in git)
│   ├───resx-hashes.json       # Cache of .resx file hashes
│   ├───new-translations-2026.json  # Source of new strings (file + key + en + ru)
│   ├───i18n-audit.ps1         # Coverage audit: platform DLLs vs our package
│   └───i18n-coverage-report.txt    # Its output - the numbers of "Resource coverage"
├───Tools/                      # Downloaded tools (not in git)
└───raw-resx-done_ru-RU/        # Source translated .resx files (243 files)
```

Line endings are pinned by `.gitattributes`: everything is stored with LF in the repository,
`.resx`/`.ps1`/`.nuspec` check out as CRLF (ResGen and Windows PowerShell consume them),
docs and JSON stay LF. Without it every clone would get EOL from its own `core.autocrlf`
setting, and the hash cache would report all 243 files as changed.

**Key files:**
- `resx-to-resources.ps1` - main build script
- `VersionManager.psm1` - version management
- `final-check.ps1` - final build verification
- `test-paths.ps1` - path testing
- `test-local-workflow.ps1` - local workflow test
- `TODO.md` - task list

---

## 📊 Project Statistics

**Translation files:** 243 `.resx`
**Strings in them:** 33,945 `<data>` elements, 33,229 of them have Cyrillic in the value.
&nbsp;&nbsp;&nbsp;&nbsp;Counted by an XML parser over root children: a naive search for `<data name=` in the file text
&nbsp;&nbsp;&nbsp;&nbsp;yields 34,917, because the header of every resx carries 4 XSD documentation examples.
**Current version:** 2026.2.2.1 (ReSharper 2026.2.2, wave `[262.0.0]`)
**Last update:** September 24, 2026
**Source .resx size:** 7,577,375 bytes
**Built .resources size:** 5,741,719 bytes

**Largest modules:**
- JetBrains.ReSharper.Daemon.CSharp.Resources.Strings.ru-RU.resx (960 KB)
- JetBrains.ReSharper.Feature.Services.Cpp.Resources.Strings.ru-RU.resx (620 KB)
- JetBrains.ReSharper.Intentions.CSharp.Resources.Strings.ru-RU.resx (410 KB)
- JetBrains.ReSharper.Daemon.Resources.Strings10.ru-RU.resx (282 KB)
- JetBrains.ReSharper.Feature.Services.Resources.Strings.ru-RU.resx (279 KB)

---

## 🧭 Resource coverage

The full answer to "should we translate everything" comes from `build/i18n-audit.ps1`: it
enumerates the neutral resources (no `*.g.resources`, no satellites) embedded in the DLLs of
the installed ReSharper platform and matches them against the resource names our package
provides. The install folder is auto-detected (`ReSharperPlatform*` under
`Program Files (x86)\JetBrains\Installations` and `%LOCALAPPDATA%`) because its name carries
an install hash and changes with every platform build. Report: `build/i18n-coverage-report.txt`.

Measured against ReSharper 2026.2.2 (`ReSharperPlatformVs18_e6a7a229`), 2026-09-24:

| Metric | Value |
|---|---|
| DLLs scanned | 624 (2 native ones failed to load) |
| Neutral `.resources` in the platform | 337 |
| **Covered by the package** | **180 of 337** |
| Not covered | 157 |
| Our `.resx` absent from this install | 63 (Rider, dotTrace Home, CommandLine, ForTea...) |
| `.resources` deployed into the platform `i18n` folder | 243 = 243, no differences |

The 157 uncovered resources are not 157 pages of untranslated UI:

- **94 are third-party libraries**: NuGet.* (15), Microsoft.* (45), DevExpress (17),
  System.* (8), Actipro (5), yWorks (2), MahApps, NHunspell. The satellite mechanism does not
  cover them, and most of them never reach the Visual Studio interface.
- **63 are JetBrains-owned**; split by the actual number of string records inside them:
  - 13 resources = 2,892 strings are `...Asp.Resources.Sharepoint.ResourceFiles.*` -
    SharePoint reference data that PSI uses to parse ASP.NET markup. **Not UI text, must not
    be translated.**
  - 38 resources = **0 strings** - empty WinForms/WPF localization containers
    (`ProductBaseForm`, `PromptWinForm`, `AdvancedNamingSettingsForm`, `TemplateChooserDialog`,
    `AdjustNamespacesPage`, ...): the text of such dialogs is compiled into code, the resource
    mechanism cannot localize it. **Nothing to extract.**
  - 12 resources = **60 strings** - the real remainder: `Razor.CSharp.Resources.Texts` (15),
    `Application.BuildScript.Compile.LicenseTexts` (15), `DotTraceLicenseSupportResources` (5),
    `dotTraceInstant.ViewModel.Interface.Resources` (4), `UnitTestProvider.MSTest12/14/15...Strings`
    (4 each), `FileLayoutPatternResources` (3), `Unity...AdditionalFileLayoutResources` (2),
    `DotTrace.Ide.Core.Interface.Resources` (2), `CodeInspectionWikiResources` (1),
    `Resources.resources` of the VS package (1). Of these 60: 11 strings belong to dotTrace
    (a separate product, not part of ReSharper inside Visual Studio), 15 are license texts,
    and the remaining 34 in 8 tables are the actual translation work tracked in TODO.md.

**Conclusion:** extracting resources from every DLL is not needed. Of the 337 platform
resources, the uncovered localizable remainder is 60 strings in 12 tables - against 33,229
strings already translated. The 63 of our `.resx` that are absent from this VS install are kept
on purpose: they belong to Rider, dotPeek, dotMemory and dotTrace Home, which this same source
tree serves.

---

## 🚫 What is deliberately NOT translated (the `ru == en` flag)

`build/i18n-verify-translations.ps1` reports entries whose Russian value equals the neutral
English one. Those are not missed translations; they fall into two legitimate classes:

1. **Product names and universal buttons** - `ReSharper`, `Visual Studio`, `IntelliJ IDEA`,
   `ASP`, `XML`, `URI:`, `Tab`, `OK`. No language translates them.
2. **`*SettingDescription` entries whose value upstream JetBrains itself stores as a raw token**:
   verified against `JetBrains.Platform.UIInteractive.Shell.dll`, where the neutral English
   `DefaultReporterChangedSettingDescription` and `UpgradePerformedSettingDescription` are
   literally `UpgradePerformed` - the description of a migration setting looks like an event
   identifier in the original product too. Our Russian value mirrors English honestly; there is
   **no key/value desync** and nothing to translate.

Do not "fix" such entries. If a `ru == en` flag appears on a key that belongs to neither class,
that is a real gap and it should be closed with a translation.

One more case, settled by measurement rather than by reading the report: the key
`Resource0UsageInlineWillProduceConflicts_Text` in
`JetBrains.ReSharper.Refactorings.Xaml.Resources.Strings`. Out of 215 rows with placeholder
mismatches it is the only formally dangerous one (Russian references an index the checker did not
find in English). The neutral English value there literally reads
`Inlining resource {0, usage} will produce conflicts`, and `[string]::Format` on that string
throws `FormatException` even when an argument is supplied (verified on .NET Framework) - so
upstream never formats this text, and `{0, usage}` is junk in the English original itself. Our
`{0}` stays as it is: if it ever gets formatted it is safer than the original, and if it does not,
it shows exactly the same kind of junk the original shows.

---

## 🚀 Main Build Script

### `resx-to-resources.ps1`

> **📅 Last updated:** 2026-09-24  
> **✨ What's new today:**
> - ✅ Every `.ps1`/`.psm1` is saved with a UTF-8 BOM: without it Windows PowerShell 5.1 reads the script in the system ANSI codepage, turns Cyrillic into garbage and fails to parse the file
> - ✅ `build.ps1` and `VersionManager.psm1` read `.nuspec` with an explicit `-Encoding UTF8` (a run under 5.1 used to re-encode the Russian text into mojibake)
> - ✅ `.nuspec`/`.resx` rewriting goes through `WriteAllText` - `Out-File` appended one blank line per run
> - ✅ Parallel conversion (`-up`, `-t`, `-Threads`) with auto thread selection
> - ✅ Auto-download of PowerShell 7 to `./Tools/PWSH7` when needed
> - ✅ Auto-download of `nuget.exe` to `./Tools/NuGet` (ResGen.exe has no standalone download - the script finds it in the Windows SDK instead)
> - ✅ New flags: `-AcceptAll/-aa` (CI/CD), `-CleanTools`, `-NoNetwork` (offline)
> - ✅ Hash history: up to 10 versions in `resx-hashes.history.json`
> - ✅ Enhanced error details: line/position display + visual `^` indicator
> - ✅ Improved output: concise `[✓] file.resx` format + resource statistics
> - ✅ Summary block "CONVERSION SUMMARY" with time, speed, resource count
> - ✅ Interactive confirmation when running without parameters
> - ✅ Russian keyboard layout support: `т/Т/да/Д` = yes, `н/Н/нет` = no
> - ✅ System info on startup (PS version, CPU, cores)
> - ✅ Single-responsibility functions + `<# .SYNOPSIS #>` documentation
> - ✅ Thread-safe logging via `[System.IO.File]::AppendAllText()`
> - ✅ `VersionAlreadyUpdated` flag: prevents double version increment

An intelligent script for managing the build process with change tracking via SHA256 hashes.

#### Intelligent features:

1. **Hash caching** - saves hashes of all .resx files in `build/resx-hashes.json`
2. **Incremental conversion** - converts only changed files
3. **Auto-version increment** - automatically updates version when changes are detected
4. **Conflict checking** - prevents incompatible parameter combinations
5. **Parallel processing** - multi-threaded conversion via PowerShell 7+ (`-up`)
6. **Self-hosting infrastructure** - auto-download missing tools to `./Tools`
7. **Change history** - stores up to 10 snapshots with timestamps in `.history.json`
8. **Error details** - parses ResGen output to show line/position with visual indicator

#### Parameters:

| Parameter | Alias | Description | Default |
|-----------|--------|-------------|---------|
| `-ResxFolder` | - | Folder with source .resx files | `.\raw-resx-done_ru-RU` |
| `-ResourcesOutput` | - | Folder for generated .resources files | `.\build\resources` |
| `-Version` | - | Build version manually (otherwise auto-increment) | (auto) |
| `-LogFile` | - | Main log file path | `build.log` |
| `-ErrorLogFile` | - | Error log file path | `build.errors.log` |
| `-NoBuild` | `-nb` | Conversion only, no package building | - |
| `-BuildOnly` | `-bo` | Package building only, no conversion | - |
| `-NoResgen` | `-nr` | Skip .resources generation | - |
| `-SyncVersions` | `-sv` | Synchronize versions before execution | - |
| `-SkipVersionUpdate` | `-svu` | Disable auto-version increment (for CI/CD) | - |
| `-ForceAll` | `-fa` | Force conversion of ALL .resx files | - |
| `-UseParallel` | `-up`, `-t`, `-Threads` | Thread count for parallel processing (0=off, 1=auto, 2..N=explicit) | `0` |
| `-AcceptAll` | `-aa` | Auto-consent for tool downloads (for CI/CD) | - |
| `-CleanTools` | - | Clean `./Tools` folder before run | - |
| `-NoNetwork` | - | Disable all network requests (offline mode) | - |
| `-Help` | `-h` | Show help | - |

#### Usage examples:

```powershell
# 🔹 Full process: check → convert → build
.\resx-to-resources.ps1

# 🔹 With parallelism (speedup): 8 threads + version sync
.\resx-to-resources.ps1 -up 8 -sv

# 🔹 Smart parallelism: auto thread selection (half of CPU cores)
.\resx-to-resources.ps1 -up -sv

# 🔹 Conversion of changed files only
.\resx-to-resources.ps1 -NoBuild

# 🔹 Package building only (resources already ready)
.\resx-to-resources.ps1 -BuildOnly

# 🔹 CI/CD mode: all files, no version increment, auto-consent
.\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild -AcceptAll

# 🔹 Offline mode: no downloads, skip resgen
.\resx-to-resources.ps1 -NoNetwork -NoResgen

# 🔹 Short forms:
.\resx-to-resources.ps1 -fa -svu -nb -aa    # For CI/CD
.\resx-to-resources.ps1 -bo                 # Build only
.\resx-to-resources.ps1 -up -sv             # Parallel + sync
```

#### How change detection works:

1. **First run:** creates `build/resx-hashes.json` with hashes of all files
2. **Subsequent runs:** compares hashes with saved ones
3. **Only converts:** new or modified files
4. **Deleted files:** logged but don't affect build
5. **History:** saves up to 10 latest snapshots in `resx-hashes.history.json`

**Sample output:**
```
=== Checking changes in .resx files ===
Loaded hashes from cache: 243
[CHANGED] JetBrains.UI.Resources.Strings.ru-RU.resx
[NEW] JetBrains.New.Module.ru-RU.resx
[DELETED] JetBrains.Old.Module.ru-RU.resx

=== Change statistics ===
Total files: 243
Changed: 1
New: 1
Deleted: 1
Unchanged: 233
Files to convert: 2
Has changes: YES

  ═════════════════════════════════════════════════════════════
  CONVERSION SUMMARY
  ═════════════════════════════════════════════════════════════
  Files processed: 2
  Successful:      2
  Errors:          0
  Total resources: 1247
  Time:            0.24 sec.
  Speed:           8.33 files/sec.
  ═════════════════════════════════════════════════════════════
```

#### Error details:

When conversion fails, the script shows:
- Line number and position in the .resx file (if available)
- Error message from ResGen
- The problematic code line with visual `^` indicator

**Example:**
```
  [!] JetBrains.Broken.File.resx
      Line 42, Position 15
      error RG000: The data at line 42, position 15 is invalid.
      Code: <data name="InvalidKey" xml:space="preserve">
              ^
```

#### Russian keyboard layout support:

In interactive prompts, the following inputs are supported:
- **Yes:** `y`, `Y`, `т`, `Т`, `да`, `Д`
- **No:** `n`, `N`, `н`, `Н`, `нет`, `Enter` (default)

---

## 🎯 Installation

### Via NuGet (ReSharper Extension Manager):
```
PM> Install-Package BaHooo.ReSharper.I18n.ru
```

### Via JetBrains Marketplace:
1. Open **Extensions** → **Marketplace** in ReSharper
2. Search for "Russian Language Pack for ReSharper"
3. Click **Install**

### Manual installation:
1. Download `.nupkg` file from [Releases](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases)
2. Drag and drop file into ReSharper Extensions window
3. Restart Visual Studio

---

## 📦 Package Contents

**NuGet package (`BaHooo.ReSharper.I18n.ru.2026.2.2.1.nupkg`):**

### Metadata:
- **ID:** `BaHooo.ReSharper.I18n.ru`
- **Version:** `2026.2.2.1`
- **Dependencies:** Wave `[262.0.0]` (ReSharper 2026.2, Visual Studio 2026)
- **License:** CC BY-NC-SA 4.0 (acceptance required)

### Files:
- `icon.png` - package icon
- `README.md` - documentation
- `LICENSE` - license agreement
- `DotFiles/Extensions/BaHooo.ReSharper.I18n.ru/i18n/*.resources` - localization files

---

## 💖 Project Support

The project is developed and maintained on enthusiasm. If you want to support further development:

### 💰 Donations:
- **Destream (cards, cryptocurrency):** https://destream.net/live/bahooo22_06537/donate
- **Telegram:** [@compohelp_vitebsk](https://t.me/compohelp_vitebsk) (for donation inquiries)

### 🤝 Other forms of support:
- ⭐ **Star** the project on GitHub
- 🐛 **Report translation errors**
- 💡 **Suggest improvements**
- 📢 **Tell colleagues** about the project

---

## 🔧 Utilities

### Testing paths
```powershell
.\test-paths.ps1
```

### Final build verification
```powershell
.\final-check.ps1
```

### Local workflow test
```powershell
.\test-local-workflow.ps1
```

### Version management
```powershell
Import-Module .\VersionManager.psm1
```

---

## 🚀 GitHub Actions Workflow

### `pack-and-release.yml`

**Triggers:**
- Push to `main` branch
- Release creation
- Manual trigger

**Stages:**
1. **Checkout** - get code
2. **Setup .NET** - install .NET SDK
3. **Convert RESX** - convert .resx to .resources
4. **Build NuGet** - build NuGet package
5. **Build Marketplace** - build Marketplace package
6. **Upload Artifacts** - upload artifacts

**Workflow commands:**
```yaml
- name: Convert RESX to Resources
  run: .\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild

- name: Build NuGet Package
  run: .\resx-to-resources.ps1 -BuildOnly
```

---

## 📊 Build Process

### Stage 1: Change detection
- Load hashes from `build/resx-hashes.json`
- Calculate hashes of current files
- Identify modified/new/deleted files

### Stage 2: Version management
- When changes detected: increment version (2025.3.0.4 → 2025.3.0.5)
- Update .nuspec files
- Update .resx files

### Stage 3: Conversion
- Only modified files are converted using ResGen
- Result saved to `build/resources/`

### Stage 4: Package building
1. **NuGet package** - for installation via ReSharper
2. **Marketplace package** - for publishing to JetBrains Marketplace

---

## 📝 Translation Examples

**UI elements:**
- `PleaseHelpUsImprove_Text` → "Помогите нам стать лучше" (Help us improve)
- `ConvertThemedIconsActionText` → "Преобразовать тематические значки…" (Convert themed icons…)
- `DisableOtherInstance_Text` → "Отключить другой экземпляр" (Disable other instance)
- `ProvideFeedback_Text` → "Оставить отзыв" (Provide feedback)
- `CopyFullPathActionText` → "Копировать полный путь" (Copy full path)

**Terminology:**
- `Code Inspection` → "Проверка кода" (Code inspection)
- `Refactoring` → "Рефакторинг" (Refactoring)
- `Quick Fix` → "Быстрое исправление" (Quick fix)
- `Solution` → "Решение" (Solution)
- `Project` → "Проект" (Project)

---

## ⚙️ Requirements for Local Build

1. **PowerShell 7 (`pwsh`) is the recommended interpreter.** The scripts also run under Windows
   PowerShell 5.1, but **only with a UTF-8 BOM in `.ps1`/`.psm1`**: without the BOM, 5.1 reads the
   file in the system ANSI codepage, Cyrillic strings turn into garbage and the script stops
   parsing. The parallel run (`-up` / `-Threads N` in `resx-to-resources.ps1`) is a separate case:
   under 5.1 the `Ensure-PowerShell7Available` function (lines 717-754) downloads portable
   PowerShell 7 (101 MB for `PowerShell-7.6.6-win-x64.zip`) into `Tools\PWSH7\` and restarts the
   script, so launching under `pwsh 7` right away is faster and needs no network access.
2. **ResGen.exe** - ships only inside the Windows SDK, there is no separate download for it.
   The script looks for it in `PATH`, then in every
   `Microsoft SDKs\Windows\v10.0A\bin\NETFX * Tools\` directory, then in `.\Tools\ResGen\`.
   If it is missing, `.resources` generation is skipped with a warning and the build continues.
3. **NuGet CLI** (nuget.exe) - for creating packages
   - Install: `winget install Microsoft.NuGet`
   - Or download: https://www.nuget.org/downloads
   - Or let the script download it into `.\Tools\NuGet` (`-NoNetwork` disables this)

---

## 📦 Build Results

After successful build, artifacts will be available in folders:
- `MarketplaceFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - JetBrains Marketplace
- `NugetFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - NuGet

**Package name format:** `BaHooo.ReSharper.I18n.ru.{version}.nupkg`

---

## 🔄 Versioning

**Version format:** `Year.Major.Minor.Build`

**Example:** `2026.2.2.1`
- `2026` - release year
- `2` - major ReSharper version (2026.2)
- `2` - ReSharper patch (2026.2.2)
- `1` - build number (incremented with changes)

The first three components must match the supported platform: the package is built for one
Wave, which is visible in `<dependency id="Wave" version="[262.0.0]" />` of both `.nuspec`
files. A package built for 253 will not load under platform 262 at all.

**Files where version is updated:**
- `NugetFolder/BaHooo.ReSharper.I18n.ru.nuspec`
- `MarketplaceFolder/BaHooo.ReSharper.I18n.ru.nuspec`
- `raw-resx-done_ru-RU/JetBrains.UI.Avalonia.Resources.Strings.ru-RU.resx`
- `raw-resx-done_ru-RU/JetBrains.UI.Resources.Strings.ru-RU.resx`

---

## 📜 License

### Main License
**Creative Commons Attribution‑NonCommercial‑ShareAlike 4.0 International (CC BY‑NC‑SA 4.0)**  
Copyright (c) 2025 Ivan "BaHooo" Zelenkevich

### Terms:
- **Attribution (BY)**: Credit the author (Ivan "BaHooo" Zelenkevich) and link to original repository
- **NonCommercial (NC)**: For non-commercial use only
- **ShareAlike (SA)**: Derivative works under the same CC BY-NC-SA 4.0 license

### Commercial Use:
Requires separate license agreement with the author:
📧 E-Mail: a7706061@outlook.com  
📱 Telegram: [Ivan "BaHooo" 3](https://t.me/compohelp_vitebsk)

---

## 🤝 Feedback

### Reporting issues:
- **GitHub Issues**: [https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues)
- **Telegram**: [@compohelp_vitebsk](https://t.me/compohelp_vitebsk)

### Translation suggestions:
- Create an Issue with "translation" label
- Specify source phrase and your translation variant
- Explain why your variant is better

---

## 🐛 Debugging and Troubleshooting

### Checking logs
```powershell
# Main log
Get-Content build.log -Tail 50

# Error log
Get-Content build.errors.log

# Hash cache
Get-Content build\resx-hashes.json | ConvertFrom-Json | Select-Object -First 5
```

### Component testing
```powershell
# Testing paths and dependencies
.\test-paths.ps1

# Local full workflow test
.\test-local-workflow.ps1

# Final artifact verification
.\final-check.ps1
```

### Common problems and solutions:

1. **"nuget.exe not found"**
   ```powershell
   winget install Microsoft.NuGet
   # or
   # Download from https://www.nuget.org/downloads
   # and add to PATH
   ```

2. **"ResGen not found"**
   ```powershell
   # Install Windows SDK or .NET SDK
   # ResGen is usually located at:
   # C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\
   ```

3. **"Permission denied"**
   ```powershell
   # Run PowerShell as Administrator
   # or change permissions on build/ folder
   ```

4. **Hash file corrupted**
   ```powershell
   # Delete cache and perform full conversion
   Remove-Item build\resx-hashes.json -ErrorAction SilentlyContinue
   .\resx-to-resources.ps1 -ForceAll
   ```

5. **No changes, but build needed**
   ```powershell
   # Force conversion of all files
   .\resx-to-resources.ps1 -ForceAll
   ```

---

## 📝 Work Recommendations

### For developers:
```powershell
# Daily work
.\resx-to-resources.ps1

# After changes in several files
.\resx-to-resources.ps1 -NoBuild
# Check result, then:
.\resx-to-resources.ps1 -BuildOnly
```

### For CI/CD:
```powershell
# First stage: conversion
.\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild

# Second stage: building
.\resx-to-resources.ps1 -BuildOnly
```

### For debugging:
```powershell
# Check status
.\test-paths.ps1

# Full log with details
.\resx-to-resources.ps1 2>&1 | Tee-Object -FilePath debug.log

# Check specific file
# (temporarily add -Verbose to script)
```

---

## 🎉 Project History

**Project milestones:**
- **2024.11.27** - Anya "Pixel" Zelenkevich was born
- **2025.11.27** - Project started
- **2025.12.1** - First build
- **2025.12.8** - Release 2025.3.0.7
- **2026.03.28** - Moved to ReSharper 2025.3.3, release 2025.3.3.10
- **2026.09.24** - Build pipeline revision (script encodings, `.nuspec` corruption under PowerShell 5.1), release 2025.3.3.11
- **2026.09.24** - Moved to ReSharper 2026.2.2: 507 new strings in 57 tables, wave raised to `[262.0.0]`, package 2026.2.2.1, release 2026.2.2.1 not published yet

---

## 🔗 Useful Links

- [JetBrains Marketplace](https://plugins.jetbrains.com/)
- [NuGet Gallery](https://www.nuget.org/)
- [ReSharper Documentation](https://www.jetbrains.com/resharper/documentation/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [CC BY-NC-SA 4.0 License](https://creativecommons.org/licenses/by-nc-sa/4.0/)
- **Support the project:** https://destream.net/live/bahooo22_06537/donate