# Інструкція по інтеграції Keybinds

## Що було додано

### 1. Нові файли

1. **lib/models/keybind_info.dart** - Моделі для зберігання keybinds
   - `KeybindInfo` - окремий keybind з секції INI
   - `CharacterKeybinds` - всі keybinds персонажа

2. **lib/services/ini_parser_service.dart** - Крос-платформний парсер INI файлів
   - Парсить INI файли з будь-якої папки
   - Шукає секції з ключовими словами: keyswap, keyup, keydown, keybind тощо
   - Працює рекурсивно, знаходить всі .ini файли

3. **lib/screens/components/keybinds_widget.dart** - UI компоненти
   - `KeybindsWidget` - повний віджет для відображення всіх keybinds
   - `KeybindsBadge` - компактний значок з кількістю keybinds

### 2. Оновлені файли

1. **lib/models/character_info.dart**
   - Додано поле `keybinds` типу `CharacterKeybinds?`
   - Оновлено `copyWith` метод

2. **lib/services/mod_manager_service.dart**
   - Додано `IniParserService _iniParser`
   - Додано методи:
     - `getCharacterKeybinds(characterId)` - keybinds для одного персонажа
     - `getAllCharactersKeybinds()` - keybinds для всіх персонажів
     - `enrichCharactersWithKeybinds(characters)` - додає keybinds до списку персонажів

## Як інтегрувати в mods_screen.dart

### Варіант 1: Відображення keybinds в списку модів

У методі `loadMods()`, після створення списку `characters`, додайте:

```dart
// Перед setState додайте збагачення персонажів keybinds
final modManagerService = await ApiService.getModManagerService();
characters = await modManagerService.enrichCharactersWithKeybinds(characters);
```

### Варіант 2: Відображення keybinds для вибраного персонажа

У методі `build()`, де відображається список модів, додайте після `CharacterCardsListWidget`:

```dart
// Відображення keybinds для вибраного персонажа
final selectedCharacter = characters.isNotEmpty && selectedIndex < characters.length
    ? characters[selectedIndex]
    : null;

if (selectedCharacter?.keybinds != null) {
  KeybindsWidget(
    keybinds: selectedCharacter!.keybinds,
    scaleFactor: scaleFactor,
  ),
}
```

### Варіант 3: Бейдж на картці персонажа

У `character_cards_list_widget.dart`, додайте бейдж в метод `_buildCharacterCard`:

```dart
// Десь в Stack з іконкою персонажа
Positioned(
  bottom: 2,
  right: 2,
  child: KeybindsBadge(
    keybinds: character.keybinds,
    scaleFactor: scaleFactor,
  ),
),
```

### Варіант 4: Повне відображення в окремій секції

```dart
// В Column з основним контентом:
if (selectedCharacter?.keybinds != null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: KeybindsWidget(
      keybinds: selectedCharacter!.keybinds,
      scaleFactor: scaleFactor,
    ),
  ),
```

## Тестування

### 1. Створіть тестові INI файли

В папці `savemods` створіть папку персонажа (наприклад, `anby`) і додайте файл `config.ini`:

```ini
[keySwap]
Key1=VK_F1
Key2=VK_F2
SwapMode=toggle

[KeyUP]
Key=VK_UP
Action=jump
```

### 2. Перезавантажте додаток

- Keybinds мають автоматично з'явитися в UI
- Перевірте що працює копіювання значень при кліку
- Перевірте відображення на різних масштабах UI

## Налагодження

Якщо keybinds не відображаються:

1. Перевірте що INI файли існують в правильних папках
2. Подивіться логи в консолі (починаються з `IniParserService:`)
3. Перевірте що секції в INI мають правильні назви (містять ключові слова)
4. Перевірте що `saveModsPath` правильно налаштований

## Примітки

- Парсер ігнорує коментарі (`;` і `#`)
- Секції case-insensitive
- Підтримуються всі стандартні формати INI
- Крос-платформність забезпечена через використання `path` package
