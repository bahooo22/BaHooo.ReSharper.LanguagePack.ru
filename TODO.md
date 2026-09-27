# TODO

Список задач по проекту. Ранее здесь лежал черновик-дамп диалога про глоссарий машинного перевода — он сохранён в истории git (коммит до `2026-09-24`).

---

## 🔥 Ближайший релиз: 2026.2.2.2

Всё готово локально и проверено измерением, а не со слов. Осталась только публикация.

- [x] Перевести 507 новых строк ReSharper 2026.2.2 (57 таблиц) — `9789367`
- [x] Перезалить переводы из чистого JSON, убрать mojibake — `2ea7538`
- [x] Поднять Wave до `[262.0.0]` (ReSharper 2026.2) — `92fa740`
- [x] Синхронизировать версию `2026.2.2.1` в обоих `.nuspec` и в version-bearing `.resx` — `c7ba5dc`, `725a5a2`
- [x] Bump `2026.2.2.1` → `2026.2.2.2` (`f29b9b4`, 27.09 22:03): оба `.nuspec`, About в двух version-bearing `.resx`,
      hash-кэши; wave-диапазон `[261.0.0,263.0.0)` не тронут. Верификация распаковкой: оба `*.2026.2.2.2.nupkg` —
      `ver=2026.2.2.2`, 251 `.resources`, побайтово равны `build/resources` (mismatch 0), About везде `v. 2026.2.2.2`,
      README внутри = боковой по SHA-256
- [x] Пересобрать `.resources` и упаковать: на 26.09 в `raw-resx-done_ru-RU/` 251 файл, в `build/resources/` 251
      (34 026 элементов `<data>`, 34 024 уникальных ключа, 33 327 значений с кириллицей)
- [x] Дерево-сравнение всей библиотеки JetBrains (1458 `JetBrains*.dll`, `build/i18n-compare-tree.ps1`): закрыт
      паритет `Feature.Services.Cpp` (не хватало 52 ключа из 3359) + 2 таблицы 261-эры
      (`VsIntegration.Resources.SR`, `dotTraceInstant.Model.Interface`) — `bc99ab5`
- [x] Для живой 2026.1 локально собран устанавливаемый пакет
      `MarketplaceFolder/artifacts/BaHooo.ReSharper.I18n.ru.2026.1.0.1.nupkg` (251 `.resources`, wave `[261.0.0]`,
      пересобран вручную 27.09 08:11: nuspec = `2026.1.0.1`/`[261.0.0]`, staging
      `DotFiles\Extensions\BaHooo.ReSharper.I18n.ru\i18n` наполняется копией `build/resources`, затем прямой
      `nuget.exe pack` — путь `-BuildOnly -SkipVersionUpdate` не годится, потому что `-svu` отменяет только
      инкремент, а кросс-синхронизация версий между папками остаётся; без staging пакет собирается пустым (251→0).
      С 27.09 (`cb28fcb`) mainline-wave — диапазон `[261.0.0,263.0.0)`, поэтому этот пакет больше не обязателен,
      но не удалён; в git bump под 261 не поднимался
- [ ] **ОПАСНОСТЬ, проверено распаковкой:** локальные `*/artifacts/*.2026.2.2.1.nupkg` (пересобраны 27.09 22:00/22:01
      прогоном, где bump молча не применился)
      содержат уже 251 ресурс (+3 набора и 62 новые строки сверх опубликованного `2026.2.2.1` на 248). Под этим номером
      заливать нельзя никогда; цель публикации после bump'а `f29b9b4` — `2026.2.2.2` (этот номер не публиковался).
      Не перепутать файл: в `E:\Temp\quarantine-2026.2.2.2\{nuget,marketplace}` лежат `.2026.2.2.2.nupkg` той же
      серии 26.09 20:59 (1 986 844 / 1 984 466 байт) — НЕ публиковать, настоящие артефакты — в `*/artifacts/`
      (1 986 850 / 1 984 473 байт, 27.09 22:03)
- [x] Задеплоить в тестовый `i18n`-каталог: на 25.09 было 248 из 248. **Регресс 26.09:** после возврата пользователя
      на 2026.1 в `i18n` лежит 236 файлов (mtime 25.09 22:11), 15 наборов не задеплоены (14 прежних + `DotPeekCommon`)
      — среди них три MSTest-
      копии, `DotTrace.Ide.Core.Interface`, обе таблицы dotTraceInstant, `VsIntegration.Resources.SR`,
      `Application.Res.StringTable`, `Application.Resources.VsResources`, `DPA.Ide.VS.Resources.Strings`,
      `Profiler.Windows.Resources.Strings`, `SignatureVerifier.Messages`, `Standalone.TabWell`,
      `UI.Resources.StringTable`. **Закрыто 27.09 замером: 251 из 251 и в `i18n` установки, и в оффлайн-папке,
      лишнего нет; побайтовая сверка после bump'а — расхождений 0**
- [x] **Перезалить 2 файла из `build/resources`** — закрыто самим bump'ом, перезаливка не нужна (замер 27.09 22:05,
      VS закрыта): `JetBrains.UI.Resources.Strings.ru-RU.resources` и `JetBrains.UI.Avalonia.Resources.Strings.ru-RU.resources`
      лежали в `Extensions\BaHooo.ReSharper.I18n.ru\i18n` и в `%LOCALAPPDATA%\JetBrains\i18n-ru` с байтами bump-прогона
      26.09 21:52 (`623ABAC39C`/`BE910F8210`, About `v. 2026.2.2.2`) и расходились с `build/resources` на версии
      `2026.2.2.1`. После `-fa`/bump'а на `2026.2.2.2` в `build/resources` ровно те же байты → побайтовая сверка:
      251 из 251, расхождений 0, лишних и отсутствующих 0 в ОБОИХ каналах
- [ ] После любого `git`-отката `.resx`: пересобирать только `-fa -svu`. `build/resources` вне git
      (`.gitignore:467 *.resources`), поэтому откат его не трогает, а `build/resx-hashes.json` после отката совпадает
      с содержимым `.resx` → инкрементный прогон и `-BuildOnly` молча упаковывают устаревшие `.resources`
      (замер 27.09: пакеты 21:24 несли `v. 2026.2.2.2` при верном nuspec). Сверку пакетов делать не только по
      количеству/wave, но и по байтам против `build/resources` и по строке About
- [ ] Правка пайплайна (предложение владелице `resx-to-resources.ps1`): применять явный `-Version X` независимо от
      `HasChanges` — сейчас `Update-VersionIfChangesDetected` выходит на `resx-to-resources.ps1:1675` при отсутствии
      изменений, ещё до ветки `$Script:Version` (`:1691`),
      поэтому при свежем hash-кэше пакеты собираются под СТАРЫМ номером. Замер 27.09: первый bump-прогон (22:00/22:01)
      молча пересобрал `*/artifacts/*.2026.2.2.1.nupkg` — внутренне консистентные (About тоже `v. 2026.2.2.1`,
      `0E2BA08969`/`080874B6F0`), то есть отказ не виден ни по коду возврата, ни по содержимому: не поднимается просто
      ничего. Явная версия требует `-sv` (Этап 0, `Sync-Versions -Force:$true` на `:1651` — применяется всегда) либо
      `-fa` (принудительный `HasChanges=$true` на `:1725`); `-aa` к этому не относится — это согласие на загрузку
      инструментов из сети. Рабочая комбинация: `-aa -sv -Version 'X'` (повторный прогон
      22:03 дал консистентные `*.2026.2.2.2.nupkg`). Признак проверки после любого bump'а: `<version>` в обоих nuspec,
      About внутри обоих version-bearing ресурсов и mtime артефактов. Правило процесса не меняется: bump — только по явному
      «повышай» от пользователя, публикация новых строк — только следующим bump-циклом
- [x] Offline-приложения (dotPeek/dotTrace/dotMemory/dotCover standalone): культура только из переменной
      окружения `JET_BACKEND_CULTURE`, сателлиты ищутся ПЛОСКО (`<Set>.<culture>.resources`) в папках из
      `JET_BACKEND_LOCALIZATION_FOLDERS` (base64(UTF8) путь, разделитель `;`); `Extensions\*\i18n` — только канал VS.
      `build/i18n-offline-deploy.ps1` кладёт 251 плоский ресурс в `%LOCALAPPDATA%\JetBrains\i18n-ru` и пишет
      `launchers\ru-{dotPeek,dotTrace,dotMemory,dotCover}261.bat` — проверено живьём на dotPeek 261 (`da3b8af`)
- [ ] `git push origin main` + тег `2026.2.2.2`
- [ ] После возврата 2026.2.x переснять `build/i18n-semantic-scan.ps1`, `build/i18n-audit.ps1` и
      `build/dll-coverage-matrix.ps1` против живой 262: текущие цифры покрытия (620 DLL / 344 neutral /
      187 покрыто / 157 без покрытия / 64 устаревших) сняты против 261
- [ ] Выложить `NugetFolder/artifacts/BaHooo.ReSharper.I18n.ru.2026.2.2.2.nupkg` на nuget.org
- [ ] Выложить `MarketplaceFolder/artifacts/BaHooo.ReSharper.I18n.ru.2026.2.2.2.nupkg` в JetBrains Marketplace
      (публикация — решение пользователя; `2026.2.2.2` никогда не публиковался)

CI (`pack-and-release.yml`) создаёт только GitHub Release с обоими `.nupkg` — на nuget.org и в Marketplace публикация ручная.

---

## 🧭 Пробелы покрытия перевода — ЗАКРЫТО 24.09.2026 (было: 12 наборов / 60 строк, 9 фраз)

Аудит против установленной платформы 2026.2.2 (`build/i18n-audit.ps1`, отчёт в `build/i18n-coverage-report.txt`): 624 DLL → 337 нейтральных `.resources`, 248 в пакете, **185 покрыто**. Из 152 «отсутствующих» подавляющее большинство — сторонние библиотеки (Roslyn, NuGet, DevExpress, Actipro, yWorks, MSTest-platform, Owin), которые наш пакет переводить не может и не должен.

Дефицит по ресурсам JetBrains раскладывался на 63 набора так (сейчас 58 — пять закрыты):

- 13 наборов — файлы данных SharePoint (`…Asp.Resources.Sharepoint.ResourceFiles.*`, 2 892 строки): это синхронизированные с ASPX-разметкой словари, перевод бессмысленен;
- 38 наборов — пустые контейнеры WinForms/WPF (0 строковых записей, только `.resources`-обёртки форм);
- **12 наборов / 60 строк — настоящие таблицы с текстами; переводимая их часть закрыта 24.09.2026 (`9694bb2`, `9fdcc5f`).**

Таблица дефицита теперь печатается самим аудитом (`build/i18n-audit.ps1`, секция «ТАБЛИЦЫ СО
СТРОКАМИ» в отчёте), а колонка «Что внутри» ниже — не догадка, а результат чтения значений каждой
строки из neutral-ресурсов DLL платформы через `ResourceReader`:

| Набор | Строк | Что внутри (проверено чтением значений) |
|---|---|---|
| `JetBrains.ReSharper.Psi.Src.Razor.CSharp.Resources.Texts` | 15 | шаблоны генерируемого C#-кода: `);`, `{0}({1}`, `{1} partial class {0}`, `[{1}] public override void Execute() {{`, шапка `// <auto-generated>` |
| `JetBrains.Application.BuildScript.Compile.LicenseTexts` | 15 | полные тексты EULA Microsoft / yWorks / DevExpress / Windows SDK плюс служебные комментарии «License text was taken from <URL> on 12.09.2024 by …» |
| `JetBrains.ReSharper.UnitTestProvider.MSTest12/14/15.…Provider.Resources.Strings` | 4 × 3 | настоящие фразы раннера («Not an MSTest project», «VS2017 version is outdated», «Unsupported MSTest flavor: {0}»); upstream дублирует один и тот же набор в трёх сборках провайдера |
| `JetBrains.DotTrace.UI.resources.agreements.DotTraceLicenseSupportResources` | 5 | RTF-документы соглашений (`{\rtf1\adeflang1025\ansi…`) — не текст интерфейса |
| `JetBrains.dotTraceInstant.ViewModel.Interface.resources.Resources` | 4 | настоящие подписи кнопок: `Delete`, `Stop`, `Delete session?`, `Delete` (две записи буквально совпадают → 3 уникальных) |
| `JetBrains.ReSharper.Psi.CSharp.Src.CodeStyle.FileLayoutPatternResources` | 3 | XML `<Patterns xmlns="urn:schemas-jetbrains-com:member-reordering-patterns">` и XSLT-трансформация миграции |
| `JetBrains.DotTrace.Ide.Core.Interface.resources.Resources` | 2 | настоящие фразы диалога профайлера |
| `JetBrains.ReSharper.Plugins.Unity.CSharp.Psi.CodeStyle.AdditionalFileLayoutResources` | 2 | тот же XML-паттерн перезаказа участников |
| `JetBrains.ReSharper.Feature.Services.Src.Explanatory.CodeInspectionWikiResources` | 1 | XML-индекс `<Item Id="…"/>` идентификаторов инспекций |
| `Resources` (без неймспейса) | 1 | ключ `666`, значение — AHE-токен `AHR2RRIDC0RRA9ZMJM…`, не текст |

Итог измерения: 60 строк дают **51 уникальное значение**, и 42 из них переводить нельзя по природе
содержимого (юридические тексты, RTF, шаблоны генерируемого кода, XML/XSLT, токен). Переводимых
остается **18 строк = 9 уникальных фраз**, причём 12 из 18 — это три копии четырёх фраз MSTest, а
их перевод уже написан в `JetBrains.ReSharper.UnitTestProvider.MSTest11.Resources.Strings.ru-RU.resx`.
**Закрытие 24.09.2026:** 12 строк MSTest заведены под литеральными именами ресурсов (`9694bb2`);
6 строк dotTrace переведены (`9fdcc5f`: «Удалить», «Удалить сеанс?», «Остановить» и 2 строки диалога
профайлера). Паритет ключей с нейтральными ресурсами проверен чтением из DLL (4==4, 2==2). Аудит:
248 resx, 185 из 337 покрыто, **переводимый остаток — 0**. Оставшиеся 42 строки переводить нельзя по
содержанию — см. таблицу выше.

- [x] Разобрать 60 строк дефицита по содержанию, а не по имени набора: сделано чтением значений из
      DLL; 42 строки закрыты как «не текст интерфейса», остаток — 9 уникальных фраз
- [x] Реальная работа по пакету: **1 набор × 4 строки** — закрыто `9694bb2`: resx заведены под литеральными именами `…MSTest12/14/15.......v11.Provider.Resources.Strings`
      под литеральными именами ресурсов (семь точек подряд — это настоящее имя из `GetManifestResourceNames`,
      проверено), перенеся готовый перевод из MSTest11. Механизм сателлитов ищет ресурс по полному
      имени, поэтому одного MSTest11 на три сборки не хватает
- [x] 6 строк (3 уникальных) `dotTraceInstant.ViewModel.Interface` и 2 строки `DotTrace.Ide.Core.Interface` —
      решено переводить попутно (dotTrace ставится отдельно, в ReSharper-в-VS эти фразы не видны, но исходник
      у нас общий): закрыто `9fdcc5f` — «Удалить», «Остановить», «Удалить сеанс?», паритет 4==4 и 2==2
- [ ] По `LicenseTexts` (15) решить, нужен ли перевод юридически; самостоятельного решения тут нет

Прежняя оценка «~230 строк / 19 наборов» была ложной: `JetBrains.Application.Resources.VsResources`
и оба `StringTable`, которые там значились, уже давно покрыты пакетом, а SharePoint-словари были
посчитаны как работа. Вторая ложная оценка — «реальная работа 31–34 строки»: Razor `Texts`,
`FileLayoutPatternResources`, `AdditionalFileLayoutResources` и `CodeInspectionWikiResources`
(31 из 34) оказались шаблонами кода и XML, а не текстом интерфейса.

---

## 🔍 Разобрать 214 срабатываний «ПЛЕЙСХОЛДЕРЫ» в отчёте проверки

`build/i18n-translation-report.txt` текущий `build/i18n-translation-report.txt` даёт 214 строки с расхождением
плейсхолдеров; до фикса `d892aaf` было 215. Разложение по признаку риска (посчитано по колонкам
`en[…] != ru[…]`):

- **209** — ru потерял хотя бы один индекс en; **4** — тот же набор индексов, только другой порядок
  или повторы (в русском это нормально); **1** — ru ссылается на индекс, которого в en нет
  (`JetBrains.ReSharper.Refactorings.Xaml…Resource0UsageInlineWillProduceConflicts_Text`).
  Последний формально похож на риск `FormatException`, но проверено на .NET Framework: сам
  en-value `Inlining resource {0, usage} will produce conflicts` бросает `FormatException` даже
  с аргументом (`{0, usage}` — невалидный format item), то есть upstream этот текст не форматирует
  вообще. Наш `{0}` безопаснее оригинала — не трогаем.

Из 209 — **204 в одном файле** `JetBrains.ReSharper.Daemon.CSharp.Resources.Strings` (системный
узор: вместо `{0}`/`{1}` в русском стоит описательная формулировка, например
`CanSimplifyDictionaryLookupWithTryAddMessage`: en `…with '{0}'` → ru `…с помощью 'TryAdd'`, где
аргумент всегда один и тот же). Оставшиеся 5 разобраны по neutral-значениям, вычитанным из DLL
платформы через `ResourceReader`:

| таблица | ключ | en | ru | индекс |
|---|---|---|---|---|
| `DPA.Core.Resources.Strings` | `Tooltip_SqlConnectionCountIssue_Template` | `{0} DB {1}, {2}` | `{0} подключений к БД, {2}` | `{1}` = «connections» впитан в русскую форму — норма |
| `DPA.Core.Resources.Strings` | `Tooltip_SqlCommandCountIssue_Template` | `{0} DB {1} executed, {2}` | `Выполнено {0} команд БД, {2}` | `{1}` = «commands» — то же |
| `JetBrains.UI.Resources.CommonStrings` | `__Change_WillBeLostUnlessApplied_Text` | `{0} {1} change{2} will be lost unless applied` | `Изменения {0} {1} будут потеряны, если не применить` | `{2}` = английская флексия `s` — в русском не нужна |
| `…Feature.Services.CSharp` | `CSharp_EditorConfigOverride_Text` | `{0} for {1} overrides some naming rules on this page` | `Некоторые правила именования на этой странице переопределяются {0} для решения` | `{1}` потерян, а «решения» захардкожено — требует runtime |
| `…ExternalSources.CSharp` | `PdbHasNotBeenGeneratedBecauseAssembly_WithPdbName_AndSignature___Text` | `PDB has not been generated because assembly {0} with PDB name {1} and signature {2} {3}` | `PDB не был создан, так как сборка {0} имеет имя PDB {1} и сигнатуру {2}` | `{3}` потерян — требует runtime |

- [x] Отсеять крэш от косметики: из всей выборки единственная строка, где перевод ломал
      `string.Format`, — `Flip_Operands__Text` (`{0'` без закрывающей скобки); закрыто `d892aaf`.
      Остальные расхождения формат не роняют.
- [ ] Пройти 204 строки `Daemon.CSharp` глазами и поделить на «аргумент всегда константа → править
      не надо» и «реально теряем значение → вернуть `{n}` в перевод».
- [ ] Решить две спорные строки из таблицы выше (`CSharp_EditorConfigOverride_Text`,
      `PdbHasNotBeenGenerated…`): нужно фактическое значение `{1}` / `{3}` из рантайма, вслепую
      менять смысл нельзя.
- [ ] После правок переснять отчёт: `build/i18n-verify-translations.ps1`

Правило `ru == en` (362 записи, из них 346 содержат строчные латинские последовательности от трёх
букв и потому помечены как подозрительные) — НЕ пропуск: имена продуктов,
универсальные кнопки и `*SettingDescription`, у которых сам upstream хранит в value сырой токен
(проверено по `JetBrains.Platform.UIInteractive.Shell.dll`: `DefaultReporterChangedSettingDescription`
= `UpgradePerformed`). Подробно — раздел «🚫 Что сознательно НЕ переводится» в `README.md`.

---

## 🧹 Гигиена репозитория

- [ ] Удалить из-под версионирования: `resx-to-resourcesV1.back`, `build/resx-hashes.json.back.json`, `NugetFolder/BaHooo.ReSharper.I18n.ru/build.ps1.txt` — это ручные бэкапы, git хранит историю лучше
- [ ] Решить судьбу 6 `.resx`-заглушек: в них ровно **0** элементов `<data>` и 5816 байт — это чистый шаблон resx без единой строки перевода (`JetBrains.PsiFeatures.VisualStudio.SinceVs14`, `…SinceVs16RoslynAware`, `…Web.UIInteractive`, `JetBrains.Rider.Plugins.Verse`, `JetBrains.TeamCity.Presentation.Wpf`, `OperatorsResolveCacheGenerator`). Прежняя формулировка «по 4 служебные строки» — артефакт подсчёта: наивный regex ловил 4 примера из XSD-шапки файла. Либо удалить, либо объяснить в README, почему они пустые. Рядом стоял 7-й файл `JetBrains.Common.SystemModulesOptionsManager.Resources.SystemModulesConstants` — 9 записей без кириллицы. РЕШЕНО 25.09.2026: это не «латинические константы», а видимая страница настроек профайлера «System Modules» (кнопки, заголовок диалога, тексты ошибок, абзац-пояснение) — переведена целиком (проверено чтением neutral-значений из DLL установки `_000`)
- [ ] Разобраться с 64 `.resx`, которых нет в DLL живой установки 2026.1 (список в `build/i18n-coverage-report.txt`, секция «В ПАКЕТЕ, НО НЕ НАЙДЕНО В DLL»): Rider / dotPeek / dotTrace / Cpp / FSharp / TeamCity / SourceView — они нужны для Rider-сценария или мёртвый груз?
- [x] Добавить `.gitattributes`: `* text=auto eol=lf` + принудительный CRLF для `*.resx`/`*.nuspec`/`*.ps1`/`*.cmd`, binary для dll/exe/nupkg/resources. `working-tree-encoding=UTF-8` сознательно НЕ используем: у 7 resx уже есть BOM, git добавил бы второй
- [ ] Рабочую копию привести к новым правилам EOL одним `git add --renormalize .` + повторным
      checkout: сейчас `git ls-files --eol` показывает 285 индексовых blob'ов в LF (то есть новые
      правила ничего в истории не меняют), но в рабочей копии 13 текстовых файлов лежат с LF и
      6 со смешанными окончаниями вместо предписанного CRLF
- [x] Исправить скачивание ResGen в `resx-to-resources.ps1`: GUID в ссылке был выдуман (404).
      Теперь путь поиска `PATH → Windows SDK (включая обход всего дерева по маске ResGen.exe) →
      .\Tools\ResGen`, скачивания нет: при отсутствии выдаётся инструкция из Visual Studio
      Installer и сборка продолжается без генерации `.resources`
- [x] Требование к интерпретатору зафиксировано в обоих README: параллельный прогон (`-up`) делать
      под `pwsh 7`, потому что под 5.1 `Ensure-PowerShell7Available` скачивает portable PowerShell 7
      (101 МБ для 7.6.6) в `Tools\PWSH7\` и перезапускает скрипт.
- [ ] Косметический коммит «убрать астральные emoji из `Write-Host`» сознательно НЕ сделан, и делать
      не нужно: к удалённому каталогу `Ḁ/` он отношения не имеет. Замеры байтов: U+1E00 в UTF-8 —
      это `E1 B8 80` (BMP, ведущий байт `E1`), астральный эмодзи — `F0 9F 9A 80` (ведущий `F0`) или,
      при побайтовом кодировании суррогатов, `ED A0 BD` (ведущий `ED`). Продолжение многобайтной
      последовательности не может быть равно `E1` (диапазон `80-BF`), значит ни одна замена эмодзи на
      ASCII не способна убрать интересующую байтовую тройку. Единственный доказанный класс порчи в
      этом пайплайне — отсутствие UTF-8 BOM в `.ps1` под 5.1; он закрыт заранее.

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
