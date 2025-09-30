/// Модель даних для персонажа
class CharacterInfo {
  final String id;
  final String name;
  final String? iconPath;
  final List<ModInfo> skins;

  CharacterInfo({
    required this.id,
    required this.name,
    this.iconPath,
    this.skins = const [],
  });

  CharacterInfo copyWith({
    String? id,
    String? name,
    String? iconPath,
    List<ModInfo>? skins,
  }) {
    return CharacterInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      skins: skins ?? this.skins,
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

  ModInfo({
    required this.id,
    required this.name,
    required this.characterId,
    required this.isActive,
    this.imagePath,
    this.description,
  });

  factory ModInfo.fromJson(Map<String, dynamic> json) {
    return ModInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      characterId: json['character_id'] as String? ?? '',
      isActive: json['is_active'] as bool,
      imagePath: json['image_path'] as String?,
      description: json['description'] as String?,
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
    };
  }

  ModInfo copyWith({
    String? id,
    String? name,
    String? characterId,
    bool? isActive,
    String? imagePath,
    String? description,
  }) {
    return ModInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      characterId: characterId ?? this.characterId,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
    );
  }
}
