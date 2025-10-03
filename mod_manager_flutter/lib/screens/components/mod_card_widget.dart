import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/character_info.dart';

class ModCardWidget extends StatefulWidget {
  final ModInfo mod;
  final bool isDarkMode;
  final Map<String, String> modCharacterTags;
  final Function(String) getCharacterName;

  const ModCardWidget({
    Key? key,
    required this.mod,
    required this.isDarkMode,
    required this.modCharacterTags,
    required this.getCharacterName,
  }) : super(key: key);

  @override
  State<ModCardWidget> createState() => _ModCardWidgetState();
}

class _ModCardWidgetState extends State<ModCardWidget> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(isHovered ? 1.02 : 1.0)
          ..translate(0.0, isHovered ? -4.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _getModCardGradient(widget.mod, widget.isDarkMode, isHovered),
          border: Border.all(
            color: _getModCardBorderColor(widget.mod, widget.isDarkMode, isHovered),
            width: widget.mod.isActive ? 2.5 : (isHovered ? 2.0 : 1.2),
          ),
          boxShadow: _getModCardShadows(widget.mod, widget.isDarkMode, isHovered),
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
                                widget.isDarkMode 
                                    ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                widget.isDarkMode 
                                    ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
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
                              key: ValueKey('${widget.mod.id}_${widget.mod.imagePath}'),
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
}