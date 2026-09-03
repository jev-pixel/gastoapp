import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
// Two things were added on top of the original system:
//   1. Typography — Inter (via google_fonts), the closest free match to
//      San Francisco's metrics/spacing, applied app-wide through
//      [WalletFontScope] so no screen has to hand-pick a font family.
//   2. Responsiveness — [WalletBreakpoints] + [WalletResponsivePage] give
//      every screen a shared, centered, max-width reading column on
//      tablet/desktop instead of phone-width content stretched edge to
//      edge, and [WalletSheetShell] turns into a centered floating panel
//      (macOS "form sheet" style) above the tablet breakpoint instead of
//      a full-bleed bottom sheet.
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
  static const glassFillStrong = Color(0xFAFFFFFF);
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

  // Full-bleed gradient pairs for the "card style" allowance tiles — each
  // allowance gets a saturated color card instead of a plain white tile
  // with a colored icon badge. Order/hue-family matches allowanceIconFg
  // above so an allowance's identity color stays consistent everywhere
  // it appears (icon chip, progress bar, full card).
  static const allowanceCardGradients = [
    [Color(0xFFEC9A5D), Color(0xFFD9772E)], // orange
    [Color(0xFF6FA4FF), Color(0xFF2A63D6)], // blue
    [Color(0xFF3FD1AE), Color(0xFF0E8F63)], // green/teal
    [Color(0xFFE79BCB), Color(0xFFC1428A)], // pink
    [Color(0xFFE9C765), Color(0xFFB98A16)], // amber/gold
    [Color(0xFFA597F5), Color(0xFF6C5CE7)], // purple
  ];
}

// ---------------------------------------------------------------------------
// Typography — Inter everywhere via a single DefaultTextStyle scope, so
// individual screens/sheets keep their existing TextStyle(...) calls
// (weight, size, color) and only the font family + baseline metrics are
// centralized here. Explicit fields on a Text's own style always win over
// this scope, so nothing downstream needs to change its color/weight.
// ---------------------------------------------------------------------------

/// Wrap any screen/sheet root in this once to make every descendant `Text`
/// render in Inter with sane baseline color/height, without having to touch
/// each individual TextStyle. If the app's MaterialApp already sets
/// `theme: ThemeData(textTheme: GoogleFonts.interTextTheme())`, this is a
/// harmless no-op layered on top — kept here so this feature reads
/// correctly even before that global change lands.
class WalletFontScope extends StatelessWidget {
  const WalletFontScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.inter(
        color: WalletPalette.ink,
        fontSize: 14,
        height: 1.32,
        letterSpacing: -0.1,
      ),
      child: child,
    );
  }
}

/// Convenience for wiring Inter into a top-level `MaterialApp(theme: ...)`
/// once that becomes available — matches [WalletFontScope]'s metrics.
ThemeData walletThemeData({Brightness brightness = Brightness.light}) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(textTheme: GoogleFonts.interTextTheme(base.textTheme));
}

// ---------------------------------------------------------------------------
// Responsiveness — three breakpoints (phone / tablet / desktop). Every
// screen reads its column count and content width from here so the whole
// feature scales consistently instead of each screen inventing its own
// thresholds.
// ---------------------------------------------------------------------------

class WalletBreakpoints {
  WalletBreakpoints._();

  static const double tablet = 700;
  static const double desktop = 1100;

  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= desktop;

  /// Column count for card-style grids (allowances, etc.) — 2 up on
  /// phone, 3 on tablet, 4 on desktop-width windows.
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 4;
    if (width >= tablet) return 3;
    return 2;
  }

  /// Max width for a screen's main reading column. Phones get the full
  /// width; tablet/desktop get a capped, centered column so text and
  /// cards don't stretch into unreadable full-bleed rows — the same
  /// instinct behind macOS windows keeping a comfortable content width
  /// even when the window is wide.
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktop) return 1040;
    if (width >= tablet) return 760;
    return width;
  }
}

/// Centers [child] in a max-width column per [WalletBreakpoints], and
/// applies [WalletFontScope]. Wrap the scrollable body of every wallet
/// screen in this — it's a no-op on phone widths (max width == screen
/// width) and gives tablet/desktop a proper reading column.
class WalletResponsivePage extends StatelessWidget {
  const WalletResponsivePage({super.key, required this.child, this.maxWidth});
  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth ?? WalletBreakpoints.contentMaxWidth(context);
    return WalletFontScope(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Derives a stable pseudo card number's last 4 digits from any seed
/// string (an id, a name) so the same wallet always shows the same
/// "masked" digits instead of a random one on every rebuild.
String maskedCardDigits(String seed) {
  final n = seed.hashCode.abs() % 10000;
  return n.toString().padLeft(4, '0');
}

/// Decorative EMV chip — the small gold rectangle on a physical card.
/// Purely visual, sized to read correctly at both the small horizontal
/// preview tiles and the full ATM-style hero card.
class AtmChip extends StatelessWidget {
  const AtmChip({super.key, this.width = 34, this.height = 25});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6E3A1), Color(0xFFC9A344), Color(0xFFF6E3A1)],
        ),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }
}

/// Thin engraved-looking lines across [AtmChip] to sell the "metal
/// contact chip" read instead of a flat gold rounded rect.
class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = 0.8;
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    canvas.drawLine(Offset(size.width * 0.34, 0), Offset(size.width * 0.34, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.66, 0), Offset(size.width * 0.66, size.height), paint);
    final rectPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.14, size.height * 0.18, size.width * 0.72, size.height * 0.64),
        Radius.circular(size.height * 0.18),
      ),
      rectPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ChipLinesPainter oldDelegate) => false;
}

/// Rotated wifi glyph used as a stand-in for the contactless-payment
/// "sound wave" mark printed on tap-to-pay bank/e-wallet cards.
class AtmContactlessIcon extends StatelessWidget {
  const AtmContactlessIcon({super.key, this.color = Colors.white, this.size = 20});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 1.5708, // 90deg, radians
      child: Icon(Icons.wifi_rounded, color: color, size: size),
    );
  }
}

/// Small monospaced "masked PAN" row — e.g. •••• •••• •••• 4821 — shared
/// by the ATM hero card and the compact horizontal card-wallet tiles.
class MaskedCardNumber extends StatelessWidget {
  const MaskedCardNumber({
    super.key,
    required this.lastFour,
    this.color = Colors.white,
    this.fontSize = 16,
    this.compact = false,
  });

  final String lastFour;
  final Color color;
  final double fontSize;
  /// Compact mode collapses to a single leading dot-group ("•••• 4821")
  /// for tight spaces like the small horizontal preview cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final groups = compact ? ['••••', lastFour] : ['••••', '••••', '••••', lastFour];
    return Text(
      groups.join('  '),
      style: GoogleFonts.robotoMono(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
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
/// the first child of a body [Stack]. Gains a fourth blob on wide windows
/// so the effect still reads across a desktop-width canvas instead of
/// pooling in one corner.
class WalletAmbientBackground extends StatelessWidget {
  const WalletAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = WalletBreakpoints.isTablet(context);
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
          Positioned(top: -70, right: -60, child: _blob(220, WalletPalette.primaryEnd.withValues(alpha: 0.10))),
          Positioned(top: 240, left: -90, child: _blob(260, WalletPalette.accentBlueEnd.withValues(alpha: 0.09))),
          Positioned(bottom: -100, right: -30, child: _blob(240, WalletPalette.tealEnd.withValues(alpha: 0.08))),
          if (isWide)
            Positioned(bottom: 60, left: 120, child: _blob(200, WalletPalette.amberEnd.withValues(alpha: 0.05))),
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
                        colors: [Colors.white.withValues(alpha: 0.24), Colors.white.withValues(alpha: 0.0)],
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
                        colors: [Colors.black.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
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
      color: Colors.white.withValues(alpha: 0.7),
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
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isWide = WalletBreakpoints.isTablet(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isWide)
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: WalletPalette.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(fontSize: 12, color: WalletPalette.textMuted),
                      ),
                    ),
                ],
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
              : [BoxShadow(color: colors.first.withValues(alpha: 0.30), blurRadius: 18, offset: const Offset(0, 9))],
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
///
/// Responsive behavior: on phone widths this stays a full-width bottom
/// sheet with only the top corners rounded, same as before. At/above
/// [WalletBreakpoints.tablet] it becomes a centered, all-corners-rounded
/// floating panel capped at [maxWidth] — the macOS/iPadOS "form sheet"
/// treatment, so a compact form doesn't stretch across a whole tablet or
/// desktop-width window.
class WalletSheetShell extends StatelessWidget {
  const WalletSheetShell({super.key, required this.child, this.maxWidth = 480});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isWide = WalletBreakpoints.isTablet(context);
    final radius = isWide
        ? BorderRadius.circular(28)
        : const BorderRadius.vertical(top: Radius.circular(26));

    final glass = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: WalletPalette.glassFill,
            borderRadius: radius,
            border: isWide
                ? Border.all(color: Colors.white.withValues(alpha: 0.6))
                : Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.6))),
            boxShadow: isWide
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 48,
                      offset: const Offset(0, 24),
                    ),
                  ]
                : null,
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

    if (!isWide) return WalletFontScope(child: glass);

    return WalletFontScope(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: glass,
          ),
        ),
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Motion — "Premium Touch" pass. Shared curves/durations + a few reusable
// animated primitives so transitions stay consistent across every sheet
// and screen instead of each file picking its own timing by feel. This is
// additive on top of everything above — nothing existing changes shape.
// ---------------------------------------------------------------------------

class WalletMotion {
  WalletMotion._();

  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 560);

  /// Fast start, soft landing — the way macOS sheets and springboard
  /// icons ease in, instead of a linear or symmetric ease.
  static const Curve settle = Curves.easeOutCubic;

  /// A touch of overshoot for things that should feel "alive" (success
  /// states, sheet entrances) without going full bouncy/elastic.
  static const Curve pop = Curves.easeOutBack;
}

/// Scales [child] down slightly on press and springs back on release —
/// the tactile "give" every tappable surface has on macOS/iOS, instead of
/// Material's flat ripple-only feedback. Wrap buttons, cards, list tiles.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: WalletMotion.quick,
  );

  void _setPressed(bool pressed) {
    if (widget.onTap == null) return;
    pressed ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - (_controller.value * (1 - widget.scaleDown));
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// Fades + slides [child] up into place once, with an optional [delay] —
/// used to stagger list entrances (transaction rows, action tiles)
/// instead of everything popping in on the same frame.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 14});

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final total = WalletMotion.standard + delay;
    final delayFraction = (delay.inMilliseconds / total.inMilliseconds).clamp(0.0, 0.9);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delayFraction, 1.0, curve: WalletMotion.settle),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, offset * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

/// A one-shot diagonal light sweep played once on mount — the little
/// "wake up" shimmer Apple Wallet/Card plays when a card first appears.
/// Purely decorative; sits above [GlassSheen], never intercepts taps.
class OneShotSheen extends StatefulWidget {
  const OneShotSheen({super.key, required this.radius, this.delay = const Duration(milliseconds: 120)});
  final BorderRadius radius;
  final Duration delay;

  @override
  State<OneShotSheen> createState() => _OneShotSheenState();
}

class _OneShotSheenState extends State<OneShotSheen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: widget.radius,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(_controller.value);
              return FractionalTranslation(
                translation: Offset(-1.6 + t * 3.2, -1.6 + t * 3.2),
                child: Transform.rotate(
                  angle: -0.6,
                  child: Container(
                    width: 160,
                    height: 520,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
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
}

/// Compact glass "toolbar" action tile — icon over a short label, used
/// for the row of card actions (Add / Spend / Transfer / Scan / Receive)
/// instead of stock [OutlinedButton]s, so the row reads like a macOS
/// toolbar segment rather than a row of form buttons.
class WalletToolbarAction extends StatelessWidget {
  const WalletToolbarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = WalletPalette.primaryEnd,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WalletPalette.glassBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: tint),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: WalletPalette.ink.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents [builder] as a bottom sheet with a soft scale + slide + fade
/// entrance instead of Flutter's default linear slide-up — the "form
/// sheet" pop macOS/iPadOS uses. Drop-in replacement for
/// [showModalBottomSheet] for every wallet sheet; [WalletSheetShell]
/// still owns width/keyboard/tablet-centering behavior underneath.
Future<T?> showWalletSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.32),
    transitionDuration: WalletMotion.standard,
    pageBuilder: (context, _, __) => Align(alignment: Alignment.bottomCenter, child: builder(context)),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: WalletMotion.settle);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      );
    },
  );
}