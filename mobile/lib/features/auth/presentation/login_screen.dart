import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../wallet/presentation/wallet_screen.dart';
import 'auth_provider.dart';
import 'glass_theme.dart';
import 'pin_input_field.dart';
import 'register_screen.dart';

const String _emailDomain = '@gasto.ph';

InputDecoration _glassFieldDecoration({
  required String label,
  IconData? icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: LightGlassTheme.textMuted, fontSize: 13.5),
    prefixIcon: icon == null ? null : Icon(icon, color: LightGlassTheme.forestGreen, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: Colors.white.withOpacity(0.75),
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: LightGlassTheme.subtleBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: LightGlassTheme.subtleBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: LightGlassTheme.forestGreen, width: 1.6),
    ),
  );
}

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
        child: GlowBlob(colors: colors, size: size),
      ),
    );
  }
}

class _WaveBackground extends StatelessWidget {
  const _WaveBackground({
    required this.entrance,
    required this.drift,
    required this.height,
  });

  final Animation<double> entrance;
  final Animation<double> drift;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([entrance, drift]),
        builder: (context, _) {
          final rise = (1 - entrance.value) * 36;
          return Opacity(
            opacity: entrance.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, rise),
              child: SizedBox(
                width: double.infinity,
                height: height,
                child: CustomPaint(
                  painter: _WavePainter(progress: drift.value),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLayer(
      canvas,
      size,
      phaseShift: progress * 2 * math.pi,
      waveHeight: size.height * 0.16,
      baseline: size.height * 0.62,
      wavelength: size.width * 0.9,
      colors: [LightGlassTheme.deepGreen.withOpacity(0.12), LightGlassTheme.forestGreen.withOpacity(0.08)],
    );
    _paintLayer(
      canvas,
      size,
      phaseShift: progress * 2 * math.pi * 1.4 + math.pi * 0.4,
      waveHeight: size.height * 0.10,
      baseline: size.height * 0.74,
      wavelength: size.width * 0.65,
      colors: [LightGlassTheme.brightGold.withOpacity(0.20), LightGlassTheme.darkGold.withOpacity(0.10)],
    );
  }

  void _paintLayer(
    Canvas canvas,
    Size size, {
    required double phaseShift,
    required double waveHeight,
    required double baseline,
    required double wavelength,
    required List<Color> colors,
  }) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()..moveTo(0, size.height);
    final step = size.width / 64;
    for (double x = 0; x <= size.width; x += step) {
      final y = baseline + math.sin((x / wavelength) * 2 * math.pi + phaseShift) * waveHeight;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.progress != progress;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _pinKey = GlobalKey<PinInputFieldState>();
  String _pin = '';
  bool _obscurePin = true;
  bool _pinError = false;
  bool _loginSucceeded = false;

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

  late final AnimationController _glowController;
  late final Animation<double> _glowScale;
  late final Animation<double> _glowOpacity;

  late final AnimationController _driftController;
  late final AnimationController _successController;
  late final AnimationController _shakeController;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.08).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
    ]).animate(_introController);

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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shake = CurvedAnimation(parent: _shakeController, curve: Curves.linear);

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
    _shakeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider auth) async {
    if (_pin.length != 4) {
      setState(() => _pinError = true);
      HapticFeedback.mediumImpact();
      return;
    }

    final username = _emailController.text.trim();
    final email = '$username$_emailDomain';

    final success = await auth.login(email, _pin);
    if (!mounted) return;

    if (success) {
      setState(() => _pinError = false);
      HapticFeedback.lightImpact();
      setState(() => _loginSucceeded = true);
      await _successController.forward();
      if (!mounted) return;
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
      setState(() => _pinError = true);
      _pinKey.currentState?.clear();
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: LightGlassTheme.canvasBackground,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _DriftingBlob(
              entrance: _blobEntrance,
              drift: _driftController,
              phase: 0,
              amplitude: 14,
              colors: const [LightGlassTheme.brightGold, LightGlassTheme.darkGold],
              size: 280,
            ),
          ),
          Positioned(
            bottom: -60,
            left: -80,
            child: _DriftingBlob(
              entrance: _blobEntrance,
              drift: _driftController,
              phase: math.pi * 0.7,
              amplitude: 16,
              colors: const [LightGlassTheme.lighterGreen, LightGlassTheme.forestGreen],
              size: 300,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _WaveBackground(
              entrance: _blobEntrance,
              drift: _driftController,
              height: MediaQuery.of(context).size.height * 0.46,
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                          LightGlassTheme.brightGold.withOpacity(0.45),
                                          LightGlassTheme.brightGold.withOpacity(0.0),
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
                                      width: 88,
                                      height: 88,
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(26),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [LightGlassTheme.brightGold, LightGlassTheme.darkGold],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: LightGlassTheme.forestGreen.withOpacity(0.18),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                          BoxShadow(
                                            color: LightGlassTheme.darkGold.withOpacity(0.25),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
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
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _iconFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: const Text(
                            'GastoApp',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: LightGlassTheme.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeTransition(
                        opacity: _iconFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: const Text(
                            'Know before you spend.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14.5, color: LightGlassTheme.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SlideTransition(
                        position: _formSlide,
                        child: FadeTransition(
                          opacity: _formFade,
                          child: LightGlassCard(
                            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
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
                                          inputFormatters: [
                                            FilteringTextInputFormatter.deny(RegExp(r'[@\s]')),
                                          ],
                                          decoration: _glassFieldDecoration(
                                            label: 'Username',
                                            icon: Icons.mail_outline_rounded,
                                          ).copyWith(
                                            suffixText: _emailDomain,
                                            suffixStyle: const TextStyle(
                                              color: LightGlassTheme.textMuted,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              '4-Digit PIN',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: LightGlassTheme.textMuted,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => setState(() => _obscurePin = !_obscurePin),
                                              child: Icon(
                                                _obscurePin
                                                    ? Icons.visibility_outlined
                                                    : Icons.visibility_off_outlined,
                                                color: LightGlassTheme.textMuted,
                                                size: 19,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedBuilder(
                                          animation: _shake,
                                          builder: (context, child) {
                                            final t = _shake.value;
                                            final dx = math.sin(t * math.pi * 8) * (1 - t) * 10;
                                            return Transform.translate(offset: Offset(dx, 0), child: child);
                                          },
                                          child: PinInputField(
                                            key: _pinKey,
                                            obscure: _obscurePin,
                                            hasError: _pinError,
                                            onChanged: (value) => setState(() {
                                              _pin = value;
                                              if (_pinError) _pinError = false;
                                            }),
                                            onCompleted: (_) {
                                              if (!context.read<AuthProvider>().isLoading) {
                                                _handleLogin(context.read<AuthProvider>());
                                              }
                                            },
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
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: LightGlassTheme.danger.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: LightGlassTheme.danger.withOpacity(0.25)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.error_outline_rounded,
                                                    color: LightGlassTheme.danger, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    auth.errorMessage!,
                                                    style: const TextStyle(
                                                        color: LightGlassTheme.danger, fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 22),
                                        Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            gradient: const LinearGradient(
                                              colors: [LightGlassTheme.forestGreen, LightGlassTheme.lighterGreen],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: LightGlassTheme.forestGreen.withOpacity(0.25),
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: (auth.isLoading || _loginSucceeded)
                                                ? null
                                                : () => _handleLogin(auth),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              foregroundColor: Colors.white,
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
                                                    : const Text(
                                                        'Log In',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w800, fontSize: 15.5),
                                                      ),
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
                                            child: RichText(
                                              text: const TextSpan(
                                                style: TextStyle(
                                                    color: LightGlassTheme.textMuted, fontSize: 13.5),
                                                children: [
                                                  TextSpan(text: "Don't have an account? "),
                                                  TextSpan(
                                                    text: 'Register',
                                                    style: TextStyle(
                                                      color: LightGlassTheme.forestGreen,
                                                      fontWeight: FontWeight.w800,
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
                      FadeTransition(
                        opacity: _formFade,
                        child: const Center(
                          child: Text(
                            'Developed by Justine Villarosa',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: LightGlassTheme.textMuted,
                              fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }
}