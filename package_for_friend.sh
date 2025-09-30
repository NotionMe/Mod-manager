#!/bin/bash

# 📦 Скрипт для упаковки проекту та передачі друзям

echo "╔═══════════════════════════════════════════════════════╗"
echo "║       📦 Упаковка Mod Manager для передачі           ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# Назва архіву
ARCHIVE_NAME="mod-manager-installer.tar.gz"
DATE=$(date +%Y%m%d)
ARCHIVE_WITH_DATE="mod-manager-installer-$DATE.tar.gz"

# Кольори
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}ℹ${NC} Що буде упаковано:"
echo "  ✓ Інсталяційний скрипт (install.sh)"
echo "  ✓ Вихідний код (src/, mod_manager_flutter/)"
echo "  ✓ Конфігурація (requirements.txt, pubspec.yaml)"
echo "  ✓ Документацію (README, інструкції)"
echo "  ✓ Ресурси (assets/)"
echo ""

# Питаємо користувача
read -p "Продовжити упаковку? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Скасовано."
    exit 1
fi

echo ""
echo -e "${BLUE}ℹ${NC} Створення архіву..."

# Виключаємо непотрібні файли
tar -czf "$ARCHIVE_WITH_DATE" \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.pytest_cache' \
    --exclude='node_modules' \
    --exclude='build' \
    --exclude='.dart_tool' \
    --exclude='*.log' \
    --exclude='mod_manager_flutter/.flutter-plugins-dependencies' \
    --exclude='mod_manager_flutter/linux/flutter/ephemeral' \
    install.sh \
    start.sh \
    run_flutter.sh \
    run_python.sh \
    quick_install.sh \
    api_server.py \
    requirements.txt \
    config.json \
    README*.md \
    INSTALL*.md \
    QUICK_START.txt \
    src/ \
    mod_manager_flutter/ \
    assets/ \
    2>/dev/null

if [ $? -eq 0 ]; then
    # Створюємо також версію без дати
    cp "$ARCHIVE_WITH_DATE" "$ARCHIVE_NAME"
    
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_WITH_DATE" | cut -f1)
    
    echo ""
    echo -e "${GREEN}✓${NC} Архів успішно створено!"
    echo ""
    echo "  📦 Файл: $ARCHIVE_WITH_DATE"
    echo "  📏 Розмір: $ARCHIVE_SIZE"
    echo "  📦 Копія: $ARCHIVE_NAME"
    echo ""
    echo -e "${YELLOW}📤 Як передати другу:${NC}"
    echo ""
    echo "  1. Відправ файл через:"
    echo "     - Google Drive / Dropbox"
    echo "     - Email (якщо < 25 MB)"
    echo "     - USB флешку"
    echo "     - Локальна мережа: python3 -m http.server"
    echo ""
    echo "  2. Друг розпаковує:"
    echo "     tar -xzf $ARCHIVE_NAME"
    echo "     cd mod-manager"
    echo "     ./install.sh"
    echo ""
    echo "  3. Або дай інструкцію:"
    echo "     cat QUICK_START.txt"
    echo ""
    
    # Створюємо інструкцію для друга
    cat > "ІНСТРУКЦІЯ_ДЛЯ_ДРУГА.txt" << 'EOF'
════════════════════════════════════════════════════════════════
    🎮 MOD MANAGER - ШВИДКЕ ВСТАНОВЛЕННЯ
════════════════════════════════════════════════════════════════

1. РОЗПАКУЙ АРХІВ:
   tar -xzf mod-manager-installer.tar.gz
   cd mod-manager

2. ЗАПУСТИ ІНСТАЛЯТОР:
   ./install.sh

3. ДОЧЕКАЙСЯ ЗАВЕРШЕННЯ (5-10 хвилин)

4. НАЛАШТУЙ config.json:
   nano config.json
   Вкажи шлях до папки Mods гри

5. ЗАПУСТИ:
   ./start.sh

Детальніше: QUICK_START.txt або INSTALL_GUIDE.md

════════════════════════════════════════════════════════════════
EOF
    
    echo -e "${GREEN}✓${NC} Створено інструкцію: ІНСТРУКЦІЯ_ДЛЯ_ДРУГА.txt"
    echo ""
    
    # Пропонуємо створити README для архіву
    cat > "README_АРХІВ.txt" << 'EOF'
🎮 MOD MANAGER - АРХІВ ДЛЯ УСТАНОВКИ

Цей архів містить повну версію Mod Manager з автоматичним інсталятором.

ШВИДКИЙ СТАРТ:
===============

1. Розпакуй архів:
   tar -xzf mod-manager-installer.tar.gz

2. Перейди в папку:
   cd mod-manager

3. Запусти інсталятор:
   ./install.sh

4. Слідуй інструкціям на екрані

ВИМОГИ:
========
- Linux (Ubuntu, Debian, Arch, Fedora)
- Інтернет для завантаження залежностей
- ~2 GB вільного місця

ДОКУМЕНТАЦІЯ:
=============
- QUICK_START.txt - Швидкий посібник
- INSTALL_GUIDE.md - Детальна інструкція
- README_INSTALLER.md - Повний README

ПІДТРИМКА:
==========
GitHub: https://github.com/yourusername/mod-manager
EOF
    
    echo -e "${GREEN}✓${NC} Створено README_АРХІВ.txt"
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}    ✓ Готово! Проект упаковано і готовий до передачі   ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    
else
    echo ""
    echo -e "${RED}✗${NC} Помилка при створенні архіву"
    exit 1
fi
