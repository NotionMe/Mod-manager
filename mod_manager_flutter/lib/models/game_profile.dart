class GameProfile {
  final String id;
  final String name;
  final String hookType;
  final String modsPath;
  final String saveModsPath;
  final List<String> activeMods;
  final List<String> favoriteMods;
  final Map<String, String> modCharacterTags;

  const GameProfile({
    required this.id,
    required this.name,
    required this.modsPath,
    required this.saveModsPath,
    this.hookType = 'zzz',
    List<String>? activeMods,
    List<String>? favoriteMods,
    Map<String, String>? modCharacterTags,
  }) : activeMods = activeMods ?? const [],
       favoriteMods = favoriteMods ?? const [],
       modCharacterTags = modCharacterTags ?? const {};

  GameProfile copyWith({
    String? id,
    String? name,
    String? hookType,
    String? modsPath,
    String? saveModsPath,
    List<String>? activeMods,
    List<String>? favoriteMods,
    Map<String, String>? modCharacterTags,
  }) {
    return GameProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      hookType: hookType ?? this.hookType,
      modsPath: modsPath ?? this.modsPath,
      saveModsPath: saveModsPath ?? this.saveModsPath,
      activeMods: activeMods ?? List<String>.from(this.activeMods),
      favoriteMods: favoriteMods ?? List<String>.from(this.favoriteMods),
      modCharacterTags:
          modCharacterTags ?? Map<String, String>.from(this.modCharacterTags),
    );
  }

  factory GameProfile.fromJson(Map<String, dynamic> json) {
    final active = json['active_mods'];
    final favorites = json['favorite_mods'];
    final tags = json['mod_character_tags'];

    return GameProfile(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Profile',
      hookType: (json['hook_type'] as String? ?? 'zzz').toLowerCase(),
      modsPath: json['mods_path'] as String? ?? '',
      saveModsPath: json['save_mods_path'] as String? ?? '',
      activeMods: active is List ? List<String>.from(active) : const <String>[],
      favoriteMods: favorites is List
          ? List<String>.from(favorites)
          : const <String>[],
      modCharacterTags: tags is Map
          ? Map<String, String>.from(
              tags.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            )
          : const <String, String>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hook_type': hookType,
      'mods_path': modsPath,
      'save_mods_path': saveModsPath,
      'active_mods': activeMods,
      'favorite_mods': favoriteMods,
      'mod_character_tags': modCharacterTags,
    };
  }
}
