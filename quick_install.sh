#!/bin/bash

# 🎮 Швидкий інсталятор Mod Manager
# Використовуйте цей скрипт для передачі проекту друзям

echo "╔═══════════════════════════════════════════════════════╗"
echo "║       🎮 Mod Manager - Швидка установка              ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Перевірка curl або wget
if command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl -fsSL"
elif command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget -qO-"
else
    echo "❌ Помилка: curl або wget не знайдено"
    echo "   Встановіть один з них:"
    echo "   sudo apt install curl"
    exit 1
fi

# URL репозиторію (замініть на ваш)
REPO_URL="https://github.com/yourusername/mod-manager"
INSTALL_SCRIPT_URL="$REPO_URL/raw/main/install.sh"

echo "📦 Завантаження інсталятора..."
echo ""

# Завантажуємо та запускаємо install.sh
bash <($DOWNLOAD_CMD $INSTALL_SCRIPT_URL)
