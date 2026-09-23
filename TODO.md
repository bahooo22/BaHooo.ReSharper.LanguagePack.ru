# TODO

Список задач по проекту. Ранее здесь лежал черновик-дамп диалога про глоссарий машинного перевода — он сохранён в истории git (коммит до `2026-09-24`).

---

## 🔥 Ближайший релиз: 2025.3.3.11

Собрать и опубликовать то, что уже готово локально.

- [x] Перевести 9 pending-правок в `raw-resx-done_ru-RU/` в `.resources`
- [x] Поднять версию до `2025.3.3.11` в обоих `.nuspec` и в двух version-bearing `.resx`
- [x] Проверить, что пакеты упакованы и внутри 236 ресурсов
- [ ] `git push` + создать тег (локальный коммит уже готов)
- [ ] Выложить `BaHooo.ReSharper.I18n.ru.2025.3.3.11.nupkg` на nuget.org
- [ ] Выложить тот же пакет в JetBrains Marketplace

CI (`pack-and-release.yml`) создаёт только GitHub Release с обоими `.nupkg` — на nuget.org и в Marketplace публикация ручная.

---

## 🧭 Закрыть пробелы покрытия (~230 строк)

По аудиту установленной платформы ReSharper (см. раздел «🧭 Покрытие ресурсов» в README) переведено 173 набора из 247 потенциально переводимых. Из 74 пробелов 55 фиктивные (37 пустых WinForms/WPF-контейнеров + 18 наборов SharePoint-данных на 9857 строк — их переводить нельзя). Реальных пропусков интерфейса — 19 наборов / 293 строки, из них к VS относятся ~10:

| Набор | Строк | Комментарий |
|---|---|---|
| `JetBrains.Application.Resources.VsResources` | 81 | диалоги и окна интеграции с VS |
| `JetBrains.UI.Resources.StringTable` | 56 | |
| `JetBrains.Application.Res.StringTable` | 56 | дубль предыдущего — переводить синхронно |
| `JetBrains.ReSharper.Psi.Src.Razor.CSharp.Resources.Texts` | 15 | |
| `JetBrains.Application.BuildScript.Compile.LicenseTexts` | 15 | тексты лицензий — проверить, нужен ли перевод юридически |
| `JetBrains.SignatureVerifier.Messages` | 5 | |
| `JetBrains.VsIntegration.Resources.SR` | 4 | |
| `JetBrains.ReSharper.Psi.CSharp.Src.CodeStyle.FileLayoutPatternResources` | 3 | |
| `JetBrains.ReSharper.Feature.Services.Src.Explanatory.CodeInspectionWikiResources` | 1 | |

- [ ] Достать эти наборы из DLL платформы, проверить реальное число строк
- [ ] Перевести и положить в `raw-resx-done_ru-RU/`
- [ ] Остальные 9 наборов из 19 (мелочь, вне VS-интерфейса) — решить по одному

---

## 🧹 Гигиена репозитория

- [ ] Удалить из-под версионирования: `resx-to-resourcesV1.back`, `build/resx-hashes.json.back.json`, `NugetFolder/BaHooo.ReSharper.I18n.ru/build.ps1.txt` — это ручные бэкапы, git хранит историю лучше
- [ ] Решить судьбу 6 `.resx`-заглушек (по 4 служебные записи, 5816 Б, перевода нет): `JetBrains.PsiFeatures.VisualStudio.SinceVs14`, `…SinceVs16RoslynAware`, `…Web.UIInteractive`, `JetBrains.Rider.Plugins.Verse`, `JetBrains.TeamCity.Presentation.Wpf`, `OperatorsResolveCacheGenerator`. Либо удалить, либо объяснить в README, почему они пустые
- [ ] Разобраться с 61 нашим `.resx`, которых нет в платформе VS (Rider / dotTrace / dotPeek / dotMemory) — они нужны для Rider-сценария или мёртвый груз?
- [ ] Добавить `.gitattributes` с `text working-tree-encoding=UTF-8` / `eol=crlf` для `*.ps1`, `*.psm1`, `*.resx`, `*.nuspec` — защищает от той самой ANSI-порчи, которая уже ломала `.nuspec`
- [ ] Исправить URL скачивания ResGen в `resx-to-resources.ps1`: GUID в ссылке выдуман, отдаёт 404. Сейчас баг латентный (срабатывает только при отсутствии ResGen), но при первой чистой машине сборка упадёт

---

## 📦 Совместимость с ReSharper 2026.x

- [ ] Поднять dependency wave с `[253.0.0]` на актуальный после выхода стабильного 2026.1 — локальная платформа сейчас EAP с `FileVersion 777.0.0.0`, ориентироваться на неё нельзя
- [ ] После смены wave: пересобрать, прогнать аудит имён наборов заново (JetBrains переименовывали сборки), обновить таблицу покрытия в README
- [ ] Проверить, что `AssembliesToSearch`/список DLL в скрипте выгрузки не отстал от новой раскладки платформы

---

## 📝 Документация

- [ ] Перенести `README.md` и `README.en.md` на один источник правды (сейчас рассинхрон по версиям и цифрам)
- [ ] Описать ручной шаг публикации (nuget.org + Marketplace) отдельным разделом — его проще всего забыть
- [ ] Обновить раздел «Статистика проекта» после закрытия пробелов покрытия
