# F10 Auto-Reload для ZZZ Mod Manager

## Опис

Цей мод менеджер тепер підтримує автоматичне перезавантаження модів у 3DMigoto/XXMI через відправку клавіші F10. Це дозволяє миттєво застосовувати зміни модів без ручного натискання F10 у грі.

## Як це працює

### XXMI/3DMigoto та F10

XXMI (ZZMI) використовує 3DMigoto для завантаження модів. У файлі `d3dx.ini` є налаштування:

```ini
; reload all fixes from ShaderFixes folder
reload_fixes = no_modifiers VK_F10
```

Це означає, що при натисканні F10, 3DMigoto перезавантажує всі моди з папки `ShaderFixes` та інших директорій.

### Автоматизація на Linux

Наш мод менеджер автоматично відправляє F10 коли ви:
- Активуєте мод
- Деактивуєте мод
- Натискаєте кнопку "F10" в інтерфейсі

## Методи реалізації

### 1. Відправка клавіш через системні інструменти

#### X11 (xdotool)
```bash
sudo apt install xdotool
```

#### Wayland (ydotool)
```bash
sudo apt install ydotool
```

### 2. Створення сигнальних файлів

Додаток створює файли `.reload_signal` та `.mod_timestamp` у папці модів, які можуть відслідковуватися 3DMigoto.

### 3. Генерація INI файлів

Створюється тимчасовий `mod_reload_trigger.ini` файл з командами перезавантаження:

```ini
[Constants]
$force_reload = 1

[Present]
post run = CommandListForceReload

[CommandListForceReload]
if $force_reload == 1
    $force_reload = 0
    run = BuiltInCommandListReloadConfig
endif
```

### 4. Python резервний скрипт

У папці `scripts/f10_reload.py` є резервний скрипт, який можна викликати окремо:

```bash
python3 scripts/f10_reload.py /шлях/до/модів
```

## Налаштування

### 1. Встановлення XXMI

```bash
# Завантажте XXMI Installer
wget https://github.com/SpectrumQT/XXMI-Installer/releases/latest

# Або використовуйте ZZMI для Zenless Zone Zero
wget https://github.com/leotorrez/ZZMI-Package/releases/latest
```

### 2. Налаштування d3dx.ini

Переконайтеся що у файлі `d3dx.ini` є рядок:

```ini
reload_fixes = no_modifiers VK_F10
reload_config = no_modifiers VK_F10
```

### 3. Встановлення залежностей

#### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install xdotool  # для X11
sudo apt install ydotool  # для Wayland
```

#### Arch Linux:
```bash
sudo pacman -S xdotool     # для X11
yay -S ydotool            # для Wayland
```

#### Fedora:
```bash
sudo dnf install xdotool   # для X11
sudo dnf install ydotool   # для Wayland
```

## Використання

### Автоматичне перезавантаження

1. Налаштуйте шляхи у Налаштуваннях
2. Активуйте/деактивуйте моди - F10 відправиться автоматично
3. Або натисніть кнопку "F10" в інтерфейсі для ручного перезавантаження

### Перевірка роботи

У налаштуваннях є секція "F10 Mod Reload" з:
- ✓ Статус налаштувань
- 🔧 Кнопка встановлення залежностей  
- 📖 Детальні інструкції

## Діагностика проблем

### Перевірка інструментів

```bash
# Перевірка xdotool
which xdotool && echo "xdotool встановлений" || echo "xdotool НЕ встановлений"

# Перевірка ydotool
which ydotool && echo "ydotool встановлений" || echo "ydotool НЕ встановлений"

# Перевірка типу дисплею
echo $XDG_SESSION_TYPE
```

### Ручна перевірка

```bash
# Тест відправки F10
xdotool key F10

# Або для Wayland
ydotool key 67:1 67:0
```

### Логи

Усі операції F10 логуються в консоль. Запустіть додаток з терміналу щоб бачити логи:

```bash
flutter run
```

## Troubleshooting

### Проблема: F10 не відправляється

**Рішення:**
1. Перевірте чи встановлений xdotool/ydotool
2. Переконайтеся що гра запущена
3. Спробуйте ручну відправку F10 через термінал

### Проблема: 3DMigoto не реагує на F10

**Рішення:**
1. Перевірте налаштування у d3dx.ini
2. Переконайтеся що XXMI правильно налаштований
3. Перевірте що гра запущена через XXMI Launcher

### Проблема: Дозволи для ydotool

**Рішення:**
```bash
# Додайте користувача до групи input
sudo usermod -a -G input $USER

# Перезайдіть або перезавантажте систему
```

## Технічні деталі

### Підтримувані системи
- ✅ Linux X11
- ✅ Linux Wayland  
- ❌ Windows (не потрібно, працює нативно)
- ❌ macOS (Zenless Zone Zero не підтримується)

### Підтримувані інструменти
- `xdotool` - для X11
- `ydotool` - для Wayland
- Python скрипт - резервний метод

### Коди клавіш
- F10 = VK_F10 = 0x79 (Windows)
- F10 = key 67 (ydotool)
- F10 = key F10 (xdotool)

## Безпека

Цей функціонал відправляє лише клавішу F10 і не має доступу до інших системних ресурсів. Усі файли створюються тільки у папці модів і автоматично видаляються.