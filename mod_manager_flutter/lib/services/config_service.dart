import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// Сервіс для роботи з конфігурацією додатку
class ConfigService {
  static const String _keyModsPath = 'mods_path';
  static const String _keySaveModsPath = 'save_mods_path';
  static const String _keyActiveMods = 'active_mods';
  static const String _keyTheme = 'theme';
  static const String _keyLanguage = 'language';

  final SharedPreferences _prefs;
  File? _configFile;

  ConfigService(this._prefs) {
    _initConfigFile();
  }

  /// Ініціалізація файлу конфігурації для додаткового збереження
  void _initConfigFile() {
    try {
      // Зберігаємо конфіг також у JSON файл для сумісності
      final configPath = path.join(Directory.current.path, 'config.json');
      _configFile = File(configPath);
    } catch (e) {
      print('Помилка ініціалізації config файлу: $e');
    }
  }

  /// Отримати шлях до папки з оригінальними модами (SaveMods)
  String? get modsPath => _prefs.getString(_keyModsPath);

  /// Отримати шлях до папки куди створювати links (Mods)
  String? get saveModsPath => _prefs.getString(_keySaveModsPath);

  /// Отримати список активних модів
  List<String> get activeMods => _prefs.getStringList(_keyActiveMods) ?? [];

  /// Отримати тему
  String get theme => _prefs.getString(_keyTheme) ?? 'dark-blue';

  /// Отримати мову
  String get language => _prefs.getString(_keyLanguage) ?? 'uk';

  /// Встановити шлях до папки з модами
  Future<bool> setModsPath(String path) async {
    try {
      await _prefs.setString(_keyModsPath, path);
      await _saveToFile();
      return true;
    } catch (e) {
      print('Помилка збереження mods_path: $e');
      return false;
    }
  }

  /// Встановити шлях до папки SaveMods
  Future<bool> setSaveModsPath(String path) async {
    try {
      await _prefs.setString(_keySaveModsPath, path);
      await _saveToFile();
      return true;
    } catch (e) {
      print('Помилка збереження save_mods_path: $e');
      return false;
    }
  }

  /// Встановити обидва шляхи одразу
  Future<bool> setPaths(String modsPath, String saveModsPath) async {
    try {
      await _prefs.setString(_keyModsPath, modsPath);
      await _prefs.setString(_keySaveModsPath, saveModsPath);
      await _saveToFile();
      return true;
    } catch (e) {
      print('Помилка збереження шляхів: $e');
      return false;
    }
  }

  /// Додати мод до списку активних
  Future<bool> addActiveMod(String modId) async {
    try {
      final mods = activeMods;
      if (!mods.contains(modId)) {
        mods.add(modId);
        await _prefs.setStringList(_keyActiveMods, mods);
        await _saveToFile();
      }
      return true;
    } catch (e) {
      print('Помилка додавання активного моду: $e');
      return false;
    }
  }

  /// Видалити мод зі списку активних
  Future<bool> removeActiveMod(String modId) async {
    try {
      final mods = activeMods;
      mods.remove(modId);
      await _prefs.setStringList(_keyActiveMods, mods);
      await _saveToFile();
      return true;
    } catch (e) {
      print('Помилка видалення активного моду: $e');
      return false;
    }
  }

  /// Встановити тему
  Future<bool> setTheme(String theme) async {
    try {
      await _prefs.setString(_keyTheme, theme);
      await _saveToFile();
      return true;
    } catch (e) {
      print('Помилка збереження теми: $e');
      return false;
    }
  }

  /// Встановити мову
  Future<bool> setLanguage(String language) async {
    try {
      await _prefs.setString(_keyLanguage, language);
      await _saveToFile();
      return true;
    } catch (e) {
      print('Помилка збереження мови: $e');
      return false;
    }
  }

  /// Завантажити конфігурацію з JSON файлу
  Future<bool> loadFromFile() async {
    try {
      if (_configFile == null || !await _configFile!.exists()) {
        print('Config файл не існує');
        return false;
      }

      final content = await _configFile!.readAsString();
      final Map<String, dynamic> config = jsonDecode(content);

      // Завантажуємо дані в SharedPreferences
      if (config.containsKey('mods_path')) {
        await _prefs.setString(_keyModsPath, config['mods_path']);
      }
      if (config.containsKey('save_mods_path')) {
        await _prefs.setString(_keySaveModsPath, config['save_mods_path']);
      }
      if (config.containsKey('active_mods')) {
        final List<String> mods = List<String>.from(config['active_mods']);
        await _prefs.setStringList(_keyActiveMods, mods);
      }
      if (config.containsKey('theme')) {
        await _prefs.setString(_keyTheme, config['theme']);
      }
      if (config.containsKey('language')) {
        await _prefs.setString(_keyLanguage, config['language']);
      }

      print('Конфігурацію завантажено з файлу');
      return true;
    } catch (e) {
      print('Помилка завантаження конфігурації: $e');
      return false;
    }
  }

  /// Зберегти конфігурацію в JSON файл
  Future<bool> _saveToFile() async {
    try {
      if (_configFile == null) return false;

      final config = {
        'mods_path': modsPath ?? '',
        'save_mods_path': saveModsPath ?? '',
        'active_mods': activeMods,
        'theme': theme,
        'language': language,
        'first_run': false,
      };

      final jsonString = JsonEncoder.withIndent('  ').convert(config);
      await _configFile!.writeAsString(jsonString);

      print('Конфігурацію збережено в файл');
      return true;
    } catch (e) {
      print('Помилка збереження конфігурації в файл: $e');
      return false;
    }
  }

  /// Очистити всю конфігурацію
  Future<bool> clear() async {
    try {
      await _prefs.clear();
      if (_configFile != null && await _configFile!.exists()) {
        await _configFile!.delete();
      }
      return true;
    } catch (e) {
      print('Помилка очищення конфігурації: $e');
      return false;
    }
  }
}
