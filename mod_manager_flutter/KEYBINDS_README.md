# 🎮 Keybinds Feature

## 🚀 Швидкий старт

### 1. Створіть тестовий INI файл

```bash
# Windows PowerShell
mkdir savemods\test_char
copy EXAMPLE_CONFIG.ini savemods\test_char\config.ini

# Linux/Mac
mkdir -p savemods/test_char
cp EXAMPLE_CONFIG.ini savemods/test_char/config.ini
```

### 2. Запустіть додаток

```bash
flutter run -d windows
# або
flutter run -d linux
```

### 3. Перевірте результат

- Відкрийте вкладку **Mods**
- Виберіть персонажа `test_char`
- Ви побачите:
  - **Бейдж** на картці персонажа з числом keybinds
  - **Панель** з детальним відображенням keybinds

## 📖 Документація

- **[KEYBINDS_SUMMARY.md](./KEYBINDS_SUMMARY.md)** - Повний опис реалізації
- **[KEYBINDS_INTEGRATION_GUIDE.md](./KEYBINDS_INTEGRATION_GUIDE.md)** - Інструкція з інтеграції
- **[TESTING_GUIDE.md](./TESTING_GUIDE.md)** - Інструкція з тестування
- **[EXAMPLE_CONFIG.ini](./EXAMPLE_CONFIG.ini)** - Приклад INI файлу

## 💡 Як це працює

```
savemods/               ← ваша папка з модами
  └── персонаж/        ← папка персонажа
      └── *.ini        ← INI файл(и) з keybinds
```

### Приклад INI:

```ini
[keySwap]
Key1=VK_F1
Key2=VK_F2

[KeyUP]
Key=VK_UP
Action=jump
```

## ✨ Особливості

- ✅ **Крос-платформність**: Працює на Windows + Linux
- ✅ **Автоматичне визначення**: Знаходить keybind-секції автоматично
- ✅ **Рекурсивний пошук**: Шукає .ini файли в підпапках
- ✅ **Копіювання**: Клік → копіювання значення
- ✅ **Масштабування**: Адаптується під розмір UI

## 🎯 Що відображається

### 1. Бейдж на картці персонажа
```
┌─────────┐
│  Anby   │
│  [⌨ 12] │ ← кількість keybinds
└─────────┘
```

### 2. Панель з деталями
```
╔════════════════════════════════╗
║ ⌨ Keybinds                    ║
║                                ║
║ [keySwap]                      ║
║   Key1        VK_F1      📋    ║
║   Key2        VK_F2      📋    ║
║                                ║
║ [KeyUP]                        ║
║   Key         VK_UP      📋    ║
║   Action      jump       📋    ║
╚════════════════════════════════╝
```

## 🔧 Налаштування

### Підтримувані секції (case-insensitive):
- `keyswap`, `keyup`, `keydown`
- `keyleft`, `keyright`, `keypress`
- `keybind`, `keybinds`
- `hotkey`, `hotkeys`

### Формат INI:
```ini
; Коментар (ігнорується)
# Також коментар

[НазваСекції]
Ключ=Значення
Ключ2=Значення2
```

## 🐛 Troubleshooting

### Keybinds не відображаються?

1. ✅ Перевірте що `saveModsPath` налаштований (Settings)
2. ✅ Перевірте що .ini файли існують
3. ✅ Перевірте назви секцій (мають містити ключові слова)
4. ✅ Подивіться консоль на помилки (`IniParserService:`)

### Бейдж не з'являється?

1. ✅ Перевірте що секції мають правильні назви
2. ✅ Перевірте що файл не порожній
3. ✅ Перевірте формат INI (має бути валідний)

## 📝 Приклади використання

### Простий приклад
```ini
[keySwap]
F1=Skin1
F2=Skin2
F3=Skin3
```

### Складний приклад
```ini
[CustomKeybinds]
OpenMenu=VK_M
CloseMenu=VK_ESC
ToggleHUD=VK_H
Screenshot=F12
QuickSave=F5
QuickLoad=F9

[CharacterControls]
Jump=SPACE
Crouch=CTRL
Sprint=SHIFT
Interact=E
```

## 🎨 Кастомізація

### Змінити масштаб keybinds:
```dart
KeybindsWidget(
  keybinds: character.keybinds,
  scaleFactor: 1.2, // Більше = більший розмір
)
```

### Змінити позицію бейджа:
```dart
Positioned(
  bottom: -4,  // Змініть ці значення
  right: -4,
  child: KeybindsBadge(...)
)
```

## 📊 Статистика

- **Код**: ~650 нових рядків
- **Файли**: 3 нові + 4 змінені
- **Компоненти**: 2 UI віджети
- **Сервіси**: 1 парсер + інтеграція

## 🔗 Корисні посилання

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart path package](https://pub.dev/packages/path)
- [INI Format Specification](https://en.wikipedia.org/wiki/INI_file)

---

**Питання?** Дивіться повну документацію в `KEYBINDS_SUMMARY.md`
