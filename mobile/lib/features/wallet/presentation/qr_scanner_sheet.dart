import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../domain/emv_qr_parser.dart';
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

  late final AnimationController _scanLineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    EmvQrPayload payload;
    try {
      payload = EmvQrParser.parse(raw);
    } on EmvQrParseException {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't read this as a payment QR code."),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!payload.crcValid) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This code failed an integrity check — try scanning again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _handled = true);
    HapticFeedback.mediumImpact();
    setState(() => _success = true);
    unawaited(_frameController.forward(from: 0));
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;

    // Most real P2P QR Ph codes are static and carry no fixed amount —
    // the payer always types it into their own banking app. Ask here too.
    final confirmedAmount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AmountConfirmSheet(
        merchantName: payload.merchantName,
        proxyValue: payload.proxyValue,
        initialAmount: payload.amount,
      ),
    );

    if (!mounted) return;
    if (confirmedAmount == null || confirmedAmount <= 0) {
      setState(() {
        _handled = false;
        _success = false;
      });
      return;
    }

    // Provider comes from the wallet the user is already inside in
    // GastoApp — NOT from the QR. QR Ph doesn't identify a brand, and
    // even GCash/Maya's own native codes don't tell us which app the
    // *scanning* user wants to pay with; that's the user's own choice.
    final wallet = context.read<CardWalletProvider>().byId(widget.cardWalletId);
    final provider = (wallet?.provider ?? 'Other').toLowerCase();

    final reservation = await context.read<CardWalletProvider>().reserveQr(
          cardWalletId: widget.cardWalletId,
          amount: confirmedAmount,
          provider: provider,
          merchantName: payload.merchantName,
          destinationAccount: payload.proxyValue,
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
                        ValueListenableBuilder<MobileScannerState>(
                          valueListenable: _controller,
                          builder: (context, state, _) => _GlassCircleButton(
                            icon: state.torchState == TorchState.on
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
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
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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

/// Shown right after a successful scan — collects/confirms the amount
/// (most P2P QR Ph codes carry none) before a reservation is created.
class _AmountConfirmSheet extends StatefulWidget {
  const _AmountConfirmSheet({this.merchantName, this.proxyValue, this.initialAmount});
  final String? merchantName;
  final String? proxyValue;
  final double? initialAmount;

  @override
  State<_AmountConfirmSheet> createState() => _AmountConfirmSheetState();
}

class _AmountConfirmSheetState extends State<_AmountConfirmSheet> {
  late final _controller = TextEditingController(
    text: (widget.initialAmount != null && widget.initialAmount! > 0)
        ? widget.initialAmount!.toStringAsFixed(2)
        : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WalletSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHeader(title: 'Confirm Payment', icon: Icons.receipt_long_rounded),
          if (widget.merchantName != null) ...[
            Text('To: ${widget.merchantName}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
          ],
          if (widget.proxyValue != null) ...[
            Text(widget.proxyValue!, style: TextStyle(color: WalletPalette.textMuted, fontSize: 12.5)),
            const SizedBox(height: 14),
          ],
          SheetTextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            label: 'Amount (PHP)',
            icon: Icons.payments_outlined,
            prefixText: '₱ ',
          ),
          const SizedBox(height: 6),
          Text(
            widget.initialAmount == null
                ? "This code didn't specify an amount — enter what you're sending."
                : 'Confirm the amount before continuing.',
            style: TextStyle(fontSize: 12, color: WalletPalette.textMuted, height: 1.3),
          ),
          const SizedBox(height: 22),
          SheetPrimaryButton(
            label: 'Continue',
            onTap: () => Navigator.of(context).pop(double.tryParse(_controller.text)),
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
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
            Text('Camera unavailable:\n$message', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onGoBack, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter({required this.scanProgress, required this.frameScale, required this.success});
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
    canvas.drawPath(scrimPath, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final accent = success ? const Color(0xFF3FD17A) : Colors.white;

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: success ? 0.9 : 0.55)
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
          colors: [Colors.transparent, accent.withValues(alpha: 0.55), Colors.transparent],
        ).createShader(lineRect);
      canvas.drawRect(lineRect, glow);
      canvas.drawLine(
        Offset(rect.left + 8, lineY),
        Offset(rect.right - 8, lineY),
        Paint()..color = accent.withValues(alpha: 0.9)..strokeWidth = 2,
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