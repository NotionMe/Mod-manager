import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Сервіс для роботи з конфігурацією додатку
class ConfigService {
  static const String _keyModsPath = 'mods_path';
  static const String _keySaveModsPath = 'save_mods_path';
  static const String _keyActiveMods = 'active_mods';
  static const String _keyTheme = 'theme';
  static const String _keyLanguage = 'language';
  static const String _keyModCharacterTags = 'mod_character_tags';

  final SharedPreferences _prefs;
  File? _configFile;

  ConfigService(this._prefs) {
    _initConfigFile();
  }

  void _initConfigFile() {
    try {
      final configPath = path.join(Directory.current.path, AppConstants.configFileName);
      _configFile = File(configPath);
    } catch (e) {}
  }

  String? get modsPath => _prefs.getString(_keyModsPath);
  String? get saveModsPath => _prefs.getString(_keySaveModsPath);
  List<String> get activeMods => _prefs.getStringList(_keyActiveMods) ?? [];
  String get theme => _prefs.getString(_keyTheme) ?? 'dark-blue';
  String get language => _prefs.getString(_keyLanguage) ?? 'uk';
  
  Map<String, String> get modCharacterTags {
    final json = _prefs.getString(_keyModCharacterTags);
    if (json == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(json));
    } catch (e) {
      return {};
    }
  }

  Future<bool> setModsPath(String path) async {
    try {
      await _prefs.setString(_keyModsPath, path);
      await _saveToFile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setSaveModsPath(String path) async {
    try {
      await _prefs.setString(_keySaveModsPath, path);
      await _saveToFile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setPaths(String modsPath, String saveModsPath) async {
    try {
      await _prefs.setString(_keyModsPath, modsPath);
      await _prefs.setString(_keySaveModsPath, saveModsPath);
      await _saveToFile();
      return true;
    } catch (e) {
      return false;
    }
  }

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
      return false;
    }
  }

  Future<bool> removeActiveMod(String modId) async {
    try {
      final mods = activeMods;
      mods.remove(modId);
      await _prefs.setStringList(_keyActiveMods, mods);
      await _saveToFile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setModCharacterTag(String modId, String characterId) async {
    try {
      final tags = modCharacterTags;
      tags[modId] = characterId;
      await _prefs.setString(_keyModCharacterTags, jsonEncode(tags));
      await _saveToFile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setTheme(String theme) async {
    try {
      await _prefs.setString(_keyTheme, theme);
      await _saveToFile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setLanguage(String language) async {
    try {
      await _prefs.setString(_keyLanguage, language);
      await _saveToFile();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loadFromFile() async {
    try {
      if (_configFile == null || !await _configFile!.exists()) return false;

      final content = await _configFile!.readAsString();
      final Map<String, dynamic> config = jsonDecode(content);

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
      if (config.containsKey('mod_character_tags')) {
        await _prefs.setString(_keyModCharacterTags, jsonEncode(config['mod_character_tags']));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveToFile() async {
    try {
      if (_configFile == null) return false;

      final config = {
        'mods_path': modsPath ?? '',
        'save_mods_path': saveModsPath ?? '',
        'active_mods': activeMods,
        'theme': theme,
        'language': language,
        'mod_character_tags': modCharacterTags,
        'first_run': false,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(config);
      await _configFile!.writeAsString(jsonString);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      await _prefs.clear();
      if (_configFile != null && await _configFile!.exists()) {
        await _configFile!.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
