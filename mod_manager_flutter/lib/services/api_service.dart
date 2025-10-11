import 'dart:ui';
import 'package:mod_manager_flutter/utils/state_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character_info.dart';
import '../models/game_profile.dart';
import 'config_service.dart';
import 'mod_manager_service.dart';

/// API сервіс для роботи з модами
class ApiService {
  static ModManagerService? _modManager;
  static ConfigService? _configService;
  static ProviderContainer? _container;

  static Future<void> initialize({ProviderContainer? container}) async {
    if (_configService == null) {
      final prefs = await SharedPreferences.getInstance();
      _configService = ConfigService(prefs);
      await _configService!.loadFromFile();
    }

    if (container != null) {
      _container = container;
      final localeCode = _configService?.language ?? 'en';
      _container!.read(localeProvider.notifier).state = Locale(localeCode);
    }

    if (_modManager == null) {
      _modManager = ModManagerService(_configService!, _container!);
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

  /// Активує скін для персонажа, автоматично деактивуючи інші скіни цього персонажа
  static Future<bool> toggleModForCharacter(
    String modId,
    String characterId,
    List<ModInfo> characterSkins, {
    bool multiMode = false,
  }) async {
    try {
      await initialize();

      // Знаходимо поточний мод
      final currentMod = characterSkins.firstWhere((mod) => mod.id == modId);

      // Якщо мод вже активний, просто деактивуємо його
      if (currentMod.isActive) {
        return await _modManager!.deactivateMod(modId);
      }

      // У режимі Single - деактивуємо всі інші активні скіни
      if (!multiMode) {
        for (final skin in characterSkins) {
          if (skin.isActive && skin.id != modId) {
            await _modManager!.deactivateMod(skin.id);
          }
        }
      }
      // У режимі Multi - просто додаємо до активних

      // Активуємо новий скін
      return await _modManager!.activateMod(modId);
    } catch (e) {
      throw Exception('Помилка переключення моду для персонажа: $e');
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

  static Future<Map<String, dynamic>> getConfig() async {
    try {
      await initialize();
      return {
        'mods_path': _configService!.modsPath ?? '',
        'save_mods_path': _configService!.saveModsPath ?? '',
        'language': _configService!.language,
        'selected_profile_id': _configService!.selectedProfileId,
        'profiles': _configService!.profiles
            .map((profile) => profile.toJson())
            .toList(),
      };
    } catch (e) {
      throw Exception('Помилка отримання конфігурації: $e');
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    await initialize();
    await _configService!.setLanguage(languageCode);
    _container?.read(localeProvider.notifier).state = Locale(languageCode);
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

  static Future<List<GameProfile>> getProfiles() async {
    await initialize();
    return _configService!.profiles;
  }

  static Future<GameProfile> getCurrentProfile() async {
    await initialize();
    return _configService!.currentProfile;
  }

  static Future<GameProfile> createProfile({
    required String name,
    String hookType = 'custom',
    String modsPath = '',
    String saveModsPath = '',
    bool selectAfterCreate = true,
  }) async {
    await initialize();
    return _configService!.createProfile(
      name: name,
      hookType: hookType,
      modsPath: modsPath,
      saveModsPath: saveModsPath,
      selectAfterCreate: selectAfterCreate,
    );
  }

  static Future<bool> updateProfile({
    required String profileId,
    String? name,
    String? hookType,
    String? modsPath,
    String? saveModsPath,
  }) async {
    await initialize();
    return _configService!.updateProfile(
      profileId: profileId,
      name: name,
      hookType: hookType,
      modsPath: modsPath,
      saveModsPath: saveModsPath,
    );
  }

  static Future<bool> deleteProfile(String profileId) async {
    await initialize();
    return _configService!.deleteProfile(profileId);
  }

  static Future<bool> setActiveProfile(String profileId) async {
    await initialize();
    return _configService!.setSelectedProfile(profileId);
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

  /// Автоматично визначає та встановлює теги для всіх модів
  static Future<Map<String, String>> autoTagAllMods() async {
    try {
      await initialize();
      return await _modManager!.autoTagAllMods();
    } catch (e) {
      throw Exception('Помилка автотегування: $e');
    }
  }

  /// Перевіряє, чи це перший запуск додатку
  static Future<bool> isFirstRun() async {
    await initialize();
    return _configService!.isFirstRun;
  }

  /// Завершує початкове налаштування
  static Future<void> completeFirstRun() async {
    await initialize();
    await _configService!.setFirstRunComplete();
  }
}
