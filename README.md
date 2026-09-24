# 📘 BaHooo.ReSharper.LanguagePack.ru

![ReSharper Russian Language Pack Icon](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/NugetFolder/BaHooo.ReSharper.I18n.ru/icon.png)

# Русский языковой пакет от BaHooo для JetBrains ReSharper 

[![Release](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases)
[![Build](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/actions/workflows/pack-and-release.yml)
[![Last commit](https://img.shields.io/github/last-commit/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/commits/main)
[![Issues](https://img.shields.io/github/issues/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues)
[![PRs](https://img.shields.io/github/issues-pr/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pulls)
[![Stars](https://img.shields.io/github/stars/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/stargazers)
[![Forks](https://img.shields.io/github/forks/bahooo22/BaHooo.ReSharper.LanguagePack.ru?style=social)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/network/members)
[![Repo size](https://img.shields.io/github/repo-size/bahooo22/BaHooo.ReSharper.LanguagePack.ru)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru)
[![NuGet Version](https://img.shields.io/nuget/v/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru)
[![NuGet Downloads](https://img.shields.io/nuget/dt/BaHooo.ReSharper.I18n.ru)](https://www.nuget.org/packages/BaHooo.ReSharper.I18n.ru)
[![Platform](https://img.shields.io/badge/platform-.NET-blue)](#)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-lightgrey)](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/LICENSE)
[![Donate](https://img.shields.io/badge/donate-red)]()

---

| **Release** | **Build** | **Last commit** |
|---|---|---|
| ![GitHub release](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru) | ![Workflow](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml) | ![Last commit](https://img.shields.io/github/last-commit/bahooo22/BaHooo.ReSharper.LanguagePack.ru) |

[![README: English](https://img.shields.io/badge/README-English-blue)](./README.en.md)

Плагин для русской локализации интерфейса ReSharper в Visual Studio.

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
│       ├───build.ps1
│       └───BaHooo.ReSharper.I18n.ru.nuspec
├───NugetFolder/                # Пакет для NuGet
│   └───BaHooo.ReSharper.I18n.ru/
│       ├───DotFiles/
│       ├───package/
│       ├───build.ps1
│       └───BaHooo.ReSharper.I18n.ru.nuspec
├───build/                      # Промежуточные материалы и отчёты
│   ├───resources/             # .resources, собранные ResGen (в git не попадает)
│   ├───resx-hashes.json       # Кэш хэшей .resx файлов
│   ├───new-translations-2026.json  # Источник новых строк_version_ (ключ + en + ru)
│   ├───i18n-audit.ps1         # Аудит покрытия: DLL платформы vs наш пакет
│   └───i18n-coverage-report.txt    # Его вывод — цифры раздела «Покрытие ресурсов»
├───Tools/                      # Скачиваемые инструменты (в git не попадает)
└───raw-resx-done_ru-RU/        # Исходные переведенные файлы .resx (243 файла)
```

Окончания строк зафиксированы в `.gitattributes`: в репозитории всё хранится в LF,
`.resx`/`.ps1`/`.nuspec` в рабочем дереве — CRLF (их расходуют ResGen и Windows
PowerShell), документация и JSON — LF. Без этого каждый, кто клонирует репозиторий,
получал бы EOL по своей настройке `core.autocrlf`, и кэш хэшей считал бы все 243 файла
изменёнными.

**Основные файлы:**
- `resx-to-resources.ps1` - основной скрипт сборки
- `VersionManager.psm1` - управление версиями
- `final-check.ps1` - проверка финальной сборки
- `test-paths.ps1` - тестирование путей
- `test-local-workflow.ps1` - локальный тест workflow
- `TODO.md` - список задач

---

## 📊 Статистика проекта

**Файлов перевода:** 243 `.resx`
**Строк в них:** 33 945 элементов `<data>`, из них 33 229 содержат кириллицу в значении.
&nbsp;&nbsp;&nbsp;&nbsp;Считано XML-парсером по детям корня: наивный поиск `<data name=` по тексту файла даёт 34 917,
&nbsp;&nbsp;&nbsp;&nbsp;потому что в шапке каждого resx лежат 4 примера из XSD-документации.
**Текущая версия:** 2026.2.2.1 (ReSharper 2026.2.2, wave `[262.0.0]`)
**Последнее обновление:** 24 сентября 2026 года
**Размер исходных .resx:** 7 577 375 байт
**Общий размер .resources:** 5 741 719 байт

**Крупнейшие модули:**
- JetBrains.ReSharper.Daemon.CSharp.Resources.Strings.ru-RU.resx (960 КБ)
- JetBrains.ReSharper.Feature.Services.Cpp.Resources.Strings.ru-RU.resx (620 КБ)
- JetBrains.ReSharper.Intentions.CSharp.Resources.Strings.ru-RU.resx (410 КБ)
- JetBrains.ReSharper.Daemon.Resources.Strings10.ru-RU.resx (282 КБ)
- JetBrains.ReSharper.Feature.Services.Resources.Strings.ru-RU.resx (279 КБ)

---

## 🧭 Покрытие ресурсов

Полный ответ на вопрос «надо ли переводить всё» даёт `build/i18n-audit.ps1`: он берёт
все neutral-ресурсы (без `*.g.resources` и без сателлитов) из DLL установленной
платформы ReSharper и сверяет их с именами, которые покрывает наш пакет. Каталог
установки ищется сам (`ReSharperPlatform*` в `Program Files (x86)\JetBrains\Installations`
и в `%LOCALAPPDATA%`), потому что имя папки содержит хэш установки и меняется при каждом
переходе на новый билд. Отчёт — `build/i18n-coverage-report.txt`.

Замер против ReSharper 2026.2.2 (`ReSharperPlatformVs18_e6a7a229`), 24.09.2026:

| Показатель | Значение |
|---|---|
| DLL просканировано | 624 (загрузить не удалось 2 нативные) |
| Neutral `.resources` в платформе | 337 |
| **Покрыто пакетом** | **180 из 337** |
| Не покрыто | 157 |
| `.resx` пакета, которых нет в этой установке | 63 (Rider, dotTrace Home, CommandLine, ForTea…) |
| Задеплоено `.resources` в `i18n` установки | 243 = 243, расхождений нет |

157 непокрытых — это не «непереведённые строки». Разложение:

- **94 набора — чужие библиотеки**: NuGet.* (15), Microsoft.* (45), DevExpress (17), System.* (8), Actipro (5), yWorks (2), MahApps, NHunspell. Механизм сателлитов ReSharper их не перекрывает, и в интерфейс VS они почти не попадают.
- **63 набора — свои (JetBrains.*), и по фактическому числу строковых записей в них:**
  - 13 наборов = 2 892 строки — `JetBrains.ReSharper.Psi.Src.Asp.Resources.Sharepoint.ResourceFiles.*`. Это справочные данные SharePoint, нужные PSI для разбора ASP.NET-разметки, а не текст интерфейса. **Переводить нельзя.**
  - 38 наборов = **0 строк** — пустые контейнеры локализации WinForms/WPF-форм (`ProductBaseForm`, `PromptWinForm`, `AdvancedNamingSettingsForm`, `TemplateChooserDialog`, `AdjustNamespacesPage` и т. п.): текст в таких диалогах зашит в код, resource-механизмом он не локализуется. **Доставывать нечего.**
  - 12 наборов = **60 строк** — остаток, и он мелкий: `Razor.CSharp.Resources.Texts` (15), `Application.BuildScript.Compile.LicenseTexts` (15), `DotTraceLicenseSupportResources` (5), `dotTraceInstant.ViewModel.Interface.Resources` (4), `UnitTestProvider.MSTest12/14/15…Strings` (по 4), `FileLayoutPatternResources` (3), `Unity…AdditionalFileLayoutResources` (2), `DotTrace.Ide.Core.Interface.Resources` (2), `CodeInspectionWikiResources` (1), `Resources.resources` пакета VS (1). Из этих 60 строк 11 относятся к dotTrace (отдельный продукт, в ReSharper внутри VS не виден), 15 — тексты лицензий, а реальная работа — 34 строки в 8 таблицах, они расписаны в TODO.md.

**Вывод:** «доставать все ресурсы из всех DLL» не нужно. Из 337 наборов локализуемый
остаток, не покрытый пакетом, — 60 строк в 12 таблицах против 33 229 уже переведённых.
Ресурсы, отсутствующие в установке VS (63 наших `.resx`), оставлены намеренно: они
принадлежат продуктам того же пакета `.resources`-механики (Rider/dotPeek/dotMemory/dotTrace
Home), которые мы поддерживаем тем же исходником.

---

## 🚀 Основной скрипт сборки

### `resx-to-resources.ps1`

> **📅 Последнее обновление:** 2026-09-24  
> **✨ Что нового сегодня:**
> - ✅ Все `.ps1`/`.psm1` сохранены с UTF-8 BOM: без него Windows PowerShell 5.1 читает скрипт в ANSI-кодировке и спотыкается о русские строки
> - ✅ `build.ps1` и `VersionManager.psm1` читают `.nuspec` с явным `-Encoding UTF8` (раньше прогон под 5.1 перекодировал русский текст в кракозябры)
> - ✅ Перезапись `.nuspec`/`.resx` ведётся через `WriteAllText` — `Out-File` дописывал пустую строку в конец на каждый запуск
> - ✅ Параллельная конвертация (`-up`, `-t`, `-Threads`) с авто-выбором потоков
> - ✅ Авто-загрузка PowerShell 7 в `./Tools/PWSH7` при необходимости
> - ✅ Авто-загрузка `nuget.exe` в `./Tools/NuGet` (ResGen.exe скачивать не откуда: он приходит только с Windows SDK, скрипт находит его там)
> - ✅ Новые флаги: `-AcceptAll/-aa` (CI/CD), `-CleanTools`, `-NoNetwork` (оффлайн)
> - ✅ История хэшей: до 10 версий в `resx-hashes.history.json`
> - ✅ Детализация ошибок: показ строки/позиции + визуальный указатель `^`
> - ✅ Улучшенный вывод: лаконичный формат `[✓] file.resx` + статистика ресурсов
> - ✅ Итоговая статистика: блок «ИТОГИ КОНВЕРТАЦИИ» с временем, скоростью, количеством
> - ✅ Запрос подтверждения при запуске без параметров
> - ✅ Поддержка русской раскладки: `т/Т/да/Д` = да, `н/Н/нет` = нет
> - ✅ Информация о системе при старте (версия PS, CPU, ядра)
> - ✅ Функции с единой ответственностью + документация `<# .SYNOPSIS #>`
> - ✅ Потокобезопасное логирование через `[System.IO.File]::AppendAllText()`
> - ✅ Флаг `VersionAlreadyUpdated`: предотвращение двойного инкремента версии

Умный скрипт для управления процессом сборки с отслеживанием изменений через хэши SHA256.

#### Интеллектуальные возможности:

1. **Кэширование хэшей** - сохраняет хэши всех .resx файлов в `build/resx-hashes.json`
2. **Инкрементальная конвертация** - конвертирует только изменённые файлы
3. **Автоинкремент версии** - при изменениях автоматически обновляет версию
4. **Проверка конфликтов** - предотвращает несовместимые комбинации параметров
5. **Параллельная обработка** - многопоточная конвертация через PowerShell 7+ (`-up`)
6. **Автономная инфраструктура** - авто-загрузка отсутствующих инструментов в `./Tools`
7. **История изменений** - хранение до 10 снимков состояния с метками времени
8. **Детализация ошибок** - парсинг вывода ResGen для показа строки/позиции ошибки

#### Параметры:

| Параметр | Алиас | Описание | По умолчанию |
|----------|--------|----------|--------------|
| `-ResxFolder` | - | Папка с исходными .resx файлами | `.\raw-resx-done_ru-RU` |
| `-ResourcesOutput` | - | Папка для сгенерированных .resources файлов | `.\build\resources` |
| `-Version` | - | Версия сборки вручную (иначе автоинкремент) | (авто) |
| `-LogFile` | - | Файл основного лога | `build.log` |
| `-ErrorLogFile` | - | Файл лога ошибок | `build.errors.log` |
| `-NoBuild` | `-nb` | Только конвертация, без сборки пакетов | - |
| `-BuildOnly` | `-bo` | Только сборка, без конвертации | - |
| `-NoResgen` | `-nr` | Пропустить генерацию .resources | - |
| `-SyncVersions` | `-sv` | Синхронизировать версии перед выполнением | - |
| `-SkipVersionUpdate` | `-svu` | Отключить автоинкремент версии (для CI/CD) | - |
| `-ForceAll` | `-fa` | Принудительная конвертация ВСЕХ .resx файлов | - |
| `-UseParallel` | `-up`, `-t`, `-Threads` | Количество потоков для параллельной обработки (0=выкл, 1=авто, 2..N=явно) | `0` |
| `-AcceptAll` | `-aa` | Авто-согласие на загрузку инструментов (для CI/CD) | - |
| `-CleanTools` | - | Очистить папку `./Tools` перед запуском | - |
| `-NoNetwork` | - | Запретить любые сетевые запросы (оффлайн-режим) | - |
| `-Help` | `-h` | Показать справку | - |

#### Примеры использования:

```powershell
# 🔹 Полный процесс: проверка → конвертация → сборка
.\resx-to-resources.ps1

# 🔹 С параллелизмом (ускорение): 8 потоков + синхронизация версий
.\resx-to-resources.ps1 -up 8 -sv

# 🔹 Умный параллелизм: авто-выбор потоков (половина ядер)
.\resx-to-resources.ps1 -up -sv

# 🔹 Только конвертация изменённых файлов
.\resx-to-resources.ps1 -NoBuild

# 🔹 Только сборка пакетов (ресурсы уже готовы)
.\resx-to-resources.ps1 -BuildOnly

# 🔹 CI/CD режим: все файлы, без инкремента версии, авто-согласие
.\resx-to-resources.ps1 -ForceAll -SkipVersionUpdate -NoBuild -AcceptAll

# 🔹 Оффлайн-режим: без загрузок, пропуск resgen
.\resx-to-resources.ps1 -NoNetwork -NoResgen

# 🔹 Краткие формы:
.\resx-to-resources.ps1 -fa -svu -nb -aa    # Для CI/CD
.\resx-to-resources.ps1 -bo                 # Только сборка
.\resx-to-resources.ps1 -up -sv             # Параллельно + синхронизация
```

#### Как работает проверка изменений:

1. **При первом запуске:** создаётся `build/resx-hashes.json` с хэшами всех файлов
2. **При последующих запусках:** сравниваются хэши с сохранёнными
3. **Конвертируются только:** новые или изменённые файлы
4. **Удалённые файлы:** отмечаются в логе, но не влияют на сборку
5. **История:** сохраняется до 10 последних снимков в `resx-hashes.history.json`

**Пример вывода:**
```
=== Проверка изменений в .resx файлах ===
Загружено хэшей из кэша: 243
[ИЗМЕНЕН] JetBrains.UI.Resources.Strings.ru-RU.resx
[НОВЫЙ] JetBrains.New.Module.ru-RU.resx
[УДАЛЕН] JetBrains.Old.Module.ru-RU.resx

=== Статистика изменений ===
Всего файлов: 243
Измененных: 1
Новых: 1
Удаленных: 1
Без изменений: 233
Файлов для конвертации: 2
Есть изменения: ДА

  ═════════════════════════════════════════════════════════════
  ИТОГИ КОНВЕРТАЦИИ
  ═════════════════════════════════════════════════════════════
  Файлов обработано: 2
  Успешно:           2
  Ошибок:            0
  Всего ресурсов:    1247
  Время:             0,24 сек.
  Скорость:          8,33 файлов/сек.
  ═════════════════════════════════════════════════════════════
```

#### Детализация ошибок:

При ошибке конвертации скрипт показывает:
- Номер строки и позицию в .resx файле (если доступны)
- Текст ошибки от ResGen
- Проблемную строку кода с визуальным указателем `^`

**Пример:**
```
  [!] JetBrains.Broken.File.resx
      Строка 42, Позиция 15
      error RG000: The data at line 42, position 15 is invalid.
      Код: <data name="InvalidKey" xml:space="preserve">
              ^
```

#### Поддержка русской раскладки:

В интерактивных запросах поддерживаются:
- **Да:** `y`, `Y`, `т`, `Т`, `да`, `Д`
- **Нет:** `n`, `N`, `н`, `Н`, `нет`, `Enter` (по умолчанию)

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

**NuGet пакет (`BaHooo.ReSharper.I18n.ru.2026.2.2.1.nupkg`):**

### Метаданные:
- **ID:** `BaHooo.ReSharper.I18n.ru`
- **Версия:** `2026.2.2.1`
- **Зависимости:** Wave `[262.0.0]` (ReSharper 2026.2, Visual Studio 2026)
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
- При изменениях: инкрементируется последняя компонента (2026.2.2.1 → 2026.2.2.2)
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

1. **Windows PowerShell 5.1 или PowerShell 7** - для выполнения скриптов. Работают оба, но **только при UTF-8 BOM в `.ps1`/`.psm1`**: без него Windows PowerShell 5.1 читает скрипт в системной ANSI-кодировке, русские строки превращаются в мусор и файл не парсится.
2. **ResGen.exe** - только в составе Windows SDK (отдельной загрузки нет). Скрипт ищет его в `PATH`, затем в `Microsoft SDKs\Windows\v10.0A\bin\NETFX * Tools\`, затем в `.\Tools\ResGen\`. Если не нашёл — генерация `.resources` пропускается с предупреждением, а сборка продолжается.
3. **NuGet CLI** (nuget.exe) - для создания пакетов
   - Установить: `winget install Microsoft.NuGet` или скачать с https://www.nuget.org/downloads
   - Или скрипт скачает его сам в каталог Tools\NuGet (отключается флагом -NoNetwork)
4. **.NET SDK** - не требуется: ResGen берётся из Windows SDK, а `dotnet` в пайплайне не участвует

---

## 📦 Результаты сборки

После успешной сборки артефакты будут доступны в папках:
- `MarketplaceFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - JetBrains Marketplace
- `NugetFolder/BaHooo.ReSharper.I18n.ru/artifacts/` - NuGet

**Формат имени пакета:** `BaHooo.ReSharper.I18n.ru.{версия}.nupkg`

---

## 🔄 Версионирование

**Формат версии:** `ГГГГ.Мажор.Патч.Билд` — четыре компонента, где первые три повторяют версию ReSharper

**Пример:** `2026.2.2.1`
- `2026` - год релиза
- `2` - мажорная версия ReSharper (2026.2)
- `2` - патч ReSharper (2026.2.2)
- `1` - номер сборки (инкрементируется при изменениях)

Версии первых трёх компонент обязаны соответствовать поддерживаемой платформе: пакет
собирается под конкретный Wave, и расхождение видно в `<dependency id="Wave" version="[262.0.0]" />`
обаих `.nuspec`. Пакет, собранный под 253, под платформой 262 просто не загрузится.

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

2. **"ResGen.exe не найден"**
   ```powershell
   # Отдельной загрузки ResGen.exe нет — он приходит только с Windows SDK.
   # Visual Studio Installer -> Отдельные компоненты -> SDK для Windows
   # Проверить наличие:
   Test-Path 'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8.1 Tools\ResGen.exe'
   # Скрипт ищет ResGen в PATH, во всех каталогах Windows SDK и в .\Tools\ResGen\
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
- **2025.12.8** - Релиз 2025.3.0.7
- **2026.03.28** - Переход на ReSharper 2025.3.3, релиз 2025.3.3.10
- **2026.09.24** - Ревизия пайплайна (кодировки скриптов, порча `.nuspec` при сборке в PowerShell 5.1), сборка 2025.3.3.11
- **2026.09.24** - Переход на ReSharper 2026.2.2: 507 новых строк в 57 таблицах, wave поднят до `[262.0.0]`, перезаливка перевода после mojibake-сбора, пакет `2026.2.2.1`

---

## 🔗 Полезные ссылки

- [JetBrains Marketplace](https://plugins.jetbrains.com/)
- [NuGet Gallery](https://www.nuget.org/)
- [ReSharper Documentation](https://www.jetbrains.com/resharper/documentation/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Лицензия CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
- **Поддержать проект:** https://destream.net/live/bahooo22_06537/donate
