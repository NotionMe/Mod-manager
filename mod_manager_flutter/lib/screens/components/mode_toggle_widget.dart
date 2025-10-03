import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../utils/state_providers.dart';

class ModeToggleWidget extends StatelessWidget {
  final AnimationController modeToggleAnimationController;
  final Animation<double> modeToggleAnimation;
  final ActivationMode activationMode;
  final Function(ActivationMode) onModeChanged;

  const ModeToggleWidget({
    Key? key,
    required this.modeToggleAnimationController,
    required this.modeToggleAnimation,
    required this.activationMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ModeToggleContent(
      modeToggleAnimationController: modeToggleAnimationController,
      modeToggleAnimation: modeToggleAnimation,
      activationMode: activationMode,
      onModeChanged: onModeChanged,
    );
  }
}

class _ModeToggleContent extends ConsumerWidget {
  final AnimationController modeToggleAnimationController;
  final Animation<double> modeToggleAnimation;
  final ActivationMode activationMode;
  final Function(ActivationMode) onModeChanged;

  const _ModeToggleContent({
    Key? key,
    required this.modeToggleAnimationController,
    required this.modeToggleAnimation,
    required this.activationMode,
    required this.onModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: Container(
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
                animation: modeToggleAnimation,
                builder: (context, child) {
                  final animProgress = modeToggleAnimation.value;
                  
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
                    modeToggleAnimationController.forward(from: 0.0);
                    onModeChanged(ActivationMode.single);
                  }
                },
                isDarkMode: isDarkMode,
                animationController: modeToggleAnimationController,
              ),
              _buildModeButton(
                label: 'Multi',
                isActive: activationMode == ActivationMode.multi,
                onTap: () {
                  if (activationMode != ActivationMode.multi) {
                    modeToggleAnimationController.forward(from: 0.0);
                    onModeChanged(ActivationMode.multi);
                  }
                },
                isDarkMode: isDarkMode,
                animationController: modeToggleAnimationController,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDarkMode,
    required AnimationController animationController,
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