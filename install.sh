#!/bin/bash

# 🎮 Mod Manager - Автоматичний інсталятор для Linux
# Цей скрипт встановлює всі залежності та налаштовує проект

set -e  # Зупинити виконання при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функції для виводу
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}    🎮 Mod Manager - Інсталятор${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# Перевірка чи запущено з sudo (не потрібно)
if [ "$EUID" -eq 0 ]; then
    print_warning "Не запускайте цей скрипт з sudo!"
    print_info "Скрипт сам запитає пароль, коли потрібно."
    exit 1
fi

print_header

# 1. Перевірка Python
print_info "Перевірка Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_success "Python встановлено: $PYTHON_VERSION"
else
    print_error "Python 3 не знайдено!"
    print_info "Встановлюємо Python 3..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
    print_success "Python встановлено"
fi

# 2. Перевірка Flutter
print_info "Перевірка Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_success "Flutter встановлено: $FLUTTER_VERSION"
else
    print_warning "Flutter не знайдено!"
    print_info "Встановлюємо Flutter..."
    
    # Встановлюємо залежності для Flutter
    sudo apt install -y curl git unzip xz-utils zip libglu1-mesa
    sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
    
    # Завантажуємо Flutter
    cd ~
    if [ ! -d "flutter" ]; then
        git clone https://github.com/flutter/flutter.git -b stable
    fi
    
    # Додаємо Flutter до PATH
    if ! grep -q 'flutter/bin' ~/.bashrc; then
        echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
        print_info "Додано Flutter до PATH в ~/.bashrc"
    fi
    
    export PATH="$PATH:$HOME/flutter/bin"
    
    # Запускаємо flutter doctor
    flutter doctor
    print_success "Flutter встановлено"
fi

# Повертаємось до директорії проекту
cd "$(dirname "$0")"

# 3. Встановлення Python залежностей
print_info "Встановлення Python залежностей..."
if [ -f "requirements.txt" ]; then
    python3 -m pip install --user -r requirements.txt
    print_success "Python залежності встановлено"
else
    print_warning "requirements.txt не знайдено, пропускаємо Python залежності"
fi

# 4. Встановлення Flutter залежностей
print_info "Встановлення Flutter залежностей..."
if [ -d "mod_manager_flutter" ]; then
    cd mod_manager_flutter
    flutter pub get
    print_success "Flutter залежності встановлено"
    cd ..
else
    print_warning "Папка mod_manager_flutter не знайдена"
fi

# 5. Створення необхідних директорій
print_info "Створення необхідних директорій..."
mkdir -p assets/characters
mkdir -p assets/mod_images
mkdir -p mod_manager_flutter/assets/mod_images
print_success "Директорії створено"

# 6. Створення config.json якщо не існує
if [ ! -f "config.json" ]; then
    print_info "Створення config.json..."
    cat > config.json << 'EOF'
{
    "game_dir": "/path/to/your/game/Mods",
    "mods_backup_dir": "./mods_backup"
}
EOF
    print_success "config.json створено"
    print_warning "ВАЖЛИВО: Відредагуйте config.json та вкажіть шлях до папки Mods вашої гри!"
fi

# 7. Перевірка API сервера
print_info "Перевірка API сервера..."
if [ -f "api_server.py" ]; then
    print_success "API сервер знайдено"
else
    print_warning "api_server.py не знайдено"
fi

# 8. Створення скрипта запуску
print_info "Створення скриптів запуску..."

# Скрипт для Python GUI
cat > run_python.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
python3 src/main.py
EOF
chmod +x run_python.sh

# Скрипт для Flutter GUI + API
cat > run_flutter.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

# Запускаємо API сервер у фоні
echo "Запуск API сервера..."
python3 api_server.py &
API_PID=$!
echo "API сервер запущено (PID: $API_PID)"

# Даємо серверу час на запуск
sleep 2

# Запускаємо Flutter додаток
echo "Запуск Flutter додатку..."
cd mod_manager_flutter
flutter run -d linux

# Коли Flutter закривається, зупиняємо API сервер
echo "Зупинка API сервера..."
kill $API_PID 2>/dev/null
EOF
chmod +x run_flutter.sh

# Повний скрипт запуску
cat > start.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

echo "═══════════════════════════════════════════════════════"
echo "    🎮 Mod Manager"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Виберіть інтерфейс:"
echo "  1) Flutter (сучасний, рекомендовано)"
echo "  2) Python/PyQt6 (класичний)"
echo ""
read -p "Ваш вибір (1 або 2): " choice

case $choice in
    1)
        ./run_flutter.sh
        ;;
    2)
        ./run_python.sh
        ;;
    *)
        echo "Невірний вибір. Запускаємо Flutter..."
        ./run_flutter.sh
        ;;
esac
EOF
chmod +x start.sh

print_success "Скрипти запуску створено"

# 9. Створення .desktop файлу для швидкого запуску
print_info "Створення ярлика на робочому столі..."
CURRENT_DIR=$(pwd)
cat > ~/.local/share/applications/mod-manager.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Mod Manager
Comment=Менеджер модів для XXMI/ZZMI
Exec=$CURRENT_DIR/start.sh
Icon=$CURRENT_DIR/assets/icon.png
Terminal=true
Categories=Game;Utility;
EOF

print_success "Ярлик створено"

# 10. Фінальні інструкції
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    ✓ Встановлення завершено!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
print_info "Що далі:"
echo ""
echo "  1. Відредагуйте config.json та вкажіть шлях до папки Mods"
echo "     nano config.json"
echo ""
echo "  2. Запустіть програму одним із способів:"
echo "     ./start.sh              - інтерактивний вибір інтерфейсу"
echo "     ./run_flutter.sh        - Flutter інтерфейс (рекомендовано)"
echo "     ./run_python.sh         - Python інтерфейс"
echo ""
echo "  3. Або знайдіть 'Mod Manager' у меню програм"
echo ""

if ! command -v flutter &> /dev/null; then
    print_warning "УВАГА: Flutter було встановлено, але може не бути в PATH"
    print_info "Перезапустіть термінал або виконайте:"
    echo "     source ~/.bashrc"
fi

print_success "Готово! Приємного користування! 🎮"
