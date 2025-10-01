import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
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

class _ModsScreenState extends ConsumerState<ModsScreen> with TickerProviderStateMixin {
  bool isLoading = false;
  String? errorMessage;
  Map<String, String> modCharacterTags = {}; // modId -> characterId
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  // Debounce timers to prevent rapid rebuilds
  Timer? _rebuildDebounce;
  Timer? _characterSelectionDebounce;

  // Prevent multiple simultaneous operations
  bool _isOperationInProgress = false;
  bool _isLoadingMods = false;

  // Cache for preventing unnecessary rebuilds
  List<CharacterInfo>? _lastCharactersState;

  @override
  void initState() {
    super.initState();
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeInOut,
    ));
    _loadTags();
    loadMods();
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _rebuildDebounce?.cancel();
    _characterSelectionDebounce?.cancel();
    super.dispose();
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
    
    // Перезавантажуємо моди, щоб оновити UI з новими тегами
    await loadMods();
  }

  Future<void> loadMods() async {
    // Prevent multiple simultaneous load operations
    if (_isLoadingMods) return;
    _isLoadingMods = true;

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

      // Only update state if it actually changed to prevent unnecessary rebuilds
      if (_charactersActuallyChanged(characters)) {
        _lastCharactersState = List.from(characters);
        ref.read(charactersProvider.notifier).state = characters;
      }
      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    } finally {
      _isLoadingMods = false;
    }
  }

  Future<void> toggleMod(ModInfo mod) async {
    // Prevent multiple simultaneous operations
    if (_isOperationInProgress) return;
    _isOperationInProgress = true;

    // Cancel any pending debounce
    _rebuildDebounce?.cancel();

    try {
      final wasActive = mod.isActive;
      final activationMode = ref.read(activationModeProvider);

      // If activating a mod in single mode, deactivate other active mods for this character
      if (!wasActive && activationMode == ActivationMode.single) {
        await _deactivateOtherModsForCharacter(mod.characterId, excludeModId: mod.id);
      }

      await ApiService.toggleMod(mod.id);

      // Longer debounce to prevent rapid blinking - increased to 300ms
      _rebuildDebounce = Timer(const Duration(milliseconds: 300), () async {
        if (mounted) {
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
        }
        _isOperationInProgress = false;
      });
    } catch (e) {
      _isOperationInProgress = false;
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.8 + (_loadingAnimation.value * 0.2),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _loadingAnimation.value,
                  child: Text(
                    'Завантаження модів...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
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
                    const Spacer(),
                    // Mode toggle buttons
                    _buildModeToggle(),
                  ],
                ),
              ),
              Expanded(
                child: characters.isEmpty
                    ? Center(
                        child: Text('Персонажів не знайдено', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      )
                    : AnimationLimiter(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: characters.length,
                          itemBuilder: (context, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildCharacterCard(characters[index], index, index == selectedIndex),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
        // Counter for active mods
        if (currentSkins.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Активні моди',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${currentSkins.where((mod) => mod.isActive).length}/${currentSkins.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
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
                      child: AnimationLimiter(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: currentSkins.length,
                          itemBuilder: (context, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                horizontalOffset: 100.0,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: _buildModCard(currentSkins[index]),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(CharacterInfo character, int index, bool isSelected) {
    return DragTarget<ModInfo>(
      onAcceptWithDetails: (details) async {
        // Показуємо повідомлення про початок обробки
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Збереження тегу...'),
                ],
              ),
              backgroundColor: const Color(0xFF6366F1),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        
        // Зберігаємо тег персонажа для моду
        await _saveTag(details.data.id, character.id);
        
        // Показуємо повідомлення про успішне збереження
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Мод "${details.data.name}" прив\'язано до ${character.name}'),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final bool isHovering = candidateData.isNotEmpty;
        
        return GestureDetector(
          onTap: () {
            // Cancel any pending character selection
            _characterSelectionDebounce?.cancel();
            _characterSelectionDebounce = Timer(const Duration(milliseconds: 250), () {
              if (mounted) {
                ref.read(selectedCharacterIndexProvider.notifier).state = index;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovering 
                          ? const Color(0xFF10B981) 
                          : isSelected 
                              ? const Color(0xFF6366F1) 
                              : Colors.grey.withOpacity(0.3),
                      width: isHovering ? 4 : isSelected ? 3 : 2,
                    ),
                    boxShadow: isHovering
                        ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 16, spreadRadius: 3)]
                        : isSelected
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
                              child: Icon(Icons.person, size: 25, color: Colors.grey[600]),
                            ),
                          )
                        : Container(
                            color: Colors.grey.withOpacity(0.2),
                            child: Icon(Icons.person, size: 25, color: Colors.grey[600]),
                          ),
                  ),
                ),
                if (isSelected || isHovering) ...[
                  const SizedBox(height: 4),
                  Text(
                    character.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isHovering ? const Color(0xFF10B981) : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModCard(ModInfo mod) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return LongPressDraggable<ModInfo>(
      data: mod,
      delay: const Duration(milliseconds: 500), // Затримка 0.5 секунди перед початком drag
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6366F1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: mod.imagePath != null && File(mod.imagePath!).existsSync()
                      ? Image.file(
                          File(mod.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: Colors.grey.withOpacity(0.1),
                          child: Icon(Icons.image_not_supported, size: 32, color: Colors.grey[600]),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  mod.name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildModCardContent(mod, isDarkMode),
      ),
      child: Tooltip(
        message: 'Натисніть та утримуйте для перетягування\nКлікніть для активації',
        child: GestureDetector(
          onTap: () => toggleMod(mod),
          onSecondaryTapDown: (details) {
            _showContextMenu(context, mod, details.globalPosition);
          },
          child: _buildModCardContent(mod, isDarkMode),
        ),
      ),
    );
  }

  Widget _buildModCardContent(ModInfo mod, bool isDarkMode) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
                  // Показуємо тег персонажа, якщо він є
                  if (modCharacterTags.containsKey(mod.id))
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getCharacterName(modCharacterTags[mod.id]!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  String _getCharacterName(String characterId) {
    try {
      final characters = ref.read(charactersProvider);
      final character = characters.firstWhere(
        (char) => char.id == characterId,
      );
      return character.name;
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildModeToggle() {
    final activationMode = ref.watch(activationModeProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          _buildModeButton(
            label: 'Single',
            isActive: activationMode == ActivationMode.single,
            onTap: () {
              // Cancel any pending operations when switching modes
              _rebuildDebounce?.cancel();
              _characterSelectionDebounce?.cancel();
              _isOperationInProgress = false;
              ref.read(activationModeProvider.notifier).state = ActivationMode.single;
            },
          ),
          _buildModeButton(
            label: 'Multi',
            isActive: activationMode == ActivationMode.multi,
            onTap: () {
              // Cancel any pending operations when switching modes
              _rebuildDebounce?.cancel();
              _characterSelectionDebounce?.cancel();
              _isOperationInProgress = false;
              ref.read(activationModeProvider.notifier).state = ActivationMode.multi;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF0EA5E9)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  bool _charactersActuallyChanged(List<CharacterInfo> newCharacters) {
    if (_lastCharactersState == null) return true;
    if (_lastCharactersState!.length != newCharacters.length) return true;

    for (int i = 0; i < newCharacters.length; i++) {
      final oldChar = _lastCharactersState![i];
      final newChar = newCharacters[i];

      if (oldChar.id != newChar.id ||
          oldChar.name != newChar.name ||
          oldChar.skins.length != newChar.skins.length) {
        return true;
      }

      // Check if any mod states changed
      for (int j = 0; j < newChar.skins.length; j++) {
        if (oldChar.skins[j].id != newChar.skins[j].id ||
            oldChar.skins[j].isActive != newChar.skins[j].isActive ||
            oldChar.skins[j].name != newChar.skins[j].name) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> _deactivateOtherModsForCharacter(String characterId, {String? excludeModId}) async {
    try {
      final characters = ref.read(charactersProvider);
      final character = characters.firstWhere(
        (char) => char.id == characterId,
        orElse: () => CharacterInfo(id: '', name: '', iconPath: null, skins: []),
      );

      if (character.id.isNotEmpty) {
        final activeMods = character.skins.where((mod) => mod.isActive && mod.id != excludeModId).toList();
        for (final mod in activeMods) {
          await ApiService.toggleMod(mod.id);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

}
