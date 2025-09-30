#!/bin/bash

# Скрипт запуску Mod Manager для Linux

echo "🎮 Запуск Mod Manager..."

# Перевіряємо чи встановлений Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 не знайдено. Встановіть Python 3.8 або новіше."
    exit 1
fi

# Перевіряємо чи встановлені залежності
if ! python3 -c "import customtkinter" &> /dev/null; then
    echo "📦 Встановлення залежностей..."
    pip install -r requirements.txt
fi

# Запускаємо програму
python3 src/main.py

echo "👋 Програму завершено."
