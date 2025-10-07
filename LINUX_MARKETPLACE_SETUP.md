# Налаштування Marketplace на Linux

## Системні вимоги

Для роботи вбудованого браузера (WebView) у маркетплейсі на Linux потрібні наступні пакети:

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    webkit2gtk-4.0 \
    libwebkit2gtk-4.0-dev \
    libsoup2.4-dev \
    libjavascriptcoregtk-4.0-dev
```

### Fedora
```bash
sudo dnf install -y \
    webkit2gtk3-devel \
    libsoup-devel
```

### Arch Linux
```bash
sudo pacman -S webkit2gtk
```

## 7-Zip для архівів .rar і .7z

Для розпакування .rar та .7z архівів потрібен 7-Zip:

### Ubuntu/Debian
```bash
sudo apt-get install p7zip-full
```

### Fedora
```bash
sudo dnf install p7zip p7zip-plugins
```

### Arch Linux
```bash
sudo pacman -S p7zip
```

## Функціональність маркетплейсу

На Linux працює повністю так само, як на Windows:
- ✅ Вбудований браузер GameBanana
- ✅ Пошук модів
- ✅ Завантаження модів (zip, rar, 7z)
- ✅ Автоматична установка
- ✅ Запобігання подвійного завантаження

## Особливості

1. **SSL сертифікати**: Автоматично ігноруються помилки SSL (як і на Windows)
2. **Завантаження**: Файли завантажуються в `~/.local/share/mod_manager/downloads` або системну тимчасову папку
3. **Розпакування**: ZIP файли обробляються нативно, RAR/7Z через p7zip

## Можливі проблеми

### Маркетплейс не відображається
```bash
# Перевірте чи встановлено webkit2gtk
dpkg -l | grep webkit2gtk   # Ubuntu/Debian
rpm -qa | grep webkit2gtk   # Fedora
pacman -Q webkit2gtk        # Arch
```

### Не розпаковуються .rar/.7z файли
```bash
# Перевірте наявність 7z
which 7z
# або
which 7za
```

## Збірка проекту на Linux

```bash
cd mod_manager_flutter
flutter pub get
flutter build linux --release
```

Виконуваний файл буде у `build/linux/x64/release/bundle/`
