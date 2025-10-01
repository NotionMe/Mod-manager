import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/constants.dart';
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
  
  // Animation controller for mode toggle liquid effect
  late AnimationController _modeToggleAnimationController;
  late Animation<double> _modeToggleAnimation;

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
    
    // Initialize liquid animation controller
    _modeToggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _modeToggleAnimation = CurvedAnimation(
      parent: _modeToggleAnimationController,
      curve: Curves.easeInOutCubic,
    );
    
    _loadTags();
    loadMods();
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _modeToggleAnimationController.dispose();
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

      // Longer debounce to prevent rapid blinking
      _rebuildDebounce = Timer(AppConstants.modToggleDebounceDelay, () async {
        if (mounted) {
          await loadMods();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(wasActive ? 'Деактивовано' : 'Активовано'),
                duration: AppConstants.snackBarDuration,
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

  Future<void> _reloadMods() async {
    if (_isOperationInProgress) return;
    
    setState(() {
      _isOperationInProgress = true;
    });

    try {
      final modManagerService = await ref.read(modManagerServiceProvider.future);
      final success = await modManagerService.reloadMods();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(success ? 'Моди перезавантажені (F10)' : 'Помилка перезавантаження'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            width: 300,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
    }
  }

  Widget _buildF10ReloadButton() {
    return Tooltip(
      message: 'Перезавантажити моди (F10)',
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isOperationInProgress ? null : _reloadMods,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _isOperationInProgress ? 1 : 0,
                    duration: const Duration(milliseconds: 1000),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'F10',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  children: [
                    Text('Персонажі', style: TextStyle(fontSize: AppConstants.headerTextSize, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.smallPadding,
                        vertical: AppConstants.tinyPadding,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(AppConstants.activeModBorderColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.smallPadding),
                      ),
                      child: Text(
                        '${characters.length}',
                        style: TextStyle(
                          fontSize: AppConstants.captionTextSize,
                          color: const Color(AppConstants.activeModBorderColor),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // F10 Reload button
                    _buildF10ReloadButton(),
                    const SizedBox(width: 12),
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
                          padding: EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                          itemCount: characters.length,
                          itemBuilder: (context, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: AppConstants.fastAnimationDuration,
                              child: SlideAnimation(
                                horizontalOffset: 30.0,
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
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            child: Row(
              children: [
                Text(
                  'Активні моди',
                  style: TextStyle(
                    fontSize: AppConstants.titleTextSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: AppConstants.smallMargin),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.smallPadding,
                    vertical: AppConstants.tinyPadding,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.activeModCountColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.smallPadding),
                  ),
                  child: Text(
                    '${currentSkins.where((mod) => mod.isActive).length}/${currentSkins.length}',
                    style: TextStyle(
                      fontSize: AppConstants.captionTextSize,
                      color: const Color(AppConstants.activeModCountColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Моди для вибраного персонажа
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Для старого контенту (що виходить)
              final isOldWidget = child.key != ValueKey('character_${selectedIndex}_${currentSkins.length}') && 
                                  child.key != const ValueKey('empty');
              
              // Старий контент йде вліво
              final outOffset = Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-1.0, 0),
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInCubic,
              ));
              
              // Новий контент приходить справа
              final inOffset = Tween<Offset>(
                begin: const Offset(1.0, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));
              
              // Масштабування для більш плавного ефекту
              final scaleAnimation = Tween<double>(
                begin: 0.8,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));
              
              return SlideTransition(
                position: animation.status == AnimationStatus.reverse ? outOffset : inOffset,
                child: FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              );
            },
            child: currentSkins.isEmpty
                ? Center(
                    key: const ValueKey('empty'),
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
                    key: ValueKey('character_${selectedIndex}_${currentSkins.length}'),
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return AnimationLimiter(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: AppConstants.smallPadding),
                            itemCount: currentSkins.length,
                            itemBuilder: (context, index) {
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 500),
                                delay: Duration(milliseconds: 50 * index),
                                child: SlideAnimation(
                                  horizontalOffset: 100.0,
                                  curve: Curves.easeOutCubic,
                                  child: FadeInAnimation(
                                    curve: Curves.easeOut,
                                    child: ScaleAnimation(
                                      scale: 0.5,
                                      curve: Curves.easeOutBack,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: AppConstants.smallPadding),
                                        child: SizedBox(
                                          height: constraints.maxHeight,
                                          child: _buildModCard(currentSkins[index]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
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
            // Immediate response for character selection - no debounce needed
            if (mounted) {
              ref.read(selectedCharacterIndexProvider.notifier).state = index;
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(right: AppConstants.characterCardMarginRight),
            transform: Matrix4.identity()
              ..scale(isSelected ? 1.05 : (isHovering ? 1.03 : 1.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: AppConstants.characterCardWidth,
                  height: AppConstants.characterCardHeight,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovering
                          ? const Color(AppConstants.activeModCountColor)
                          : isSelected
                              ? const Color(AppConstants.activeModBorderColor)
                              : Colors.grey.withOpacity(0.3),
                      width: isHovering
                          ? AppConstants.characterCardBorderWidthHover
                          : isSelected
                              ? AppConstants.characterCardBorderWidthSelected
                              : AppConstants.characterCardBorderWidth,
                    ),
                    boxShadow: isHovering
                        ? [BoxShadow(
                            color: const Color(AppConstants.activeModCountColor).withOpacity(0.4),
                            blurRadius: AppConstants.characterCardBlurRadius,
                            spreadRadius: AppConstants.characterCardSpreadRadiusHover,
                          )]
                        : isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(AppConstants.activeModBorderColor).withOpacity(0.4),
                                  blurRadius: AppConstants.characterCardBlurRadius + 5,
                                  spreadRadius: AppConstants.characterCardSpreadRadiusSelected,
                                ),
                                BoxShadow(
                                  color: const Color(AppConstants.activeModBorderColor).withOpacity(0.2),
                                  blurRadius: AppConstants.characterCardBlurRadius + 10,
                                  spreadRadius: AppConstants.characterCardSpreadRadiusSelected + 2,
                                ),
                              ]
                            : null,
                  ),
                  child: ClipOval(
                    child: character.iconPath != null
                        ? Image.asset(
                            character.iconPath!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: AppConstants.characterCardWidth * 0.5,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey.withOpacity(0.2),
                            child: Icon(
                              Icons.person,
                              size: AppConstants.characterCardWidth * 0.5,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: (isSelected || isHovering)
                      ? Column(
                          children: [
                            SizedBox(height: AppConstants.tinyPadding),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut,
                              style: TextStyle(
                                fontSize: AppConstants.smallCaptionTextSize,
                                fontWeight: FontWeight.w600,
                                color: isHovering 
                                    ? const Color(AppConstants.activeModCountColor) 
                                    : (isSelected ? const Color(AppConstants.activeModBorderColor) : Colors.grey[700]),
                              ),
                              child: Text(
                                character.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
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
      delay: AppConstants.dragDelay,
      hapticFeedbackOnStart: true,
      feedback: Material(
        elevation: AppConstants.dragFeedbackElevation,
        borderRadius: BorderRadius.circular(AppConstants.modCardBorderRadius),
        child: Container(
          width: AppConstants.modCardWidth * 0.5, // Slightly smaller for feedback
          height: AppConstants.modCardImageHeight * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppConstants.modCardBorderRadius),
            border: Border.all(
              color: const Color(AppConstants.activeModBorderColor),
              width: AppConstants.modCardBorderWidthActive,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(AppConstants.activeModBorderColor).withOpacity(0.3),
                blurRadius: AppConstants.modCardBlurRadiusActive,
                spreadRadius: AppConstants.modCardSpreadRadiusActive,
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
        opacity: AppConstants.dragFeedbackOpacity,
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
    return _ModCardWidget(
      mod: mod, 
      isDarkMode: isDarkMode,
      modCharacterTags: modCharacterTags,
      getCharacterName: _getCharacterName,
      getModCardGradient: _getModCardGradient,
      getModCardBorderColor: _getModCardBorderColor,
      getModCardShadows: _getModCardShadows,
    );
  }

  // Допоміжні методи для стилізації
  LinearGradient _getModCardGradient(ModInfo mod, bool isDarkMode, bool isHovered) {
    if (mod.isActive) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromRGBO(14, 165, 233, isHovered ? 0.2 : 0.15),
          Color.fromRGBO(59, 130, 246, isHovered ? 0.15 : 0.1),
          Color.fromRGBO(139, 92, 246, isHovered ? 0.1 : 0.05),
        ],
      );
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        isDarkMode 
            ? Color.fromRGBO(31, 41, 55, isHovered ? 0.9 : 0.8)
            : Color.fromRGBO(255, 255, 255, isHovered ? 0.95 : 0.9),
        isDarkMode 
            ? Color.fromRGBO(17, 24, 39, isHovered ? 0.95 : 0.9)
            : Color.fromRGBO(249, 250, 251, isHovered ? 0.98 : 0.95),
      ],
    );
  }

  Color _getModCardBorderColor(ModInfo mod, bool isDarkMode, bool isHovered) {
    if (mod.isActive) {
      return Color.fromRGBO(14, 165, 233, isHovered ? 0.8 : 0.6);
    }
    
    if (isHovered) {
      return isDarkMode 
          ? Color.fromRGBO(255, 255, 255, 0.2)
          : Color.fromRGBO(0, 0, 0, 0.15);
    }
    
    return isDarkMode 
        ? Color.fromRGBO(255, 255, 255, 0.08)
        : Color.fromRGBO(0, 0, 0, 0.06);
  }

  List<BoxShadow> _getModCardShadows(ModInfo mod, bool isDarkMode, bool isHovered) {
    List<BoxShadow> shadows = [];
    
    if (mod.isActive) {
      shadows.addAll([
        BoxShadow(
          color: Color.fromRGBO(14, 165, 233, isHovered ? 0.3 : 0.2),
          blurRadius: isHovered ? 20 : 15,
          offset: Offset(0, isHovered ? 8 : 6),
          spreadRadius: isHovered ? 2 : 1,
        ),
        BoxShadow(
          color: Color.fromRGBO(14, 165, 233, isHovered ? 0.15 : 0.1),
          blurRadius: isHovered ? 30 : 25,
          offset: Offset(0, isHovered ? 12 : 10),
          spreadRadius: isHovered ? 3 : 2,
        ),
      ]);
    } else {
      shadows.add(
        BoxShadow(
          color: isDarkMode 
              ? Color.fromRGBO(0, 0, 0, isHovered ? 0.4 : 0.2)
              : Color.fromRGBO(156, 163, 175, isHovered ? 0.2 : 0.1),
          blurRadius: isHovered ? 15 : 10,
          offset: Offset(0, isHovered ? 6 : 4),
          spreadRadius: isHovered ? 1 : 0,
        ),
      );
    }
    
    if (isHovered && !mod.isActive) {
      shadows.add(
        BoxShadow(
          color: isDarkMode 
              ? Color.fromRGBO(255, 255, 255, 0.05)
              : Color.fromRGBO(0, 0, 0, 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 1,
        ),
      );
    }
    
    return shadows;
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
      height: 38,
      decoration: BoxDecoration(
        color: isDarkMode 
            ? const Color(0xFF1F2937).withOpacity(0.6)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated sliding background with liquid wave effect
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            left: activationMode == ActivationMode.single ? 2 : 76,
            top: 2,
            bottom: 2,
            width: 72,
            child: AnimatedBuilder(
              animation: _modeToggleAnimation,
              builder: (context, child) {
                final animProgress = _modeToggleAnimation.value;
                
                return ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Stack(
                    children: [
                      // Main gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                const Color(0xFF0EA5E9),
                                const Color(0xFF06B6D4),
                                animProgress * 0.3,
                              )!,
                              Color.lerp(
                                const Color(0xFF06B6D4),
                                const Color(0xFF0EA5E9),
                                animProgress * 0.3,
                              )!,
                            ],
                          ),
                        ),
                      ),
                      // Liquid wave effect overlay - first layer
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LiquidWavePainter(
                            animationValue: animProgress,
                            waveAmplitude: 3.0,
                            waveFrequency: 1.5,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                      // Additional wave layer for depth - second layer
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LiquidWavePainter(
                            animationValue: animProgress,
                            waveAmplitude: 2.2,
                            waveFrequency: 2.0,
                            color: Colors.white.withOpacity(0.2),
                            phaseShift: pi / 2,
                          ),
                        ),
                      ),
                      // Third wave layer for even more depth
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LiquidWavePainter(
                            animationValue: animProgress,
                            waveAmplitude: 1.5,
                            waveFrequency: 2.5,
                            color: Colors.white.withOpacity(0.15),
                            phaseShift: pi,
                          ),
                        ),
                      ),
                      // Shimmer effect that flows with the animation
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(-1.5 + (animProgress * 3.0), -0.5),
                              end: Alignment(0.5 + (animProgress * 3.0), 0.5),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.25),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Shadow overlay for the background indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            left: activationMode == ActivationMode.single ? 2 : 76,
            top: 2,
            bottom: 2,
            width: 72,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeButton(
                label: 'Single',
                isActive: activationMode == ActivationMode.single,
                onTap: () {
                  if (activationMode != ActivationMode.single) {
                    _modeToggleAnimationController.forward(from: 0.0);
                    _rebuildDebounce?.cancel();
                    _characterSelectionDebounce?.cancel();
                    _isOperationInProgress = false;
                    ref.read(activationModeProvider.notifier).state = ActivationMode.single;
                  }
                },
                isDarkMode: isDarkMode,
              ),
              _buildModeButton(
                label: 'Multi',
                isActive: activationMode == ActivationMode.multi,
                onTap: () {
                  if (activationMode != ActivationMode.multi) {
                    _modeToggleAnimationController.forward(from: 0.0);
                    _rebuildDebounce?.cancel();
                    _characterSelectionDebounce?.cancel();
                    _isOperationInProgress = false;
                    ref.read(activationModeProvider.notifier).state = ActivationMode.multi;
                  }
                },
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 38,
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive 
                ? Colors.white
                : isDarkMode 
                    ? Colors.white.withOpacity(0.5)
                    : Colors.black.withOpacity(0.5),
            letterSpacing: 0.3,
          ),
          child: Text(label),
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

class _ModCardWidget extends StatefulWidget {
  final ModInfo mod;
  final bool isDarkMode;
  final Map<String, String> modCharacterTags;
  final String Function(String) getCharacterName;
  final LinearGradient Function(ModInfo, bool, bool) getModCardGradient;
  final Color Function(ModInfo, bool, bool) getModCardBorderColor;
  final List<BoxShadow> Function(ModInfo, bool, bool) getModCardShadows;

  const _ModCardWidget({
    required this.mod,
    required this.isDarkMode,
    required this.modCharacterTags,
    required this.getCharacterName,
    required this.getModCardGradient,
    required this.getModCardBorderColor,
    required this.getModCardShadows,
  });

  @override
  State<_ModCardWidget> createState() => _ModCardWidgetState();
}

class _ModCardWidgetState extends State<_ModCardWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: AppConstants.modCardWidth,
        transform: Matrix4.identity()
          ..scale(isHovered ? 1.02 : 1.0)
          ..translate(0.0, isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: widget.getModCardGradient(widget.mod, widget.isDarkMode, isHovered),
          border: Border.all(
            color: widget.getModCardBorderColor(widget.mod, widget.isDarkMode, isHovered),
            width: widget.mod.isActive ? 2.5 : (isHovered ? 2.0 : 1.2),
          ),
          boxShadow: widget.getModCardShadows(widget.mod, widget.isDarkMode, isHovered),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            gradient: isHovered 
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(255, 255, 255, 0.05),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Зображення моду з новим стилем
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.mod.imagePath != null && File(widget.mod.imagePath!).existsSync()
                          ? null
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                widget.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                              ],
                            ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.mod.imagePath != null && File(widget.mod.imagePath!).existsSync())
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: Image.file(
                              File(widget.mod.imagePath!),
                              fit: BoxFit.cover,
                              key: ValueKey(widget.mod.imagePath! + DateTime.now().millisecondsSinceEpoch.toString()),
                              cacheWidth: null,
                              cacheHeight: null,
                            ),
                          )
                        else
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode 
                                    ? Color.fromRGBO(255, 255, 255, 0.05)
                                    : Color.fromRGBO(0, 0, 0, 0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: widget.isDarkMode 
                                    ? Color.fromRGBO(255, 255, 255, 0.4)
                                    : Color.fromRGBO(0, 0, 0, 0.4),
                              ),
                            ),
                          ),
                        
                        // Градієнт оверлей для кращої читабельності
                        if (widget.mod.imagePath != null && File(widget.mod.imagePath!).existsSync())
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color.fromRGBO(0, 0, 0, 0.1),
                                ],
                              ),
                            ),
                          ),
                        
                        // Стильний статус індикатор
                        Positioned(
                          top: 12,
                          right: 12,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.mod.isActive
                                  ? const Color(0xFF10B981)
                                  : widget.isDarkMode 
                                      ? const Color(0xFF374151)
                                      : const Color(0xFF6B7280),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.mod.isActive 
                                      ? Color.fromRGBO(16, 185, 129, 0.3)
                                      : Color.fromRGBO(0, 0, 0, 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.mod.isActive ? Icons.check_rounded : Icons.close_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Тег персонажа з новим стилем
                        if (widget.modCharacterTags.containsKey(widget.mod.id))
                          Positioned(
                            top: 12,
                            left: 12,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(14, 165, 233, 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.getCharacterName(widget.modCharacterTags[widget.mod.id]!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Назва моду з новим стилем
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                  color: widget.mod.isActive
                      ? (widget.isDarkMode 
                          ? Color.fromRGBO(14, 165, 233, 0.1)
                          : Color.fromRGBO(14, 165, 233, 0.05))
                      : (widget.isDarkMode 
                          ? Color.fromRGBO(255, 255, 255, 0.02)
                          : Color.fromRGBO(0, 0, 0, 0.01)),
                ),
                child: Text(
                  widget.mod.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: widget.mod.isActive
                        ? const Color(0xFF0EA5E9)
                        : (widget.isDarkMode ? Color.fromRGBO(255, 255, 255, 0.9) : Color.fromRGBO(0, 0, 0, 0.8)),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// Custom painter for liquid wave effect
class _LiquidWavePainter extends CustomPainter {
  final double animationValue;
  final double waveAmplitude;
  final double waveFrequency;
  final Color color;
  final double phaseShift;

  _LiquidWavePainter({
    required this.animationValue,
    required this.waveAmplitude,
    required this.waveFrequency,
    required this.color,
    this.phaseShift = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Create smooth wave across the width
    for (double x = 0; x <= size.width; x += 1) {
      final normalizedX = x / size.width;
      
      // Create wave that animates smoothly
      final wave = sin(
        (normalizedX * waveFrequency * 2 * pi) + 
        (animationValue * 4 * pi) + 
        phaseShift
      );
      
      // Apply wave amplitude with smooth falloff at edges
      final edgeFactor = sin(normalizedX * pi);
      final y = (size.height * 0.5) + (wave * waveAmplitude * edgeFactor);
      
      path.lineTo(x, y);
    }
    
    // Complete the path
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.waveAmplitude != waveAmplitude ||
           oldDelegate.waveFrequency != waveFrequency;
  }
}
