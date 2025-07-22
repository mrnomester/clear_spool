# Функция для проверки прав администратора
function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Проверяем, запущен ли скрипт с правами администратора
if (-not (Test-IsAdmin)) {
    Write-Host "Скрипт не запущен с правами администратора. Перезапускаем с повышенными правами..."
    
    # Получаем полный путь к текущему скрипту
    $scriptPath = $MyInvocation.MyCommand.Definition
    
    # Запускаем скрипт с повышенными правами
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $args" -Verb RunAs
    exit
}

# Основной код скрипта
# Подтверждение операции
if (-not $Force) {
    $confirmation = Read-Host "Вы уверены, что хотите очистить очередь печати? (y/n)"
    if ($confirmation -ne 'y') {
        Write-Host "Отмена операции." -ForegroundColor Yellow
        exit
    }
}

try {
    Write-Host "Останавливаем службу печати..." -ForegroundColor Cyan
    Stop-Service -Name Spooler -Force -ErrorAction Stop
    Write-Host "Служба успешно остановлена" -ForegroundColor Green

    # Путь к очереди печати
    $printQueuePath = Join-Path $env:SystemRoot "System32\spool\PRINTERS"

    Write-Host "Очищаем очередь печати..." -ForegroundColor Cyan
    $files = Get-ChildItem -Path $printQueuePath -File -ErrorAction Stop
    if ($files.Count -gt 0) {
        $files | ForEach-Object {
            try {
                Remove-Item $_.FullName -Force -ErrorAction Stop
                Write-Host "Удален файл: $($_.Name)" -ForegroundColor DarkGray
            }
            catch {
                Write-Warning "Ошибка при удалении $($_.Name): $_"
            }
        }
        Write-Host "Очередь печати очищена. Удалено $($files.Count) файлов." -ForegroundColor Green
    }
    else {
        Write-Host "Очередь печати уже пуста." -ForegroundColor Blue
    }
}
catch {
    Write-Host "Критическая ошибка: $_" -ForegroundColor Red
    exit 1
}
finally {
    # Всегда перезапускаем службу
    Write-Host "Перезапускаем службу печати..." -ForegroundColor Cyan
    Start-Service -Name Spooler -ErrorAction SilentlyContinue
    Write-Host "Служба успешно запущена" -ForegroundColor Green
}

Write-Host "Очистка завершена успешно!" -ForegroundColor Green