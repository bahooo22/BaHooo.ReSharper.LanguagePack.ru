# JetBrains.I18n.ru — Russian Language Pack for ReSharper

Репозиторий GitHub: https://github.com/bahooo22/BaHooo.ReSharper.LanguagePack.ru

![icon](icon.png)


Русский языковой пакет для JetBrains ReSharper.


> Автор: Ivan "BaHooo" Zelenkevich. Перевод основан на строках продукта JetBrains ReSharper.


## Что это делает


Этот пакет добавляет русскую локализацию интерфейса для ReSharper — строки меню, диалогов, тултипов и т.д., которые поставляются с продуктом ReSharper и его плагинами.


> **Важно:** пакет предоставляет локализацию как расширение для платформы JetBrains — он не изменяет установочные файлы IDE, а устанавливается как расширение.


## Быстрый старт — локальная установка


1. Скопируйте или скачайте собранный `.nupkg` (например `JetBrains.I18n.ru.2025.11.27.nupkg`).
2. Откройте Visual Studio → `Extensions (Расширения)` → `Manage Extensions` (или `ReSharper → Manage Extensions`).
3. Нажмите `Install from Disk` (Установить из файла) и выберите `.nupkg`.
4. Перезапустите Visual Studio (если потребуется).
5. Откройте `ReSharper → Options → Environment → General` и в разделе `Localization` выберите `Русский`.


Если по каким-то причинам пакет не появляется — убедитесь, что вы использовали `nuget pack` для упаковки и что структура пакета соответствует описанной в README.


## Разработка и сборка


Локально упаковка выполняется через PowerShell-скрипт `build.ps1`.


```powershell
# простая упаковка
.
# из корня репозитория
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 2025.11.27

Если вам нужно сначала сгенерировать .resources из .resx, используйте package.ps1 (требует resgen):

```powershell -ExecutionPolicy Bypass -File .\package.ps1 -Version 2025.11.27

## CI / GitHub Actions

Репозиторий включает GitHub Actions workflow .github/workflows/pack-and-release.yml. При создании релиза или ручном запуске workflow создаёт .nupkg и сохраняет его как артефакт.

Как правильно подготовить .resources

Извлеките оригинальные .resources файлы (если у вас .resources, используйте resgen для дизассемблирования в .resx и правьте их).

После перевода используйте resgen или Resource Compiler, чтобы получить обратно .resources.

Поместите скомпилированные .resources в папку:
DotFiles/Extensions/JetBrains.I18n.ru/i18n/

Запакуйте *.resources в .nupkg (скрипт build.ps1 делает это автоматически).

Совет: сохраняйте оригинальные *.resx в истории git, чтобы было удобно ревью переводов.

Публикация в JetBrains Marketplace (обзор)

Зарегистрируйтесь на JetBrains Marketplace: https://plugins.jetbrains.com/.

Создайте новый плагин и укажите метаданные (название, описание, иконка).

Загрузите *.nupkg в качестве релиза.

Опубликуйте.

Подробная инструкция по публикации есть в документации JetBrains. Обратите внимание на требования к метаданным и совместимости с версиями ReSharper.

Лицензия и права

Строки интерфейса принадлежат JetBrains и поставляются по лицензионным условиям JetBrains.

Перевод — работа автора (Ivan "BaHooo" Zelenkevich).

Перед распространением убедитесь, что ваша публикация не нарушает лицензию JetBrains (в случае сомнений — свяжитесь с JetBrains).

Как помочь с переводом

Форкните репозиторий, добавьте/отредактируйте *.resx файлы и создайте PR.

Для обсуждения используйте GitHub Issues или Telegram: https://t.me/compohelp_vitebsk.

