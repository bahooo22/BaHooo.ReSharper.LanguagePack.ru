# 📘 BaHooo.ReSharper.LanguagePack.ru

![ReSharper Russian Language Pack Icon](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/NugetFolder/BaHooo.ReSharper.I18n.ru/icon.png)

| [![GitHub license](https://img.shields.io/github/license/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](LICENSE) | [![NuGet Version](https://img.shields.io/nuget/v/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru) | [![NuGet Downloads](https://img.shields.io/nuget/dt/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru) |
|---|---|---|
| [![GitHub release (latest by date)](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases) | [![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/actions/workflows/pack-and-release.yml) | [![GitHub last commit](https://img.shields.io/github/last-commit/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/commits/main) |
| [![GitHub issues](https://img.shields.io/github/issues/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues) | [![GitHub pull requests](https://img.shields.io/github/issues-pr/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pulls) | [![GitHub Repo size](https://img.shields.io/github/repo-size/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru) |
| [![GitHub Repo stars](https://img.shields.io/github/stars/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/stargazers) | [![GitHub forks](https://img.shields.io/github/forks/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/network/members) | [![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru) |
| ![Platform](https://img.shields.io/badge/platform-.NET-blue) | ![Language](https://img.shields.io/github/languages/top/bahooo22/BaHooo.ReSharper.LanguagePack.ru) | [![Donate](https://img.shields.io/badge/donate-destream.net-red)](https://destream.net/live/bahooo22_06537/donate) |
| [![English](https://img.shields.io/badge/README-Русская→English-blue)](./README.en.md) |
Плагин для русской локализации интерфейса **ReSharper** в Visual Studio.

---

## 📁 Структура проекта

```
├───.github/
│   └───workflows/              # GitHub Actions workflows
│       └───pack-and-release.yml
├───MarketplaceFolder/          # Пакет для JetBrains Marketplace
│   └───BaHooo.ReSharper.I18n.ru/
│       ├───DotFiles/
│       ├───package/
│       └───build.ps1
├───NugetFolder/                # Пакет для NuGet
│   └───BaHooo.ReSharper.I18n.ru/
│       ├───DotFiles/
│       ├───package/
│       └───build.ps1
├───build/                      # Ресурсы для сборки
│   └───resx-hashes.json       # Кэш хэшей .resx файлов
└───raw-resx-done_ru-RU/        # Исходные переведенные файлы .resx (236 файлов)
```

**Основные файлы:**
- `resx-to-resources.ps1` - основной скрипт сборки
- `VersionManager.psm1` - управление версиями
- `final-check.ps1` - проверка финальной сборки
- `test-paths.ps1` - тестирование путей
- `test-local-workflow.ps1` - локальный тест workflow
- `TODO.md` - список задач

---

## 📊 Статистика проекта

**Всего переведенных файлов:** 236 файлов .resx  
**Текущая версия:** 2025.3.0.7  
**Последнее обновление:** 8 декабря 2025 года  
**Общий размер ресурсов:** 5 615 837 Байт

**Ключевые модули:**
- JetBrains.UI.Resources.Strings.ru-RU.resx (61 КБ)
- JetBrains.ReSharper.Daemon.CSharp.Resources.Strings.ru-RU.resx (901 КБ)
- JetBrains.ReSharper.Feature.Services.Cpp.Resources.Strings.ru-RU.resx (605 КБ)
- JetBrains.Rider.Backend.Resources.Strings.ru-RU.resx (167 КБ)

---

## 🚀 Основной скрипт сборки

### `resx-to-resources.ps1`

Умный скрипт для управления процессом сборки с отслеживанием изменений через хэши SHA256.

#### Интеллектуальные возможности:

1. **Кэширование хэшей** - сохраняет хэши всех .resx файлов в `build/resx-hashes.json`
2. **Инкрементальная конвертация** - конвертирует только измененные файлы
3. **Автоинкремент версии** - при изменениях автоматически обновляет версию
4. **Проверка конфликтов** - предотвращает несовместимые комбинации параметров

#### Параметры:

| Параметр | Алиас | Описание | По умолчанию |
|----------|--------|----------|--------------|
| `-ResxFolder` | - | Папка с .resx файлами | `.\raw-resx-done_ru-RU` |
| `-ResourcesOutput` | - | Папка для .resources файлов | `.\build\resources` |
| `-NoBuild` | `-nb` | Только конвертация, без сборки | - |
| `-BuildOnly` | `-bo` | Только сборка, без конвертации | - |
| `-NoResgen` | `-nr` | Пропустить генерацию .resources | - |
| `-SyncVersions` | `-sv` | Синхронизировать версии | - |
| `-SkipVersionUpdate` | `-svu` | Отключить автоинкремент версии | - |
| `-ForceAll` | `-fa` | Принудительная конвертация всех файлов | - |
| `-Help` | `-h` | Показать справку | - |

#### Примеры использования:

```powershell
# Полный процесс: проверка → конвертация → сборка
.\resx-to-resources.ps1

# Только конвертация измененных файлов
.\resx-to-resources.ps1 -NoBuild

# Только сборка пакетов
.\resx-to-resources.ps1 -BuildOnly

# CI/CD режим: все файлы, без инкремента версии
.\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild

# Синхронизация версий
.\resx-to-resources.ps1 -SyncVersions

# Краткие формы:
.\resx-to-resources.ps1 -fa -svu -nb    # Для CI/CD
.\resx-to-resources.ps1 -bo             # Только сборка
```

#### Как работает проверка изменений:

1. **При первом запуске:** создается `build/resx-hashes.json` с хэшами всех файлов
2. **При последующих запусках:** сравниваются хэши с сохраненными
3. **Конвертируются только:** новые или измененные файлы
4. **Удаленные файлы:** отмечаются в логе, но не влияют на сборку

**Пример вывода:**
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

## 🎯 Установка

### Через NuGet (ReSharper Extension Manager):
```
PM> Install-Package BaHooo.ReSharper.I18n.ru
```

### Через JetBrains Marketplace:
1. Откройте **Extensions** → **Marketplace** в ReSharper
2. Найдите "Russian Language Pack for ReSharper"
3. Нажмите **Install**

### Ручная установка:
1. Скачайте `.nupkg` файл из [Releases](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases)
2. Перетащите файл в окно ReSharper Extensions
3. Перезапустите Visual Studio

---

## 📦 Содержимое пакета

**NuGet пакет (`BaHooo.ReSharper.I18n.ru.2025.3.0.7.nupkg`):**

### Метаданные:
- **ID:** `BaHooo.ReSharper.I18n.ru`
- **Версия:** `2025.3.0.7`
- **Зависимости:** Wave `[253.0.0]` (ReSharper 2025.3)
- **Лицензия:** CC BY-NC-SA 4.0 (требуется принятие)

### Файлы:
- `icon.png` - иконка пакета
- `README.md` - документация
- `LICENSE` - лицензионное соглашение
- `DotFiles/Extensions/BaHooo.ReSharper.I18n.ru/i18n/*.resources` - файлы локализации

---

## 💖 Поддержка проекта

Проект разрабатывается и поддерживается на энтузиазме. Если вы хотите поддержать дальнейшую разработку:

### 💰 Пожертвования:
- **Destream (карты, криптовалюта):** https://destream.net/live/bahooo22_06537/donate
- **Telegram:** [@compohelp_vitebsk](https://t.me/compohelp_vitebsk) (для связи по вопросам донатов)

### 🤝 Другие формы поддержки:
- ⭐ **Поставьте звезду** на GitHub
- 🐛 **Сообщайте об ошибках** перевода
- 💡 **Предлагайте улучшения**
- 📢 **Расскажите о проекте** коллегам

---

## 🔧 Утилиты

### Тестирование путей
```powershell
.\test-paths.ps1
```

### Проверка финальной сборки
```powershell
.\final-check.ps1
```

### Локальный тест workflow
```powershell
.\test-local-workflow.ps1
```

### Управление версиями
```powershell
Import-Module .\VersionManager.psm1
```

---

## 🚀 GitHub Actions Workflow

### `pack-and-release.yml`

**Триггеры:**
- Push в ветку `main`
- Создание релиза
- Ручной запуск

**Этапы:**
1. **Checkout** - получение кода
2. **Setup .NET** - установка .NET SDK
3. **Convert RESX** - конвертация .resx в .resources
4. **Build NuGet** - сборка NuGet пакета
5. **Build Marketplace** - сборка Marketplace пакета
6. **Upload Artifacts** - загрузка артефактов

**Команды в workflow:**
```yaml
- name: Convert RESX to Resources
  run: .\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild

- name: Build NuGet Package
  run: .\resx-to-resources.ps1 -BuildOnly
```

---

## 📊 Процесс сборки

### Этап 1: Проверка изменений
- Загружаются хэши из `build/resx-hashes.json`
- Вычисляются хэши текущих файлов
- Определяются измененные/новые/удаленные файлы

### Этап 2: Управление версиями
- При изменениях: инкрементируется версия (2025.3.0.4 → 2025.3.0.5)
- Обновляются .nuspec файлы
- Обновляются .resx файлы

### Этап 3: Конвертация
- Только измененные файлы конвертируются с помощью ResGen
- Результат сохраняется в `build/resources/`

### Этап 4: Сборка пакетов
1. **NuGet пакет** - для установки через ReSharper
2. **Marketplace пакет** - для публикации в JetBrains Marketplace

---

## 📝 Примеры перевода

**Элементы интерфейса:**
- `PleaseHelpUsImprove_Text` → "Помогите нам стать лучше"
- `ConvertThemedIconsActionText` → "Преобразовать тематические значки…"
- `DisableOtherInstance_Text` → "Отключить другой экземпляр"
- `ProvideFeedback_Text` → "Оставить отзыв"
- `CopyFullPathActionText` → "Копировать полный путь"

**Терминология:**
- `Code Inspection` → "Проверка кода"
- `Refactoring` → "Рефакторинг"
- `Quick Fix` → "Быстрое исправление"
- `Solution` → "Решение"
- `Project` → "Проект"

---

## ⚙️ Требования для локальной сборки

1. **.NET SDK** - для работы ResGen
2. **NuGet CLI** (nuget.exe) - для создания пакетов
   - Установить: `winget install Microsoft.NuGet`
   - Или скачать: https://www.nuget.org/downloads
3. **PowerShell 5.1+** - для выполнения скриптов
4. **ResGen.exe** - обычно входит в состав Windows SDK или .NET SDK

---

## 📦 Результаты сборки

После успешной сборки артефакты будут доступны в папках:
- `MarketplaceFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - JetBrains Marketplace
- `NugetFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - NuGet

**Формат имени пакета:** `BaHooo.ReSharper.I18n.ru.{версия}.nupkg`

---

## 🔄 Версионирование

**Формат версии:** `ГГГГ.Майнор.Минор.Билд`

**Пример:** `2025.3.0.7`
- `2025` - год релиза
- `3` - мажорная версия ReSharper (2025.3)
- `0` - минорная версия пакета
- `7` - номер сборки (инкрементируется при изменениях)

**Файлы, где обновляется версия:**
- `NugetFolder/BaHooo.ReSharper.I18n.ru.nuspec`
- `MarketplaceFolder/BaHooo.ReSharper.I18n.ru.nuspec`
- `raw-resx-done_ru-RU/JetBrains.UI.Avalonia.Resources.Strings.ru-RU.resx`
- `raw-resx-done_ru-RU/JetBrains.UI.Resources.Strings.ru-RU.resx`

---

## 📜 Лицензия

### Основная лицензия
**Creative Commons Attribution‑NonCommercial‑ShareAlike 4.0 International (CC BY‑NC‑SA 4.0)**  
Copyright (c) 2025 Ivan "BaHooo" Zelenkevich

### Условия:
- **Attribution (BY)**: Указывайте автора (Ivan "BaHooo" Zelenkevich) и ссылку на оригинальный репозиторий
- **NonCommercial (NC)**: Только для некоммерческого использования
- **ShareAlike (SA)**: Производные работы под той же лицензией

### Коммерческое использование:
Требуется отдельное лицензионное соглашение с автором:
📧 E-Mail: a7706061@outlook.com  
📱 Telegram: [Иван "BaHooo" 3](https://t.me/compohelp_vitebsk)

---

## 🤝 Обратная связь

### Сообщение об ошибках:
- **GitHub Issues**: [https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues)
- **Telegram**: [@compohelp_vitebsk](https://t.me/compohelp_vitebsk)

### Предложения по переводу:
- Создайте Issue с пометкой "translation"
- Укажите исходную фразу и ваш вариант перевода
- Объясните, почему ваш вариант лучше

---

## 🐛 Отладка и решение проблем

### Проверка логов
```powershell
# Основной лог
Get-Content build.log -Tail 50

# Лог ошибок
Get-Content build.errors.log

# Кэш хэшей
Get-Content build\resx-hashes.json | ConvertFrom-Json | Select-Object -First 5
```

### Тестирование компонентов
```powershell
# Проверка путей и зависимостей
.\test-paths.ps1

# Локальный тест полного workflow
.\test-local-workflow.ps1

# Проверка финальных артефактов
.\final-check.ps1
```

### Частые проблемы и решения:

1. **"nuget.exe not found"**
   ```powershell
   winget install Microsoft.NuGet
   # или
   # Скачайте с https://www.nuget.org/downloads
   # и добавьте в PATH
   ```

2. **"ResGen not found"**
   ```powershell
   # Установите Windows SDK или .NET SDK
   # ResGen обычно находится в:
   # C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\
   ```

3. **"Permission denied"**
   ```powershell
   # Запустите PowerShell от администратора
   # или измените права на папку build/
   ```

4. **Хэш-файл поврежден**
   ```powershell
   # Удалите кэш и выполните полную конвертацию
   Remove-Item build\resx-hashes.json -ErrorAction SilentlyContinue
   .\resx-to-resources.ps1 -ForceAll
   ```

5. **Нет изменений, но нужна сборка**
   ```powershell
   # Принудительная конвертация всех файлов
   .\resx-to-resources.ps1 -ForceAll
   ```

---

## 📝 Рекомендации по работе

### Для разработчиков:
```powershell
# Ежедневная работа
.\resx-to-resources.ps1

# После изменений в нескольких файлах
.\resx-to-resources.ps1 -NoBuild
# Проверить результат, затем:
.\resx-to-resources.ps1 -BuildOnly
```

### Для CI/CD:
```powershell
# Первый этап: конвертация
.\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild

# Второй этап: сборка
.\resx-to-resources.ps1 -BuildOnly
```

### Для отладки:
```powershell
# Проверить состояние
.\test-paths.ps1

# Полный лог с деталями
.\resx-to-resources.ps1 2>&1 | Tee-Object -FilePath debug.log

# Проверить конкретный файл
# (временно добавьте -Verbose к скрипту)
```

---

## 🎉 История проекта

**Вехи проекта:**
- **2024.11.27** - Родилась Аня "Pixel" Зеленкевич
- **2025.11.27** - Проект начат
- **2025.12.1** - Первая сборка
- **2025.12.8** - Текущий релиз (версия 2025.3.0.7)

---

## 🔗 Полезные ссылки

- [JetBrains Marketplace](https://plugins.jetbrains.com/)
- [NuGet Gallery](https://www.nuget.org/)
- [ReSharper Documentation](https://www.jetbrains.com/resharper/documentation/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Лицензия CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
- **Поддержать проект:** https://destream.net/live/bahooo22_06537/donate