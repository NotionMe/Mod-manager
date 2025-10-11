import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants.dart';
import '../../models/character_info.dart';
import '../../l10n/app_localizations.dart';
import 'keybinds_widget.dart';

class CharacterCardsListWidget extends ConsumerStatefulWidget {
  final List<CharacterInfo> characters;
  final int selectedIndex;
  final Function(int) onCharacterSelected;
  final Function(String, String) onCharacterTagSaved;
  final Map<String, String> modCharacterTags;

  const CharacterCardsListWidget({
    Key? key,
    required this.characters,
    required this.selectedIndex,
    required this.onCharacterSelected,
    required this.onCharacterTagSaved,
    required this.modCharacterTags,
  }) : super(key: key);

  @override
  ConsumerState<CharacterCardsListWidget> createState() =>
      _CharacterCardsListWidgetState();
}

class _CharacterCardsListWidgetState
    extends ConsumerState<CharacterCardsListWidget> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final characters = widget.characters;

    if (characters.isEmpty) {
      return Center(
        child: Text(
          loc.t('mods.characters.empty'),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    final dragDevices = <PointerDeviceKind>{
      PointerDeviceKind.touch,
      PointerDeviceKind.mouse,
      PointerDeviceKind.trackpad,
      PointerDeviceKind.stylus,
    };

    return Listener(
      onPointerSignal: (PointerSignalEvent event) {
        if (event is PointerScrollEvent && _scrollController.hasClients) {
          final delta = event.scrollDelta.dy != 0
              ? event.scrollDelta.dy
              : event.scrollDelta.dx;
          if (delta == 0) return;
          final position = _scrollController.position;
          final newOffset = (position.pixels + delta).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          );
          _scrollController.jumpTo(newOffset);
        }
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: dragDevices,
          physics: const BouncingScrollPhysics(),
        ),
        child: AnimationLimiter(
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
            ),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: AppConstants.fastAnimationDuration,
                child: SlideAnimation(
                  horizontalOffset: 30.0,
                  child: FadeInAnimation(
                    child: _buildCharacterCard(
                      context,
                      characters[index],
                      index,
                      index == widget.selectedIndex,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterCard(
    BuildContext context,
    CharacterInfo character,
    int index,
    bool isSelected,
  ) {
    final loc = context.loc;
    return DragTarget<ModInfo>(
      onWillAccept: (_) => character.id != 'favorites',
      onAcceptWithDetails: (details) async {
        if (character.id == 'favorites') {
          return;
        }
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
                  Text(loc.t('mods.dialog.saving_tag')),
                ],
              ),
              backgroundColor: const Color(0xFF6366F1),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        // Зберігаємо тег персонажа для моду
        widget.onCharacterTagSaved(details.data.id, character.id);

        // Показуємо повідомлення про успішне збереження
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.t(
                        'mods.dialog.mod_assigned',
                        params: {
                          'mod': details.data.name,
                          'character': character.name,
                        },
                      ),
                    ),
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
            widget.onCharacterSelected(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(
              right: AppConstants.characterCardMarginRight,
            ),
            transform: Matrix4.identity()
              ..scale(isSelected ? 1.05 : (isHovering ? 1.03 : 1.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
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
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    AppConstants.activeModCountColor,
                                  ).withOpacity(0.4),
                                  blurRadius:
                                      AppConstants.characterCardBlurRadius,
                                  spreadRadius: AppConstants
                                      .characterCardSpreadRadiusHover,
                                ),
                              ]
                            : isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    AppConstants.activeModBorderColor,
                                  ).withOpacity(0.4),
                                  blurRadius:
                                      AppConstants.characterCardBlurRadius + 5,
                                  spreadRadius: AppConstants
                                      .characterCardSpreadRadiusSelected,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    AppConstants.activeModBorderColor,
                                  ).withOpacity(0.2),
                                  blurRadius:
                                      AppConstants.characterCardBlurRadius + 10,
                                  spreadRadius:
                                      AppConstants
                                          .characterCardSpreadRadiusSelected +
                                      2,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: character.id == 'all'
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0EA5E9),
                                      Color(0xFF06B6D4),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.apps,
                                  size: AppConstants.characterCardWidth * 0.5,
                                  color: Colors.white,
                                ),
                              )
                            : character.id == 'favorites'
                            ? Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF97316),
                                      Color(0xFFFACC15),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.star,
                                  size: AppConstants.characterCardWidth * 0.5,
                                  color: Colors.white,
                                ),
                              )
                            : character.iconPath != null
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
                    // Бейдж з кількістю keybinds
                    if (character.keybinds != null &&
                        character.keybinds!.keybinds.isNotEmpty)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: KeybindsBadge(
                          keybinds: character.keybinds,
                          scaleFactor: 0.8,
                        ),
                      ),
                  ],
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
                                    ? const Color(
                                        AppConstants.activeModCountColor,
                                      )
                                    : (isSelected
                                          ? const Color(
                                              AppConstants.activeModBorderColor,
                                            )
                                          : Colors.grey[700]),
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
}
