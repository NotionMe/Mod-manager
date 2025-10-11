import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/keybind_info.dart';

/// Віджет для відображення keybinds персонажа
/// Показує всі знайдені keybinds з INI файлів
class KeybindsWidget extends StatefulWidget {
  final CharacterKeybinds? keybinds;
  final double scaleFactor;

  const KeybindsWidget({
    super.key,
    required this.keybinds,
    this.scaleFactor = 1.0,
  });

  @override
  State<KeybindsWidget> createState() => _KeybindsWidgetState();
}

class _KeybindsWidgetState extends State<KeybindsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.keybinds == null || widget.keybinds!.keybinds.isEmpty) {
      return const SizedBox.shrink();
    }

    // Фільтруємо тільки keybinds з key значенням
    final validKeybinds = widget.keybinds!.keybinds
        .where((kb) => kb.keyValue != null && kb.keyValue!.isNotEmpty)
        .toList();

    if (validKeybinds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 6 * widget.scaleFactor,
        horizontal: 16 * widget.scaleFactor,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8 * widget.scaleFactor),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок з кнопкою розгортання
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8 * widget.scaleFactor),
            child: Padding(
              padding: EdgeInsets.all(10 * widget.scaleFactor),
              child: Row(
                children: [
                  Icon(
                    Icons.keyboard_outlined,
                    size: 16 * widget.scaleFactor,
                    color: const Color(0xFF6366F1),
                  ),
                  SizedBox(width: 8 * widget.scaleFactor),
                  Text(
                    'Keybinds',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13 * widget.scaleFactor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6 * widget.scaleFactor),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * widget.scaleFactor,
                      vertical: 2 * widget.scaleFactor,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        10 * widget.scaleFactor,
                      ),
                    ),
                    child: Text(
                      '${validKeybinds.length}',
                      style: TextStyle(
                        color: const Color(0xFF6366F1),
                        fontSize: 11 * widget.scaleFactor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18 * widget.scaleFactor,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          // Список keybinds (розгортається)
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.only(
                left: 10 * widget.scaleFactor,
                right: 10 * widget.scaleFactor,
                bottom: 10 * widget.scaleFactor,
              ),
              child: Wrap(
                spacing: 6 * widget.scaleFactor,
                runSpacing: 6 * widget.scaleFactor,
                children: validKeybinds
                    .map((keybind) => _buildKeybindChip(keybind))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeybindChip(KeybindInfo keybind) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * widget.scaleFactor,
        vertical: 6 * widget.scaleFactor,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF8B5CF6).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6 * widget.scaleFactor),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            keybind.displayName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11 * widget.scaleFactor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6 * widget.scaleFactor),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * widget.scaleFactor,
              vertical: 2 * widget.scaleFactor,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4 * widget.scaleFactor),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              keybind.keyValue ?? '',
              style: TextStyle(
                color: const Color(0xFFFBBF24),
                fontSize: 11 * widget.scaleFactor,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Компактний віджет для відображення кількості keybinds
/// Показується як значок з числом
class KeybindsBadge extends StatelessWidget {
  final CharacterKeybinds? keybinds;
  final double scaleFactor;
  final VoidCallback? onTap;

  const KeybindsBadge({
    super.key,
    required this.keybinds,
    this.scaleFactor = 1.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (keybinds == null || keybinds!.keybinds.isEmpty) {
      return const SizedBox.shrink();
    }

    final keybindCount = keybinds!.keybinds.fold<int>(
      0,
      (sum, kb) => sum + kb.keys.length,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * scaleFactor),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scaleFactor,
          vertical: 4 * scaleFactor,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.keyboard,
              size: 14 * scaleFactor,
              color: const Color(0xFF6366F1),
            ),
            SizedBox(width: 4 * scaleFactor),
            Text(
              '$keybindCount',
              style: TextStyle(
                color: const Color(0xFF6366F1),
                fontSize: 12 * scaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
