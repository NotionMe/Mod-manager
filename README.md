# Mod Manager для Zenless Zone Zero

Flutter додаток для керування модами через symbolic links.

## 🎯 Особливості

- ✅ **100% на Dart** - без Python залежностей
- ✅ **Symbolic Links** - безпечне керування модами без копіювання файлів
- ✅ **Швидкий** - нативна робота з файловою системою
- ✅ **Зручний UI** - сучасний Flutter інтерфейс
- ✅ **Кросплатформний** - підтримка Linux, Windows, MacOS

## 🏗️ Архітектура

```
lib/
├── models/           # Моделі даних
│   ├── mod_info.dart
│   └── character_info.dart
├── services/         # Бізнес-логіка
│   ├── mod_manager_service.dart  # Керування модами
│   ├── config_service.dart       # Конфігурація
│   └── api_service.dart          # API фасад
├── screens/          # Екрани UI
│   └── mods_screen.dart
└── utils/            # Утиліти
    └── zzz_characters.dart
```

## 🔧 Як працює

1. **Сканування модів** - додаток сканує папку SaveMods і знаходить всі доступні моди
2. **Symbolic Links** - при активації моду створюється symlink в папці Mods
3. **Безпечна деактивація** - видаляється тільки symlink, оригінальні файли залишаються
4. **Персистентна конфігурація** - налаштування зберігаються в SharedPreferences + JSON

## 📦 Встановлення

```bash
cd mod_manager_flutter
flutter pub get
flutter run -d linux
```

## ⚙️ Конфігурація

Налаштуйте шляхи до папок:
- **Mods Path (SaveMods)** - папка з оригінальними модами
- **Save Mods Path (Mods)** - папка куди створюються symlinks

Приклад:
```
Mods Path: /path/to/ZZMI/SaveMods
Save Mods Path: /path/to/ZZMI/Mods
```

## 🚀 Використання

1. Відкрийте додаток
2. Налаштуйте шляхи в Settings (⚙️)
3. Виберіть персонажа
4. Активуйте/деактивуйте моди одним кліком

## 🛠️ Технології

- **Flutter 3.8+** - UI framework
- **Dart 3.0+** - мова програмування
- **SharedPreferences** - локальне збереження
- **Path** - робота зі шляхами
- **dart:io** - файлова система та symlinks

## 📝 Бізнес-логіка

### ModManagerService
Головний сервіс для керування модами:
- `scanMods()` - сканування доступних модів
- `activateMod()` - створення symlink
- `deactivateMod()` - видалення symlink  
- `toggleMod()` - переключення стану
- `isModActive()` - перевірка активності

### ConfigService
Управління конфігурацією:
- Збереження шляхів до папок
- Список активних модів
- Тема та мова інтерфейсу
- Синхронізація з JSON файлом

## 🔐 Безпека

- ✅ Використовуються тільки symbolic links
- ✅ Оригінальні файли ніколи не видаляються
- ✅ Валідація шляхів перед операціями
- ✅ Обробка помилок та логування

## 🎮 Підтримувані персонажі

Anby, Nicole, Billy, Nekomata, Corin, Ellen, Koleda, Ben, Anton, 
Soukaku, Lycaon, Grace, Rina, Soldier 11, Lucy, Piper, Burnice, 
Caesar, Jane, Seth, Qingyi, Zhu Yuan, Belle, Wise, Yanagi, 
Lighter, Harumasa, Miyabi, Evelyn, Pulchra, Astra

## 📄 Ліцензія

MIT License - вільне використання
