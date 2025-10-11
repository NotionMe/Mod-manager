import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/keybind_info.dart';

/// Крос-платформний сервіс для парсингу INI файлів
/// Працює як на Windows, так і на Linux
class IniParserService {
  /// Регулярний вираз для знаходження секцій (напр. [keySwap], [KeyUP])
  static final RegExp _sectionRegex = RegExp(r'^\[([^\]]+)\]$');

  /// Регулярний вираз для знаходження пар ключ=значення
  static final RegExp _keyValueRegex = RegExp(r'^([^=]+)=(.*)$');

  /// Список типових назв секцій з keybinds (case-insensitive)
  static const List<String> keybindSections = [
    'keyswap',
    'keyup',
    'keydown',
    'keyleft',
    'keyright',
    'keypress',
    'keybind',
    'keybinds',
    'hotkey',
    'hotkeys',
  ];

  /// Парсить INI файл і повертає список keybinds
  /// Шукає секції, що містять в назві ключові слова для keybinds
  Future<List<KeybindInfo>> parseIniFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return [];
      }

      final lines = await file.readAsLines();
      final keybinds = <KeybindInfo>[];
      String? currentSection;
      final currentKeys = <String, String>{};

      for (var line in lines) {
        // Видаляємо пробіли на початку та в кінці
        line = line.trim();

        // Пропускаємо порожні рядки та коментарі
        if (line.isEmpty || line.startsWith(';') || line.startsWith('#')) {
          continue;
        }

        // Перевіряємо чи це секція
        final sectionMatch = _sectionRegex.firstMatch(line);
        if (sectionMatch != null) {
          // Зберігаємо попередню секцію якщо вона була keybind-секцією
          if (currentSection != null && _isKeybindSection(currentSection)) {
            if (currentKeys.isNotEmpty) {
              keybinds.add(
                KeybindInfo(
                  section: currentSection,
                  keys: Map.from(currentKeys),
                ),
              );
              currentKeys.clear();
            }
          }

          // Починаємо нову секцію
          currentSection = sectionMatch.group(1);
          continue;
        }

        // Перевіряємо чи це пара ключ=значення
        final keyValueMatch = _keyValueRegex.firstMatch(line);
        if (keyValueMatch != null && currentSection != null) {
          final key = keyValueMatch.group(1)?.trim() ?? '';
          final value = keyValueMatch.group(2)?.trim() ?? '';

          if (key.isNotEmpty) {
            currentKeys[key] = value;
          }
        }
      }

      // Зберігаємо останню секцію якщо вона була keybind-секцією
      if (currentSection != null && _isKeybindSection(currentSection)) {
        if (currentKeys.isNotEmpty) {
          keybinds.add(
            KeybindInfo(section: currentSection, keys: Map.from(currentKeys)),
          );
        }
      }

      return keybinds;
    } catch (e) {
      print('IniParserService: Помилка парсингу INI файлу $filePath: $e');
      return [];
    }
  }

  /// Перевіряє чи є секція keybind-секцією
  /// Ловить всі секції що починаються з "Key" або містять ключові слова
  bool _isKeybindSection(String sectionName) {
    final lowerSection = sectionName.toLowerCase();
    // Перевіряємо чи секція починається з "key" (наприклад [KeyHair], [KeyLegs])
    if (lowerSection.startsWith('key')) {
      return true;
    }
    // Або містить ключові слова
    return keybindSections.any((keyword) => lowerSection.contains(keyword));
  }

  /// Шукає всі INI файли в вказаній директорії (рекурсивно)
  Future<List<String>> findIniFiles(String directoryPath) async {
    try {
      final dir = Directory(directoryPath);
      if (!await dir.exists()) {
        print('IniParserService: Директорія не існує: $directoryPath');
        return [];
      }

      final iniFiles = <String>[];

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.ini')) {
          print('IniParserService: Знайдено INI файл: ${entity.path}');
          iniFiles.add(entity.path);
        }
      }

      print(
        'IniParserService: Знайдено ${iniFiles.length} INI файлів в $directoryPath',
      );
      return iniFiles;
    } catch (e) {
      print('IniParserService: Помилка пошуку INI файлів в $directoryPath: $e');
      return [];
    }
  }

  /// Парсить всі INI файли в директорії персонажа
  /// Повертає об'єкт CharacterKeybinds з усіма знайденими keybinds
  Future<CharacterKeybinds?> parseCharacterDirectory(
    String characterId,
    String directoryPath,
  ) async {
    try {
      final iniFiles = await findIniFiles(directoryPath);
      if (iniFiles.isEmpty) {
        return null;
      }

      final allKeybinds = <KeybindInfo>[];

      for (final iniFile in iniFiles) {
        final keybinds = await parseIniFile(iniFile);
        allKeybinds.addAll(keybinds);
      }

      if (allKeybinds.isEmpty) {
        return null;
      }

      return CharacterKeybinds(
        characterId: characterId,
        keybinds: allKeybinds,
        iniFilePath:
            iniFiles.first, // Зберігаємо шлях до першого знайденого файлу
      );
    } catch (e) {
      print('IniParserService: Помилка парсингу директорії $directoryPath: $e');
      return null;
    }
  }

  /// Парсить INI файли для всіх персонажів в savemods
  /// Повертає мапу characterId -> CharacterKeybinds
  Future<Map<String, CharacterKeybinds>> parseAllCharacters(
    String saveModsPath,
  ) async {
    try {
      final saveModsDir = Directory(saveModsPath);
      if (!await saveModsDir.exists()) {
        print('IniParserService: saveModsPath не існує: $saveModsPath');
        return {};
      }

      final characterKeybinds = <String, CharacterKeybinds>{};
      print('IniParserService: Сканування $saveModsPath для keybinds...');

      await for (final entity in saveModsDir.list()) {
        if (entity is Directory) {
          final characterId = path.basename(entity.path);

          // Пропускаємо системні папки
          if (characterId.startsWith('.') || characterId.startsWith('__')) {
            continue;
          }

          print('IniParserService: Перевірка папки $characterId...');
          final keybinds = await parseCharacterDirectory(
            characterId,
            entity.path,
          );

          if (keybinds != null) {
            print(
              'IniParserService: Знайдено ${keybinds.keybinds.length} keybinds для $characterId',
            );
            characterKeybinds[characterId] = keybinds;
          } else {
            print('IniParserService: INI файлів не знайдено в $characterId');
          }
        }
      }

      print(
        'IniParserService: Загалом знайдено keybinds для ${characterKeybinds.length} папок',
      );
      return characterKeybinds;
    } catch (e) {
      print(
        'IniParserService: Помилка парсингу всіх персонажів в $saveModsPath: $e',
      );
      return {};
    }
  }
}
