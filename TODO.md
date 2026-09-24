# TODO

Список задач по проекту. Ранее здесь лежал черновик-дамп диалога про глоссарий машинного перевода — он сохранён в истории git (коммит до `2026-09-24`).

---

## 🔥 Ближайший релиз: 2026.2.2.1

Всё готово локально и проверено измерением, а не со слов. Осталась только публикация.

- [x] Перевести 507 новых строк ReSharper 2026.2.2 (57 таблиц) — `2b63458`
- [x] Перезалить переводы из чистого JSON, убрать mojibake — `d8bc33e`
- [x] Поднять Wave до `[262.0.0]` (ReSharper 2026.2) — `3e4b91d`
- [x] Синхронизировать версию `2026.2.2.1` в обоих `.nuspec` и в version-bearing `.resx` — `0c78161`, `1efb180`
- [x] Пересобрать `.resources` и упаковать: проверено — в `raw-resx-done_ru-RU/` 243 файла, в `build/resources/` 243, в каждом `.nupkg` 243 ресурса
- [x] Задеплоить в тестовый `i18n`-каталог: 243 из 243 совпадают с resx-списком
- [ ] `git push origin main` + тег `2026.2.2.1`
- [ ] Выложить `NugetFolder/artifacts/BaHooo.ReSharper.I18n.ru.2026.2.2.1.nupkg` на nuget.org
- [ ] Выложить `MarketplaceFolder/artifacts/BaHooo.ReSharper.I18n.ru.2026.2.2.1.nupkg` в JetBrains Marketplace

CI (`pack-and-release.yml`) создаёт только GitHub Release с обоими `.nupkg` — на nuget.org и в Marketplace публикация ручная.

---

## 🧭 Закрыть пробелы покрытия (12 наборов / 60 строк)

Свежий аудит против установленной платформы 2026.2.2 (`build/i18n-audit.ps1`, отчёт в `build/i18n-coverage-report.txt`): 624 DLL → 337 нейтральных `.resources`, 243 в пакете, **180 покрыто**. Из 157 «отсутствующих» подавляющее большинство — сторонние библиотеки (Roslyn, NuGet, DevExpress, Actipro, yWorks, MSTest-platform, Owin), которые наш пакет переводить не может и не должен.

Реальный дефицит по ресурсам JetBrains — 63 набора, и он раскладывается так:

- 13 наборов — файлы данных SharePoint (`…Asp.Resources.Sharepoint.ResourceFiles.*`, 2 892 строки): это синхронизированные с ASPX-разметкой словари, перевод бессмысленен;
- 38 наборов — пустые контейнеры WinForms/WPF (0 строковых записей, только `.resources`-обёртки форм);
- **12 наборов / 60 строк — настоящие таблицы с текстами.**

| Набор | DLL | Строк | Что это |
|---|---|---|---|
| `JetBrains.ReSharper.Psi.Src.Razor.CSharp.Resources.Texts` | ReSharper.Psi.Web | 15 | Razor-подсветка |
| `JetBrains.Application.BuildScript.Compile.LicenseTexts` | Platform.Shell | 15 | тексты лицензий — переводить только после юридической проверки |
| `JetBrains.ReSharper.UnitTestProvider.MSTest12/14/15.…Provider.Resources.Strings` | три UnitTestProvider-а | 4 × 3 | провайдеры MSTest |
| `JetBrains.ReSharper.Psi.CSharp.Src.CodeStyle.FileLayoutPatternResources` | Psi.CSharp | 3 | паттерны расположения кода |
| `JetBrains.DotTrace.UI.resources.agreements.DotTraceLicenseSupportResources` | DotTrace.UI.Builders | 5 | dotTrace, вне ReSharper-в-VS |
| `JetBrains.dotTraceInstant.ViewModel.Interface.resources.Resources` | dotTraceInstant | 4 | dotTrace |
| `JetBrains.ReSharper.Plugins.Unity.CSharp.Psi.CodeStyle.AdditionalFileLayoutResources` | Plugins.Unity | 2 | Unity-плагин |
| `JetBrains.DotTrace.Ide.Core.Interface.resources.Resources` | DotTrace.Ide.Core | 2 | dotTrace |
| `JetBrains.ReSharper.Feature.Services.Src.Explanatory.CodeInspectionWikiResources` | Feature.Services | 1 | ссылка на wiki инспекции |
| `Resources` | PlatformVs18.VisualStudio.v18.0.Package | 1 | ресурс VS-пакета (1,2 МБ, в основном не текст) |

- [ ] Перевести 6 наборов, реально видимых в VS-интерфейсе ReSharper: Razor `Texts` (15), 3 × MSTest `Strings` (по 4), `FileLayoutPatternResources` (3), `CodeInspectionWikiResources` (1) — итого 31 строка
- [ ] `AdditionalFileLayoutResources` (2 строки) из Unity-плагина и `Resources.resources` VS-пакета (1 строка) — перевести попутно или закрыть как «не наш сценарий»
- [ ] По `LicenseTexts` (15) решить, нужен ли перевод юридически
- [ ] 11 строк dotTrace-наборов (`DotTraceLicenseSupportResources` 5, `dotTraceInstant.ViewModel.Interface` 4, `DotTrace.Ide.Core.Interface` 2) закрыть как «не переводим»: dotTrace — отдельный продукт, в VS-сценарий не попадает

Прежняя оценка «~230 строк / 19 наборов» была ложной: `JetBrains.Application.Resources.VsResources` и оба `StringTable`, которые там значились, уже давно покрыты пакетом, а SharePoint-словари были посчитаны как работа.

---

## 🧹 Гигиена репозитория

- [ ] Удалить из-под версионирования: `resx-to-resourcesV1.back`, `build/resx-hashes.json.back.json`, `NugetFolder/BaHooo.ReSharper.I18n.ru/build.ps1.txt` — это ручные бэкапы, git хранит историю лучше
- [ ] Решить судьбу 6 `.resx`-заглушек: в них ровно **0** элементов `<data>` и 5816 байт — это чистый шаблон resx без единой строки перевода (`JetBrains.PsiFeatures.VisualStudio.SinceVs14`, `…SinceVs16RoslynAware`, `…Web.UIInteractive`, `JetBrains.Rider.Plugins.Verse`, `JetBrains.TeamCity.Presentation.Wpf`, `OperatorsResolveCacheGenerator`). Прежняя формулировка «по 4 служебные строки» — артефакт подсчёта: наивный regex ловил 4 примера из XSD-шапки файла. Либо удалить, либо объяснить в README, почему они пустые. Рядом стоит 7-й файл `JetBrains.Common.SystemModulesOptionsManager.Resources.SystemModulesConstants` — 9 записей, но ни одной с кириллицей (латинические константы), он нужен как есть
- [ ] Разобраться с 63 `.resx`, которых нет в DLL платформы 2026.2.2 (список в `build/i18n-coverage-report.txt`, секция «В ПАКЕТЕ, НО НЕ НАЙДЕНО В DLL»): Rider / dotPeek / dotTrace / Cpp / FSharp / TeamCity / SourceView — они нужны для Rider-сценария или мёртвый груз?
- [x] Добавить `.gitattributes`: `* text=auto eol=lf` + принудительный CRLF для `*.resx`/`*.nuspec`/`*.ps1`/`*.cmd`, binary для dll/exe/nupkg/resources. `working-tree-encoding=UTF-8` сознательно НЕ используем: у 7 resx уже есть BOM, git добавил бы второй
- [ ] Рабочую копию привести к новым правилам EOL одним `git add --renormalize .` + повторным
      checkout: сейчас `git ls-files --eol` показывает 285 индексовых blob'ов в LF (то есть новые
      правила ничего в истории не меняют), но в рабочей копии 13 текстовых файлов лежат с LF и
      6 со смешанными окончаниями вместо предписанного CRLF
- [x] Исправить скачивание ResGen в `resx-to-resources.ps1`: GUID в ссылке был выдуман (404).
      Теперь путь поиска `PATH → Windows SDK (включая обход всего дерева по маске ResGen.exe) →
      .\Tools\ResGen`, скачивания нет: при отсутствии выдаётся инструкция из Visual Studio
      Installer и сборка продолжается без генерации `.resources`

---

## 📦 Совместимость с ReSharper 2026.x

- [x] Поднять dependency wave с `[253.0.0]` на `[262.0.0]` (стабильный 2026.2, платформа `262.0.20260915`, VS `[18.0,19.0)`)
- [x] После смены wave: пересобрать, прогнать аудит имён наборов заново, обновить таблицу покрытия в README
- [ ] Перед следующим повышением wave проверить, что `AssembliesToSearch`/список DLL в скрипте аудита не отстал от новой раскладки платформы (в 2026.2.2 не загрузились только 2 нативные `Hunspell*.dll` — это норма)
- [ ] Дождаться стабильного 2026.3: сверить свежие имена наборов и заново запустить аудит

---

## 📝 Документация

- [x] Сверить `README.md` и `README.en.md` с фактическим состоянием: версия, wave, число файлов/строк, таблица покрытия, требования к сборке (2026-09-24)
- [ ] Перенести два README на один источник правды по цифрам: сейчас статистика и таблица покрытия продублированы вручную и расходятся при каждой пересборке
- [ ] Описать ручной шаг публикации (nuget.org + Marketplace) отдельным разделом с командами — его проще всего забыть

---

## 🗑 Локальный мусор (не в git)

- [x] Рабочие файлы сверки 2026-09-24 удалены: `build/_gap_strings.txt`, `build/_audit_run_mine.log`,
      `build/_pre_restore_build_ps1.bak` (их содержание теперь или в `i18n-coverage-report.txt`,
      или в истории git). Пустой каталог `Ḁ/` в корне удалён — артефакт mojibake-пути:
      U+1E00 не кодируется в CP1251, поэтому git его не показывал.
- [ ] `build/PEER-HANDOFF-2026-09-24.md` — запись разделения работ между диалогами; держать до
      публикации 2026.2.2.1, потом удалить или перенести в описание релиза
