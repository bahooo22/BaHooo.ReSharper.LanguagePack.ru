# 🇷🇺 BaHooo.ReSharper.I18n.ru — Русский языковой пакет для ReSharper

[GitHub](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru) · [Telegram](https://t.me/compohelp_vitebsk) · [Donate]()

![icon](https://raw.githubusercontent.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/main/NugetFolder/BaHooo.ReSharper.I18n.ru/icon.png)

Русский перевод интерфейсных строк JetBrains ReSharper.  
Автор: Ivan "BaHooo" Zelenkevich. Перевод основан на оригинальных строках ReSharper.

---

## 🛠️ Статус

| CI | Release | License |
|----|---------|---------|
| ![CI](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml?branch=main&label=ci) | ![Release](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru) | 📜 License: [CC BY-NC-SA 4.0](LICENSE) · [Additional Terms](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/LICENSE.additional.md) |

---

## 🚀 Быстрый старт

1. Установите пакет через NuGet:
   ```
   PM> Install-Package BaHooo.ReSharper.I18n.ru
   ```
   или скачайте `.nupkg` из [Releases](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases).
2. В Visual Studio: **Extensions → Manage Extensions → Install from Disk** → выберите `.nupkg`.  
   В ReSharper: **ReSharper → Manage Extensions → Install from Disk**.
3. Перезапустите Visual Studio.
4. В ReSharper → Options → Environment → General → Localization выберите «Русский».

---

## 🧭 Поддерживаемые версии

- **ReSharper:** основной пакет `2026.2.2.1` собран под ReSharper 2026.2.2 (wave `[262.0.0]`, Visual Studio 2026).  
  Для ReSharper 2026.1 (VS 2022) в [Releases](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases) выкладывается сборка `2026.1.0.1` (wave `[261.0.0]`) с тем же переводом.
- **Visual Studio:** 2019, 2022, 2026 (под конкретный wave — см. выше).
- Полное покрытие локализуемых ресурсов платформы 2026.x: **251 набор `.resources`**, 34 024 уникальные строковые записи, из них 33 327 переведены на кириллицу (остальные — имена продуктов и служебные токены, которые не переводятся ни в одном языке).

---

## 🖥️ Offline-продукты (dotPeek / dotTrace / dotMemory / dotCover)

Standalone-приложения JetBrains не читают каталог `Extensions\*\i18n` — культура и
сателлиты берутся из переменных окружения:

```
JET_BACKEND_CULTURE=ru-RU
JET_BACKEND_LOCALIZATION_FOLDERS=<base64(UTF8) путь к папке с *.ru-RU.resources>
```

В репозитории `build/i18n-offline-deploy.ps1` зеркалит собранные `.resources` в
`%LOCALAPPDATA%\JetBrains\i18n-ru` и пишет по `.bat`-запускателю на каждый продукт
(`ru-dotPeek261.bat` и т. п.). Работает и с файлами из этого пакета: распакуйте
`.nupkg` как zip и укажите в `JET_BACKEND_LOCALIZATION_FOLDERS` папку
`DotFiles\Extensions\BaHooo.ReSharper.I18n.ru\i18n`.

---

## 📦 Структура пакета

```
BaHooo.ReSharper.I18n.ru.nupkg
├─ DotFiles/
│  └─ Extensions/
│     └─ BaHooo.ReSharper.I18n.ru/
│        └─ i18n/
│           └─ *.resources
├─ icon.png
├─ README.md
├─ LICENSE
└─ BaHooo.ReSharper.I18n.ru.nuspec
```

Ключевые элементы:
- `.resources` — бинарные файлы локализации, собранные из `.resx` (251 набор).
- `.nuspec` — метаданные пакета.
- `icon.png` — иконка плагина.
- `LICENSE` — условия использования.

---

## 🛠️ Сборка и упаковка

Сборка выполняется из корня [репозитория](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru)
основным скриптом `resx-to-resources.ps1` (инкрементальная конвертация `.resx` → `.resources`
по хэшам, автоинкремент версии, упаковка NuGet + Marketplace). Полная документация
по параметрам и примерам — в [README репозитория](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru#-основной-скрипт-сборки).

Требуется: `resgen.exe` (входит в Windows SDK; скрипт находит его сам), `nuget.exe`
(при необходимости скачивается автоматически).

---

## ⚠️ Траблшутинг

- Плагин не появляется в списке локализаций:
  - Перезапустите Visual Studio.
  - Убедитесь, что `.resources` лежат в `DotFiles/Extensions/BaHooo.ReSharper.I18n.ru/i18n/`.
  - Проверьте, что версия пакета соответствует wave платформы (2026.2.x — для ReSharper 2026.2).
  - Проверьте логи ReSharper (**Help → Show Log**).

- Ошибка при установке `.nupkg`:
  - Распакуйте `.nupkg` как zip и проверьте структуру.
  - Проверьте корректность `.nuspec` (id, version).

---

## ✅ QA локализации — чеклист

- Контекст строки (меню, тултип, диалог).  
- Плейсхолдеры и порядок параметров.  
- Длина перевода и переносы (не ломают UI).  
- Падежи, склонения и множественное число.  
- Единая терминология (глоссарий).  
- Не переводить технические идентификаторы и пути.

---

## 🤝 Вклад

- Форкните репозиторий.  
- Отредактируйте `.resx` файлы.  
- Создайте Pull Request с описанием изменений.  

Дополнительно: CONTRIBUTING.md, CODE_OF_CONDUCT.md.

---

## 📜 Лицензия

- Исходные строки принадлежат JetBrains.  
- Перевод — авторская работа Ivan "BaHooo" Zelenkevich.  
- Лицензия: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).  
- Коммерческое использование требует отдельного соглашения.

---

## 📬 Контакты

- GitHub: [репозиторий](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru)  
- Issues: [открыть задачу](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues)  
- Telegram: [@compohelp_vitebsk](https://t.me/compohelp_vitebsk)  
- Donate: https://destream.net/live/bahooo22_06537/donate

---

# Contributing — перевод и ревью

Спасибо, что хотите помочь развитию **Russian Language Pack for ReSharper**! 🎉

Этот гайд описывает минимальные правила, чтобы ваш вклад легко принимался и быстро попадал в релиз.

---

## 📁 1. Fork → Branch

1. Сделайте **fork** репозитория.
2. Создайте ветку формата:

   ```
   translation/ru-update-<module>
   ```

   Примеры:

   * `translation/ru-update-daemon`
   * `translation/ru-update-refactorings`

---

## 📝 2. Где находятся файлы перевода

Переводимые файлы лежат здесь:

```
raw-resx-done_ru-RU/
```

Формат файлов:

* Основной формат для редактирования: **`.resx`** (именно их правим в PR)
* Итоговый формат для ReSharper: **`.resources`** — генерируется сборкой, в PR его класть не нужно

Если `.resx` нет — откройте Issue, и автор добавит исходники.

---

## 🔧 3. Работа с переводом

### Правила перевода

* Старайтесь придерживаться терминологии Visual Studio / Rider / .NET.
* Лаконично, без дословной кальки.
* Предпочтение деловой терминологии:

  * ✔ "Переход к объявлению"
  * ✔ "Быстрые действия"
  * ❌ "Сделать быстрое действие"

### Когда сложно перевести

Оставьте вариант в `<!-- комментарии -->` внутри `.resx` или создайте Issue.

---

## 🔁 4. Конвертация `.resx` → `.resources`

JetBrains использует **binary .resources**, а `.resx` — только для редактирования.

Конвертация выполняется командой:

```
resgen.exe File.ru-RU.resx File.ru-RU.resources
```

или одним запуском из корня репозитория:

```
.\resx-to-resources.ps1 -NoBuild
```

**Важно:** имя набора должно оставаться тем же!

Пример:

```
JetBrains.ReSharper.Daemon.Main.Resources.Strings.ru-RU.resx
↓
JetBrains.ReSharper.Daemon.Main.Resources.Strings.ru-RU.resources
```

---

## 🧪 5. Локальное тестирование

Поместите `.resources` файлы в директорию ReSharper Extensions:

```
%LocalAppData%\JetBrains\Installations\<ReSharperPlatform>\Extensions\BaHooo.ReSharper.I18n.ru\i18n\
```

Перезапустите Visual Studio.

Если русский язык виден в списке языков — всё собрано верно.

---

## 📤 6. Создание Pull Request

Перед отправкой PR убедитесь, что:

* `.resx` обновлены
* конвертация проходит без ошибок (`.\resx-to-resources.ps1 -NoBuild`)
* описание PR содержит:

  * какие модули переведены
  * какие строки были непереводимы или вызывают сомнение

Название PR должно быть формата:

```
[translation] Обновление модуля <module-name>
```

Пример:

```
[translation] Улучшение перевода инспекций C#
```

---

## 💬 7. Связь

Если нужны пояснения по структуре или форматам:

* GitHub Issues: [https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues)
* Telegram: [https://t.me/compohelp_vitebsk](https://t.me/compohelp_vitebsk)

---

Спасибо за вклад! ❤️  
Ваши исправления помогают сделать ReSharper удобнее и доступнее для всех русскоязычных пользователей.
