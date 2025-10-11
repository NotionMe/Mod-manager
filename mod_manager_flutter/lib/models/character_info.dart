import 'keybind_info.dart';

/// Модель даних для персонажа
class CharacterInfo {
  final String id;
  final String name;
  final String? iconPath;
  final List<ModInfo> skins;
  final CharacterKeybinds? keybinds;

  CharacterInfo({
    required this.id,
    required this.name,
    this.iconPath,
    this.skins = const [],
    this.keybinds,
  });

  CharacterInfo copyWith({
    String? id,
    String? name,
    String? iconPath,
    List<ModInfo>? skins,
    CharacterKeybinds? keybinds,
  }) {
    return CharacterInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      skins: skins ?? this.skins,
      keybinds: keybinds ?? this.keybinds,
    );
  }
}

/// Модель даних для скіна персонажа
class ModInfo {
  final String id;
  final String name;
  final String characterId;
  final bool isActive;
  final String? imagePath;
  final String? description;
  final bool isFavorite;
  final List<KeybindInfo>? keybinds;

  ModInfo({
    required this.id,
    required this.name,
    required this.characterId,
    required this.isActive,
    this.imagePath,
    this.description,
    this.isFavorite = false,
    this.keybinds,
  });

  factory ModInfo.fromJson(Map<String, dynamic> json) {
    return ModInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      characterId: json['character_id'] as String? ?? '',
      isActive: json['is_active'] as bool,
      imagePath: json['image_path'] as String?,
      description: json['description'] as String?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      keybinds: json['keybinds'] != null
          ? (json['keybinds'] as List)
                .map((e) => KeybindInfo.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'character_id': characterId,
      'is_active': isActive,
      'image_path': imagePath,
      'description': description,
      'is_favorite': isFavorite,
      'keybinds': keybinds?.map((e) => e.toJson()).toList(),
    };
  }

  ModInfo copyWith({
    String? id,
    String? name,
    String? characterId,
    bool? isActive,
    String? imagePath,
    String? description,
    bool? isFavorite,
    List<KeybindInfo>? keybinds,
  }) {
    return ModInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      characterId: characterId ?? this.characterId,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      keybinds: keybinds ?? this.keybinds,
    );
  }
}
