import 'dart:ui';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Wallet design system — "premium macOS" direction.
//
// Shared by every screen/sheet under wallet/presentation so the whole
// feature reads as one cohesive surface instead of several bolted-together
// dialogs: a cool graphite canvas with soft ambient color underneath (the
// way macOS windows pick up light from the desktop), frosted-glass panels,
// deep ink-green as the primary "card" gradient (an Apple Wallet-style
// card, not a flat brand color), and a single reusable diagonal glass
// sheen used on every gradient tile so the lighting stays consistent.
//
// Import this file instead of redefining a local _Palette / local sheet
// input widgets per-file — that's what made the four bottom sheets drift
// out of sync before.
// ---------------------------------------------------------------------------

class WalletPalette {
  WalletPalette._();

  // Canvas — a barely-there vertical gradient instead of a flat fill.
  static const canvasTop = Color(0xFFF4F6F7);
  static const canvasBottom = Color(0xFFE8ECEE);

  // Glass surfaces
  static const glassFill = Color(0xF7FFFFFF);
  static const glassBorder = Color(0x14101A16);
  static const hairline = Color(0x111C2B22);

  // Text
  static const ink = Color(0xFF141E19);
  static const textMuted = Color(0xFF69796F);
  static const textFaint = Color(0xFF9FAEA6);

  // Brand — deep ink-green "card" gradient (3-stop, reads richer than a
  // flat two-color fill at large sizes).
  static const primaryStart = Color(0xFF0A3D2C);
  static const primaryMid = Color(0xFF11593F);
  static const primaryEnd = Color(0xFF1E9463);

  static const accentBlueStart = Color(0xFF2A63D6);
  static const accentBlueEnd = Color(0xFF6FA4FF);

  static const tealStart = Color(0xFF0B6E67);
  static const tealEnd = Color(0xFF35CBB6);

  static const amberStart = Color(0xFFC0791D);
  static const amberEnd = Color(0xFFF0AE3F);

  static const danger = Color(0xFFE0514F);

  static const dockGlassDark = Color(0xE6151C19);
  static const dockGlassDarkAlt = Color(0xE6232F29);

  static const allowanceIconBg = [
    Color(0xFFFFE7D6),
    Color(0xFFDCEAFF),
    Color(0xFFE1F5E0),
    Color(0xFFFCE1EF),
    Color(0xFFFFF2C2),
    Color(0xFFE7E3FF),
  ];
  static const allowanceIconFg = [
    Color(0xFFD9772E),
    Color(0xFF2E6ADE),
    Color(0xFF238A50),
    Color(0xFFC1428A),
    Color(0xFFB98A16),
    Color(0xFF6C5CE7),
  ];
}

/// Brand-flavored gradients for card wallets, so BDO/GCash/UnionBank/Maya
/// read like distinct digital cards instead of one generic blue tile.
class CardProviderStyle {
  final List<Color> gradient;
  final Color textColor;
  final Color subTextColor;
  final Color accent; // used for the little "chip" decoration
  const CardProviderStyle({
    required this.gradient,
    this.textColor = Colors.white,
    this.subTextColor = Colors.white70,
    this.accent = Colors.white,
  });
}

class CardProviderPalette {
  CardProviderPalette._();

  static const _bdo = CardProviderStyle(
    gradient: [Color(0xFF002E6D), Color(0xFF0056B3)], // BDO navy/blue
    textColor: Colors.white,
    subTextColor: Color(0xFFBFD4FF),
    accent: Color(0xFFF0B429), // gold chip
  );

  static const _gcash = CardProviderStyle(
    gradient: [Color(0xFF00317F), Color(0xFF0072CE)], // GCash blue
    textColor: Colors.white,
    subTextColor: Color(0xFFBFE0FF),
    accent: Colors.white,
  );

  static const _maya = CardProviderStyle(
    gradient: [Color(0xFF0B0B0B), Color(0xFF00A651)], // Maya black/green
    textColor: Colors.white,
    subTextColor: Color(0xFFB8F5CE),
    accent: Color(0xFF00D66B),
  );

  static const _unionBank = CardProviderStyle(
    gradient: [Color(0xFFF7941D), Color(0xFFFFD65A)], // UnionBank yellow/gold
    textColor: Color(0xFF1A1A1A),
    subTextColor: Color(0xFF5B4300),
    accent: Color(0xFF1A1A1A),
  );

  static const _other = CardProviderStyle(
    gradient: [WalletPalette.accentBlueStart, WalletPalette.accentBlueEnd],
  );

  static CardProviderStyle of(String provider) {
    switch (provider.toUpperCase()) {
      case 'BDO':
        return _bdo;
      case 'GCASH':
        return _gcash;
      case 'MAYA':
        return _maya;
      case 'UNIONBANK':
        return _unionBank;
      default:
        return _other;
    }
  }
}
/// Soft ambient color glow behind scaffold content — the same trick macOS
/// uses under widgets and Control Center: barely-visible tinted blobs,
/// heavily blurred, that never compete with foreground content. Sits as
/// the first child of a body [Stack].
class WalletAmbientBackground extends StatelessWidget {
  const WalletAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [WalletPalette.canvasTop, WalletPalette.canvasBottom],
              ),
            ),
          ),
          Positioned(top: -70, right: -60, child: _blob(220, WalletPalette.primaryEnd.withOpacity(0.10))),
          Positioned(top: 240, left: -90, child: _blob(260, WalletPalette.accentBlueEnd.withOpacity(0.09))),
          Positioned(bottom: -100, right: -30, child: _blob(240, WalletPalette.tealEnd.withOpacity(0.08))),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// Frosted-glass panel: blurred backdrop + translucent fill + hairline
/// border. The base building block for cards that sit over
/// [WalletAmbientBackground].
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 24,
    this.color = WalletPalette.glassFill,
    this.blur = 24,
    this.border = true,
    this.padding,
  });

  final Widget child;
  final double radius;
  final Color color;
  final double blur;
  final bool border;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: border ? Border.all(color: WalletPalette.glassBorder) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Decorative diagonal glass sheen pinned to a gradient tile's top-left,
/// plus a soft bottom-right shadow so the tile reads as pressed glass
/// rather than a flat gradient. Purely cosmetic — never intercepts taps.
class GlassSheen extends StatelessWidget {
  const GlassSheen({super.key, required this.radius});
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  heightFactor: 0.6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white.withOpacity(0.24), Colors.white.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: FractionallySizedBox(
                  widthFactor: 0.6,
                  heightFactor: 0.4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomRight,
                        radius: 1.1,
                        colors: [Colors.black.withOpacity(0.10), Colors.black.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small frosted circular icon button — used in the app bar in place of a
/// flat white [IconButton], so the toolbar reads as glass too.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.foreground = WalletPalette.primaryStart,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withOpacity(0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: WalletPalette.glassBorder),
          ),
          child: Icon(icon, size: 18, color: foreground),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Drag handle + icon-badge header used at the top of every bottom sheet.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    required this.icon,
    this.iconBg = const Color(0xFFE1F5E0),
    this.iconFg = WalletPalette.primaryStart,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: WalletPalette.hairline, borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconFg, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: WalletPalette.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Shared text-field chrome used across every wallet bottom sheet.
class SheetTextField extends StatelessWidget {
  const SheetTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.keyboardType,
    this.prefixText,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: WalletPalette.hairline),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: WalletPalette.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, size: 20, color: WalletPalette.textMuted),
        labelStyle: const TextStyle(color: WalletPalette.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: enabled ? Colors.white : WalletPalette.canvasTop,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WalletPalette.primaryEnd, width: 1.6),
        ),
      ),
    );
  }
}

/// Shared dropdown chrome, matching [SheetTextField].
class SheetDropdownField<T> extends StatelessWidget {
  const SheetDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String label;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: WalletPalette.hairline),
    );
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: WalletPalette.ink),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: WalletPalette.textMuted),
        labelStyle: const TextStyle(color: WalletPalette.textMuted, fontSize: 13.5),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WalletPalette.primaryEnd, width: 1.6),
        ),
      ),
    );
  }
}

/// Primary gradient pill button used at the bottom of every sheet.
class SheetPrimaryButton extends StatelessWidget {
  const SheetPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.colors = const [WalletPalette.primaryStart, WalletPalette.primaryEnd],
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onTap == null;
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: disabled
              ? null
              : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          color: disabled ? WalletPalette.hairline : null,
          boxShadow: disabled
              ? null
              : [BoxShadow(color: colors.first.withOpacity(0.30), blurRadius: 18, offset: const Offset(0, 9))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: disabled ? null : onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet outer shell — frosted-glass rounded top, consistent
/// padding + keyboard inset handling, shared by every wallet sheet.
class WalletSheetShell extends StatelessWidget {
  const WalletSheetShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: WalletPalette.glassFill,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.6))),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
