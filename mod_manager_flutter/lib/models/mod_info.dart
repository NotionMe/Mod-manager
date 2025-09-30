/// Модель даних для мода
class ModInfo {
  final String id;
  final String name;
  final bool isActive;
  final String? imagePath;

  ModInfo({
    required this.id,
    required this.name,
    required this.isActive,
    this.imagePath,
  });

  factory ModInfo.fromJson(Map<String, dynamic> json) {
    return ModInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
      imagePath: json['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
      'image_path': imagePath,
    };
  }

  ModInfo copyWith({
    String? id,
    String? name,
    bool? isActive,
    String? imagePath,
  }) {
    return ModInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
