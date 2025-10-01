import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as path;
import '../models/character_info.dart';
import '../services/api_service.dart';
import '../utils/state_providers.dart';
import '../utils/zzz_characters.dart';

class ModsScreen extends ConsumerStatefulWidget {
  const ModsScreen({super.key});

  @override
  ConsumerState<ModsScreen> createState() => _ModsScreenState();
}

class _ModsScreenState extends ConsumerState<ModsScreen> {
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadMods();
  }

  Future<void> loadMods() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final loadedMods = await ApiService.getMods();
      print('📦 Завантажено модів: ${loadedMods.length}');

      final Map<String, List<ModInfo>> characterMods = {};
      for (var oldMod in loadedMods) {
        String charId = 'unknown';
        for (var char in zzzCharacters) {
          if (oldMod.id.toLowerCase().contains(char.toLowerCase()) ||
              oldMod.name.toLowerCase().contains(char.toLowerCase())) {
            charId = char;
            break;
          }
        }
        print('  🎭 Мод: ${oldMod.name} -> персонаж: $charId');

        // Перевіряємо, чи є локальне зображення
        final localImagePath = '../assets/mod_images/${oldMod.id}.png';
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

      print('👥 Персонажів з модами: ${characters.length}');
      for (final char in characters) {
        print('  ${char.name}: ${char.skins.length} модів');
      }

      ref.read(charactersProvider.notifier).state = characters;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> toggleMod(ModInfo mod) async {
    try {
      // Зберігаємо старий стан ДО переключення
      final wasActive = mod.isActive;

      await ApiService.toggleMod(mod.id);
      await loadMods();

      if (mounted) {
        // Показуємо повідомлення на основі СТАРОГО стану (що було зроблено)
        final message = wasActive ? 'Деактивовано' : 'Активовано';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 1),
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
        // Використовуємо відносний шлях до папки в кореневій директорії проекту
        final appDir = Directory('../assets/mod_images');
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }

        final imagePath = path.join(appDir.path, '${mod.id}.png');
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        print('Image saved to: ${file.path}');
        print('File exists: ${await file.exists()}');
        print('File size: ${await file.length()} bytes');

        // Асинхронно оновлюємо всі моди з новим шляхом
        await loadMods();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Зображення збережено та оновлено'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('У буфері обміну немає зображення'),
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
      print('Error pasting image: $e');
    }
  }

  void _showContextMenu(
    BuildContext context,
    ModInfo mod,
    Offset position,
    double sss,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.image, size: 18 * sss),
              SizedBox(width: 8 * sss),
              Text(
                'Додати фото з буфера',
                style: GoogleFonts.poppins(fontSize: 13 * sss),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              _pasteImageFromClipboard(mod);
            });
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                mod.isActive ? Icons.toggle_off : Icons.toggle_on,
                size: 18 * sss,
              ),
              SizedBox(width: 8 * sss),
              Text(
                mod.isActive ? 'Деактивувати' : 'Активувати',
                style: GoogleFonts.poppins(fontSize: 13 * sss),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              toggleMod(mod);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sss = ref.watch(zoomScaleProvider);
    final characters = ref.watch(charactersProvider);
    final selectedIndex = ref.watch(selectedCharacterIndexProvider);
    final currentSkins = ref.watch(currentCharacterSkinsProvider);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64 * sss, color: Colors.red),
            SizedBox(height: 16 * sss),
            Text(errorMessage!, style: GoogleFonts.poppins(fontSize: 14 * sss)),
            SizedBox(height: 16 * sss),
            ElevatedButton(
              onPressed: loadMods,
              child: Text(
                'Спробувати знову',
                style: GoogleFonts.poppins(fontSize: 13 * sss),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 90 * sss),
      child: Column(
        children: [
          Container(
            height: 130 * sss,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
            ),
            child: Center(
              child: characters.isEmpty
                  ? Text(
                      'Персонажів не знайдено',
                      style: GoogleFonts.poppins(
                        fontSize: 14 * sss,
                        color: Colors.grey,
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(
                        horizontal: 15 * sss,
                        vertical: 10 * sss,
                      ),
                      itemCount: characters.length,
                      itemBuilder: (context, index) {
                        return _buildCharacterCard(
                          characters[index],
                          index,
                          index == selectedIndex,
                          sss,
                        );
                      },
                    ),
            ),
          ),
          Expanded(
            child: currentSkins.isEmpty
                ? Center(
                    child: Text(
                      characters.isEmpty
                          ? 'Завантажте моди'
                          : 'Виберіть персонажа',
                      style: GoogleFonts.poppins(
                        fontSize: 18 * sss,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : _buildSkinsGrid(currentSkins, sss),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(
    CharacterInfo character,
    int index,
    bool isSelected,
    double sss,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedCharacterIndexProvider.notifier).state = index;
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8 * sss),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Кругла аватарка з рамкою
            Container(
              width: 80 * sss,
              height: 80 * sss,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.9)
                      : Colors.white.withOpacity(0.3),
                  width: isSelected ? 4 : 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: character.iconPath != null
                    ? Image.asset(
                        character.iconPath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.withOpacity(0.3),
                            child: Icon(
                              Icons.person,
                              size: 40 * sss,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey.withOpacity(0.3),
                        child: Icon(
                          Icons.person,
                          size: 40 * sss,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: 8 * sss),
              Text(
                character.name,
                style: GoogleFonts.poppins(
                  fontSize: 12 * sss,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkinsGrid(List<ModInfo> skins, double sss) {
    return Center(
      child: Container(
        height: 450 * sss,
        alignment: Alignment.center,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20 * sss),
          itemCount: skins.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * sss),
              child: _buildSkinCard(skins[index], sss),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkinCard(ModInfo skin, double sss) {
    return GestureDetector(
      onTap: () => toggleMod(skin),
      onSecondaryTapDown: (details) {
        _showContextMenu(context, skin, details.globalPosition, sss);
      },
      child: SizedBox(
        width: 240 * sss,
        height: 360 * sss,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20 * sss),
            border: Border.all(
              color: skin.isActive
                  ? Colors.blue.withOpacity(0.9)
                  : Colors.white.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: skin.isActive
                    ? Colors.blue.withOpacity(0.4)
                    : Colors.black.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17 * sss),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (skin.imagePath != null &&
                    File(skin.imagePath!).existsSync())
                  Image.file(File(skin.imagePath!), fit: BoxFit.cover)
                else
                  Container(
                    color: Colors.grey.shade800,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 60 * sss,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(12 * sss),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.95),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skin.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13 * sss,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (skin.description != null &&
                            skin.description!.isNotEmpty) ...[
                          SizedBox(height: 4 * sss),
                          Text(
                            skin.description!,
                            style: GoogleFonts.poppins(
                              fontSize: 10 * sss,
                              color: Colors.grey.shade300,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10 * sss,
                  right: 10 * sss,
                  child: Container(
                    padding: EdgeInsets.all(8 * sss),
                    decoration: BoxDecoration(
                      color: skin.isActive
                          ? Colors.green.withOpacity(0.9)
                          : Colors.grey.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      skin.isActive ? Icons.check : Icons.close,
                      size: 18 * sss,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
