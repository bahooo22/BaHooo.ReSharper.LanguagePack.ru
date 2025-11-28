# === Пути к Python и окружениям ===
$PY311   = "C:\Users\eXample\AppData\Local\Programs\Python\Python311\python.exe"
$VENVROOT = "F:\eXample\venvs"

$ARGOSVENV = "$VENVROOT\argos"
$ONMTVENV  = "$VENVROOT\onmt"

$ARGOSACTIVATE = "$ARGOSVENV\Scripts\Activate.ps1"
$ONMTACTIVATE  = "$ONMTVENV\Scripts\Activate.ps1"

# === Меню выбора ===
Write-Host "Выберите действие:"
Write-Host "1. Создать Argos Translate"
Write-Host "2. Создать OpenNMT-py"
Write-Host "3. Создать Argos и OpenNMT"
Write-Host "4. Удалить Argos Translate"
Write-Host "5. Удалить OpenNMT-py"
Write-Host "6. Удалить Argos и OpenNMT"
Write-Host "7. Проверить существующие окружения"
$choice = Read-Host "Введите номер (1-7)"

switch ($choice) {
    "1" {
        Write-Host ">>> Установка Argos Translate..."
        if (Test-Path $ARGOSVENV) {
            Write-Host "Старое окружение Argos найдено, удаляю..."
            Remove-Item -Recurse -Force $ARGOSVENV
        }
        & $PY311 -m venv $ARGOSVENV
        & $ARGOSACTIVATE
        python -m pip install --upgrade pip setuptools wheel
        python -m pip install argostranslate tqdm
        deactivate
        Write-Host ">>> Argos Translate успешно установлен."
        Write-Host "Для активации используйте: .\\activate-venv.ps1 и выберите Argos."
    }
    "2" {
        Write-Host ">>> Установка OpenNMT-py..."
        if (Test-Path $ONMTVENV) {
            Write-Host "Старое окружение OpenNMT найдено, удаляю..."
            Remove-Item -Recurse -Force $ONMTVENV
        }
        & $PY311 -m venv $ONMTVENV
        & $ONMTACTIVATE
        python -m pip install --upgrade pip setuptools wheel
		python -m pip install "numpy==1.26.4"
		python -m pip install sentencepiece
        python -m pip install OpenNMT-py
        deactivate
        Write-Host ">>> OpenNMT-py успешно установлен."
        Write-Host "Для активации используйте: .\\activate-venv.ps1 и выберите OpenNMT."
    }
    "3" {
        Write-Host ">>> Установка Argos Translate..."
        if (Test-Path $ARGOSVENV) {
            Write-Host "Старое окружение Argos найдено, удаляю..."
            Remove-Item -Recurse -Force $ARGOSVENV
        }
        & $PY311 -m venv $ARGOSVENV
        & $ARGOSACTIVATE
        python -m pip install --upgrade pip setuptools wheel
        python -m pip install argostranslate tqdm
        deactivate
        Write-Host ">>> Argos Translate успешно установлен."

        Write-Host ">>> Установка OpenNMT-py..."
        if (Test-Path $ONMTVENV) {
            Write-Host "Старое окружение OpenNMT найдено, удаляю..."
            Remove-Item -Recurse -Force $ONMTVENV
        }
        & $PY311 -m venv $ONMTVENV
        & $ONMTACTIVATE
        python -m pip install --upgrade pip setuptools wheel
		python -m pip install "numpy==1.26.4"
		python -m pip install sentencepiece
        python -m pip install OpenNMT-py
        deactivate
        Write-Host ">>> OpenNMT-py успешно установлен."
        Write-Host "Для активации используйте: .\\activate-venv.ps1 и выберите нужное окружение."
    }
    "4" {
        Write-Host ">>> Удаление Argos Translate..."
        if (Test-Path $ARGOSVENV) {
            Remove-Item -Recurse -Force $ARGOSVENV
            Write-Host "Argos Translate удалён."
        } else {
            Write-Host "Окружение Argos не найдено."
        }
    }
    "5" {
        Write-Host ">>> Удаление OpenNMT-py..."
        if (Test-Path $ONMTVENV) {
            Remove-Item -Recurse -Force $ONMTVENV
            Write-Host "OpenNMT-py удалён."
        } else {
            Write-Host "Окружение OpenNMT не найдено."
        }
    }
    "6" {
        Write-Host ">>> Удаление Argos и OpenNMT..."
        if (Test-Path $ARGOSVENV) { Remove-Item -Recurse -Force $ARGOSVENV; Write-Host "Argos Translate удалён." }
        if (Test-Path $ONMTVENV) { Remove-Item -Recurse -Force $ONMTVENV; Write-Host "OpenNMT-py удалён." }
    }
    "7" {
        Write-Host ">>> Проверка окружений..."
        if (Test-Path $ARGOSVENV) {
            Write-Host "Argos Translate: установлено ($ARGOSVENV)"
        } else {
            Write-Host "Argos Translate: отсутствует"
        }
        if (Test-Path $ONMTVENV) {
            Write-Host "OpenNMT-py: установлено ($ONMTVENV)"
        } else {
            Write-Host "OpenNMT-py: отсутствует"
        }
    }
    default {
        Write-Host "Неверный выбор. Запустите скрипт снова и введите число от 1 до 7."
    }
}
