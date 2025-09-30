# Maintainer: Your Name <your.email@example.com>
pkgname=mod-manager-git
pkgver=r1.0.0
pkgrel=1
pkgdesc="Менеджер модів для XXMI/ZZMI (Zenless Zone Zero, Genshin Impact, Star Rail)"
arch=('x86_64')
url="https://github.com/yourusername/mod-manager"
license=('MIT')
depends=(
    'python>=3.8'
    'flutter>=3.0'
    'python-flask'
    'python-pillow'
    'python-pyqt6'
    'gtk3'
    'clang'
    'cmake'
    'ninja'
    'pkg-config'
)
makedepends=(
    'git'
    'flutter'
)
provides=('mod-manager')
conflicts=('mod-manager')
source=("git+$url.git")
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir/mod-manager"
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

prepare() {
    cd "$srcdir/mod-manager"
    
    # Встановлюємо Python залежності
    pip install --user -r requirements.txt
    
    # Встановлюємо Flutter залежності
    cd mod_manager_flutter
    flutter pub get
}

build() {
    cd "$srcdir/mod-manager/mod_manager_flutter"
    
    # Будуємо Flutter додаток для Linux
    flutter build linux --release
}

package() {
    cd "$srcdir/mod-manager"
    
    # Створюємо директорії
    install -dm755 "$pkgdir/opt/mod-manager"
    install -dm755 "$pkgdir/usr/bin"
    install -dm755 "$pkgdir/usr/share/applications"
    install -dm755 "$pkgdir/usr/share/pixmaps"
    
    # Копіюємо Python код
    cp -r src "$pkgdir/opt/mod-manager/"
    cp api_server.py "$pkgdir/opt/mod-manager/"
    cp requirements.txt "$pkgdir/opt/mod-manager/"
    
    # Копіюємо Flutter build
    cp -r mod_manager_flutter/build/linux/x64/release/bundle/* "$pkgdir/opt/mod-manager/"
    
    # Копіюємо assets
    cp -r assets "$pkgdir/opt/mod-manager/"
    
    # Створюємо конфігураційний файл за замовчуванням
    install -Dm644 config.json "$pkgdir/opt/mod-manager/config.json.example"
    
    # Копіюємо .desktop файл
    install -Dm644 mod-manager.desktop "$pkgdir/usr/share/applications/mod-manager.desktop"
    
    # Якщо є іконка
    if [ -f "assets/icon.png" ]; then
        install -Dm644 assets/icon.png "$pkgdir/usr/share/pixmaps/mod-manager.png"
    fi
    
    # Створюємо wrapper скрипт
    cat > "$pkgdir/usr/bin/mod-manager" << 'EOF'
#!/bin/bash
cd /opt/mod-manager

# Запускаємо API сервер у фоні
python3 api_server.py &
API_PID=$!

# Запускаємо Flutter GUI
./mod_manager_flutter

# Коли GUI закривається, зупиняємо API
kill $API_PID 2>/dev/null
EOF
    
    chmod +x "$pkgdir/usr/bin/mod-manager"
    
    # Копіюємо документацію
    install -Dm644 README.md "$pkgdir/usr/share/doc/mod-manager/README.md"
    install -Dm644 INSTALL_GUIDE.md "$pkgdir/usr/share/doc/mod-manager/INSTALL_GUIDE.md"
}
