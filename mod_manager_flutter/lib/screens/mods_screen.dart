import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as path;
import '../models/character_info.dart';
import '../services/api_service.dart';
import '../utils/state_providers.dart';
import '../utils/zzz_characters.dart';
import '../utils/path_helper.dart';

class ModsScreen extends ConsumerStatefulWidget {
  const ModsScreen({super.key});

  @override
  ConsumerState<ModsScreen> createState() => _ModsScreenState();
}

class _ModsScreenState extends ConsumerState<ModsScreen> {
  bool isLoading = false;
  String? errorMessage;
  Map<String, String> modCharacterTags = {}; // modId -> characterId

  @override
  void initState() {
    super.initState();
    _loadTags();
    loadMods();
  }

  Future<void> _loadTags() async {
    final configService = await ApiService.getConfigService();
    setState(() {
      modCharacterTags = configService.modCharacterTags;
    });
  }

  Future<void> _saveTag(String modId, String characterId) async {
    final configService = await ApiService.getConfigService();
    await configService.setModCharacterTag(modId, characterId);
    setState(() {
      modCharacterTags[modId] = characterId;
    });
  }

  Future<void> loadMods() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedMods = await ApiService.getMods();
      final Map<String, List<ModInfo>> characterMods = {};

      for (var oldMod in loadedMods) {
        // Використовуємо збережений тег або автовизначення
        String charId = modCharacterTags[oldMod.id] ?? 'unknown';
        
        // Якщо тегу немає, пробуємо автовизначити
        if (charId == 'unknown') {
          for (var char in zzzCharacters) {
            if (oldMod.id.toLowerCase().contains(char.toLowerCase()) ||
                oldMod.name.toLowerCase().contains(char.toLowerCase())) {
              charId = char;
              break;
            }
          }
        }

        final localImagePath = path.join(PathHelper.getModImagesPath(), '${oldMod.id}.png');
        final localImageFile = File(localImagePath);
        final imagePath = await localImageFile.exists()
            ? localImagePath
            : oldMod.imagePath;

        final mod = ModInfo(
          id: oldMod.id,
          name: oldMod.name,
          characterId: charId,
          isActive: oldMod.isActive,
          imagePath: imagePath,
        );

        if (!characterMods.containsKey(charId)) {
          characterMods[charId] = [];
        }
        characterMods[charId]!.add(mod);
      }

      final characters = zzzCharacters
          .map((charId) {
            return CharacterInfo(
              id: charId,
              name: getCharacterDisplayName(charId),
              iconPath: 'assets/characters/$charId.png',
              skins: characterMods[charId] ?? [],
            );
          })
          .where((char) => char.skins.isNotEmpty)
          .toList();

      ref.read(charactersProvider.notifier).state = characters;
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> toggleMod(ModInfo mod) async {
    try {
      final wasActive = mod.isActive;
      await ApiService.toggleMod(mod.id);
      await loadMods();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasActive ? 'Деактивовано' : 'Активовано'),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pasteImageFromClipboard(ModInfo mod) async {
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null) {
        // Ensure the directory exists
        await PathHelper.ensureModImagesDirectoryExists();
        final appDir = Directory(PathHelper.getModImagesPath());

        final imagePath = path.join(appDir.path, '${mod.id}.png');
        final file = File(imagePath);
        
        // Видаляємо старе фото якщо існує
        if (await file.exists()) {
          await file.delete();
        }
        
        // Записуємо нове фото
        await file.writeAsBytes(imageBytes);
        
        // Очищаємо кеш зображення
        if (mounted) {
          final imageProvider = FileImage(file);
          await imageProvider.evict();
        }

        await loadMods();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Фото оновлено'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('У буфері немає зображення'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showEditDialog(ModInfo mod) {
    final selectedChar = ValueNotifier<String>(mod.characterId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Mod'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mod.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text('Character Tag:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: selectedChar,
              builder: (context, value, _) {
                return DropdownButtonFormField<String>(
                  value: zzzCharacters.contains(value) ? value : zzzCharacters.first,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: zzzCharacters.map((charId) {
                    return DropdownMenuItem(
                      value: charId,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/characters/$charId.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.person, size: 24, color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(getCharacterDisplayName(charId)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      selectedChar.value = newValue;
                    }
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _saveTag(mod.id, selectedChar.value);
              await loadMods();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tag оновлено'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, ModInfo mod, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () => _showEditDialog(mod));
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.image, size: 18),
              SizedBox(width: 8),
              Text('Додати фото'),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () => _pasteImageFromClipboard(mod));
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(mod.isActive ? Icons.toggle_off : Icons.toggle_on, size: 18),
              const SizedBox(width: 8),
              Text(mod.isActive ? 'Деактивувати' : 'Активувати'),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () => toggleMod(mod));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final characters = ref.watch(charactersProvider);
    final selectedIndex = ref.watch(selectedCharacterIndexProvider);
    final currentSkins = ref.watch(currentCharacterSkinsProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Помилка завантаження', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(errorMessage!, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: loadMods,
              icon: const Icon(Icons.refresh),
              label: const Text('Спробувати знову'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header з вибором персонажа
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Персонажі', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${characters.length}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: characters.isEmpty
                    ? Center(
                        child: Text('Персонажів не знайдено', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: characters.length,
                        itemBuilder: (context, index) {
                          return _buildCharacterCard(characters[index], index, index == selectedIndex);
                        },
                      ),
              ),
            ],
          ),
        ),
        // Моди для вибраного персонажа
        Expanded(
          child: currentSkins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        characters.isEmpty ? 'Завантажте моди' : 'Виберіть персонажа',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      height: 420,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: currentSkins.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildModCard(currentSkins[index]),
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(CharacterInfo character, int index, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedCharacterIndexProvider.notifier).state = index;
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.3),
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, spreadRadius: 2)]
                    : null,
              ),
              child: ClipOval(
                child: character.iconPath != null
                    ? Image.asset(
                        character.iconPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.withOpacity(0.2),
                          child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
                        ),
                      )
                    : Container(
                        color: Colors.grey.withOpacity(0.2),
                        child: Icon(Icons.person, size: 30, color: Colors.grey[600]),
                      ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Text(
                character.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModCard(ModInfo mod) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return GestureDetector(
      onTap: () => toggleMod(mod),
      onSecondaryTapDown: (details) {
        _showContextMenu(context, mod, details.globalPosition);
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: mod.isActive
                ? const Color(0xFF6366F1)
                : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            width: mod.isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: mod.isActive ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: mod.isActive ? 12 : 8,
              spreadRadius: mod.isActive ? 1 : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Зображення моду
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (mod.imagePath != null && File(mod.imagePath!).existsSync())
                      Image.file(
                        File(mod.imagePath!),
                        fit: BoxFit.cover,
                        key: ValueKey(mod.imagePath! + DateTime.now().millisecondsSinceEpoch.toString()),
                        cacheWidth: null,
                        cacheHeight: null,
                      )
                    else
                      Container(
                        color: Colors.grey.withOpacity(0.1),
                        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey[600]),
                      ),
                    // Status indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: mod.isActive
                              ? const Color(0xFF6366F1).withOpacity(0.9)
                              : Colors.grey.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          mod.isActive ? Icons.check : Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Назва моду
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                mod.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
