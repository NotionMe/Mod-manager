# PowerShell скрипт для створення portable версії ZZZ Mod Manager
# Створює ZIP архів з усіма необхідними файлами

param(
    [string]$Version = "1.0.0"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ZZZ Mod Manager - Portable Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Перевірка наявності Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ПОМИЛКА: Flutter не знайдено в PATH!" -ForegroundColor Red
    Write-Host "Встановіть Flutter: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# Білд Flutter додатку
Write-Host "[1/3] Білдимо Flutter додаток для Windows..." -ForegroundColor Green
Set-Location -Path "mod_manager_flutter"
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Помилка при білді Flutter додатку!" -ForegroundColor Red
    Set-Location -Path ".."
    exit $LASTEXITCODE
}

Set-Location -Path ".."

# Створення portable версії
Write-Host ""
Write-Host "[2/3] Створюємо portable версію..." -ForegroundColor Green

$buildPath = "mod_manager_flutter\build\windows\x64\runner\Release"
$outputDir = "windows_installer\output"
$portableName = "ZZZ-Mod-Manager-Portable-$Version"
$portablePath = "$outputDir\$portableName"

# Створення директорій
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if (Test-Path $portablePath) {
    Remove-Item -Path $portablePath -Recurse -Force
}

New-Item -ItemType Directory -Path $portablePath | Out-Null

# Копіювання файлів
Write-Host "Копіюємо файли..." -ForegroundColor Yellow
Copy-Item -Path "$buildPath\*" -Destination $portablePath -Recurse -Force

# Копіювання іконки
if (Test-Path "assets\icon.png") {
    $assetsPath = "$portablePath\data\flutter_assets\assets"
    if (-not (Test-Path $assetsPath)) {
        New-Item -ItemType Directory -Path $assetsPath -Force | Out-Null
    }
    Copy-Item -Path "assets\icon.png" -Destination $assetsPath -Force
}

# Створення README для portable версії
$readmeContent = @"
# ZZZ Mod Manager (Portable Version)

Це portable версія ZZZ Mod Manager - не потребує установки!

## Як використовувати:

1. Розпакуйте цей архів у будь-яку директорію
2. Запустіть mod_manager_flutter.exe

## ВАЖЛИВО:

⚠️ Для створення мод-симлінків потрібні права адміністратора!

**Рекомендується:**
- Клік правою кнопкою на mod_manager_flutter.exe
- Виберіть "Запустити від імені адміністратора"

## Системні вимоги:

- Windows 10 або новіше (x64)
- Права адміністратора (для роботи з симлінками)

## Видалення:

Просто видаліть цю директорію - програма не залишає файлів у системі.
(Окрім налаштувань у %APPDATA%)

## Підтримка:

GitHub: https://github.com/NotionMe/Mod-manager
Issues: https://github.com/NotionMe/Mod-manager/issues

Версія: $Version
"@

Set-Content -Path "$portablePath\README.txt" -Value $readmeContent -Encoding UTF8

# Створення батнік-файлу для запуску від адміна
$runAsAdminContent = @"
@echo off
REM Автоматичний запуск від імені адміністратора

:: Перевірка прав адміністратора
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Запускаємо ZZZ Mod Manager...
    start "" "%~dp0mod_manager_flutter.exe"
) else (
    echo Запит прав адміністратора...
    powershell -Command "Start-Process '%~dp0mod_manager_flutter.exe' -Verb RunAs"
)
"@

Set-Content -Path "$portablePath\Run_As_Admin.bat" -Value $runAsAdminContent -Encoding ASCII

# Створення ZIP архіву
Write-Host ""
Write-Host "[3/3] Створюємо ZIP архів..." -ForegroundColor Green

$zipPath = "$outputDir\$portableName.zip"
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}

Compress-Archive -Path $portablePath -DestinationPath $zipPath -CompressionLevel Optimal

# Очищення тимчасової директорії
Remove-Item -Path $portablePath -Recurse -Force

# Отримання розміру файлу
$zipSize = (Get-Item $zipPath).Length / 1MB

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Успішно!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Portable версія: $zipPath" -ForegroundColor Yellow
Write-Host "Розмір: $([math]::Round($zipSize, 2)) MB" -ForegroundColor Yellow
Write-Host ""
Write-Host "Користувачі можуть просто розпакувати ZIP і запустити!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
