# 📘 BaHooo.ReSharper.LanguagePack.ru

![ReSharper Russian Language Pack Icon](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/NugetFolder/BaHooo.ReSharper.I18n.ru/icon.png)

| [![GitHub license](https://img.shields.io/github/license/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](LICENSE) | [![NuGet Version](https://img.shields.io/nuget/v/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru) | [![NuGet Downloads](https://img.shields.io/nuget/dt/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru) |
|---|---|---|
| [![GitHub release (latest by date)](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases) | [![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/actions/workflows/pack-and-release.yml) | [![GitHub last commit](https://img.shields.io/github/last-commit/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/commits/main) |
| [![GitHub issues](https://img.shields.io/github/issues/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues) | [![GitHub pull requests](https://img.shields.io/github/issues-pr/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pulls) | [![GitHub Repo size](https://img.shields.io/github/repo-size/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru) |
| [![GitHub Repo stars](https://img.shields.io/github/stars/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/stargazers) | [![GitHub forks](https://img.shields.io/github/forks/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/network/members) | [![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru) |
| ![Platform](https://img.shields.io/badge/platform-.NET-blue) | ![Language](https://img.shields.io/github/languages/top/bahooo22/BaHooo.ReSharper.LanguagePack.ru) | [![Donate](https://img.shields.io/badge/donate-destream.net-red)](https://destream.net/live/bahooo22_06537/donate) |
| [![Русский](https://img.shields.io/badge/README-English→Русская-blue)](./README.md) |
A plugin for Russian localization of the **ReSharper** interface in Visual Studio.

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
├───build/                      # Build resources
│   └───resx-hashes.json       # Cache of .resx file hashes
└───raw-resx-done_ru-RU/        # Source translated .resx files (236 files)
```

**Key files:**
- `resx-to-resources.ps1` - main build script
- `VersionManager.psm1` - version management
- `final-check.ps1` - final build verification
- `test-paths.ps1` - path testing
- `test-local-workflow.ps1` - local workflow test
- `TODO.md` - task list

---

## 📊 Project Statistics

**Total translated files:** 236 .resx files  
**Current version:** 2025.3.0.7  
**Last update:** December 8, 2025  
**Total resource size:** ~5,6 MB

**Key modules:**
- JetBrains.UI.Resources.Strings.ru-RU.resx (61 KB)
- JetBrains.ReSharper.Daemon.CSharp.Resources.Strings.ru-RU.resx (901 KB)
- JetBrains.ReSharper.Feature.Services.Cpp.Resources.Strings.ru-RU.resx (605 KB)
- JetBrains.Rider.Backend.Resources.Strings.ru-RU.resx (167 KB)

---

## 🚀 Main Build Script

### `resx-to-resources.ps1`

An intelligent script for managing the build process with change tracking via SHA256 hashes.

#### Intelligent features:

1. **Hash caching** - saves hashes of all .resx files in `build/resx-hashes.json`
2. **Incremental conversion** - converts only changed files
3. **Auto-version increment** - automatically updates version when changes are detected
4. **Conflict checking** - prevents incompatible parameter combinations

#### Parameters:

| Parameter | Alias | Description | Default |
|-----------|--------|-------------|---------|
| `-ResxFolder` | - | Folder with source .resx files | `.\raw-resx-done_ru-RU` |
| `-ResourcesOutput` | - | Folder for generated .resources files | `.\build\resources` |
| `-NoBuild` | `-nb` | Conversion only, no package building | - |
| `-BuildOnly` | `-bo` | Package building only, no conversion | - |
| `-NoResgen` | `-nr` | Skip .resources generation | - |
| `-SyncVersions` | `-sv` | Synchronize versions | - |
| `-SkipVersionUpdate` | `-svu` | Disable auto-version increment | - |
| `-ForceAll` | `-fa` | Force conversion of ALL .resx files | - |
| `-Help` | `-h` | Show help | - |

#### Usage examples:

```powershell
# Full process: check → convert → build
.\resx-to-resources.ps1

# Conversion of changed files only
.\resx-to-resources.ps1 -NoBuild

# Package building only
.\resx-to-resources.ps1 -BuildOnly

# CI/CD mode: all files, no version increment
.\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild

# Version synchronization
.\resx-to-resources.ps1 -SyncVersions

# Short forms:
.\resx-to-resources.ps1 -fa -svu -nb    # For CI/CD
.\resx-to-resources.ps1 -bo             # Build only
```

#### How change detection works:

1. **First run:** creates `build/resx-hashes.json` with hashes of all files
2. **Subsequent runs:** compares hashes with saved ones
3. **Only converts:** new or modified files
4. **Deleted files:** logged but don't affect build

**Sample output:**
```
=== Проверка изменений в .resx файлах ===
Загружено хэшей из кэша: 404
[ИЗМЕНЕН] JetBrains.UI.Resources.Strings.ru-RU.resx
[НОВЫЙ] JetBrains.New.Module.ru-RU.resx
[УДАЛЕН] JetBrains.Old.Module.ru-RU.resx

=== Статистика изменений ===
Всего файлов: 405
Измененных: 1
Новых: 1
Удаленных: 1
Без изменений: 403
Файлов для конвертации: 2
Есть изменения: ДА
```

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

**NuGet package (`BaHooo.ReSharper.I18n.ru.2025.3.0.7.nupkg`):**

### Metadata:
- **ID:** `BaHooo.ReSharper.I18n.ru`
- **Version:** `2025.3.0.7`
- **Dependencies:** Wave `[253.0.0]` (ReSharper 2025.3)
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

1. **.NET SDK** - for ResGen to work
2. **NuGet CLI** (nuget.exe) - for creating packages
   - Install: `winget install Microsoft.NuGet`
   - Or download: https://www.nuget.org/downloads
3. **PowerShell 5.1+** - for script execution
4. **ResGen.exe** - usually included with Windows SDK or .NET SDK

---

## 📦 Build Results

After successful build, artifacts will be available in folders:
- `MarketplaceFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - JetBrains Marketplace
- `NugetFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - NuGet

**Package name format:** `BaHooo.ReSharper.I18n.ru.{version}.nupkg`

---

## 🔄 Versioning

**Version format:** `Year.Major.Minor.Build`

**Example:** `2025.3.0.7`
- `2025` - release year
- `3` - major ReSharper version (2025.3)
- `0` - package minor version
- `7` - build number (incremented with changes)

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
- **2025.12.8** - Current release (version 2025.3.0.7)

---

## 🔗 Useful Links

- [JetBrains Marketplace](https://plugins.jetbrains.com/)
- [NuGet Gallery](https://www.nuget.org/)
- [ReSharper Documentation](https://www.jetbrains.com/resharper/documentation/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [CC BY-NC-SA 4.0 License](https://creativecommons.org/licenses/by-nc-sa/4.0/)
- **Support the project:** https://destream.net/live/bahooo22_06537/donate