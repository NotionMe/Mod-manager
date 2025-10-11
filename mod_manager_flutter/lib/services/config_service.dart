import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/game_profile.dart';
import '../utils/path_helper.dart';

/// Сервіс для роботи з конфігурацією додатку
class ConfigService {
  static const String _keyModsPath = 'mods_path';
  static const String _keySaveModsPath = 'save_mods_path';
  static const String _keyActiveMods = 'active_mods';
  static const String _keyTheme = 'theme';
  static const String _keyLanguage = 'language';
  static const String _keyModCharacterTags = 'mod_character_tags';
  static const String _keyFavoriteMods = 'favorite_mods';
  static const String _keyFirstRun = 'first_run';
  static const String _keyProfiles = 'profiles';
  static const String _keySelectedProfileId = 'selected_profile_id';
  static const String _defaultProfileId = 'profile_zzz';

  final SharedPreferences _prefs;
  File? _configFile;
  List<GameProfile>? _profilesCache;
  String? _selectedProfileCache;

  ConfigService(this._prefs) {
    _initConfigFile();
  }

  void _initConfigFile() {
    try {
      final appDataPath = PathHelper.getAppDataPath();
      final configPath = path.join(appDataPath, AppConstants.configFileName);
      _configFile = File(configPath);

      // Створюємо директорію якщо її немає
      final dir = Directory(appDataPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    } catch (e) {
      // Fallback на поточну директорію для розробки
      final configPath = path.join(
        Directory.current.path,
        AppConstants.configFileName,
      );
      _configFile = File(configPath);
    }
  }

  List<GameProfile> _getProfilesInternal() {
    if (_profilesCache != null) {
      return List<GameProfile>.from(_profilesCache!);
    }

    final stored = _prefs.getString(_keyProfiles);
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is List) {
          final profiles = decoded
              .whereType<Map>()
              .map((raw) => GameProfile.fromJson(raw.cast<String, dynamic>()))
              .toList();
          if (profiles.isNotEmpty) {
            _profilesCache = profiles;
            return List<GameProfile>.from(profiles);
          }
        }
      } catch (_) {
        // Fall back to legacy profile if parsing fails
      }
    }

    final legacyProfile = _buildLegacyProfile();
    _profilesCache = [legacyProfile];
    _selectedProfileCache ??= legacyProfile.id;
    return [legacyProfile];
  }

  GameProfile _buildLegacyProfile() {
    final legacyActive =
        _prefs.getStringList(_keyActiveMods) ?? const <String>[];
    final legacyFavorites =
        _prefs.getStringList(_keyFavoriteMods) ?? const <String>[];
    final tagsJson = _prefs.getString(_keyModCharacterTags);
    Map<String, String> legacyTags = const <String, String>{};

    if (tagsJson != null && tagsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(tagsJson);
        if (decoded is Map) {
          legacyTags = decoded.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        }
      } catch (_) {
        legacyTags = const <String, String>{};
      }
    }

    final modsPath = _prefs.getString(_keyModsPath) ?? '';
    final saveModsPath = _prefs.getString(_keySaveModsPath) ?? '';

    return GameProfile(
      id: _defaultProfileId,
      name: 'Zenless Zone Zero',
      hookType: 'zzz',
      modsPath: modsPath,
      saveModsPath: saveModsPath,
      activeMods: List<String>.from(legacyActive),
      favoriteMods: List<String>.from(legacyFavorites),
      modCharacterTags: Map<String, String>.from(legacyTags),
    );
  }

  String _resolveSelectedProfileId(List<GameProfile> profiles) {
    final storedId =
        _selectedProfileCache ?? _prefs.getString(_keySelectedProfileId);
    if (storedId != null && profiles.any((profile) => profile.id == storedId)) {
      _selectedProfileCache = storedId;
      return storedId;
    }

    final fallbackId = profiles.isNotEmpty
        ? profiles.first.id
        : _defaultProfileId;
    _selectedProfileCache = fallbackId;
    return fallbackId;
  }

  Future<void> _persistProfiles(
    List<GameProfile> profiles, {
    String? selectedProfileId,
  }) async {
    if (profiles.isEmpty) {
      throw ArgumentError('Profiles list cannot be empty');
    }

    final selectedId = selectedProfileId ?? _resolveSelectedProfileId(profiles);
    final normalizedProfiles = List<GameProfile>.from(profiles);
    _profilesCache = normalizedProfiles;
    _selectedProfileCache = selectedId;

    final profilesJson = jsonEncode(
      normalizedProfiles.map((profile) => profile.toJson()).toList(),
    );

    await _prefs.setString(_keyProfiles, profilesJson);
    await _prefs.setString(_keySelectedProfileId, selectedId);

    final current = normalizedProfiles.firstWhere(
      (profile) => profile.id == selectedId,
      orElse: () => normalizedProfiles.first,
    );

    await _prefs.setString(_keyModsPath, current.modsPath);
    await _prefs.setString(_keySaveModsPath, current.saveModsPath);
    await _prefs.setStringList(_keyActiveMods, current.activeMods);
    await _prefs.setStringList(_keyFavoriteMods, current.favoriteMods);
    await _prefs.setString(
      _keyModCharacterTags,
      jsonEncode(current.modCharacterTags),
    );

    await _saveToFile();
  }

  int _currentProfileIndex(List<GameProfile> profiles, String selectedId) {
    final index = profiles.indexWhere((profile) => profile.id == selectedId);
    return index == -1 ? 0 : index;
  }

  String _generateProfileId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return 'profile_$timestamp';
  }

  Future<bool> _updateCurrentProfile(
    GameProfile Function(GameProfile current) updater,
  ) async {
    try {
      final profiles = _getProfilesInternal();
      final selectedId = selectedProfileId;
      final index = _currentProfileIndex(profiles, selectedId);
      final updatedProfile = updater(profiles[index]);
      profiles[index] = updatedProfile;
      await _persistProfiles(profiles, selectedProfileId: selectedId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<GameProfile> createProfile({
    required String name,
    String hookType = 'custom',
    String modsPath = '',
    String saveModsPath = '',
    bool selectAfterCreate = true,
  }) async {
    final profiles = _getProfilesInternal();
    final newProfile = GameProfile(
      id: _generateProfileId(),
      name: name,
      hookType: hookType.toLowerCase(),
      modsPath: modsPath,
      saveModsPath: saveModsPath,
    );

    profiles.add(newProfile);
    final selectedId = selectAfterCreate ? newProfile.id : selectedProfileId;
    await _persistProfiles(profiles, selectedProfileId: selectedId);
    return newProfile;
  }

  Future<bool> updateProfile({
    required String profileId,
    String? name,
    String? hookType,
    String? modsPath,
    String? saveModsPath,
    List<String>? activeMods,
    List<String>? favoriteMods,
    Map<String, String>? modCharacterTags,
  }) async {
    try {
      final profiles = _getProfilesInternal();
      final index = profiles.indexWhere((profile) => profile.id == profileId);
      if (index == -1) {
        return false;
      }

      profiles[index] = profiles[index].copyWith(
        name: name,
        hookType: hookType?.toLowerCase(),
        modsPath: modsPath,
        saveModsPath: saveModsPath,
        activeMods: activeMods,
        favoriteMods: favoriteMods,
        modCharacterTags: modCharacterTags,
      );

      final selectedId = profileId == selectedProfileId
          ? profileId
          : selectedProfileId;
      await _persistProfiles(profiles, selectedProfileId: selectedId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProfile(String profileId) async {
    final profiles = _getProfilesInternal();
    if (profiles.length <= 1) {
      return false;
    }

    final index = profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) {
      return false;
    }

    profiles.removeAt(index);
    final newSelectedId = profileId == selectedProfileId
        ? profiles.first.id
        : selectedProfileId;
    await _persistProfiles(profiles, selectedProfileId: newSelectedId);
    return true;
  }

  Future<bool> setSelectedProfile(String profileId) async {
    final profiles = _getProfilesInternal();
    if (!profiles.any((profile) => profile.id == profileId)) {
      return false;
    }

    await _persistProfiles(profiles, selectedProfileId: profileId);
    return true;
  }

  List<GameProfile> get profiles => List.unmodifiable(_getProfilesInternal());

  GameProfile get currentProfile {
    final profiles = _getProfilesInternal();
    final selectedId = selectedProfileId;
    final index = _currentProfileIndex(profiles, selectedId);
    return profiles[index];
  }

  String get selectedProfileId =>
      _selectedProfileCache ??
      _resolveSelectedProfileId(_getProfilesInternal());

  String? get modsPath {
    final pathValue = currentProfile.modsPath;
    return pathValue.isEmpty ? null : pathValue;
  }

  String? get saveModsPath {
    final pathValue = currentProfile.saveModsPath;
    return pathValue.isEmpty ? null : pathValue;
  }

  List<String> get activeMods => List<String>.from(currentProfile.activeMods);
  List<String> get favoriteMods =>
      List<String>.from(currentProfile.favoriteMods);
  String get theme => _prefs.getString(_keyTheme) ?? 'dark-blue';
  String get language => _prefs.getString(_keyLanguage) ?? 'en';
  bool get isFirstRun => _prefs.getBool(_keyFirstRun) ?? true;

  Map<String, String> get modCharacterTags =>
      Map<String, String>.from(currentProfile.modCharacterTags);

  Future<bool> setModsPath(String path) async {
    return await _updateCurrentProfile(
      (profile) => profile.copyWith(modsPath: path),
    );
  }

  Future<bool> setSaveModsPath(String path) async {
    return await _updateCurrentProfile(
      (profile) => profile.copyWith(saveModsPath: path),
    );
  }

  Future<bool> setPaths(String modsPath, String saveModsPath) async {
    return await _updateCurrentProfile(
      (profile) =>
          profile.copyWith(modsPath: modsPath, saveModsPath: saveModsPath),
    );
  }

  Future<bool> addActiveMod(String modId) async {
    return await _updateCurrentProfile((profile) {
      if (profile.activeMods.contains(modId)) {
        return profile;
      }
      final updated = List<String>.from(profile.activeMods)..add(modId);
      return profile.copyWith(activeMods: updated);
    });
  }

  Future<bool> addFavoriteMod(String modId) async {
    return await _updateCurrentProfile((profile) {
      if (profile.favoriteMods.contains(modId)) {
        return profile;
      }
      final updated = List<String>.from(profile.favoriteMods)..add(modId);
      return profile.copyWith(favoriteMods: updated);
    });
  }

  Future<bool> removeFavoriteMod(String modId) async {
    return await _updateCurrentProfile((profile) {
      final updated = List<String>.from(profile.favoriteMods)..remove(modId);
      return profile.copyWith(favoriteMods: updated);
    });
  }

  Future<bool> removeActiveMod(String modId) async {
    return await _updateCurrentProfile((profile) {
      final updated = List<String>.from(profile.activeMods)..remove(modId);
      return profile.copyWith(activeMods: updated);
    });
  }

  Future<bool> setModCharacterTag(String modId, String characterId) async {
    return await _updateCurrentProfile((profile) {
      final tags = Map<String, String>.from(profile.modCharacterTags);
      tags[modId] = characterId;
      return profile.copyWith(modCharacterTags: tags);
    });
  }

  Future<bool> removeModCharacterTag(String modId) async {
    return await _updateCurrentProfile((profile) {
      final tags = Map<String, String>.from(profile.modCharacterTags);
      tags.remove(modId);
      return profile.copyWith(modCharacterTags: tags);
    });
  }

  /// Очищає теги для модів, які більше не існують
  Future<void> cleanupInvalidTags(List<String> validModIds) async {
    try {
      final tags = Map<String, String>.from(currentProfile.modCharacterTags);
      final keysToRemove = <String>[];

      for (final modId in tags.keys) {
        if (!validModIds.contains(modId)) {
          keysToRemove.add(modId);
        }
      }

      if (keysToRemove.isEmpty) {
        return;
      }

      for (final key in keysToRemove) {
        tags.remove(key);
      }

      await _updateCurrentProfile(
        (profile) => profile.copyWith(modCharacterTags: tags),
      );
    } catch (_) {
      // Ігноруємо помилки
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

  Future<bool> setFirstRunComplete() async {
    try {
      await _prefs.setBool(_keyFirstRun, false);
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

      var profilesLoaded = false;

      if (config.containsKey('profiles')) {
        final rawProfiles = config['profiles'];
        if (rawProfiles is List) {
          final parsedProfiles = rawProfiles
              .whereType<Map>()
              .map(
                (raw) =>
                    GameProfile.fromJson(Map<String, dynamic>.from(raw as Map)),
              )
              .toList();

          if (parsedProfiles.isNotEmpty) {
            final selectedId = config['selected_profile_id'] as String?;
            await _persistProfiles(
              parsedProfiles,
              selectedProfileId: selectedId,
            );
            profilesLoaded = true;
          }
        }
      }

      if (!profilesLoaded) {
        final modsPath = config['mods_path'] as String? ?? '';
        final saveModsPath = config['save_mods_path'] as String? ?? '';
        final activeMods = config['active_mods'] is List
            ? List<String>.from(config['active_mods'] as List)
            : const <String>[];
        final favoriteMods = config['favorite_mods'] is List
            ? List<String>.from(config['favorite_mods'] as List)
            : const <String>[];
        final tags = config['mod_character_tags'] is Map
            ? Map<String, String>.from(
                (config['mod_character_tags'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                ),
              )
            : const <String, String>{};

        final legacyProfile = GameProfile(
          id: _defaultProfileId,
          name: config['profile_name'] as String? ?? 'Zenless Zone Zero',
          hookType: (config['hook_type'] as String? ?? 'zzz').toLowerCase(),
          modsPath: modsPath,
          saveModsPath: saveModsPath,
          activeMods: List<String>.from(activeMods),
          favoriteMods: List<String>.from(favoriteMods),
          modCharacterTags: Map<String, String>.from(tags),
        );

        await _persistProfiles(
          [legacyProfile],
          selectedProfileId:
              config['selected_profile_id'] as String? ?? legacyProfile.id,
        );
      }

      if (config.containsKey('theme')) {
        await _prefs.setString(_keyTheme, config['theme']);
      }
      if (config.containsKey('language')) {
        await _prefs.setString(_keyLanguage, config['language']);
      }
      if (config.containsKey('first_run')) {
        await _prefs.setBool(_keyFirstRun, config['first_run']);
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
        'selected_profile_id': selectedProfileId,
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
        'mods_path': modsPath ?? '',
        'save_mods_path': saveModsPath ?? '',
        'active_mods': activeMods,
        'favorite_mods': favoriteMods,
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
      _profilesCache = null;
      _selectedProfileCache = null;
      if (_configFile != null && await _configFile!.exists()) {
        await _configFile!.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
