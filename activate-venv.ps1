$VENVROOT = "F:\eXample\venvs"
$ARGOSACTIVATE = "$VENVROOT\argos\Scripts\Activate.ps1"
$ONMTACTIVATE  = "$VENVROOT\onmt\Scripts\Activate.ps1"

Write-Host "Выберите окружение для активации:"
Write-Host "1. Argos Translate"
Write-Host "2. OpenNMT-py"
$choice = Read-Host "Введите номер (1-2)"

switch ($choice) {
    "1" { & $ARGOSACTIVATE }
    "2" { & $ONMTACTIVATE }
    default { Write-Host "Неверный выбор." }
}
