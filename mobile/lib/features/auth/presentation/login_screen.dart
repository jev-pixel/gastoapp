import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../wallet/presentation/wallet_screen.dart';
import 'auth_provider.dart';
import 'register_screen.dart';

//----------------------------------------------------------------------------
// Design tokens — mirrors the palette used across the app (wallet/dashboard)
// so auth screens feel like part of the same product.
//----------------------------------------------------------------------------
class _Palette {
  static const primaryStart = Color(0xFF0F5132);
  static const primaryEnd = Color(0xFF1B7A4A);
  static const accentBlueStart = Color(0xFF2E6ADE);
  static const accentBlueEnd = Color(0xFF5B9BF0);
  static const surface = Color(0xFFF6F8F5);
  static const fieldFill = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFE7ECE6);
  static const textMuted = Color(0xFF6B7A70);
  static const danger = Color(0xFFD9534F);
}

InputDecoration _fieldDecoration({
  required String label,
  IconData? icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon, color: _Palette.textMuted, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: _Palette.fieldFill,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _Palette.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _Palette.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _Palette.primaryStart, width: 1.6),
    ),
  );
}

// ---------------------------------------------------------------------------
// Soft radial "blob" used to give the background depth. Purely decorative —
// wrapped in IgnorePointer (by the caller) so it never intercepts taps.
// ---------------------------------------------------------------------------
class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.colors, required this.size});
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors[0].withOpacity(0.24),
            colors[1].withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A blob that fades/scales in during the intro, then drifts gently forever
// after — sin/cos on a looping 0..1 controller wraps seamlessly (no reverse
// snap), so the motion never has a visible "reset" moment.
// ---------------------------------------------------------------------------
class _DriftingBlob extends StatelessWidget {
  const _DriftingBlob({
    required this.entrance,
    required this.drift,
    required this.phase,
    required this.amplitude,
    required this.colors,
    required this.size,
  });

  final Animation<double> entrance;
  final Animation<double> drift;
  final double phase;
  final double amplitude;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([entrance, drift]),
        builder: (context, child) {
          final angle = drift.value * 2 * math.pi + phase;
          final dx = math.sin(angle) * amplitude;
          final dy = math.cos(angle) * (amplitude * 0.75);
          return Opacity(
            opacity: entrance.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.85 + 0.15 * entrance.value,
              child: Transform.translate(offset: Offset(dx, dy), child: child),
            ),
          );
        },
        child: _GlowBlob(colors: colors, size: size),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loginSucceeded = false;

  // Drives the one-shot welcome sequence: icon pops in with a small settle
  // rotation, wordmark slides up, then the form card arrives and its own
  // contents cascade in two waves (fields, then actions) rather than
  // everything appearing as one flat block.
  late final AnimationController _introController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotation;
  late final Animation<double> _iconFade;
  late final Animation<Offset> _textSlide;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _formFade;
  late final Animation<double> _blobEntrance;
  late final Animation<double> _fieldsCascade;
  late final Animation<Offset> _fieldsCascadeSlide;
  late final Animation<double> _actionsCascade;
  late final Animation<Offset> _actionsCascadeSlide;

  // Slow, looping "breathing" glow behind the icon once the intro settles.
  late final AnimationController _glowController;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;

  // Continuous ambient drift for the background blobs — runs for the life
  // of the screen, independent of the one-shot intro.
  late final AnimationController _driftController;

  // Short "success" beat: the login button morphs into a checkmark before
  // handing off to the wallet, instead of the screen just vanishing.
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_introController);

    // Small tilt that settles to upright — gives the icon a bit of physical
    // "weight" landing into place rather than just growing in size.
    _iconRotation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _iconFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _blobEntrance = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));

    _formFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
    ));

    // Two cascading waves inside the card itself: fields arrive first,
    // then the button/register row — a beat behind — so the card doesn't
    // read as one flat block popping in.
    _fieldsCascade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    );
    _fieldsCascadeSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_fieldsCascade);

    _actionsCascade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.68, 1.0, curve: Curves.easeOutCubic),
    );
    _actionsCascadeSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(_actionsCascade);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _glowScale = Tween<double>(begin: 0.88, end: 1.16).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowOpacity = Tween<double>(begin: 0.35, end: 0.65).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // Kick off the intro, then start the looping glow once it settles so
    // the pulse never fights with the pop-in scale.
    WidgetsBinding.instance.addPostFrameCallback((_) => _introController.forward());
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _glowController.dispose();
    _driftController.dispose();
    _successController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider auth) async {
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      HapticFeedback.lightImpact();
      setState(() => _loginSucceeded = true);
      await _successController.forward();
      if (!mounted) return;
      // Custom fade + scale hand-off instead of an abrupt route swap —
      // bypasses the named route so we can control the transition curve.
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (_, __, ___) => const WalletScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _Palette.surface,
      body: Stack(
        children: [
          // Decorative background wash — fades/scales in with the intro,
          // then drifts gently for as long as the screen is visible.
          Positioned(
            top: -90,
            right: -70,
            child: _DriftingBlob(
              entrance: _blobEntrance,
              drift: _driftController,
              phase: 0,
              amplitude: 14,
              colors: const [_Palette.primaryEnd, _Palette.primaryStart],
              size: 260,
            ),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _DriftingBlob(
              entrance: _blobEntrance,
              drift: _driftController,
              phase: math.pi * 0.7,
              amplitude: 18,
              colors: const [_Palette.accentBlueEnd, _Palette.accentBlueStart],
              size: 300,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon with a soft breathing glow behind it.
                    Center(
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            FadeTransition(
                              opacity: _iconFade,
                              child: AnimatedBuilder(
                                animation: _glowController,
                                builder: (context, child) => Transform.scale(
                                  scale: _glowScale.value,
                                  child: Opacity(
                                    opacity: _glowOpacity.value,
                                    child: child,
                                  ),
                                ),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _Palette.primaryEnd.withOpacity(0.55),
                                        _Palette.primaryEnd.withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: _iconFade,
                              child: ScaleTransition(
                                scale: _iconScale,
                                child: RotationTransition(
                                  turns: _iconRotation,
                                  child: Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _Palette.primaryStart.withOpacity(0.28),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.asset(
                                        'assets/icon/icon.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _iconFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: const Text(
                          'GastoApp',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Color(0xFF14231C),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FadeTransition(
                      opacity: _iconFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: const Text(
                          'Know before you spend.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: _Palette.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form card arrives as a unit, then its own contents
                    // cascade in two waves (see _fieldsCascade / _actionsCascade).
                    SlideTransition(
                      position: _formSlide,
                      child: FadeTransition(
                        opacity: _formFade,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _Palette.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: _Palette.primaryStart.withOpacity(0.10),
                                blurRadius: 32,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FadeTransition(
                                opacity: _fieldsCascade,
                                child: SlideTransition(
                                  position: _fieldsCascadeSlide,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: _fieldDecoration(
                                          label: 'Email',
                                          icon: Icons.mail_outline_rounded,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: _fieldDecoration(
                                          label: 'Password',
                                          icon: Icons.lock_outline_rounded,
                                          suffix: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: _Palette.textMuted,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscurePassword = !_obscurePassword),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              FadeTransition(
                                opacity: _actionsCascade,
                                child: SlideTransition(
                                  position: _actionsCascadeSlide,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (auth.errorMessage != null) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _Palette.danger.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: _Palette.danger.withOpacity(0.25)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline_rounded,
                                                  color: _Palette.danger, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  auth.errorMessage!,
                                                  style: const TextStyle(
                                                      color: _Palette.danger, fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 22),
                                      SizedBox(
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: (auth.isLoading || _loginSucceeded)
                                              ? null
                                              : () => _handleLogin(auth),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _loginSucceeded
                                                ? _Palette.primaryEnd
                                                : _Palette.primaryStart,
                                            disabledBackgroundColor: _loginSucceeded
                                                ? _Palette.primaryEnd
                                                : _Palette.primaryStart,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            textStyle: const TextStyle(
                                                fontWeight: FontWeight.w700, fontSize: 15),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                      strokeWidth: 2, color: Colors.white),
                                                )
                                              : _loginSucceeded
                                                  ? ScaleTransition(
                                                      scale: CurvedAnimation(
                                                        parent: _successController,
                                                        curve: Curves.elasticOut,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : const Text('Log In'),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Center(
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) => const RegisterScreen()),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                              foregroundColor: _Palette.primaryStart),
                                          child: RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                  color: _Palette.textMuted, fontSize: 13.5),
                                              children: [
                                                TextSpan(text: "Don't have an account? "),
                                                TextSpan(
                                                  text: 'Register',
                                                  style: TextStyle(
                                                    color: _Palette.primaryStart,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Developer credit
                    FadeTransition(
                      opacity: _formFade,
                      child: const Center(
                        child: Text(
                          'Developed by Justine Villarosa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _Palette.textMuted,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}