import 'package:shared_preferences/shared_preferences.dart';
import '../models/character_info.dart';
import 'config_service.dart';
import 'mod_manager_service.dart';

/// API сервіс для роботи з модами
class ApiService {
  static ModManagerService? _modManager;
  static ConfigService? _configService;

  static Future<void> initialize() async {
    if (_configService == null) {
      final prefs = await SharedPreferences.getInstance();
      _configService = ConfigService(prefs);
      await _configService!.loadFromFile();
    }

    if (_modManager == null) {
      _modManager = ModManagerService(_configService!);
    }
  }

  static Future<List<ModInfo>> getMods() async {
    try {
      await initialize();
      return await _modManager!.getModsInfo();
    } catch (e) {
      throw Exception('Помилка отримання модів: $e');
    }
  }

  static Future<bool> toggleMod(String modId) async {
    try {
      await initialize();
      return await _modManager!.toggleMod(modId);
    } catch (e) {
      throw Exception('Помилка переключення моду: $e');
    }
  }

  static Future<String> clearAll() async {
    try {
      await initialize();
      final mods = await _modManager!.getModsInfo();
      int deactivated = 0;

      for (final mod in mods) {
        if (mod.isActive) {
          await _modManager!.deactivateMod(mod.id);
          deactivated++;
        }
      }

      return 'Деактивовано $deactivated модів';
    } catch (e) {
      throw Exception('Помилка очищення: $e');
    }
  }

  static Future<Map<String, String>> getConfig() async {
    try {
      await initialize();
      return {
        'mods_path': _configService!.modsPath ?? '',
        'save_mods_path': _configService!.saveModsPath ?? '',
      };
    } catch (e) {
      throw Exception('Помилка отримання конфігурації: $e');
    }
  }

  static Future<String> updateConfig({
    required String modsPath,
    required String saveModsPath,
  }) async {
    try {
      await initialize();
      await _configService!.setPaths(modsPath, saveModsPath);
      return 'Конфігурацію збережено';
    } catch (e) {
      throw Exception('Помилка оновлення конфігурації: $e');
    }
  }

  static Future<bool> updateMod(ModInfo mod) async {
    try {
      return true;
    } catch (e) {
      throw Exception('Помилка оновлення моду: $e');
    }
  }

  static Future<ConfigService> getConfigService() async {
    await initialize();
    return _configService!;
  }

  static Future<ModManagerService> getModManagerService() async {
    await initialize();
    return _modManager!;
  }
}
