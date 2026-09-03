import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../domain/qr_model.dart';
import 'card_wallet_provider.dart';
import 'wallet_theme.dart';

class QrScannerSheet extends StatefulWidget {
  final String cardWalletId;
  const QrScannerSheet({super.key, required this.cardWalletId});

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet> with TickerProviderStateMixin {
  bool _handled = false;
  bool _success = false;

  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // Slow vertical sweep for the scan-line, mirrors the "searching" read of
  // Apple's Wallet card-scan UI rather than a bare camera preview.
  late final AnimationController _scanLineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  // One-shot pulse played on the viewfinder frame the instant a code is
  // recognized, before we even know if the reservation call succeeds.
  late final AnimationController _frameController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _frameScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: WalletMotion.settle)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: WalletMotion.pop)),
      weight: 60,
    ),
  ]).animate(_frameController);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    _frameController.dispose();
    super.dispose();
  }

  Map<String, String>? _parse(String raw) {
    final parts = raw.split('|');
    if (parts.length < 2) return null;
    return {
      'provider': parts[0].toLowerCase(),
      'amount': parts[1],
      'merchant': parts.length > 2 ? parts[2] : '',
      'account': parts.length > 3 ? parts[3] : '',
    };
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final parsed = _parse(raw);
    if (parsed == null) return;

    setState(() => _handled = true);
    HapticFeedback.mediumImpact();
    setState(() => _success = true);
    unawaited(_frameController.forward(from: 0));

    // Brief pause so the success pulse is actually perceivable before the
    // sheet navigates away — otherwise it flashes for a single frame.
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    final amount = double.tryParse(parsed['amount']!) ?? 0;
    final provider = parsed['provider']!;

    final reservation = await context.read<CardWalletProvider>().reserveQr(
          cardWalletId: widget.cardWalletId,
          amount: amount,
          provider: provider,
          merchantName: parsed['merchant']!.isEmpty ? null : parsed['merchant'],
          destinationAccount: parsed['account']!.isEmpty ? null : parsed['account'],
          rawPayload: raw,
        );

    if (!mounted) return;
    if (reservation == null) {
      setState(() {
        _handled = false;
        _success = false;
      });
      final err = context.read<CardWalletProvider>().errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }

    Navigator.of(context).pop<QrReservation>(reservation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            // Surfaces the real reason the camera preview isn't showing
            // instead of the generic "!" placeholder icon.
            errorBuilder: (context, error) => _CameraError(
              message: error.errorDetails?.message ?? error.errorCode.name,
              onGoBack: () => Navigator.of(context).pop(),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([_scanLineController, _frameController]),
              builder: (context, _) => CustomPaint(
                painter: _ViewfinderPainter(
                  scanProgress: _scanLineController.value,
                  frameScale: _frameScale.value,
                  success: _success,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _GlassCircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Scan to Pay',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<TorchState>(
                          valueListenable: _controller.torchState,
                          builder: (context, torch, _) => _GlassCircleButton(
                            icon: torch == TorchState.on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            onTap: () => _controller.toggleTorch(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _GlassCircleButton(
                          icon: Icons.cameraswitch_rounded,
                          onTap: () => _controller.switchCamera(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: AnimatedOpacity(
                opacity: _success ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  offset: 8,
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Text(
                        'Align the QR code within the frame',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
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

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleDown: 0.9,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onGoBack});
  final String message;
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_rounded, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              'Camera unavailable:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onGoBack, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}

/// Draws the dark scrim with a rounded-square cutout, animated corner
/// brackets, and a glowing scan line — a proper "viewfinder" read instead
/// of a bare camera feed with no framing.
class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({
    required this.scanProgress,
    required this.frameScale,
    required this.success,
  });

  final double scanProgress;
  final double frameScale;
  final bool success;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.72;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - size.height * 0.04),
      width: side * frameScale,
      height: side * frameScale,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));

    final scrimPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrimPath, Paint()..color = Colors.black.withOpacity(0.55));

    final accent = success ? const Color(0xFF3FD17A) : Colors.white;

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withOpacity(success ? 0.9 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = success ? 3 : 1.4,
    );

    const bracketLen = 26.0;
    final bracketPaint = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(Offset o, double dx, double dy) {
      canvas.drawLine(o, o.translate(dx * bracketLen, 0), bracketPaint);
      canvas.drawLine(o, o.translate(0, dy * bracketLen), bracketPaint);
    }

    corner(rrect.outerRect.topLeft.translate(0, 6), 1, 1);
    corner(rrect.outerRect.topRight.translate(0, 6), -1, 1);
    corner(rrect.outerRect.bottomLeft.translate(0, -6), 1, -1);
    corner(rrect.outerRect.bottomRight.translate(0, -6), -1, -1);

    if (!success) {
      final lineY = rect.top + rect.height * scanProgress;
      final lineRect = Rect.fromLTWH(rect.left + 8, lineY - 10, rect.width - 16, 20);
      final glow = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, accent.withOpacity(0.55), Colors.transparent],
        ).createShader(lineRect);
      canvas.drawRect(lineRect, glow);
      canvas.drawLine(
        Offset(rect.left + 8, lineY),
        Offset(rect.right - 8, lineY),
        Paint()
          ..color = accent.withOpacity(0.9)
          ..strokeWidth = 2,
      );
    } else {
      final checkPaint = Paint()
        ..color = accent
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final c = rect.center;
      final path = Path()
        ..moveTo(c.dx - 22, c.dy)
        ..lineTo(c.dx - 6, c.dy + 16)
        ..lineTo(c.dx + 24, c.dy - 18);
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.frameScale != frameScale ||
        oldDelegate.success != success;
  }
}

void unawaited(Future<void> future) {}