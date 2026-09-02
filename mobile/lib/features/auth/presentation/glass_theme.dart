import 'dart:ui';

import 'package:flutter/material.dart';

class LightGlassTheme {
  static const Color forestGreen = Color(0xFF123524);
  static const Color lighterGreen = Color(0xFF1B4A32);
  static const Color deepGreen = Color(0xFF0D261A);
  static const Color darkGold = Color(0xFFB8842A);
  static const Color brightGold = Color(0xFFD9B65A);

  static const Color canvasBackground = Color(0xFFF4F7F4);
  static Color glassSurface = Colors.white.withOpacity(0.68);
  static Color glassBorder = Colors.white.withOpacity(0.85);
  static const Color subtleBorder = Color(0xFFE2E8E1);

  static const Color textPrimary = Color(0xFF14231C);
  static const Color textMuted = Color(0xFF5C6B61);
  static const Color danger = Color(0xFFD9534F);
}

class LightGlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const LightGlassCard({
    super.key,
    required this.child,
    this.blur = 24.0,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: LightGlassTheme.glassSurface,
            borderRadius: br,
            border: Border.all(
              color: LightGlassTheme.glassBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: LightGlassTheme.forestGreen.withOpacity(0.06),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: LightGlassTheme.darkGold.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlowBlob extends StatelessWidget {
  final List<Color> colors;
  final double size;

  const GlowBlob({
    super.key,
    required this.colors,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors[0].withOpacity(0.25),
            colors[1].withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}