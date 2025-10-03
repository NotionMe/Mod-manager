@echo off
REM Скрипт для автоматичної побудови Windows installer
REM Запускати з кореневої директорії проекту

echo ========================================
echo  ZZZ Mod Manager - Windows Installer Builder
echo ========================================
echo.

REM Перехід до директорії Flutter проекту
cd mod_manager_flutter

echo [1/3] Білдимо Flutter додаток для Windows...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Помилка при білді Flutter додатку!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Перевіряємо наявність Inno Setup...

REM Перевірка наявності Inno Setup
set INNO_SETUP_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe
if not exist "%INNO_SETUP_PATH%" (
    echo.
    echo ПОМИЛКА: Inno Setup не знайдено!
    echo Будь ласка, завантажте та встановіть Inno Setup 6:
    echo https://jrsoftware.org/isdl.php
    echo.
    pause
    exit /b 1
)

echo Знайдено: %INNO_SETUP_PATH%

REM Повернення до кореневої директорії
cd ..

echo.
echo [3/3] Створюємо installer...
"%INNO_SETUP_PATH%" "windows_installer\setup.iss"
if %ERRORLEVEL% NEQ 0 (
    echo Помилка при створенні installer!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================
echo  Успішно! 
echo  Installer знаходиться в: windows_installer\output\
echo ========================================
echo.

pause
