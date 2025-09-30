# 🎮 Mod Manager для XXMI/ZZMI

Менеджер модів з графічним інтерфейсом для швидкого перемикання між модами в іграх через XXMI Launcher (ZZMI, GIMI, SRMI, WWMI).

![Flutter UI](screenshots/preview.png)

## ✨ Особливості

- 🎨 **Сучасний Flutter UI** - красивий і швидкий інтерфейс
- ⚡ **Миттєва активація** - symbolic links замість копіювання
- 🖼️ **Превʼю модів** - підтримка зображень з буфера обміну
- 🔄 **Асинхронне оновлення** - без перезапуску програми
- 🎯 **Множинний вибір** - активуйте кілька модів одночасно
- 🔒 **Безпечність** - оригінальні файли не торкаються

---

## 📦 Встановлення

### Arch Linux (AUR)

```bash
yay -S mod-manager-git
# або
paru -S mod-manager-git
```

### Інші дистрибутиви

#### Автоматичне встановлення:

```bash
git clone https://github.com/yourusername/mod-manager.git
cd mod-manager
./install.sh
```

#### Ручне встановлення:

```bash
# 1. Встановіть залежності
sudo apt install python3 python3-pip flutter clang cmake ninja-build pkg-config libgtk-3-dev

# 2. Клонуйте репозиторій
git clone https://github.com/yourusername/mod-manager.git
cd mod-manager

# 3. Встановіть Python залежності
pip3 install -r requirements.txt

# 4. Встановіть Flutter залежності
cd mod_manager_flutter
flutter pub get
cd ..

# 5. Запустіть
./run_flutter.sh
```

---

## ⚙️ Налаштування

Відредагуйте `config.json`:

```json
{
    "game_dir": "/home/username/.local/share/ZZMI/Mods",
    "mods_backup_dir": "./mods_backup"
}
```

**Приклади шляхів:**

- **ZZMI:** `~/.local/share/ZZMI/Mods`
- **GIMI:** `~/.local/share/GIMI/Mods`
- **SRMI:** `~/.local/share/SRMI/Mods`

---

## 🚀 Запуск

### Після встановлення через AUR:

```bash
mod-manager
```

Або знайдіть "Mod Manager" у меню програм.

### Після Git встановлення:

```bash
./start.sh          # Інтерактивний вибір
./run_flutter.sh    # Flutter GUI (рекомендовано)
./run_python.sh     # Python GUI
```

---

## 🎮 Використання

1. **Вибір персонажа** - клік на аватарку зверху
2. **Активація мода** - лівий клік на картці
3. **Додавання фото:**
   - Скопіюйте зображення (Ctrl+C)
   - Правий клік на картці мода
   - "Додати фото з буфера"
   - Зображення автоматично оновиться!

---

## 🛠️ Технології

### Backend
- Python 3.8+
- Flask REST API
- PyQt6 (опціонально)

### Frontend
- Flutter 3.0+
- Riverpod (state management)
- Google Fonts

---

## 📁 Структура проекту

```
mod-manager/
├── PKGBUILD                 # AUR пакет
├── mod-manager.desktop      # Desktop entry
├── install.sh               # Автоінсталятор
├── api_server.py            # REST API
├── config.json              # Конфігурація
├── src/                     # Python код
└── mod_manager_flutter/     # Flutter додаток
```

---

## 🐛 Відомі проблеми

### Flutter не знайдено
```bash
export PATH="$PATH:$HOME/flutter/bin"
source ~/.bashrc
```

### Порт 5000 зайнятий
Змініть порт в `api_server.py`:
```python
app.run(port=5001)
```

---

## 🤝 Внесок

Contributions are welcome! 

1. Fork репозиторію
2. Створіть feature branch (`git checkout -b feature/amazing`)
3. Commit зміни (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing`)
5. Відкрийте Pull Request

---

## 📝 TODO

- [ ] Додати підтримку Windows
- [ ] Автоматичне виявлення шляхів до ігор
- [ ] Завантаження модів з GameBanana
- [ ] Профілі модів (пресети)
- [ ] Система оновлень

---

## 📄 Ліцензія

MIT License - використовуйте вільно!

---

## 🌟 Підтримка

- 🐛 **Баги:** [GitHub Issues](https://github.com/yourusername/mod-manager/issues)
- 💬 **Обговорення:** [GitHub Discussions](https://github.com/yourusername/mod-manager/discussions)
- 📖 **Документація:** [Wiki](https://github.com/yourusername/mod-manager/wiki)

---

## 📸 Скріншоти

### Головний екран
![Main Screen](screenshots/main.png)

### Вибір модів
![Mods Selection](screenshots/mods.png)

### Налаштування
![Settings](screenshots/settings.png)

---

## 🙏 Подяки

- Спільноті XXMI/ZZMI
- Розробникам Flutter
- Всім контриб'юторам

---

**Приємного моддінгу! 🎮✨**

<p align="center">
  <a href="https://github.com/yourusername/mod-manager/stargazers">
    <img src="https://img.shields.io/github/stars/yourusername/mod-manager?style=social" alt="Stars">
  </a>
  <a href="https://github.com/yourusername/mod-manager/network/members">
    <img src="https://img.shields.io/github/forks/yourusername/mod-manager?style=social" alt="Forks">
  </a>
  <a href="https://github.com/yourusername/mod-manager/issues">
    <img src="https://img.shields.io/github/issues/yourusername/mod-manager" alt="Issues">
  </a>
  <a href="https://github.com/yourusername/mod-manager/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/yourusername/mod-manager" alt="License">
  </a>
</p>
