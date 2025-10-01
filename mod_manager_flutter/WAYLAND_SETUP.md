# Налаштування F10 Auto-Reload для Wayland

## Проблема

На Wayland, `ydotool` потребує спеціальних налаштувань та прав доступу. Крім того, **вікно гри має бути видимим і не згорнутим** для того щоб отримувати клавіатурний ввід.

## Швидке налаштування

### 1. Встановлення інструментів

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ydotool wmctrl xdotool

# Arch Linux
sudo pacman -S ydotool wmctrl xdotool

# Fedora
sudo dnf install ydotool wmctrl xdotool
```

### 2. Налаштування прав для ydotool

```bash
# Додайте вашого користувача до групи input
sudo usermod -a -G input $USER

# Увімкніть сервіс ydotool (якщо доступний)
sudo systemctl enable --now ydotool.service

# АБО запустіть ydotool daemon вручну
ydotoold &

# Перевірте чи працює ydotool
ydotool key 28:1 28:0  # має надрукувати Enter
```

### 3. **Перезавантажте систему** або вийдіть і зайдіть знову

Це необхідно щоб зміни в групах набули чинності:

```bash
# Перевірте чи ви в групі input
groups | grep input

# Якщо немає - перезавантажте систему
sudo reboot
```

## Важливі моменти

### ✅ Що має працювати:

1. **Вікно гри має бути видимим**
   - НЕ згортайте вікно гри при активації модів
   - Гра має бути на екрані (можна Alt+Tab між додатком і грою)

2. **ydotool daemon має бути запущений**
   ```bash
   # Перевірка чи запущений
   ps aux | grep ydotool
   
   # Якщо немає - запустіть
   ydotoold &
   ```

3. **Ваш користувач має бути в групі input**
   ```bash
   groups | grep input
   ```

### ❌ Що НЕ працює:

- ❌ Згорнуте вікно гри
- ❌ Гра на іншому робочому столі (якщо не активна)
- ❌ ydotool без прав доступу
- ❌ ydotool daemon не запущений

## Тестування

### Тест 1: Перевірка ydotool

```bash
# Відкрийте текстовий редактор і спробуйте:
ydotool key 28:1 28:0  # Enter
ydotool key 57:1 57:0  # Space
```

Якщо нічого не друкується - ydotool не має прав або daemon не запущений.

### Тест 2: Перевірка wmctrl

```bash
# Запустіть гру і спробуйте:
wmctrl -l  # Має показати список вікон включно з грою
wmctrl -a Zenless  # Має активувати вікно гри
```

### Тест 3: Тест F10 в грі

```bash
# Запустіть гру і спробуйте:
ydotool key 67:1 67:0  # F10

# Або використайте наш скрипт:
python3 scripts/f10_reload.py /шлях/до/модів
```

## Troubleshooting

### Проблема: "Permission denied" при використанні ydotool

**Рішення:**
```bash
# 1. Додайте себе до групи input
sudo usermod -a -G input $USER

# 2. Перезавантажте систему
sudo reboot

# 3. Перевірте
groups | grep input
```

### Проблема: ydotool нічого не друкує

**Рішення:**
```bash
# 1. Переконайтеся що daemon запущений
ps aux | grep ydotool

# 2. Якщо не запущений - запустіть
ydotoold &

# 3. Або увімкніть сервіс
sudo systemctl enable --now ydotool.service
```

### Проблема: F10 не спрацьовує в грі

**Можливі причини:**

1. **Вікно гри згорнуте** ❌
   - Розгорніть вікно гри
   - Переконайтеся що воно видиме на екрані

2. **Гра на іншому робочому столі** ❌
   - Alt+Tab до гри перед активацією моду
   - Або використовуйте `wmctrl -a Zenless` щоб переключитися

3. **Wine/Proton перехоплює клавіші** ⚠️
   - Це рідкісна проблема
   - Спробуйте встановити `winetricks vcrun2019` або `d3dcompiler_47`

4. **3DMigoto не налаштований** ❌
   - Перевірте `d3dx.ini`: `reload_fixes = no_modifiers VK_F10`

## Альтернативний метод: Автоматичне перезавантаження через INI

Якщо ydotool не працює, наш додаток створює файли в папці модів:

1. `.reload_signal` - сигнальний файл
2. `.mod_timestamp` - timestamp файл
3. `mod_reload_trigger.ini` - INI з командами

Якщо налаштувати 3DMigoto для моніторингу цих файлів, моди будуть перезавантажуватися автоматично.

## Рекомендований workflow

### Варіант 1: Alt+Tab метод (найпростіший)

1. Відкрийте гру
2. Alt+Tab до мод менеджера
3. Активуйте мод
4. Alt+Tab назад до гри
5. ✅ F10 автоматично відправиться коли вікно гри активне

### Варіант 2: Два монітори (найзручніший)

1. Гра на одному моніторі
2. Мод менеджер на другому
3. Активуйте моди - F10 відправляється автоматично
4. ✅ Миттєво бачите результат

### Варіант 3: Ручне F10 (завжди працює)

1. Активуйте мод
2. Переключіться до гри
3. Натисніть F10 вручну
4. ✅ Моди застосовуються

## Додаткові налаштування

### Автозапуск ydotool при завантаженні

Створіть systemd user service:

```bash
mkdir -p ~/.config/systemd/user/
cat > ~/.config/systemd/user/ydotool.service << 'EOF'
[Unit]
Description=ydotool daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/ydotoold
Restart=on-failure

[Install]
WantedBy=default.target
EOF

systemctl --user enable --now ydotool.service
```

### Перевірка прав доступу

```bash
# Має показати /dev/uinput
ls -l /dev/uinput

# Має показати input в списку груп
groups

# Має показати вас як члена групи input
getent group input
```

## Коди клавіш для ydotool

Для довідки, коди клавіш які ми використовуємо:

- F10: `67:1` (натиснути) `67:0` (відпустити)
- Enter: `28:1` `28:0`
- Space: `57:1` `57:0`

## Підтримка

Якщо нічого не допомагає:

1. Перевірте логи в терміналі при запуску:
   ```bash
   flutter run
   ```

2. Спробуйте Python скрипт окремо:
   ```bash
   python3 scripts/f10_reload.py /шлях/до/модів
   ```

3. Перевірте чи працює ручне F10:
   ```bash
   ydotool key 67:1 67:0
   ```

Удачі! 🎮