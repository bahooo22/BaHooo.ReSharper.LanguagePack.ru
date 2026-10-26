# 🇷🇺 BaHooo.ReSharper.I18n.ru — Русский языковой пакет для ReSharper

[GitHub](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru) · [Telegram](https://t.me/compohelp_vitebsk) · [Donate](https://www.donationalerts.com/r/bahooo)

![ReSharper Russian Language Pack Icon](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/NugetFolder/BaHooo.ReSharper.I18n.ru/icon.png)

Русский перевод интерфейсных строк ReSharper.  
Автор: Ivan "BaHooo" Zelenkevich. Перевод основан на оригинальных строках ReSharper.

---

## 🛠️ Статус

| CI | Release | License |
|----|---------|---------|
| ![CI](https://img.shields.io/github/actions/workflow/status/bahooo22/BaHooo.ReSharper.LanguagePack.ru/pack-and-release.yml?branch=main&label=ci) | ![Release](https://img.shields.io/github/v/release/bahooo22/BaHooo.ReSharper.LanguagePack.ru) | 📜 License: [CC BY-NC-SA 4.0](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/LICENSE) |

---

## 🚀 Быстрый старт

1. Установите пакет через **ReSharper → Extensions → Marketplace** или скачайте `.nupkg` из [Releases](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/releases).
2. При необходимости используйте **Install from Disk** в меню Extensions.
3. Перезапустите Visual Studio.
4. В ReSharper → Options → Environment → General → Localization выберите «Русский».

---

## 🧭 Поддерживаемые версии

- **ReSharper:** пакет `2026.2.2.3` собран под ReSharper 2026.1–2026.2 (wave-диапазон `[261.0.0,263.0.0)`) — один пакет для Visual Studio 2022 и 2026.  
  Отдельная сборка для ReSharper 2026.1 больше не требуется.
- **Visual Studio:** 2019, 2022, 2026 (под конкретный wave — см. выше).
- **Rider:** совместимость не проверялась.
- Покрытие: **251 набор `.resources`**, 34 024 уникальные строковые записи платформы ReSharper — локализуемые ресурсы закрыты полностью.

---

## 🖥️ Offline-продукты (dotPeek / dotTrace / dotMemory / dotCover)

Standalone-приложения JetBrains не читают каталог `Extensions\*\i18n` — культура и
сателлиты берутся из переменных окружения:

```
JET_BACKEND_CULTURE=ru-RU
JET_BACKEND_LOCALIZATION_FOLDERS=<base64(UTF8) путь к папке с *.ru-RU.resources>
```

Распакуйте `.nupkg` как zip и укажите в `JET_BACKEND_LOCALIZATION_FOLDERS` папку
`DotFiles\Extensions\BaHooo.ReSharper.I18n.ru\i18n` — либо используйте `.bat`-запускатели
из `build/i18n-offline-deploy.ps1` в [репозитории](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru).

---

## ✅ QA локализации

- Контекст строки (меню, тултип, диалог).  
- Плейсхолдеры и порядок параметров.  
- Длина перевода и переносы (не ломают UI).  
- Единая терминология (глоссарий).  
- Не переводить технические идентификаторы и пути.  

---

## 🤝 Вклад

Хотите помочь улучшить перевод?  
- Файлы перевода (`.resx`) лежат в `raw-resx-done_ru-RU/` [репозитория](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru); форкните его и предложите изменения.  
- Создайте Pull Request или Issue с описанием контекста.  
- Обсуждение и предложения — в [GitHub Issues](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues) или [Telegram](https://t.me/compohelp_vitebsk).  

---

## 📜 Лицензия

- Перевод — авторская работа Ivan "BaHooo" Zelenkevich.  
- Лицензия: [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/).  
- Коммерческое использование требует отдельного соглашения.  

---

## 📬 Контакты

- GitHub: [репозиторий](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru)  
- Issues: [открыть задачу](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/issues)  
- Telegram: [@compohelp_vitebsk](https://t.me/compohelp_vitebsk)  
- Donate: https://www.donationalerts.com/r/bahooo  
- Крипто-кошельки (ETH / TON / BTC): [.github/wallets.md](https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru/blob/main/.github/wallets.md)
