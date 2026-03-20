# 🇷🇺 BaHooo.ReSharper.I18n.ru — Русский языковой пакет для ReSharper

[GitHub](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru) · [Telegram](https://t.me/compohelp_vitebsk) · [Donate]()

![icon](https://raw.githubusercontent.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/main/NugetFolder/BaHooo.ReSharper.I18n.ru/icon.png)

Русский перевод интерфейсных строк JetBrains ReSharper.  
Автор: Ivan "BaHooo" Zelenkevich. Перевод основан на оригинальных строках ReSharper.

---

## 🛠️ Статус

| CI | Release | License |
|----|---------|---------|
| ![CI](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml?branch=main&label=ci) | ![Release](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru) | 📜 License: [CC BY-NC-SA 4.0](LICENSE) · [Additional Terms](LICENSE.additional.md) |

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

- **ReSharper:** проверено на 2025.3 и совместимых версиях.  
- **Visual Studio:** 2019, 2022, 2026.  
- **.NET SDK:** требуется для локальной сборки `.resources`.

---

## 📦 Структура пакета

```
BaHooo.ReSharper.I18n.ru.nupkg
├─ DotFiles/
│  └─ Extensions/
│     └─ BaHooo.ReSharper.I18n.ru/
│        └─ i18n/
│           ├─ *.resources
├─ icon.png
├─ LICENSE
└─ BaHooo.ReSharper.I18n.ru.nuspec
```

Ключевые элементы:
- `.resources` — бинарные файлы локализации, собранные из `.resx`.
- `.nuspec` — метаданные пакета.
- `icon.png` — иконка плагина.
- `LICENSE` — условия использования.

---

## 🛠️ Сборка и упаковка

Основной скрипт: `resx-to-resources.ps1`.

Примеры:
```
Смотри: https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/edit/main/README.md#-%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D0%BD%D0%BE%D0%B9-%D1%81%D0%BA%D1%80%D0%B8%D0%BF%D1%82-%D1%81%D0%B1%D0%BE%D1%80%D0%BA%D0%B8
```

Требуется: `resgen.exe` (входит в .NET SDK / Visual Studio).

---

## ⚠️ Траблшутинг

- Плагин не появляется в списке локализаций:
  - Перезапустите Visual Studio.
  - Убедитесь, что `.resources` лежат в `DotFiles/Extensions/BaHooo.ReSharper.I18n.ru/i18n/`.
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
- Donate: []()

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
DotFiles/Extensions/BaHooo.ReSharper.I18n.ru/i18n/
```

Формат файлов:

* Основной формат для редактирования: **`.resx`**
* Итоговый формат для ReSharper: **`.resources`**

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
resgen.exe File.resx File.resources
```

или PowerShell:

```
resgen File.resx File.resources
```

**Важно:** имя файла должно оставаться тем же!

Пример:

```
JetBrains.ReSharper.Daemon.Main.Resources.Strings.resx
↓
JetBrains.ReSharper.Daemon.Main.Resources.Strings.ru.resources
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
* `.resources` сгенерированы и находятся в нужных папках
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
